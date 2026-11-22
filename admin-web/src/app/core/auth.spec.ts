import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';
import { Auth } from './auth';

const session = {
  accessToken: 'access',
  refreshToken: 'refresh',
  user: { fullName: 'Admin test', role: 'ADMIN' },
};

describe('Admin authentication', () => {
  let auth: Auth;
  let http: HttpTestingController;
  beforeEach(() => {
    TestBed.resetTestingModule();
    sessionStorage.clear();
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: Router, useValue: { navigateByUrl: vi.fn().mockResolvedValue(true) } },
      ],
    });
    auth = TestBed.inject(Auth);
    http = TestBed.inject(HttpTestingController);
  });
  afterEach(() => {
    try {
      http.verify();
    } finally {
      TestBed.resetTestingModule();
      sessionStorage.clear();
    }
  });

  async function login(): Promise<void> {
    const operation = auth.login('admin@emsi-edu.ma', 'password');
    http.expectOne('/api/v1/auth/login').flush(session);
    await operation;
  }

  it('rejects student sessions and revokes their refresh token', async () => {
    const operation = auth.login('student@emsi-edu.ma', 'password');
    const rejected = expect(operation).rejects.toThrow('droits administrateur');
    http
      .expectOne('/api/v1/auth/login')
      .flush({ ...session, user: { ...session.user, role: 'STUDENT' } });
    await Promise.resolve();
    http.expectOne('/api/v1/auth/logout').flush(null);
    await rejected;
    expect(sessionStorage.getItem('emsidrive-admin')).toBeNull();
  });

  it('shares a single refresh across concurrent expired API calls', async () => {
    await login();
    const first = auth.request('GET', '/admin/users');
    const second = auth.request('GET', '/admin/reports');
    http.expectOne('/api/v1/admin/users').flush({}, { status: 401, statusText: 'Expired' });
    http.expectOne('/api/v1/admin/reports').flush({}, { status: 401, statusText: 'Expired' });
    await Promise.resolve();
    http
      .expectOne('/api/v1/auth/refresh')
      .flush({ ...session, accessToken: 'rotated', refreshToken: 'next' });
    await vi.waitFor(() => {
      const users = http.expectOne('/api/v1/admin/users');
      expect(users.request.headers.get('Authorization')).toBe('Bearer rotated');
      users.flush({ items: [] });
    });
    http.expectOne('/api/v1/admin/reports').flush({ items: [] });
    await Promise.all([first, second]);
    expect(JSON.parse(sessionStorage.getItem('emsidrive-admin')!).refreshToken).toBe('next');
  });

  it('keeps network failures available for retry without erasing the session', async () => {
    await login();
    const request = auth.request('GET', '/admin/dashboard');
    const rejected = expect(request).rejects.toBeTruthy();
    http.expectOne('/api/v1/admin/dashboard').error(new ProgressEvent('error'));
    await rejected;
    expect(sessionStorage.getItem('emsidrive-admin')).not.toBeNull();
  });

  it('discards data returned after logout', async () => {
    await login();
    const request = auth.request('GET', '/admin/dashboard');
    const rejected = expect(request).rejects.toThrow('session a changé');
    const logout = auth.logout();
    http.expectOne('/api/v1/auth/logout').flush(null);
    http.expectOne('/api/v1/admin/dashboard').flush({ users: 42 });
    await logout;
    await rejected;
    expect(sessionStorage.getItem('emsidrive-admin')).toBeNull();
  });

  it('clears the session if the server rejects its refresh token', async () => {
    await login();
    const request = auth.request('GET', '/admin/dashboard');
    const rejected = expect(request).rejects.toBeTruthy();
    http.expectOne('/api/v1/admin/dashboard').flush({}, { status: 401, statusText: 'Expired' });
    await Promise.resolve();
    http.expectOne('/api/v1/auth/refresh').flush({}, { status: 401, statusText: 'Revoked' });
    await rejected;
    expect(sessionStorage.getItem('emsidrive-admin')).toBeNull();
  });
});
