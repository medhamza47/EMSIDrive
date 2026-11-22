import { DatePipe } from '@angular/common';
import { Component, inject, OnInit, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Auth, errorMessage } from '../core/auth';
import { PageState } from '../core/page-state';
import { Label } from '../shared/label';
import { Pager } from '../shared/pager';

interface Report {
  id: string;
  reporter: string;
  reported_user: string;
  reported_user_id: string;
  category: string;
  description: string;
  status: string;
  revision: number;
  resolution_note: string | null;
  created: number;
  booking_id: string | null;
  ride_offer_id: string | null;
  ride_request_id: string | null;
}

@Component({
  imports: [FormsModule, DatePipe, Label, Pager],
  template: `<div class="page-heading">
      <div>
        <span class="eyebrow">CONFIANCE & SÉCURITÉ</span>
        <h1>Signalements</h1>
        <p>Examine les faits et conserve une trace de chaque décision.</p>
      </div>
    </div>
    <section class="panel">
      <form class="filters" (ngSubmit)="filter()">
        <div class="grow">
          <label for="report-filter">État du dossier</label>
          <select id="report-filter" name="status" [(ngModel)]="status">
            <option value="">Tous les signalements</option>
            <option value="OPEN">Ouverts</option>
            <option value="UNDER_REVIEW">En examen</option>
            <option value="RESOLVED">Résolus</option>
            <option value="DISMISSED">Classés sans suite</option>
          </select>
        </div>
        <button [disabled]="state.loading()">Filtrer</button>
      </form>
      @if (state.error()) {
        <p class="error" role="alert">{{ state.error() }}</p>
      }
      @if (state.loading()) {
        <p role="status">Chargement des signalements…</p>
      }
      <div class="table-scroll">
        <table>
          <thead>
            <tr>
              <th>Motif</th>
              <th>Signalé par</th>
              <th>Utilisateur concerné</th>
              <th>Date</th>
              <th>État</th>
              <th>Dossier</th>
            </tr>
          </thead>
          <tbody>
            @for (report of state.items(); track report.id) {
              <tr>
                <td>
                  <strong>{{ report.category | label }}</strong>
                </td>
                <td>{{ report.reporter }}</td>
                <td>{{ report.reported_user || 'Compte supprimé' }}</td>
                <td>{{ report.created | date: 'dd/MM/yyyy HH:mm' }}</td>
                <td>
                  <span class="badge" [class.warning]="report.status === 'OPEN'">{{
                    report.status | label
                  }}</span>
                </td>
                <td>
                  <button class="secondary" [disabled]="busy()" (click)="open(report)">
                    Examiner
                  </button>
                </td>
              </tr>
            }
          </tbody>
        </table>
      </div>
      @if (!state.loading() && !state.error() && !state.items().length) {
        <div class="empty">
          <h2>Aucun dossier à afficher</h2>
          <p>Les signalements envoyés depuis l’application apparaîtront ici.</p>
        </div>
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
    @if (selected(); as report) {
      <section class="panel detail">
        <div class="page-heading">
          <div>
            <span class="eyebrow">DOSSIER DE MODÉRATION</span>
            <h2>{{ report.category | label }}</h2>
          </div>
          <button class="secondary" [disabled]="busy()" (click)="selected.set(null)">Fermer</button>
        </div>
        <p>
          <strong>{{ report.reporter }}</strong> a signalé
          <strong>{{ report.reported_user }}</strong>.
        </p>
        <blockquote>{{ report.description }}</blockquote>
        <div class="references">
          <p>
            Référence du signalement <code>{{ report.id }}</code>
          </p>
          @if (report.booking_id) {
            <p>
              Réservation <code>{{ report.booking_id }}</code>
            </p>
          }
          @if (report.ride_offer_id) {
            <p>
              Offre <code>{{ report.ride_offer_id }}</code>
            </p>
          }
          @if (report.ride_request_id) {
            <p>
              Demande <code>{{ report.ride_request_id }}</code>
            </p>
          }
        </div>
        @if (report.resolution_note) {
          <p class="notice">Dernière note de modération · {{ report.resolution_note }}</p>
        }
        <form (ngSubmit)="decide(report)" #decision="ngForm">
          <label for="decision">Décision</label
          ><select id="decision" name="decision" [(ngModel)]="nextStatus">
            <option value="OPEN">Rouvrir</option>
            <option value="UNDER_REVIEW">Passer en examen</option>
            <option value="RESOLVED">Résoudre</option>
            <option value="DISMISSED">Classer sans suite</option>
          </select>
          <label for="note">Motif et mesures prises</label
          ><textarea
            id="note"
            name="note"
            required
            maxlength="500"
            rows="4"
            [(ngModel)]="reason"
          ></textarea>
          <button [disabled]="busy() || decision.invalid || !reason.trim()">
            {{ busy() ? 'Enregistrement…' : 'Enregistrer la décision' }}
          </button>
        </form>
        <p class="muted">
          Pour suspendre un compte, utilise la rubrique Utilisateurs avec un motif explicite.
        </p>
      </section>
    }`,
})
export class Reports implements OnInit {
  private api = inject(Auth);
  readonly state = new PageState<Report>(this.api, '/reports');
  status = 'OPEN';
  nextStatus = 'UNDER_REVIEW';
  reason = '';
  selected = signal<Report | null>(null);
  busy = signal(false);
  actionError = signal('');
  message = signal('');
  ngOnInit(): void {
    this.filter();
  }
  filter(): void {
    this.selected.set(null);
    void this.state.load(this.status ? { status: this.status } : {}, 0);
  }
  open(report: Report): void {
    this.selected.set(report);
    this.reason = '';
    this.nextStatus = 'UNDER_REVIEW';
    this.actionError.set('');
    this.message.set('');
  }
  async decide(report: Report): Promise<void> {
    if (this.busy() || !this.reason.trim()) return;
    this.busy.set(true);
    this.actionError.set('');
    this.message.set('');
    try {
      await this.api.request('PUT', '/admin/reports/' + report.id, {
        status: this.nextStatus,
        reason: this.reason,
        revision: report.revision,
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
