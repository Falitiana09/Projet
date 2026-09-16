-- ============================================================
--  Fichier : database/seed.sql
--  Rôle    : données initiales indispensables
-- ============================================================

USE identite_numerique_db;

-- ------------------------------------------------------------
-- 1. Rôles
-- ------------------------------------------------------------
INSERT INTO roles (code, label, description) VALUES
('ADMIN',          'Administrateur',  'Accès total à la plateforme'),
('AGENT_COMMUNAL', 'Agent communal',  'Enregistre et gère les citoyens'),
('INSTITUTION',    'Institution',     'Vérifie les identités'),
('CITOYEN',        'Citoyen',         'Consulte son identité numérique');

-- ------------------------------------------------------------
-- 2. Permissions (base)
-- ------------------------------------------------------------
INSERT INTO permissions (code, description) VALUES
('users.read',        'Lire les utilisateurs'),
('users.write',       'Créer/modifier les utilisateurs'),
('users.delete',      'Supprimer un utilisateur'),
('roles.manage',      'Gérer les rôles'),
('citizens.read',     'Lire les citoyens'),
('citizens.write',    'Créer/modifier les citoyens'),
('citizens.delete',   'Supprimer un citoyen'),
('identities.read',   'Lire les identités'),
('identities.write',  'Générer/modifier les identités'),
('qr.generate',       'Générer un QR Code'),
('verifications.read','Consulter les vérifications'),
('verifications.create','Lancer une vérification'),
('institutions.manage','Gérer les institutions'),
('api_keys.manage',   'Gérer les API Keys'),
('audit.read',        'Consulter l''audit'),
('dashboard.read',    'Accéder au dashboard');

-- ------------------------------------------------------------
-- 3. Association rôles ↔ permissions
-- ------------------------------------------------------------
-- ADMIN : toutes les permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.code = 'ADMIN';

-- AGENT_COMMUNAL
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
  'citizens.read','citizens.write',
  'identities.read','identities.write',
  'qr.generate',
  'verifications.read','verifications.create',
  'dashboard.read'
)
WHERE r.code = 'AGENT_COMMUNAL';

-- INSTITUTION
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
  'citizens.read',
  'identities.read',
  'verifications.read','verifications.create',
  'dashboard.read'
)
WHERE r.code = 'INSTITUTION';

-- CITOYEN
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
  'identities.read'
)
WHERE r.code = 'CITOYEN';

-- ------------------------------------------------------------
-- 4. Types d'institutions
-- ------------------------------------------------------------
INSERT INTO institution_types (code, label) VALUES
('SCHOOL',  'École'),
('BANK',    'Banque'),
('HOSPITAL','Hôpital'),
('ADMIN',   'Administration'),
('OTHER',   'Autre');

-- ------------------------------------------------------------
-- 5. Communes (exemples)
-- ------------------------------------------------------------
INSERT INTO communes (id, code, name, region) VALUES
(UUID(), 'C01', 'Commune d''Antananarivo', 'Analamanga'),
(UUID(), 'C02', 'Commune de Toamasina',    'Atsinanana'),
(UUID(), 'C03', 'Commune de Fianarantsoa', 'Haute Matsiatra');

-- ------------------------------------------------------------
-- 6. Utilisateur ADMIN par défaut
--    Email : admin@identite.local
--    Mot de passe (à changer) : Admin@1234
--    ⚠️ Le hash ci-dessous est un vrai hash bcrypt (cost 10)
-- ------------------------------------------------------------
INSERT INTO users (id, email, password_hash, first_name, last_name, phone, is_active)
VALUES (
  UUID(),
  'admin@identite.local',
  '$2b$10$3fQZ8y2kF6aFq0L4jGXoDOhVtIUGt8zHPLy0/OWxXtDdEoPXqUq2S',
  'Super',
  'Admin',
  NULL,
  TRUE
);

-- Association de l'admin au rôle ADMIN
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
JOIN roles r ON r.code = 'ADMIN'
WHERE u.email = 'admin@identite.local';

-- ============================================================
--  FIN DU SEED
-- ============================================================