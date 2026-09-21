-- =====================================================================
-- V17 : Consultation Gestion des Fonds pour le profil Super Admin
-- ---------------------------------------------------------------------
-- Contexte : le profil 7 (SA, h11111) ne porte que les rôles CONSOLE_ADMIN
-- (8 Super Admin, 9 Admin User). Le rôle 12 « GDF Support » (V16) porte
-- GDF_CONSULTER_DEMANDE + GDF_TOUTES_AGENCES sur la plateforme GESTION_FONDS :
-- consultation, toutes agences. On le rattache au profil SA.
--
-- Aucune modification d'enum, de sécurité ou de gateway : les authorities
-- sont construites depuis la base (profil -> rôles -> permissions).
-- Idempotent : l'insertion est ignorée si le rattachement existe déjà.
-- =====================================================================

INSERT INTO hab_profile_role (profile_id, role_id)
SELECT 7, 12
WHERE EXISTS (SELECT 1 FROM hab_profiles WHERE id = 7)
  AND EXISTS (SELECT 1 FROM hab_roles    WHERE id = 12)
  AND NOT EXISTS (
        SELECT 1 FROM hab_profile_role
        WHERE profile_id = 7 AND role_id = 12
      );
