import { Component, inject, OnInit, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Auth, errorMessage } from '../core/auth';

@Component({
  imports: [RouterLink],
  template: `<div class="page-heading">
      <div>
        <span class="eyebrow">PILOTAGE</span>
        <h1>Vue d’ensemble</h1>
        <p>L’activité de ta communauté, au même endroit.</p>
      </div>
      <button class="secondary" [disabled]="loading()" (click)="load()">Actualiser ↻</button>
    </div>
    @if (error()) {
      <p class="error" role="alert">{{ error() }}</p>
    }
    @if (loading()) {
      <p role="status">Chargement des indicateurs…</p>
    }
    @if (stats(); as data) {
      <section class="metrics" aria-label="Indicateurs de la communauté">
        @for (metric of metrics; track metric.key) {
          <a class="metric" [routerLink]="metric.path"
            ><span class="metric-icon">{{ metric.icon }}</span>
            <strong>{{ data[metric.key] }}</strong><span>{{ metric.title }}</span
            ><small>{{ metric.detail }}</small></a
          >
        }
      </section>
      <section class="overview-grid">
        <article class="feature-card">
          <span class="eyebrow">MODÉRATION</span>
          <h2>Prendre soin de la communauté</h2>
          <p>
            <strong>{{ data['reports'] }}</strong> signalement(s) à examiner. Les décisions sont
            conservées dans l’historique des actions.
          </p>
          <a routerLink="/signalements" class="button">Examiner les signalements →</a>
        </article>
        <article class="panel">
          <span class="eyebrow">RÉSEAU EMSI</span>
          <h2>Deux campus, une ville</h2>
          <div class="campus-line">
            <span class="campus-dot"></span>
            <div>
              <strong>EMSI Marrakech Centre</strong>
              <p>Route de Safi · lot Bouizgaren</p>
            </div>
          </div>
          <div class="campus-line">
            <span class="campus-dot"></span>
            <div>
              <strong>EMSI Marrakech Targa</strong>
              <p>Trajets vers et depuis le campus</p>
            </div>
          </div>
          <a routerLink="/trajets" class="text-link">Consulter les trajets ↗</a>
        </article>
      </section>
      <p class="muted">
        Indicateurs cumulés issus de la base de données · {{ data['suspended'] }} compte(s)
        suspendu(s)
      </p>
    }`,
})
export class Dashboard implements OnInit {
  private api = inject(Auth);
  stats = signal<Record<string, number> | null>(null);
  loading = signal(false);
  error = signal('');
  metrics = [
    {
      key: 'users',
      title: 'Étudiants inscrits',
      detail: 'Comptes de la communauté',
      icon: '♧',
      path: '/utilisateurs',
    },
    {
      key: 'offers',
      title: 'Offres publiées',
      detail: 'Conducteurs engagés',
      icon: '↗',
      path: '/trajets',
    },
    {
      key: 'requests',
      title: 'Demandes publiées',
      detail: 'Besoins de déplacement',
      icon: '↙',
      path: '/trajets',
    },
    {
      key: 'bookings',
      title: 'Réservations',
      detail: 'Toutes les réservations',
      icon: '▣',
      path: '/trajets',
    },
    {
      key: 'completed',
      title: 'Trajets terminés',
      detail: 'Offres arrivées à destination',
      icon: '✓',
      path: '/trajets',
    },
    {
      key: 'reports',
      title: 'Signalements actifs',
      detail: 'Ouverts et en examen',
      icon: '⚑',
      path: '/signalements',
    },
  ];
  ngOnInit(): void {
    void this.load();
  }
  async load(): Promise<void> {
    this.loading.set(true);
    this.error.set('');
    try {
      this.stats.set(await this.api.request('GET', '/admin/dashboard'));
    } catch (error) {
      this.error.set(errorMessage(error));
    } finally {
      this.loading.set(false);
    }
  }
}
