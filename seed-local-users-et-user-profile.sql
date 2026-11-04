-- =====================================================================================================
-- Seed LOCAL (hors Flyway) — les mêmes utilisateurs dans les DEUX bases, alignés uid pour uid :
--   A) utilisateurs-ci  (schéma qf_admin)            : table users   (habilitations : profil → rôles → permissions)
--   B) fund-management  (schéma "qf-fund-management") : table user_profile (photo du profil : uid + profile_code)
-- Source : liste PO 09/10/2026 (V20 Teams) + utilisateurs d'origine g1000x + ceux présents dans user_profile au 02/11.
-- Idempotent (NOT EXISTS sur uid) ; profils par code, agence par code : aucun id en dur. Email = <uid>@bnpparibas.com.
-- Connexion mock : POST http://localhost:9090/mock-auth/login?uid=<uid>
-- =====================================================================================================

-- =================================== A) utilisateurs-ci — qf_admin.users ===================================
SET search_path TO qf_admin;

INSERT INTO users (uid, email, first_name, last_name, actif, created_at, updated_at, profile_id, organization_unit_id)
SELECT v.uid, v.uid || '@bnpparibas.com', v.prenom, v.nom, true, now(), now(),
       (SELECT id FROM hab_profiles WHERE code = v.profil),
       (SELECT id FROM orga_unit WHERE type = 'AGENCE' AND code = v.agence)
FROM (VALUES
    -- ---- Génération 1 (AER_LM-261, agence 1422 DAR BOUAAZA)
    ('g10001', 'Amine',    'DA',       'DA',              '1422'),
    ('g10002', 'Salma',    'CAISSE',   'CHEF_CAISSE',     '1422'),
    ('g10003', 'Karim',    'CENTRALE', 'CAISSE_CENTRALE', NULL),
    ('g10004', 'Nadia',    'SUPPORT',  'SUPPORT',         NULL),
    -- ---- Liste PO 09/10/2026 (agence 1104 CASA MOHAMED V)
    ('j61104', 'Marouane', 'MASSOUNE', 'DA',              '1104'),
    ('j62211', 'Youness',  'BALADI',   'CHEF_CAISSE',     '1104'),
    ('j62318', 'Mourad',   'KORCHI',   'CHEF_CAISSE',     '1104'),
    ('c63005', 'Yassine',  'SMATOU',   'CAISSE_CENTRALE', NULL),
    -- ---- Présents dans user_profile fund-management (02/11) — noms non fournis : uid en nom, agence 1104 pour les profils agence
    ('c60011', 'Caisse',   'CENTRALE 60011', 'CAISSE_CENTRALE', NULL),
    ('c60010', 'Caisse',   'CENTRALE 60010', 'CAISSE_CENTRALE', NULL),
    ('j53488', 'DA',       '53488',    'DA',              '1104'),
    ('j51204', 'DA',       '51204',    'DA',              '1104'),
    ('j55729', 'DA',       '55729',    'DA',              '1104'),
    ('j52317', 'Chef',     'CAISSE 52317', 'CHEF_CAISSE', '1104'),
    ('j54061', 'Chef',     'CAISSE 54061', 'CHEF_CAISSE', '1104'),
    ('s70005', 'Support',  '70005',    'SUPPORT',         NULL)
) AS v(uid, prenom, nom, profil, agence)
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.uid = v.uid);
-- h11111 (SA, V10), j43709 et j08221 (profils DTRP existants) : ne pas toucher.

-- Contrôle A : 16 lignes, aucun profile_id NULL (sinon le profil manque dans hab_profiles → V19)
SELECT u.uid, p.code AS profil, o.code AS agence
FROM users u LEFT JOIN hab_profiles p ON p.id = u.profile_id LEFT JOIN orga_unit o ON o.id = u.organization_unit_id
WHERE u.uid IN ('g10001','g10002','g10003','g10004','j61104','j62211','j62318','c63005','c60011','c60010','j53488','j51204','j55729','j52317','j54061','s70005')
ORDER BY u.uid;


-- ============================ B) fund-management — "qf-fund-management".user_profile ============================
SET search_path TO "qf-fund-management";

-- 1) alignement des anciens codes courts (C / CC / SUP) sur les codes users
UPDATE user_profile SET profile_code = 'CHEF_CAISSE',     profile_label = 'Chef de caisse',     profile_type = 'AGENT' WHERE uid = 'g10002';
UPDATE user_profile SET profile_code = 'CAISSE_CENTRALE', profile_label = 'Caisse Centrale',    profile_type = 'AGENT' WHERE uid = 'g10003';
UPDATE user_profile SET profile_code = 'SUPPORT',         profile_label = 'Support',            profile_type = 'AGENT' WHERE uid = 'g10004';
UPDATE user_profile SET profile_code = 'DA',              profile_label = 'Directeur d''agence', profile_type = 'DA'   WHERE uid = 'g10001';

-- 2) insertion des manquants (mêmes uids que A)
INSERT INTO user_profile (id, creation_date, modification_date, uid, profile_code, profile_label, profile_type)
SELECT gen_random_uuid(), now(), now(), v.uid, v.code, v.label, v.type
FROM (VALUES
    ('g10001', 'DA',              'Directeur d''agence', 'DA'),
    ('g10002', 'CHEF_CAISSE',     'Chef de caisse',      'AGENT'),
    ('g10003', 'CAISSE_CENTRALE', 'Caisse Centrale',     'AGENT'),
    ('g10004', 'SUPPORT',         'Support',             'AGENT'),
    ('j61104', 'DA',              'Directeur d''agence', 'DA'),
    ('j62211', 'CHEF_CAISSE',     'Chef de caisse',      'AGENT'),
    ('j62318', 'CHEF_CAISSE',     'Chef de caisse',      'AGENT'),
    ('c63005', 'CAISSE_CENTRALE', 'Caisse Centrale',     'AGENT'),
    ('c60011', 'CAISSE_CENTRALE', 'Caisse Centrale',     'AGENT'),
    ('c60010', 'CAISSE_CENTRALE', 'Caisse Centrale',     'AGENT'),
    ('j53488', 'DA',              'Directeur d''agence', 'DA'),
    ('j51204', 'DA',              'Directeur d''agence', 'DA'),
    ('j55729', 'DA',              'Directeur d''agence', 'DA'),
    ('j52317', 'CHEF_CAISSE',     'Chef de caisse',      'AGENT'),
    ('j54061', 'CHEF_CAISSE',     'Chef de caisse',      'AGENT'),
    ('s70005', 'SUPPORT',         'Support',             'AGENT')
) AS v(uid, code, label, type)
WHERE NOT EXISTS (SELECT 1 FROM user_profile p WHERE p.uid = v.uid);

-- Contrôle B : même liste qu'en A, mêmes codes
SELECT uid, profile_code, profile_type FROM user_profile ORDER BY uid;
