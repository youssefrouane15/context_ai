import { DemandeCriteria, DemandeFonds } from '../../../domain/domain-core/entities/operation.model';
import { DemandeFondsDetailBrute } from '../../../domain/domain-core/entities/demande-detail.model';
import { AgenceReferentiel, libelleCoutDeplacement } from '../../../domain/domain-core/entities/agence-referentiel.model';
import { StatutDemande, classeStatut, libelleStatut, versStatutDemande } from '../../../domain/domain-core/entities/statut-demande';

/**
 * AER_LM-289 — règles pures du listing commun (agence / Caisse Centrale), testables sans Angular :
 * traduction des filtres d'écran en critères serveur, et projection d'une demande en ligne de tableau.
 */

export type ModeListing = 'agence' | 'caisse-centrale';

/** Valeurs « tout » des listes déroulantes. */
export const TOUS = 'TOUS';
export const TOUTES = 'TOUTES';

/** Option d'une liste déroulante de filtre (un seul type pour toutes les listes : *ngFor n'accepte pas une union de tuples). */
export interface OptionFiltre { code: string; libelle: string; }

/** Filtre « Type de demande » de l'écran agence → operationType / operationSens du back. */
export const TYPES_DEMANDE: readonly OptionFiltre[] = [
  { code: TOUS,        libelle: 'Tous les types' },
  { code: 'CAISSE',    libelle: 'Alimentation caisse' },
  { code: 'GAB',       libelle: 'Alimentation GAB' },
  { code: 'DEVISES',   libelle: 'Commande devises' },
  { code: 'RAMASSAGE', libelle: 'Ramassage' }
];

export const STATUTS_AGENCE: readonly OptionFiltre[] = [
  { code: TOUS,              libelle: 'Tous les statuts' },
  { code: 'INITIATED',       libelle: 'Brouillon' },
  { code: 'SUBMITTED',       libelle: 'En attente' },
  { code: 'IN_MODIFICATION', libelle: 'En modification' },
  { code: 'VALIDATED',       libelle: 'Traitée' },
  { code: 'CANCELLED',       libelle: 'Annulée' }
];

/** Caisse Centrale : jamais de brouillon (le back les exclut aussi, quel que soit le filtre). */
export const STATUTS_CAISSE_CENTRALE: readonly OptionFiltre[] = STATUTS_AGENCE.filter(s => s.code !== 'INITIATED');

/** Jour courant au format des champs date (yyyy-MM-dd), en heure locale. */
export function aujourdHui(maintenant: Date = new Date()): string {
  const decale = new Date(maintenant.getTime() - maintenant.getTimezoneOffset() * 60_000);
  return decale.toISOString().slice(0, 10);
}

/** Motifs rapides de la modale d'annulation Caisse Centrale (maquette 281). */
export const MOTIFS_RAPIDES = [
  'Dépassement du cut-off : demande hors délai',
  'Incohérence des montants : bordereau non conforme',
  'Montant supérieur au plafond : refus trésorerie centrale',
  'Demande doublon : déjà traitée pour cette agence'
] as const;

export interface FiltresListing {
  statut: string;
  urgent: boolean;
  transporteur: string;
  zone: string;
  type: string;
  recherche: string;
  dateDebut: string;   // yyyy-MM-dd (input type=date) ou ''
  dateFin: string;     // yyyy-MM-dd ou ''
}

export function construireCriteres(f: FiltresListing, page: number, size: number): DemandeCriteria {
  const c: DemandeCriteria = { page, size };
  if (f.statut !== TOUS)        { c.statut = f.statut; }
  if (f.urgent)                 { c.urgent = true; }
  if (f.transporteur !== TOUS)  { c.prestataire = f.transporteur; }
  if (f.zone !== TOUTES)        { c.zone = f.zone; }
  switch (f.type) {
    case 'CAISSE':    c.operationType = 'CASH_DESK'; break;
    case 'GAB':       c.operationType = 'ATM'; break;
    case 'DEVISES':   c.operationType = 'CURRENCY'; break;
    case 'RAMASSAGE': c.operationSens = 'COLLECTION'; break;
  }
  const recherche = f.recherche.trim();
  if (recherche)                { c.recherche = recherche; }
  if (f.dateDebut)              { c.dateDebut = `${f.dateDebut}T00:00:00`; }
  if (f.dateFin)                { c.dateFin = `${f.dateFin}T23:59:59`; }
  return c;
}

/** Une ligne du tableau, identique dans les deux modes ; chaque mode n'affiche que ses colonnes. */
export interface LigneListing {
  demande: DemandeFonds;
  reference: string;
  urgente: boolean;
  date: string | null;             // date de création (Date & heure)
  agenceCode: string;
  agenceNom: string | null;
  zone: string | null;
  transporteurId: string | null;
  transporteur: string | null;
  coutDeplacement: string | null;
  agentNom: string;                // nom complet, ou l'uid si la demande n'a pas de photo
  agentProfil: string | null;
  contenu: string[];
  statut: StatutDemande;
  libelleStatut: string;
  classeStatut: string;
  /** Traiter / Annuler (Caisse Centrale) : uniquement une demande soumise, et si l'habilitation TRAITER est là. */
  decidable: boolean;
  annulee: boolean;
}

export function versLigne(d: DemandeFonds, repli: AgenceReferentiel | null, peutDecider: boolean): LigneListing {
  const brut = d as DemandeFondsDetailBrute;
  const statut = versStatutDemande(d.requestStatus, brut.cancellationOrigin);
  return {
    demande: d,
    reference: d.uniqueRequestRef ?? '–',
    urgente: d.urgent ?? (d.operations?.some(op => op.isUrgent === true) ?? false),
    date: d.createdAt ?? brut.submittedAt ?? null,
    agenceCode: d.branchCode,
    agenceNom: d.agenceNom ?? repli?.nom ?? null,
    zone: d.zoneNom ?? repli?.zoneNom ?? null,
    transporteurId: d.prestataire ?? repli?.prestataireId ?? null,
    transporteur: d.prestataireNom ?? repli?.prestataireNom ?? null,
    coutDeplacement: libelleCoutDeplacement(d.coutDeplacement ?? repli?.coutDeplacement),
    agentNom: d.agentNom || d.user || '—',
    agentProfil: d.agentProfil ?? null,
    contenu: chipsContenu(d),
    statut,
    libelleStatut: libelleStatut(statut),
    classeStatut: classeStatut(statut),
    decidable: peutDecider && statut === 'SOUMISE',
    annulee: statut === 'ANNULEE_AGENCE' || statut === 'ANNULEE_CAISSE_CENTRALE'
  };
}

/** Mêmes chips que les listings précédents : CAISSE / GAB / DEVISES / RAMASSAGE, sans doublon. */
export function chipsContenu(d: DemandeFonds): string[] {
  const chips = (d.operations ?? []).map(op => {
    if (op.operationSens === 'COLLECTION') { return 'RAMASSAGE'; }
    if (op.operationType === 'ATM')        { return 'GAB'; }
    if (op.operationType === 'CASH_DESK')  { return 'CAISSE'; }
    if (op.operationType === 'CURRENCY')   { return 'DEVISES'; }
    return op.operationType;
  });
  return [...new Set(chips)];
}

/** Nombre de pages d'un listing paginé côté serveur. */
export function nombreDePages(total: number, taille: number): number {
  return taille > 0 ? Math.max(1, Math.ceil(total / taille)) : 1;
}
