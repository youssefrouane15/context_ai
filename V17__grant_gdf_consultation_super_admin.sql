-- =====================================================================
-- V17 : Super Admin — accès aux cards « Dérogation » et « Gestion des fonds »
-- ---------------------------------------------------------------------
-- Les deux cards du dashboard portail-ci sont conditionnées par permission :
--   - card Dérogation        -> DTRP_CHOIX_WF         (plateforme DTRP, existe déjà)
--   - card Gestion des fonds -> GDF_CONSULTER_DEMANDE  (plateforme GESTION_FONDS, V16)
--
-- Le rôle 8 « Super Admin » (profil 7 SA, h11111) reçoit directement ces
-- permissions, plus GDF_TOUTES_AGENCES : le SA n'a pas d'agence de
-- rattachement, sans ce flag fund-management ne lui remonterait aucune demande.
--
-- Aucun nouveau rôle, aucune modification d'enum Java, de sécurité ou de
-- gateway : les authorities sont construites depuis la base
-- (profil -> rôles -> permissions).
-- Idempotent : chaque permission est ignorée si elle est déjà rattachée.
-- =====================================================================

INSERT INTO hab_role_permission (role_id, permission)
SELECT 8, v.p
FROM (VALUES ('DTRP_CHOIX_WF'), ('GDF_CONSULTER_DEMANDE'), ('GDF_TOUTES_AGENCES')) AS v(p)
WHERE EXISTS (SELECT 1 FROM hab_roles WHERE id = 8)
  AND NOT EXISTS (
        SELECT 1 FROM hab_role_permission
        WHERE role_id = 8 AND permission = v.p
      );
