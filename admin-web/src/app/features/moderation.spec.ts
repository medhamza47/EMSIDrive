import { TestBed } from '@angular/core/testing';
import { Users } from './users';
import { Reports } from './reports';
import { Auth } from '../core/auth';

const account = {
  id: 'student-1',
  full_name: 'Test student',
  email: 'test@emsi-edu.ma',
  role: 'STUDENT',
  enabled: true,
  revision: 'revision-1',
  created: 123456789,
  offers: 2,
  requests: 1,
  reports: 0,
};

describe('Moderation forms', () => {
  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => TestBed.resetTestingModule());

  it('submits a reasoned account decision with its loaded revision', async () => {
    const request = vi
      .fn()
      .mockImplementation((_method, path) =>
        Promise.resolve(
          path === '/admin/users/student-1'
            ? account
            : { items: [account], total: 1, page: 0, size: 20 },
        ),
      );
    await TestBed.configureTestingModule({
      imports: [Users],
      providers: [{ provide: Auth, useValue: { request } }],
    }).compileComponents();
    const fixture = TestBed.createComponent(Users);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
    const element: HTMLElement = fixture.nativeElement;
    element.querySelector<HTMLButtonElement>('td button')!.click();
    await fixture.whenStable();
    fixture.detectChanges();
    const reason = element.querySelector<HTMLTextAreaElement>('#reason')!;
    reason.value = 'Repeated unsafe conduct';
    reason.dispatchEvent(new Event('input'));
    fixture.detectChanges();
    await fixture.whenStable();
    reason.closest('form')!.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
    await fixture.whenStable();
    fixture.detectChanges();
    expect(request).toHaveBeenCalledWith('PUT', '/admin/users/student-1/access', {
      enabled: false,
      reason: 'Repeated unsafe conduct',
      revision: 'revision-1',
    });
    expect(element.textContent).toContain('Décision enregistrée');
  });

  it('protects administrator accounts in the rendered account form', async () => {
    const request = vi
      .fn()
      .mockImplementation((_method, path) =>
        Promise.resolve(
          path === '/admin/users/student-1'
            ? { ...account, role: 'ADMIN' }
            : { items: [], total: 0, page: 0, size: 20 },
        ),
      );
    await TestBed.configureTestingModule({
      imports: [Users],
      providers: [{ provide: Auth, useValue: { request } }],
    }).compileComponents();
    const fixture = TestBed.createComponent(Users);
    await fixture.componentInstance.open({ ...account, role: 'ADMIN' });
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('#reason')).toBeNull();
    expect(fixture.nativeElement.textContent).toContain('procédure locale');
  });

  it('sends a report decision with its reason and revision', async () => {
    const report = {
      id: 'report-1',
      reporter: 'Reporter',
      reported_user: 'Driver',
      reported_user_id: 'driver-1',
      category: 'OTHER',
      description: 'Test facts',
      status: 'OPEN',
      revision: 3,
      resolution_note: null,
      created: 123456789,
      booking_id: 'booking-1',
      ride_offer_id: null,
      ride_request_id: null,
    };
    const request = vi.fn().mockResolvedValue({ items: [report], total: 1, page: 0, size: 20 });
    await TestBed.configureTestingModule({
      imports: [Reports],
      providers: [{ provide: Auth, useValue: { request } }],
    }).compileComponents();
    const fixture = TestBed.createComponent(Reports);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
    const element: HTMLElement = fixture.nativeElement;
    element.querySelector<HTMLButtonElement>('td button')!.click();
    fixture.detectChanges();
    await fixture.whenStable();
    const reason = element.querySelector<HTMLTextAreaElement>('#note')!;
    reason.value = 'Facts reviewed';
    reason.dispatchEvent(new Event('input'));
    fixture.detectChanges();
    await fixture.whenStable();
    reason.closest('form')!.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
    await fixture.whenStable();
    expect(request).toHaveBeenCalledWith('PUT', '/admin/reports/report-1', {
      status: 'UNDER_REVIEW',
      reason: 'Facts reviewed',
      revision: 3,
    });
  });
});
