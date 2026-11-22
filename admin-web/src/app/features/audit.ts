import { DatePipe } from '@angular/common';
import { Component, inject, OnInit } from '@angular/core';
import { Auth } from '../core/auth';
import { PageState } from '../core/page-state';
import { Label } from '../shared/label';
import { Pager } from '../shared/pager';

interface Action {
  id: number;
  actor: string;
  action: string;
  target_id: string;
  reason: string;
  created: number;
}

@Component({
  imports: [DatePipe, Label, Pager],
  template: `<div class="page-heading">
      <div>
        <span class="eyebrow">TRAÇABILITÉ</span>
        <h1>Historique des actions</h1>
        <p>Les décisions de modération, leur auteur et leur motif.</p>
      </div>
      <button class="secondary" [disabled]="state.loading()" (click)="state.load()">
        Actualiser ↻
      </button>
    </div>
    <section class="panel">
      @if (state.error()) {
        <p class="error" role="alert">{{ state.error() }}</p>
      }
      @if (state.loading()) {
        <p role="status">Chargement de l’historique…</p>
      }
      <div class="table-scroll">
        <table>
          <thead>
            <tr>
              <th>Date</th>
              <th>Administrateur</th>
              <th>Action</th>
              <th>Motif</th>
              <th>Référence</th>
            </tr>
          </thead>
          <tbody>
            @for (action of state.items(); track action.id) {
              <tr>
                <td>{{ action.created | date: 'dd/MM/yyyy HH:mm' }}</td>
                <td>{{ action.actor }}</td>
                <td>
                  <span class="badge neutral">{{ action.action | label }}</span>
                </td>
                <td class="reason-cell">{{ action.reason }}</td>
                <td>
                  <code>{{ action.target_id }}</code>
                </td>
              </tr>
            }
          </tbody>
        </table>
      </div>
      @if (!state.loading() && !state.error() && !state.items().length) {
        <p class="empty">Les prochaines décisions seront enregistrées ici.</p>
      }
      <app-pager
        [total]="state.total()"
        [page]="state.page()"
        [loading]="state.loading()"
        (change)="state.load(undefined, $event)"
      />
    </section>`,
})
export class Audit implements OnInit {
  readonly state = new PageState<Action>(inject(Auth), '/audit');
  ngOnInit(): void {
    void this.state.load();
  }
}
