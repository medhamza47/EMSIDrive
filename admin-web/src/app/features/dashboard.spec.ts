import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { Dashboard } from './dashboard';
import { Auth } from '../core/auth';

describe('Dashboard', () => {
  it('renders API metrics and links to actual administration routes', async () => {
    const request = vi
      .fn()
      .mockResolvedValue({
        users: 42,
        offers: 8,
        requests: 12,
        bookings: 9,
        completed: 3,
        reports: 2,
        suspended: 1,
      });
    await TestBed.configureTestingModule({
      imports: [Dashboard],
      providers: [provideRouter([]), { provide: Auth, useValue: { request } }],
    }).compileComponents();
    const fixture = TestBed.createComponent(Dashboard);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
    const element: HTMLElement = fixture.nativeElement;
    expect(request).toHaveBeenCalledWith('GET', '/admin/dashboard');
    expect(element.querySelector('.metric strong')?.textContent).toBe('42');
    expect(element.querySelectorAll('.metric').length).toBe(6);
    expect(element.querySelector('a[href="/signalements"]')).toBeTruthy();
  });
});
