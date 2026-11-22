import { signal } from '@angular/core';
import { Auth, errorMessage } from './auth';

interface Page<T> {
  items: T[];
  total: number;
  page: number;
  size: number;
}

export class PageState<T> {
  readonly items = signal<T[]>([]);
  readonly total = signal(0);
  readonly page = signal(0);
  readonly loading = signal(false);
  readonly error = signal('');
  private generation = 0;
  private params: Record<string, string | number> = {};

  constructor(
    private api: Auth,
    private path: string,
  ) {}

  async load(params = this.params, page = this.page()): Promise<void> {
    const generation = ++this.generation;
    this.params = params;
    this.loading.set(true);
    this.error.set('');
    try {
      const result = await this.api.request<Page<T>>('GET', '/admin' + this.path, undefined, {
        ...params,
        page,
      });
      if (generation !== this.generation) return;
      this.items.set(result.items);
      this.total.set(result.total);
      this.page.set(result.page);
    } catch (error) {
      if (generation === this.generation) this.error.set(errorMessage(error));
    } finally {
      if (generation === this.generation) this.loading.set(false);
    }
  }
}
