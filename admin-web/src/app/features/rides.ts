import { DatePipe } from '@angular/common';
import { Component, inject, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Auth } from '../core/auth';
import { PageState } from '../core/page-state';
import { Label } from '../shared/label';
import { Pager } from '../shared/pager';

interface Ride {
  id: string;
  kind: string;
  author: string;
  origin_label: string;
  destination_label: string;
  status: string;
  seats: number;
  departure: number;
}

@Component({
  imports: [FormsModule, DatePipe, Label, Pager],
  template: `<div class="page-heading">
      <div>
        <span class="eyebrow">DÉPLACEMENTS</span>
        <h1>Supervision des trajets</h1>
        <p>Offres et demandes des deux campus, avec leur état actuel.</p>
      </div>
    </div>
    <section class="panel">
      <form class="filters" (ngSubmit)="filter()">
        <div>
          <label for="kind">Type</label
          ><select id="kind" name="kind" [(ngModel)]="kind">
            <option value="">Tous</option>
            <option value="OFFER">Offres</option>
            <option value="REQUEST">Demandes</option>
          </select>
        </div>
        <div>
          <label for="campus">Campus</label
          ><select id="campus" name="campus" [(ngModel)]="campus">
            <option value="">Les deux campus</option>
            <option value="CENTRE">Centre</option>
            <option value="TARGA">Targa</option>
          </select>
        </div>
        <div>
          <label for="status">Statut</label
          ><select id="status" name="status" [(ngModel)]="status">
            <option value="">Tous</option>
            <option value="OPEN">Ouvert</option>
            <option value="PENDING">En attente</option>
            <option value="FULL">Complet</option>
            <option value="MATCHED">Acceptée</option>
            <option value="ONGOING">En cours</option>
            <option value="COMPLETED">Terminé</option>
            <option value="CANCELLED">Annulé</option>
            <option value="EXPIRED">Expiré</option>
          </select>
        </div>
        <div>
          <label for="date">Date à Marrakech</label
          ><input id="date" type="date" name="date" [(ngModel)]="date" />
        </div>
        <button [disabled]="state.loading()">Filtrer</button>
      </form>
      @if (state.error()) {
        <p class="error" role="alert">{{ state.error() }}</p>
      }
      @if (state.loading()) {
        <p role="status">Chargement des trajets…</p>
      }
      <div class="table-scroll">
        <table>
          <thead>
            <tr>
              <th>Trajet</th>
              <th>Auteur</th>
              <th>Type</th>
              <th>Départ</th>
              <th>Places</th>
              <th>Statut</th>
            </tr>
          </thead>
          <tbody>
            @for (ride of state.items(); track ride.kind + ride.id) {
              <tr>
                <td>
                  <strong>{{ ride.origin_label }}</strong
                  ><small>→ {{ ride.destination_label }}</small>
                </td>
                <td>{{ ride.author }}</td>
                <td>
                  <span class="badge neutral">{{ ride.kind | label }}</span>
                </td>
                <td>{{ ride.departure | date: 'dd/MM/yyyy HH:mm' }}</td>
                <td>{{ ride.seats }}</td>
                <td>
                  <span class="badge">{{ ride.status | label }}</span>
                </td>
              </tr>
            }
          </tbody>
        </table>
      </div>
      @if (!state.loading() && !state.error() && !state.items().length) {
        <p class="empty">Aucun trajet pour ces filtres.</p>
      }
      <app-pager
        [total]="state.total()"
        [page]="state.page()"
        [loading]="state.loading()"
        (change)="state.load(undefined, $event)"
      />
    </section>
    <p class="muted">
      Les dates du filtre suivent le fuseau de Marrakech. Les heures affichées suivent celui de ton
      navigateur.
    </p>`,
})
export class Rides implements OnInit {
  readonly state = new PageState<Ride>(inject(Auth), '/rides');
  kind = '';
  campus = '';
  status = '';
  date = '';
  ngOnInit(): void {
    void this.state.load();
  }
  filter(): void {
    const params: Record<string, string> = {
      kind: this.kind,
      campus: this.campus,
      status: this.status,
    };
    if (this.date) params['date'] = this.date;
    void this.state.load(params, 0);
  }
}
