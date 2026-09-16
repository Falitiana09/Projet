-- ============================================================
--  PLATEFORME SaaS IDENTITÉ NUMÉRIQUE AUGMENTÉE PAR IA
--  Fichier : database/schema.sql
--  Rôle    : création complète du schéma MySQL
--  Encodage: UTF-8 (utf8mb4)
--  Moteur  : InnoDB (transactions + FK)
-- ============================================================

-- ------------------------------------------------------------
-- 1. Création de la base
-- ------------------------------------------------------------
DROP DATABASE IF EXISTS identite_numerique_db;
CREATE DATABASE identite_numerique_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE identite_numerique_db;

-- ------------------------------------------------------------
-- 2. Table : roles
-- ------------------------------------------------------------
CREATE TABLE roles (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    code        VARCHAR(50)  NOT NULL UNIQUE,
    label       VARCHAR(100) NOT NULL,
    description VARCHAR(255) NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 3. Table : permissions
-- ------------------------------------------------------------
CREATE TABLE permissions (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    code        VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255) NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 4. Table : role_permissions (N-N)
-- ------------------------------------------------------------
CREATE TABLE role_permissions (
    role_id       INT NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_rp_role
        FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    CONSTRAINT fk_rp_permission
        FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 5. Table : communes
-- ------------------------------------------------------------
CREATE TABLE communes (
    id         CHAR(36)     NOT NULL PRIMARY KEY,
    code       VARCHAR(20)  NOT NULL UNIQUE,
    name       VARCHAR(150) NOT NULL,
    region     VARCHAR(100) NOT NULL,
    created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE INDEX idx_communes_name ON communes(name);

-- ------------------------------------------------------------
-- 6. Table : users
--    Un user peut être : ADMIN, AGENT_COMMUNAL, INSTITUTION, CITOYEN
-- ------------------------------------------------------------
CREATE TABLE users (
    id             CHAR(36)     NOT NULL PRIMARY KEY,
    email          VARCHAR(150) NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL,
    first_name     VARCHAR(100) NOT NULL,
    last_name      VARCHAR(100) NOT NULL,
    phone          VARCHAR(30)  NULL,
    is_active      BOOLEAN      NOT NULL DEFAULT TRUE,
    last_login_at  TIMESTAMP    NULL,
    created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_active ON users(is_active);

-- ------------------------------------------------------------
-- 7. Table : user_roles (N-N)
-- ------------------------------------------------------------
CREATE TABLE user_roles (
    user_id CHAR(36) NOT NULL,
    role_id INT      NOT NULL,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_ur_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_ur_role
        FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 8. Table : refresh_tokens
-- ------------------------------------------------------------
CREATE TABLE refresh_tokens (
    id         CHAR(36)     NOT NULL PRIMARY KEY,
    user_id    CHAR(36)     NOT NULL,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP    NOT NULL,
    revoked    BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_rt_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_rt_user ON refresh_tokens(user_id);
CREATE INDEX idx_rt_expires ON refresh_tokens(expires_at);

-- ------------------------------------------------------------
-- 9. Table : institution_types
-- ------------------------------------------------------------
CREATE TABLE institution_types (
    id    INT AUTO_INCREMENT PRIMARY KEY,
    code  VARCHAR(50)  NOT NULL UNIQUE,
    label VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 10. Table : institutions
-- ------------------------------------------------------------
CREATE TABLE institutions (
    id         CHAR(36)     NOT NULL PRIMARY KEY,
    type_id    INT          NOT NULL,
    name       VARCHAR(150) NOT NULL,
    email      VARCHAR(150) NOT NULL UNIQUE,
    phone      VARCHAR(30)  NULL,
    address    VARCHAR(255) NULL,
    is_active  BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_inst_type
        FOREIGN KEY (type_id) REFERENCES institution_types(id)
) ENGINE=InnoDB;

CREATE INDEX idx_inst_name ON institutions(name);
CREATE INDEX idx_inst_type ON institutions(type_id);

-- ------------------------------------------------------------
-- 11. Table : citizens
-- ------------------------------------------------------------
CREATE TABLE citizens (
    id            CHAR(36)     NOT NULL PRIMARY KEY,
    national_id   VARCHAR(50)  NOT NULL UNIQUE,
    first_name    VARCHAR(100) NOT NULL,
    last_name     VARCHAR(100) NOT NULL,
    birth_date    DATE         NOT NULL,
    birth_place   VARCHAR(150) NOT NULL,
    gender        ENUM('M','F','O') NOT NULL,
    commune_id    CHAR(36)     NOT NULL,
    address       VARCHAR(255) NULL,
    phone         VARCHAR(30)  NULL,
    email         VARCHAR(150) NULL,
    created_by    CHAR(36)     NULL,
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_cit_commune
        FOREIGN KEY (commune_id) REFERENCES communes(id),
    CONSTRAINT fk_cit_created_by
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE INDEX idx_cit_name ON citizens(last_name, first_name);
CREATE INDEX idx_cit_commune ON citizens(commune_id);
CREATE INDEX idx_cit_national ON citizens(national_id);

-- ------------------------------------------------------------
-- 12. Table : digital_identities
-- ------------------------------------------------------------
CREATE TABLE digital_identities (
    id              CHAR(36)     NOT NULL PRIMARY KEY,
    citizen_id      CHAR(36)     NOT NULL,
    identity_number VARCHAR(50)  NOT NULL UNIQUE,
    issue_date      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expiry_date     TIMESTAMP    NULL,
    status          ENUM('CREATED','ACTIVE','SUSPENDED','REVOKED','EXPIRED') NOT NULL DEFAULT 'CREATED',
    version         INT          NOT NULL DEFAULT 1,
    created_by      CHAR(36)     NULL,
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_di_citizen
        FOREIGN KEY (citizen_id) REFERENCES citizens(id) ON DELETE CASCADE,
    CONSTRAINT fk_di_created_by
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE INDEX idx_di_citizen ON digital_identities(citizen_id);
CREATE INDEX idx_di_status ON digital_identities(status);

-- ------------------------------------------------------------
-- 13. Table : qr_tokens
-- ------------------------------------------------------------
CREATE TABLE qr_tokens (
    id           CHAR(36)     NOT NULL PRIMARY KEY,
    identity_id  CHAR(36)     NOT NULL,
    token        VARCHAR(255) NOT NULL UNIQUE,
    signature    VARCHAR(255) NOT NULL,
    expires_at   TIMESTAMP    NOT NULL,
    used         BOOLEAN      NOT NULL DEFAULT FALSE,
    used_at      TIMESTAMP    NULL,
    created_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_qr_identity
        FOREIGN KEY (identity_id) REFERENCES digital_identities(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_qr_identity ON qr_tokens(identity_id);
CREATE INDEX idx_qr_token ON qr_tokens(token);
CREATE INDEX idx_qr_expires ON qr_tokens(expires_at);

-- ------------------------------------------------------------
-- 14. Table : verifications
-- ------------------------------------------------------------
CREATE TABLE verifications (
    id             CHAR(36)     NOT NULL PRIMARY KEY,
    institution_id CHAR(36)     NULL,
    agent_id       CHAR(36)     NULL,
    citizen_id     CHAR(36)     NOT NULL,
    identity_id    CHAR(36)     NULL,
    qr_token_id    CHAR(36)     NULL,
    method         ENUM('QR','MANUAL','API','BIOMETRIC') NOT NULL,
    result         ENUM('VALID','INVALID','SUSPECT','ERROR') NOT NULL,
    reason         VARCHAR(255) NULL,
    biometric_score DECIMAL(5,4) NULL,
    is_simulated   BOOLEAN      NOT NULL DEFAULT FALSE,
    ip_address     VARCHAR(45)  NULL,
    created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ver_inst
        FOREIGN KEY (institution_id) REFERENCES institutions(id) ON DELETE SET NULL,
    CONSTRAINT fk_ver_agent
        FOREIGN KEY (agent_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_ver_citizen
        FOREIGN KEY (citizen_id) REFERENCES citizens(id) ON DELETE CASCADE,
    CONSTRAINT fk_ver_identity
        FOREIGN KEY (identity_id) REFERENCES digital_identities(id) ON DELETE SET NULL,
    CONSTRAINT fk_ver_qr
        FOREIGN KEY (qr_token_id) REFERENCES qr_tokens(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE INDEX idx_ver_citizen ON verifications(citizen_id);
CREATE INDEX idx_ver_inst ON verifications(institution_id);
CREATE INDEX idx_ver_created ON verifications(created_at);
CREATE INDEX idx_ver_result ON verifications(result);

-- ------------------------------------------------------------
-- 15. Table : api_keys
-- ------------------------------------------------------------
CREATE TABLE api_keys (
    id             CHAR(36)     NOT NULL PRIMARY KEY,
    institution_id CHAR(36)     NOT NULL,
    label          VARCHAR(100) NOT NULL,
    key_hash       VARCHAR(255) NOT NULL UNIQUE,
    is_active      BOOLEAN      NOT NULL DEFAULT TRUE,
    last_used_at   TIMESTAMP    NULL,
    expires_at     TIMESTAMP    NULL,
    created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ak_inst
        FOREIGN KEY (institution_id) REFERENCES institutions(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_ak_inst ON api_keys(institution_id);
CREATE INDEX idx_ak_active ON api_keys(is_active);

-- ------------------------------------------------------------
-- 16. Table : audit_logs
-- ------------------------------------------------------------
CREATE TABLE audit_logs (
    id          CHAR(36)     NOT NULL PRIMARY KEY,
    user_id     CHAR(36)     NULL,
    action      VARCHAR(100) NOT NULL,
    resource    VARCHAR(100) NULL,
    resource_id VARCHAR(100) NULL,
    ip_address  VARCHAR(45)  NULL,
    user_agent  VARCHAR(255) NULL,
    metadata    JSON         NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE INDEX idx_audit_user ON audit_logs(user_id);
CREATE INDEX idx_audit_action ON audit_logs(action);
CREATE INDEX idx_audit_created ON audit_logs(created_at);

-- ------------------------------------------------------------
-- 17. Table : notifications
-- ------------------------------------------------------------
CREATE TABLE notifications (
    id         CHAR(36)     NOT NULL PRIMARY KEY,
    user_id    CHAR(36)     NOT NULL,
    title      VARCHAR(150) NOT NULL,
    message    TEXT         NOT NULL,
    type       ENUM('INFO','SUCCESS','WARNING','ERROR') NOT NULL DEFAULT 'INFO',
    is_read    BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notif_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_notif_user ON notifications(user_id);
CREATE INDEX idx_notif_read ON notifications(is_read);

-- ------------------------------------------------------------
-- 18. Table : biometric_templates
--    ⚠️ Aucune image brute stockée — uniquement un hash/template
-- ------------------------------------------------------------
CREATE TABLE biometric_templates (
    id            CHAR(36)     NOT NULL PRIMARY KEY,
    citizen_id    CHAR(36)     NOT NULL,
    template_hash VARCHAR(255) NOT NULL,
    provider      VARCHAR(50)  NOT NULL DEFAULT 'MOCK',
    is_simulated  BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bt_citizen
        FOREIGN KEY (citizen_id) REFERENCES citizens(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_bt_citizen ON biometric_templates(citizen_id);
CREATE INDEX idx_bt_provider ON biometric_templates(provider);

-- ============================================================
--  FIN DU SCHEMA
-- ============================================================