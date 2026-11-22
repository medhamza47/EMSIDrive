import { CanActivateFn, Router, Routes } from '@angular/router';
import { inject } from '@angular/core';
import { Auth } from './core/auth';

const adminGuard: CanActivateFn = async () => {
  const auth = inject(Auth);
  const router = inject(Router);
  return (await auth.restore()) || router.createUrlTree(['/connexion']);
};

export const routes: Routes = [
  { path: 'connexion', loadComponent: () => import('./features/login').then((m) => m.Login) },
  {
    path: '',
    canActivate: [adminGuard],
    loadComponent: () => import('./features/shell').then((m) => m.Shell),
    children: [
      { path: '', loadComponent: () => import('./features/dashboard').then((m) => m.Dashboard) },
      {
        path: 'utilisateurs',
        loadComponent: () => import('./features/users').then((m) => m.Users),
      },
      { path: 'trajets', loadComponent: () => import('./features/rides').then((m) => m.Rides) },
      {
        path: 'signalements',
        loadComponent: () => import('./features/reports').then((m) => m.Reports),
      },
      { path: 'historique', loadComponent: () => import('./features/audit').then((m) => m.Audit) },
    ],
  },
  { path: '**', redirectTo: '' },
];
