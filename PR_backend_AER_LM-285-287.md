# AER_LM-285 / AER_LM-287 — Traitement Caisse Centrale, photo du décideur, KPI, logs JSON

## Contexte
- **AER_LM-285** — Écran de traitement d'une demande par la Caisse Centrale : décision Traitée / Annulée avec motif, traçabilité du décideur.
- **AER_LM-287** — Consultation / modification d'une demande côté agence : l'en-tête affiche « Soumise le … par … » et « Traitée / Annulée le … par … ».
- Remarques PO intégrées : KPI du tableau de bord CC (en attente / urgentes / traitées du jour), logs JSON + tracing alignés sur `utilisateurs-ci`.

## Changements
### Domaine / persistance
- `V10__decision_caisse_centrale.sql` : colonnes `decision_par`, `decision_profil`, `decision_at` sur `retail.cash_request`.
- `CashRequestEntity`, `CashRequest`, `CashRequestDTO` : champs décision ; mapper web → les champs décision sont ignorés uniquement sur la requête entrante (PUT de modification), jamais en lecture.
- `CashDemandRepository.figerDecision(id, decisionPar, decisionProfil, decisionAt)` (même schéma que `figerPhotoAgence`).

### Use case `completerTacheCaisseCentrale(id, decision, contexte)`
- Nouvelle signature avec `ContexteAppelant` (comme les autres use cases) ; garde : réservé aux profils toutes agences (`RetailForbiddenException`).
- Ordre : gardes (décision obligatoire, motif ≥ 10 caractères si annulation, demande `SUBMITTED`, tâche CC active) → **`figerDecision`** → `completerTache` Camunda → retour de la demande relue. La décision est figée avant de rendre la main au workflow pour que le worker qui pose le statut final la réécrive à l'identique.

### KPI Caisse Centrale (`GET /cash/kpi?date=`)
- `compterEnAttente` / `compterUrgentes` : `requestStatus = 'SUBMITTED'` uniquement (une demande `IN_MODIFICATION` est entre les mains de l'agence, pas à traiter) ; stock jusqu'à la date incluse (`creationDate < fin`).
- `compterTraitees` + répartition par transporteur : `VALIDATED` dont `coalesce(decisionAt, modificationDate)` est dans la journée.

### Logs / observabilité
- `logstash-logback-encoder` 8.1 (propriété dans le pom parent) + `micrometer-tracing-bridge-brave` ; `logback-spring.xml` : une ligne JSON par événement avec `traceId` / `spanId` / `correlationId` / `uid` / `branchCode` (même structure que `utilisateurs-ci`) ; `management.tracing.sampling.probability: 1.0` en local.

## Tests
- `CashDemandUseCaseImplTest` : décision figée avant `completerTache` (ordre vérifié avec `InOrder`), garde profil agence → 403, garde motif, garde statut, garde tâche absente, KPI avec décisions hors journée.
- `RetailDemandControllerTest` : `PATCH /cash/{id}/complete-task` passe `contexteCourant.courant()`.

## Vérification manuelle
1. Profil Caisse Centrale : traiter une demande `SUBMITTED` → `decision_par / decision_profil / decision_at` renseignés en base et conservés après passage à `VALIDATED` par le worker.
2. Profil agence sur le même endpoint → 403.
3. `GET /cash/kpi` : en attente = `SUBMITTED` ; urgentes ⊆ en attente ; traitées = décidées aujourd'hui.
4. Console : logs JSON avec `traceId` sur chaque ligne.

## Hors périmètre / à suivre
- Date d'effet (dev du collègue) : les KPI en attente / urgentes passeront sur `date_effet <= jour` (ticket séparé).
- Pièce de 2 DH dans le référentiel des coupures (V11, à aligner sur la table `denomination`).
