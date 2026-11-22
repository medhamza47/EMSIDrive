import { Pipe, PipeTransform } from '@angular/core';

const labels: Record<string, string> = {
  STUDENT: 'Étudiant',
  ADMIN: 'Administrateur',
  OFFER: 'Offre',
  REQUEST: 'Demande',
  OPEN: 'Ouvert',
  PENDING: 'En attente',
  FULL: 'Complet',
  ONGOING: 'En cours',
  COMPLETED: 'Terminé',
  CANCELLED: 'Annulé',
  MATCHED: 'Acceptée',
  EXPIRED: 'Expiré',
  UNDER_REVIEW: 'En examen',
  RESOLVED: 'Résolu',
  DISMISSED: 'Classé sans suite',
  HARASSMENT: 'Harcèlement',
  NO_SHOW: 'Absence au rendez-vous',
  UNSAFE_DRIVING: 'Conduite dangereuse',
  FAKE_PROFILE: 'Faux profil',
  PAYMENT: 'Partage des frais',
  OTHER: 'Autre',
  ACCOUNT_SUSPENDED: 'Compte suspendu',
  ACCOUNT_REACTIVATED: 'Compte réactivé',
  ADMIN_GRANTED: 'Droits administrateur accordés',
  REPORT_OPEN: 'Signalement rouvert',
  REPORT_UNDER_REVIEW: 'Examen du signalement',
  REPORT_RESOLVED: 'Signalement résolu',
  REPORT_DISMISSED: 'Signalement classé',
};

@Pipe({ name: 'label' })
export class Label implements PipeTransform {
  transform(value: string): string {
    return labels[value] ?? value;
  }
}
