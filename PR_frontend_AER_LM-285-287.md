# AER_LM-285 / AER_LM-287 — Écran de traitement Caisse Centrale, consultation / modification agence, alignement maquettes

## Contexte
- **AER_LM-285** — Écran de traitement d'une demande par la Caisse Centrale (`caisse-centrale/:id`) : dossier complet en lecture, décision Traitée / Annulée avec motif.
- **AER_LM-287** — Amélioration consultation / modification agence : en-tête commun (statut, référence, soumise par, traitée par), entrée en modification par le badge « Mode Modification », barre d'actions, lecture seule quand la demande est verrouillée.
- Port 1:1 des maquettes `Agence_Modification-Demande`, `Agence_Modification-Bloquée`, `Caisse-Centrale_Traiter-Demande-En-Attente` (structure, classes, icônes Material Symbols).
- Remarques PO : pas de MAD dans la commande de devises, GAB limité aux billets de 200 et 100 DH, recherche masquée côté agence, « Actualiser » ne vide que la recherche, clics sur les cartes KPI.

## Changements
### Nouveaux composants (`features/fund-management/presenter/components/`)
- `demande-entete` (+ `demande-entete.regles.ts`, règles pures testées) : lien retour, alerte lecture seule, pastille de statut, « Demande Réf: », soumise / traitée par, bouton-badge « Mode Modification » → « Mode Modification actif », badge / case « Demande Urgente ». Entrée `theme: 'edition' | 'recap'`.
- `demande-barre-actions` : barre collée en bas (retour | annuler / soumettre / traiter / « Modification Verrouillée »).
- `demande-decision-modale` : motif d'annulation (≥ 10 caractères, motifs rapides côté CC).

### Nouvelle page `presenter/pages/demande-traitement/` (route `caisse-centrale/:id`, garde `toutesAgences`)
- Vue construite par `construireVueDossier(dossier, referentiel)` (`domain-core/entities/demande-dossier.model.ts`) : grilles de coupures complètes (lignes à 0 comprises) à partir de `getDenominationsCaisse/Gab`, `COUPURES_GAB = [200, 100]`.
- Décision via `DemandeActionsFacade.decider(id, 'TRAITEE' | 'ANNULEE', motif)`, rechargement différé (statut écrit par le worker).

### Écran agence `fund-management` (création / consultation / modification)
- Un seul template, trois états ; en-tête de création et barre de création conservés pour la création uniquement ; badge de l'en-tête = seule entrée en modification (`modifier()` pose le verrou) ; une seule barre partagée en consultation / modification.
- Thème `recap` (classe hôte) quand la demande est verrouillée : alerte, champs `qf-field-disabled`, libellés de la maquette Bloquée.
- Ramassage sur `devisesDisponibles` (MAD par défaut), commande de devises sur `devisesCommandables` ; GAB filtré sur `COUPURES_GAB` à la construction du FormArray ; champs natifs à la place de Material pour les sous-blocs de saisie (`MatFormField/Select/Checkbox/Icon` retirés).

### Listing
- Recherche masquée en mode agence ; `actualiser()` ne réinitialise que la recherche, debounce 300 ms ; clic KPI → filtres (en attente = statut SOUMISE, urgentes = + urgent uniquement) ; `voirDetail` → `caisse-centrale/:id` en mode CC ; modale de décision retirée du listing.

### Styles partagés (`shared/presenter/styles/`)
- `_palette.scss` : jetons des deux maquettes + mixins `theme-edition` / `theme-recap` (variables CSS posées sur le `:host` de la page) ; `_dossier.scss` : cartes, grilles de coupures, totaux, table devises, commentaire, GAB, ramassage, communs agence / CC. `angular.json` → `stylePreprocessorOptions.includePaths`.
- `index.html` : Material Symbols Outlined + Inter + JetBrains Mono ; `styles.scss` : réglage `font-variation-settings` des symboles.
- Directive `shared/presenter/directives/saisie-quantite` (quantités entières ≥ 0).

### Modèle
- `operation.model.ts` : `decisionPar`, `decisionProfil`, `decisionAt` ; `FundHttpService.getDossier(id)` + port.

## Tests
- `demande-entete.regles.spec.ts`, `demande-dossier.model.spec.ts` (grilles complètes, GAB 200/100, totaux, libellés devises).
- Existants : `demandes-list.regles.spec.ts`, `demande-capacites.spec.ts` inchangés et verts.

## Vérification manuelle
1. Consultation d'une demande en attente de mon agence : badge « Mode Modification » → `modification/:id`, badge « actif », case urgente, barre « Retour au listing / Annuler la demande / Soumettre les Modifications » ; aucun débordement horizontal.
2. Demande verrouillée : alerte + chip « Lecture Seule », pas de badge, « Modification Verrouillée » grisé.
3. Caisse Centrale : `caisse-centrale/:id` → grilles complètes, cadenas, « Annuler / Traiter la demande » ; après traitement, « Traitée le … par … » dans l'en-tête.
4. Création : GAB 2 lignes, commande de devises sans MAD, ramassage MAD par défaut.

## Hors périmètre / à suivre
- Titre de la barre du haut (« Vue Agence ») sur les pages Caisse Centrale : shell, ticket séparé.
- Date d'effet (dev du collègue) : les cartes KPI et les filtres de dates basculeront sur `date_effet` (ticket séparé).
