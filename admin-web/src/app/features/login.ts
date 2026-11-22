import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Auth, errorMessage } from '../core/auth';

@Component({
  imports: [FormsModule],
  template: `<main class="login">
    <section class="login-story">
      <a class="brand" href="/">E<span>MSI</span>Drive</a>
      <span class="eyebrow">ESPACE ADMINISTRATION</span>
      <h1>Une communauté.<br />Des trajets<br />en confiance.</h1>
      <p>
        Supervise les déplacements, accompagne les étudiants et traite les signalements depuis un
        même espace.
      </p>
      <div class="login-route">Marrakech <span>↗</span> EMSI</div>
    </section>
    <section class="login-form">
      <span class="eyebrow">BIENVENUE</span>
      <h2>Connexion administrateur</h2>
      <p class="muted">Utilise un compte EMSIDrive disposant du rôle administrateur.</p>
      <form (ngSubmit)="submit()" #form="ngForm">
        <label for="email">Adresse email</label
        ><input
          id="email"
          name="email"
          type="email"
          autocomplete="username"
          required
          [(ngModel)]="email"
        />
        <label for="password">Mot de passe</label
        ><input
          id="password"
          name="password"
          type="password"
          autocomplete="current-password"
          required
          [(ngModel)]="password"
        />
        @if (error()) {
          <p class="error" role="alert">{{ error() }}</p>
        }
        <button [disabled]="busy() || form.invalid">
          {{ busy() ? 'Connexion…' : 'Se connecter' }} <span>→</span>
        </button>
      </form>
      <p class="login-note">EMSIDrive · Covoiturage étudiant à Marrakech</p>
    </section>
  </main>`,
})
export class Login {
  private auth = inject(Auth);
  private router = inject(Router);
  email = '';
  password = '';
  busy = signal(false);
  error = signal('');
  async submit(): Promise<void> {
    if (this.busy()) return;
    this.busy.set(true);
    this.error.set('');
    try {
      await this.auth.login(this.email.trim(), this.password);
      await this.router.navigateByUrl('/');
    } catch (error) {
      this.error.set(errorMessage(error));
    } finally {
      this.busy.set(false);
      this.password = '';
    }
  }
}
