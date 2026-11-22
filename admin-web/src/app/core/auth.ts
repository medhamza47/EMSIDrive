import { HttpBackend, HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Injectable, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { firstValueFrom } from 'rxjs';

interface Session {
  accessToken: string;
  refreshToken: string;
  user: { fullName: string; role: string };
}

@Injectable({ providedIn: 'root' })
export class Auth {
  private readonly http = new HttpClient(inject(HttpBackend));
  private readonly router = inject(Router);
  private session: Session | null = this.read();
  private refreshing: Promise<Session> | null = null;
  private generation = 0;
  readonly name = signal(this.session?.user.fullName ?? '');

  private read(): Session | null {
    try {
      const value = JSON.parse(sessionStorage.getItem('emsidrive-admin') ?? 'null');
      return value?.accessToken && value?.refreshToken && value?.user?.role === 'ADMIN'
        ? value
        : null;
    } catch {
      return null;
    }
  }

  private save(session: Session): void {
    this.session = session;
    this.name.set(session.user.fullName);
    sessionStorage.setItem('emsidrive-admin', JSON.stringify(session));
  }

  async login(email: string, password: string): Promise<void> {
    const generation = this.generation;
    const session = await firstValueFrom(
      this.http.post<Session>('/api/v1/auth/login', { email, password }),
    );
    if (session.user.role !== 'ADMIN') {
      await firstValueFrom(
        this.http.post('/api/v1/auth/logout', { refreshToken: session.refreshToken }),
      ).catch(() => {});
      throw new Error('Ce compte ne possède pas les droits administrateur.');
    }
    if (generation !== this.generation) throw new Error('La session a changé.');
    this.generation++;
    this.save(session);
  }

  async restore(): Promise<boolean> {
    if (!this.session) return false;
    try {
      const user = await this.request<{ role: string }>('GET', '/me');
      if (user.role !== 'ADMIN') {
        await this.logout();
        return false;
      }
      return true;
    } catch {
      return false;
    }
  }

  async logout(): Promise<void> {
    const previous = this.session;
    this.clear();
    if (previous)
      await firstValueFrom(
        this.http.post('/api/v1/auth/logout', { refreshToken: previous.refreshToken }),
      ).catch(() => {});
  }

  private clear(): void {
    this.generation++;
    this.session = null;
    this.name.set('');
    sessionStorage.removeItem('emsidrive-admin');
    void this.router.navigateByUrl('/connexion');
  }

  private refresh(previous: Session): Promise<Session> {
    if (this.refreshing) return this.refreshing;
    const operation = firstValueFrom(
      this.http.post<Session>('/api/v1/auth/refresh', { refreshToken: previous.refreshToken }),
    )
      .then((session) => {
        if (this.session !== previous) throw new Error('La session a changé.');
        if (session.user.role !== 'ADMIN') {
          this.clear();
          throw new Error('Accès administrateur requis.');
        }
        this.save(session);
        return session;
      })
      .catch((error) => {
        if (
          this.session === previous &&
          error instanceof HttpErrorResponse &&
          [401, 403].includes(error.status)
        )
          this.clear();
        throw error;
      })
      .finally(() => {
        if (this.refreshing === operation) this.refreshing = null;
      });
    this.refreshing = operation;
    return operation;
  }

  async request<T>(
    method: string,
    path: string,
    body?: unknown,
    params: Record<string, string | number> = {},
  ): Promise<T> {
    const generation = this.generation;
    const previous = this.session;
    if (!previous) throw new Error('Reconnecte-toi pour continuer.');
    const send = (session: Session) =>
      firstValueFrom(
        this.http.request<T>(method, '/api/v1' + path, {
          body,
          params,
          headers: { Authorization: `Bearer ${session.accessToken}` },
        }),
      );
    try {
      const value = await send(previous);
      if (this.generation !== generation) throw new Error('La session a changé.');
      return value;
    } catch (error) {
      if (
        !(error instanceof HttpErrorResponse) ||
        error.status !== 401 ||
        !this.session ||
        this.generation !== generation
      )
        throw error;
      const replacement = this.session === previous ? await this.refresh(previous) : this.session;
      try {
        const value = await send(replacement);
        if (this.generation !== generation) throw new Error('La session a changé.');
        return value;
      } catch (retry) {
        if (
          retry instanceof HttpErrorResponse &&
          retry.status === 401 &&
          this.session === replacement
        )
          this.clear();
        throw retry;
      }
    }
  }
}

export function errorMessage(error: unknown): string {
  if (error instanceof HttpErrorResponse) {
    if (error.status === 0)
      return 'Le serveur est inaccessible. Vérifie que le backend est lancé sur le port 8081.';
    if (error.status === 409) return 'Cet élément a changé. Actualise la liste avant de réessayer.';
    if (error.status === 403) return 'Cette action est interdite pour ce compte.';
    if (error.status === 401) return 'Session expirée. Reconnecte-toi.';
    if (error.status === 400) return 'Vérifie les informations saisies.';
    return 'La demande a échoué. Réessaie.';
  }
  return error instanceof Error ? error.message : 'La demande a échoué.';
}
