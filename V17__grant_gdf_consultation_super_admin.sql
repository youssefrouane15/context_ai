-- =====================================================================
-- V17 : Super Admin — accès aux cards « Dérogation » et « Gestion des fonds »
-- ---------------------------------------------------------------------
-- Les deux cards du dashboard portail-ci sont désormais conditionnées par
-- permission (front) :
--   - card Dérogation        -> DTRP_CHOIX_WF          (plateforme DTRP, existe déjà)
--   - card Gestion des fonds -> GDF_CONSULTER_DEMANDE   (plateforme GESTION_FONDS, V16)
--
-- Le profil 7 SA (h11111) ne porte que les rôles 8 / 9 (CONSOLE_ADMIN) :
--   1) rôle 12 « GDF Support » (GDF_CONSULTER_DEMANDE + GDF_TOUTES_AGENCES) rattaché au SA
--   2) nouveau rôle 13 « DTRP Accès Dérogation » (plateforme DTRP) portant uniquement
--      DTRP_CHOIX_WF, rattaché au SA — un rôle dédié plutôt qu'un rôle métier
--      existant (1 à 7), pour ne pas donner au SA des droits d'initiation /
--      validation qu'il n'a pas aujourd'hui.
--
-- Aucune modification d'enum Java, de sécurité ou de gateway : les authorities
-- sont construites depuis la base (profil -> rôles -> permissions).
-- Idempotent : chaque insertion est ignorée si la ligne existe déjà.
-- =====================================================================

-- ---------- 1) Consultation Gestion des Fonds ----------

INSERT INTO hab_profile_role (profile_id, role_id)
SELECT 7, 12
WHERE EXISTS (SELECT 1 FROM hab_profiles WHERE id = 7)
  AND EXISTS (SELECT 1 FROM hab_roles    WHERE id = 12)
  AND NOT EXISTS (
        SELECT 1 FROM hab_profile_role
        WHERE profile_id = 7 AND role_id = 12
      );

-- ---------- 2) Accès à la card Dérogation ----------

INSERT INTO hab_roles (id, name, description, actif, created_at, updated_at, platform)
SELECT 13, 'DTRP Accès Dérogation', 'Accès à la card Dérogation tarifaire du portail (choix du workflow)', true, NOW(), NOW(), 'DTRP'
WHERE NOT EXISTS (SELECT 1 FROM hab_roles WHERE id = 13);

INSERT INTO hab_role_permission (role_id, permission)
SELECT 13, 'DTRP_CHOIX_WF'
WHERE NOT EXISTS (
        SELECT 1 FROM hab_role_permission
        WHERE role_id = 13 AND permission = 'DTRP_CHOIX_WF'
      );

INSERT INTO hab_profile_role (profile_id, role_id)
SELECT 7, 13
WHERE EXISTS (SELECT 1 FROM hab_profiles WHERE id = 7)
  AND NOT EXISTS (
        SELECT 1 FROM hab_profile_role
        WHERE profile_id = 7 AND role_id = 13
      );

-- Réalignement de la séquence après insertion avec id explicite (même geste que V6 / V16)
SELECT setval('hab_roles_id_seq', (SELECT MAX(id) FROM hab_roles));
