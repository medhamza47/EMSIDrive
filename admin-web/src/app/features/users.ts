import { DatePipe } from '@angular/common';
import { Component, inject, OnInit, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Auth, errorMessage } from '../core/auth';
import { PageState } from '../core/page-state';
import { Label } from '../shared/label';
import { Pager } from '../shared/pager';

interface Account {
  id: string;
  full_name: string;
  email: string;
  role: string;
  enabled: boolean;
  revision: string;
  created: number;
  offers?: number;
  requests?: number;
  reports?: number;
}

@Component({
  imports: [FormsModule, DatePipe, Label, Pager],
  template: `<div class="page-heading">
      <div>
        <span class="eyebrow">COMMUNAUTÉ</span>
        <h1>Utilisateurs</h1>
        <p>Consulte les comptes et gère leur accès à EMSIDrive.</p>
      </div>
    </div>
    <section class="panel">
      <form class="filters" (ngSubmit)="filter()">
        <div class="grow">
          <label for="search">Nom ou email</label
          ><input
            id="search"
            name="search"
            [(ngModel)]="search"
            placeholder="Rechercher un étudiant"
            maxlength="180"
          />
        </div>
        <div>
          <label for="access">Accès</label
          ><select id="access" name="access" [(ngModel)]="enabled">
            <option value="">Tous les comptes</option>
            <option value="true">Actifs</option>
            <option value="false">Suspendus</option>
          </select>
        </div>
        <button [disabled]="state.loading()">Rechercher</button>
      </form>
      @if (state.error()) {
        <p class="error" role="alert">{{ state.error() }}</p>
      }
      @if (state.loading()) {
        <p role="status">Chargement des comptes…</p>
      }
      <div class="table-scroll">
        <table>
          <thead>
            <tr>
              <th>Étudiant</th>
              <th>Rôle</th>
              <th>Accès</th>
              <th>Inscription</th>
              <th>Détails</th>
            </tr>
          </thead>
          <tbody>
            @for (user of state.items(); track user.id) {
              <tr>
                <td>
                  <strong>{{ user.full_name }}</strong
                  ><small>{{ user.email }}</small>
                </td>
                <td>{{ user.role | label }}</td>
                <td>
                  <span class="badge" [class.warning]="!user.enabled">{{
                    user.enabled ? 'Actif' : 'Suspendu'
                  }}</span>
                </td>
                <td>{{ user.created | date: 'dd/MM/yyyy' }}</td>
                <td>
                  <button class="secondary" [disabled]="busy()" (click)="open(user)">
                    Consulter
                  </button>
                </td>
              </tr>
            }
          </tbody>
        </table>
      </div>
      @if (!state.loading() && !state.error() && !state.items().length) {
        <p class="empty">Aucun compte ne correspond à ta recherche.</p>
      }
      <app-pager
        [total]="state.total()"
        [page]="state.page()"
        [loading]="state.loading()"
        (change)="state.load(undefined, $event)"
      />
    </section>
    @if (message()) {
      <p class="success" role="status">{{ message() }}</p>
    }
    @if (actionError()) {
      <p class="error" role="alert">{{ actionError() }}</p>
    }
    @if (selected(); as user) {
      <section class="panel detail" aria-label="Détails du compte">
        <div class="page-heading">
          <div>
            <span class="eyebrow">FICHE UTILISATEUR</span>
            <h2>{{ user.full_name }}</h2>
            <p>{{ user.email }}</p>
          </div>
          <button class="secondary" [disabled]="busy()" (click)="selected.set(null)">Fermer</button>
        </div>
        <div class="inline-stats">
          <span
            ><strong>{{ user.offers }}</strong> offres</span
          ><span
            ><strong>{{ user.requests }}</strong> demandes</span
          ><span
            ><strong>{{ user.reports }}</strong> signalements reçus</span
          >
        </div>
        @if (user.role !== 'ADMIN') {
          <form (ngSubmit)="decide(user)" #decision="ngForm">
            <label for="reason">Motif de {{ user.enabled ? 'suspension' : 'réactivation' }}</label>
            <textarea
              id="reason"
              name="reason"
              required
              maxlength="500"
              rows="3"
              [(ngModel)]="reason"
              placeholder="Explique la décision pour l’historique de modération"
            ></textarea>
            @if (user.enabled) {
              <p class="muted">
                La suspension coupe l’accès au compte et révoque ses sessions et appareils de
                notification.
              </p>
            }
            <button
              [class.danger]="user.enabled"
              [disabled]="busy() || decision.invalid || !reason.trim()"
            >
              {{
                busy()
                  ? 'Enregistrement…'
                  : user.enabled
                    ? 'Suspendre ce compte'
                    : 'Réactiver ce compte'
              }}
            </button>
          </form>
        } @else {
          <p class="muted">
            La gestion des droits administrateur passe par la procédure locale documentée.
          </p>
        }
      </section>
    }`,
})
export class Users implements OnInit {
  private api = inject(Auth);
  readonly state = new PageState<Account>(this.api, '/users');
  search = '';
  enabled = '';
  reason = '';
  selected = signal<Account | null>(null);
  busy = signal(false);
  actionError = signal('');
  message = signal('');
  ngOnInit(): void {
    void this.state.load();
  }
  filter(): void {
    void this.state.load(
      { search: this.search, ...(this.enabled ? { enabled: this.enabled } : {}) },
      0,
    );
  }
  async open(user: Account): Promise<void> {
    this.busy.set(true);
    this.actionError.set('');
    this.message.set('');
    this.selected.set(null);
    try {
      this.selected.set(await this.api.request('GET', '/admin/users/' + user.id));
      this.reason = '';
    } catch (error) {
      this.actionError.set(errorMessage(error));
    } finally {
      this.busy.set(false);
    }
  }
  async decide(user: Account): Promise<void> {
    if (this.busy() || !this.reason.trim()) return;
    this.busy.set(true);
    this.actionError.set('');
    this.message.set('');
    try {
      await this.api.request('PUT', '/admin/users/' + user.id + '/access', {
        enabled: !user.enabled,
        reason: this.reason,
        revision: user.revision,
      });
      this.selected.set(null);
      this.message.set('Décision enregistrée dans l’historique.');
      await this.state.load();
    } catch (error) {
      this.actionError.set(errorMessage(error));
    } finally {
      this.busy.set(false);
    }
  }
}
