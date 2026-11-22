import { Component, input, output } from '@angular/core';

@Component({
  selector: 'app-pager',
  template: `<div class="pager">
    <span>{{ total() }} résultat(s) · page {{ page() + 1 }}</span>
    <div>
      <button
        class="secondary"
        [disabled]="loading() || page() === 0"
        (click)="change.emit(page() - 1)"
      >
        Précédent
      </button>
      <button
        class="secondary"
        [disabled]="loading() || (page() + 1) * 20 >= total()"
        (click)="change.emit(page() + 1)"
      >
        Suivant
      </button>
    </div>
  </div>`,
})
export class Pager {
  total = input.required<number>();
  page = input.required<number>();
  loading = input(false);
  change = output<number>();
}
