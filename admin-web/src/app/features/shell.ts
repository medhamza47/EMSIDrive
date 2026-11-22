import { Component, inject } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { Auth } from '../core/auth';

@Component({
  imports: [RouterLink, RouterLinkActive, RouterOutlet],
  template: `<div class="workspace">
    <aside class="sidebar">
      <a routerLink="/" class="brand">E<span>MSI</span>Drive</a>
      <span class="sidebar-caption">ADMINISTRATION</span>
      <nav aria-label="Navigation principale">
        @for (link of links; track link.path) {
          <a
            [routerLink]="link.path"
            routerLinkActive="active"
            [routerLinkActiveOptions]="{ exact: link.path === '/' }"
          >
            <span aria-hidden="true">{{ link.icon }}</span>{{ link.title }}</a
          >
        }
      </nav>
      <div class="sidebar-bottom">
        <div class="campus-dot"></div>
        <strong>EMSI Marrakech</strong><small>Centre & Targa</small>
      </div>
    </aside>
    <div class="main-area">
      <header class="topbar">
        <span>Espace de gestion <span class="badge">Administrateur</span></span>
        <div>
          <span class="account-name">{{ auth.name() }}</span
          ><button class="secondary" (click)="auth.logout()">Déconnexion</button>
        </div>
      </header>
      <main class="content"><router-outlet /></main>
      <footer>EMSIDrive · Administration de la communauté étudiante</footer>
    </div>
  </div>`,
})
export class Shell {
  readonly auth = inject(Auth);
  readonly links = [
    { path: '/', title: 'Vue d’ensemble', icon: '◫' },
    { path: '/utilisateurs', title: 'Utilisateurs', icon: '♧' },
    { path: '/trajets', title: 'Trajets', icon: '↗' },
    { path: '/signalements', title: 'Signalements', icon: '⚑' },
    { path: '/historique', title: 'Historique', icon: '◷' },
  ];
}
