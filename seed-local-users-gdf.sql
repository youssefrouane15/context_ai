-- Utilisateurs de démo Gestion des Fonds — base LOCALE uniquement (hors Flyway).
-- Idempotent (NOT EXISTS sur uid) ; profils par code (hab_profiles.code), agence par code (orga_unit.code, type AGENCE) : aucun id en dur.
-- Email = <uid>@bnpparibas.com pour tous (pattern de la liste PO du 09/10/2026) ; les anciens g1000x sont réalignés.
-- Connexion mock : POST /mock-auth/login?uid=<uid> sur la gateway (9090). h11111 (SA) vient de V10, rien à faire.
SET search_path TO qf_admin;

-- ============ Génération 1 (AER_LM-261) — agence 1422 DAR BOUAAZA ============
INSERT INTO users (uid, email, first_name, last_name, actif, created_at, updated_at, profile_id, organization_unit_id)
SELECT 'g10001', 'g10001@bnpparibas.com', 'Amine', 'DA', true, now(), now(),
       (SELECT id FROM hab_profiles WHERE code = 'DA'), (SELECT id FROM orga_unit WHERE type = 'AGENCE' AND code = '1422')
WHERE NOT EXISTS (SELECT 1 FROM users WHERE uid = 'g10001');

INSERT INTO users (uid, email, first_name, last_name, actif, created_at, updated_at, profile_id, organization_unit_id)
SELECT 'g10002', 'g10002@bnpparibas.com', 'Salma', 'CAISSE', true, now(), now(),
       (SELECT id FROM hab_profiles WHERE code = 'CHEF_CAISSE'), (SELECT id FROM orga_unit WHERE type = 'AGENCE' AND code = '1422')
WHERE NOT EXISTS (SELECT 1 FROM users WHERE uid = 'g10002');

INSERT INTO users (uid, email, first_name, last_name, actif, created_at, updated_at, profile_id, organization_unit_id)
SELECT 'g10003', 'g10003@bnpparibas.com', 'Karim', 'CENTRALE', true, now(), now(),
       (SELECT id FROM hab_profiles WHERE code = 'CAISSE_CENTRALE'), NULL
WHERE NOT EXISTS (SELECT 1 FROM users WHERE uid = 'g10003');

INSERT INTO users (uid, email, first_name, last_name, actif, created_at, updated_at, profile_id, organization_unit_id)
SELECT 'g10004', 'g10004@bnpparibas.com', 'Nadia', 'SUPPORT', true, now(), now(),
       (SELECT id FROM hab_profiles WHERE code = 'SUPPORT'), NULL
WHERE NOT EXISTS (SELECT 1 FROM users WHERE uid = 'g10004');

-- ============ Génération 2 (liste PO 09/10/2026) — agence 1104 CASA MOHAMED V ============
-- Directeur d'agence
INSERT INTO users (uid, email, first_name, last_name, actif, created_at, updated_at, profile_id, organization_unit_id)
SELECT 'j61104', 'j61104@bnpparibas.com', 'Marouane', 'MASSOUNE', true, now(), now(),
       (SELECT id FROM hab_profiles WHERE code = 'DA'), (SELECT id FROM orga_unit WHERE type = 'AGENCE' AND code = '1104')
WHERE NOT EXISTS (SELECT 1 FROM users WHERE uid = 'j61104');

-- Chefs de caisse
INSERT INTO users (uid, email, first_name, last_name, actif, created_at, updated_at, profile_id, organization_unit_id)
SELECT 'j62211', 'j62211@bnpparibas.com', 'Youness', 'BALADI', true, now(), now(),
       (SELECT id FROM hab_profiles WHERE code = 'CHEF_CAISSE'), (SELECT id FROM orga_unit WHERE type = 'AGENCE' AND code = '1104')
WHERE NOT EXISTS (SELECT 1 FROM users WHERE uid = 'j62211');

INSERT INTO users (uid, email, first_name, last_name, actif, created_at, updated_at, profile_id, organization_unit_id)
SELECT 'j62318', 'j62318@bnpparibas.com', 'Mourad', 'KORCHI', true, now(), now(),
       (SELECT id FROM hab_profiles WHERE code = 'CHEF_CAISSE'), (SELECT id FROM orga_unit WHERE type = 'AGENCE' AND code = '1104')
WHERE NOT EXISTS (SELECT 1 FROM users WHERE uid = 'j62318');

-- Caisse Centrale
INSERT INTO users (uid, email, first_name, last_name, actif, created_at, updated_at, profile_id, organization_unit_id)
SELECT 'c63005', 'c63005@bnpparibas.com', 'Yassine', 'SMATOU', true, now(), now(),
       (SELECT id FROM hab_profiles WHERE code = 'CAISSE_CENTRALE'), NULL
WHERE NOT EXISTS (SELECT 1 FROM users WHERE uid = 'c63005');

-- (2e Caisse Centrale de la liste PO : coupé sur la capture — même bloc, uid/nom à compléter)
-- INSERT INTO users (...) SELECT '<uid>', '<uid>@bnpparibas.com', '<Prénom>', '<NOM>', true, now(), now(),
--        (SELECT id FROM hab_profiles WHERE code = 'CAISSE_CENTRALE'), NULL WHERE NOT EXISTS (SELECT 1 FROM users WHERE uid = '<uid>');

-- ============ Contrôle ============
SELECT u.uid, u.email, u.first_name, u.last_name, p.code AS profil, o.code AS agence
FROM users u JOIN hab_profiles p ON p.id = u.profile_id LEFT JOIN orga_unit o ON o.id = u.organization_unit_id
WHERE u.uid IN ('h11111','g10001','g10002','g10003','g10004','j61104','j62211','j62318','c63005')
ORDER BY u.uid;
-- Attendu : 9 lignes, aucun profile_id NULL (sinon le profil n'existe pas : vérifier V19), agence 1422 / 1104 renseignée pour DA et chefs de caisse.
