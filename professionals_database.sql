-- ============================================================
--  BASE DE DONNÉES : Professionals
--  Plateforme de connexion Étudiants <-> Entreprises
--  Moteur : InnoDB | Encodage : utf8mb4 | Collation : utf8mb4_unicode_ci
--  Version Laravel/React compatible
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- ============================================================
-- 1. UTILISATEURS & AUTHENTIFICATION
-- ============================================================

CREATE TABLE users (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100)        NOT NULL,
    email           VARCHAR(180)        NOT NULL UNIQUE,
    email_verified_at DATETIME          NULL,
    password        VARCHAR(255)        NOT NULL,
    role            ENUM('student','company','admin') NOT NULL DEFAULT 'student',
    avatar          VARCHAR(255)        NULL COMMENT 'Chemin vers la photo de profil',
    phone           VARCHAR(30)         NULL,
    is_active       TINYINT(1)          NOT NULL DEFAULT 1,
    remember_token  VARCHAR(100)        NULL,
    last_login_at   DATETIME            NULL,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at      DATETIME            NULL COMMENT 'Soft delete Laravel',
    INDEX idx_users_role (role),
    INDEX idx_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Comptes utilisateurs (étudiants, entreprises, admins)';


-- Profils étudiants étendus
CREATE TABLE student_profiles (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT UNSIGNED     NOT NULL UNIQUE,
    first_name      VARCHAR(80)         NOT NULL,
    last_name       VARCHAR(80)         NOT NULL,
    date_of_birth   DATE                NULL,
    gender          ENUM('M','F','other','prefer_not') NULL,
    nationality     VARCHAR(80)         NULL,
    city            VARCHAR(100)        NULL,
    country         VARCHAR(100)        NULL DEFAULT 'Congo',
    bio             TEXT                NULL,
    school          VARCHAR(200)        NULL COMMENT 'Établissement actuel',
    field_of_study  VARCHAR(200)        NULL COMMENT 'Filière / spécialité',
    level           VARCHAR(80)         NULL COMMENT 'Licence 3, Master 1, BTS…',
    graduation_year YEAR                NULL,
    cv_path         VARCHAR(255)        NULL COMMENT 'CV en PDF',
    linkedin_url    VARCHAR(255)        NULL,
    portfolio_url   VARCHAR(255)        NULL,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_sp_city (city),
    INDEX idx_sp_field (field_of_study)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Informations détaillées des étudiants';


-- ============================================================
-- 2. RÉFÉRENTIELS GÉOGRAPHIQUES & SECTEURS
-- ============================================================

CREATE TABLE countries (
    id              SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100)        NOT NULL,
    iso_code        CHAR(2)             NOT NULL UNIQUE,
    continent       VARCHAR(50)         NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Pays (référentiel ISO)';


CREATE TABLE cities (
    id              MEDIUMINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    country_id      SMALLINT UNSIGNED   NOT NULL,
    name            VARCHAR(100)        NOT NULL,
    region          VARCHAR(100)        NULL COMMENT 'Département / Province',
    latitude        DECIMAL(9,6)        NULL,
    longitude       DECIMAL(9,6)        NULL,
    INDEX idx_cities_country (country_id),
    INDEX idx_cities_name (name),
    FOREIGN KEY (country_id) REFERENCES countries(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Villes disponibles pour la recherche géographique';


CREATE TABLE sectors (
    id              SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(150)        NOT NULL,
    slug            VARCHAR(150)        NOT NULL UNIQUE COMMENT 'URL-friendly : big-data, construction…',
    icon            VARCHAR(100)        NULL COMMENT 'Nom icône (ex: fa-building)',
    description     TEXT                NULL,
    parent_id       SMALLINT UNSIGNED   NULL COMMENT 'Secteur parent (hiérarchie 2 niveaux)',
    INDEX idx_sectors_slug (slug),
    FOREIGN KEY (parent_id) REFERENCES sectors(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Secteurs d activité (Big Data, Construction, Agro-industrie…)';


-- ============================================================
-- 3. ENTREPRISES
-- ============================================================

CREATE TABLE companies (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT UNSIGNED     NOT NULL UNIQUE COMMENT 'Compte propriétaire',
    name            VARCHAR(200)        NOT NULL,
    slug            VARCHAR(220)        NOT NULL UNIQUE,
    sector_id       SMALLINT UNSIGNED   NULL,
    city_id         MEDIUMINT UNSIGNED  NULL,
    country_id      SMALLINT UNSIGNED   NULL,
    address_detail  VARCHAR(255)        NULL COMMENT 'Adresse complète',
    logo_path       VARCHAR(255)        NULL,
    cover_image     VARCHAR(255)        NULL COMMENT 'Bannière de la fiche',
    website_url     VARCHAR(255)        NULL,
    email_general   VARCHAR(180)        NULL COMMENT 'Email de contact général',
    phone_general   VARCHAR(30)         NULL,
    founded_year    YEAR                NULL,
    company_size    ENUM(
        '1-10','11-50','51-200','201-500','501-1000','1000+'
    )                                   NULL COMMENT 'Taille indicative',
    employee_count  INT UNSIGNED        NULL COMMENT 'Nombre d employés (optionnel)',
    description     TEXT                NULL COMMENT 'Description courte (carte)',
    description_full LONGTEXT           NULL COMMENT 'Description complète (fiche)',
    mission_statement TEXT              NULL,
    is_verified     TINYINT(1)          NOT NULL DEFAULT 0 COMMENT 'Badge vérifié par admin',
    is_active       TINYINT(1)          NOT NULL DEFAULT 1,
    chat_enabled    TINYINT(1)          NOT NULL DEFAULT 0 COMMENT 'Chat RH activé',
    profile_views   INT UNSIGNED        NOT NULL DEFAULT 0,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at      DATETIME            NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (sector_id) REFERENCES sectors(id) ON DELETE SET NULL,
    FOREIGN KEY (city_id) REFERENCES cities(id) ON DELETE SET NULL,
    FOREIGN KEY (country_id) REFERENCES countries(id) ON DELETE SET NULL,
    FULLTEXT INDEX ft_companies_search (name, description, description_full),
    INDEX idx_companies_sector (sector_id),
    INDEX idx_companies_city (city_id),
    INDEX idx_companies_verified (is_verified),
    INDEX idx_companies_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Fiches entreprises – cœur de la plateforme';


-- Sous-secteurs/tags additionnels d'une entreprise (relation N:N)
CREATE TABLE company_sectors (
    company_id      BIGINT UNSIGNED     NOT NULL,
    sector_id       SMALLINT UNSIGNED   NOT NULL,
    PRIMARY KEY (company_id, sector_id),
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    FOREIGN KEY (sector_id) REFERENCES sectors(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Tags sectoriels multiples par entreprise';


-- ============================================================
-- 4. MULTIMÉDIA ENTREPRISE
-- ============================================================

CREATE TABLE company_media (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id      BIGINT UNSIGNED     NOT NULL,
    type            ENUM('video','virtual_tour','image','document') NOT NULL,
    title           VARCHAR(200)        NULL,
    description     TEXT                NULL,
    url             VARCHAR(500)        NOT NULL COMMENT 'URL ou chemin fichier',
    thumbnail_url   VARCHAR(500)        NULL,
    is_featured     TINYINT(1)          NOT NULL DEFAULT 0,
    sort_order      SMALLINT UNSIGNED   NOT NULL DEFAULT 0,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    INDEX idx_cm_company_type (company_id, type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Vidéos de présentation, visite 3D, galerie photos entreprises';


-- Publications / réalisations entreprise
CREATE TABLE company_publications (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id      BIGINT UNSIGNED     NOT NULL,
    title           VARCHAR(255)        NOT NULL,
    content         LONGTEXT            NOT NULL,
    type            ENUM('achievement','news','publication','project') NOT NULL DEFAULT 'news',
    cover_image     VARCHAR(255)        NULL,
    published_at    DATETIME            NULL,
    is_published    TINYINT(1)          NOT NULL DEFAULT 1,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    INDEX idx_cp_company (company_id),
    INDEX idx_cp_published (is_published, published_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Réalisations et publications visibles sur la fiche entreprise';


-- Organigramme de l'entreprise
CREATE TABLE company_org_nodes (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id      BIGINT UNSIGNED     NOT NULL,
    parent_id       BIGINT UNSIGNED     NULL COMMENT 'Nœud parent (NULL = racine)',
    person_name     VARCHAR(150)        NOT NULL,
    title           VARCHAR(150)        NOT NULL COMMENT 'Poste / Fonction',
    department      VARCHAR(100)        NULL,
    avatar          VARCHAR(255)        NULL,
    email           VARCHAR(180)        NULL,
    sort_order      SMALLINT UNSIGNED   NOT NULL DEFAULT 0,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES company_org_nodes(id) ON DELETE SET NULL,
    INDEX idx_org_company (company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Organigramme hiérarchique de l entreprise';


-- ============================================================
-- 5. CONTACTS RH
-- ============================================================

CREATE TABLE company_hr_contacts (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id      BIGINT UNSIGNED     NOT NULL,
    full_name       VARCHAR(150)        NOT NULL,
    job_title       VARCHAR(150)        NULL COMMENT 'DRH, Responsable RH…',
    email           VARCHAR(180)        NOT NULL,
    phone           VARCHAR(30)         NULL,
    avatar          VARCHAR(255)        NULL,
    is_primary      TINYINT(1)          NOT NULL DEFAULT 0 COMMENT 'Contact RH principal',
    is_chat_enabled TINYINT(1)          NOT NULL DEFAULT 0,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    INDEX idx_hr_company (company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Contacts RH de chaque entreprise';


-- ============================================================
-- 6. OFFRES (STAGES & EMPLOIS)
-- ============================================================

CREATE TABLE job_offers (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id      BIGINT UNSIGNED     NOT NULL,
    title           VARCHAR(255)        NOT NULL,
    slug            VARCHAR(270)        NOT NULL UNIQUE,
    type            ENUM('internship','job','apprenticeship','freelance') NOT NULL DEFAULT 'internship',
    description     LONGTEXT            NOT NULL,
    requirements    TEXT                NULL COMMENT 'Profil requis',
    benefits        TEXT                NULL COMMENT 'Avantages offerts',
    location_type   ENUM('onsite','remote','hybrid') NOT NULL DEFAULT 'onsite',
    city_id         MEDIUMINT UNSIGNED  NULL,
    sector_id       SMALLINT UNSIGNED   NULL,
    salary_min      DECIMAL(12,2)       NULL,
    salary_max      DECIMAL(12,2)       NULL,
    salary_currency VARCHAR(10)         NOT NULL DEFAULT 'XAF',
    duration        VARCHAR(80)         NULL COMMENT 'Ex: 3 mois, CDI, CDD 1 an',
    start_date      DATE                NULL,
    end_date        DATE                NULL COMMENT 'Date limite candidature',
    spots_available SMALLINT UNSIGNED   NULL COMMENT 'Nombre de postes',
    is_active       TINYINT(1)          NOT NULL DEFAULT 1,
    views           INT UNSIGNED        NOT NULL DEFAULT 0,
    published_at    DATETIME            NULL,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at      DATETIME            NULL,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    FOREIGN KEY (city_id) REFERENCES cities(id) ON DELETE SET NULL,
    FOREIGN KEY (sector_id) REFERENCES sectors(id) ON DELETE SET NULL,
    FULLTEXT INDEX ft_job_search (title, description, requirements),
    INDEX idx_jobs_company (company_id),
    INDEX idx_jobs_type (type),
    INDEX idx_jobs_active (is_active, published_at),
    INDEX idx_jobs_end_date (end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Offres de stage et d emploi publiées par les entreprises';


-- Tags compétences liés aux offres
CREATE TABLE skills (
    id              SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100)        NOT NULL UNIQUE,
    slug            VARCHAR(100)        NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Référentiel de compétences / technologies';

CREATE TABLE job_offer_skills (
    job_offer_id    BIGINT UNSIGNED     NOT NULL,
    skill_id        SMALLINT UNSIGNED   NOT NULL,
    is_required     TINYINT(1)          NOT NULL DEFAULT 1,
    PRIMARY KEY (job_offer_id, skill_id),
    FOREIGN KEY (job_offer_id) REFERENCES job_offers(id) ON DELETE CASCADE,
    FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Compétences requises ou souhaitées pour une offre';


-- ============================================================
-- 7. CANDIDATURES
-- ============================================================

CREATE TABLE applications (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT UNSIGNED     NOT NULL COMMENT 'Étudiant candidat',
    job_offer_id    BIGINT UNSIGNED     NULL COMMENT 'NULL = candidature spontanée',
    company_id      BIGINT UNSIGNED     NOT NULL COMMENT 'Entreprise ciblée',
    type            ENUM('offer','spontaneous') NOT NULL DEFAULT 'offer',
    cover_letter    TEXT                NULL COMMENT 'Lettre de motivation / message',
    cv_path         VARCHAR(255)        NULL COMMENT 'CV joint (peut différer du profil)',
    additional_docs JSON                NULL COMMENT 'Autres pièces jointes (chemins)',
    status          ENUM(
        'pending','viewed','shortlisted',
        'interview','accepted','rejected','withdrawn'
    )                                   NOT NULL DEFAULT 'pending',
    notes_hr        TEXT                NULL COMMENT 'Notes internes RH (non visibles étudiant)',
    applied_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_application (user_id, job_offer_id, company_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (job_offer_id) REFERENCES job_offers(id) ON DELETE SET NULL,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    INDEX idx_app_user (user_id),
    INDEX idx_app_company (company_id),
    INDEX idx_app_status (status),
    INDEX idx_app_offer (job_offer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Candidatures (offres + spontanées)';


-- Historique des changements de statut d'une candidature
CREATE TABLE application_status_logs (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    application_id  BIGINT UNSIGNED     NOT NULL,
    old_status      VARCHAR(50)         NULL,
    new_status      VARCHAR(50)         NOT NULL,
    changed_by      BIGINT UNSIGNED     NULL COMMENT 'User qui a changé le statut',
    note            TEXT                NULL,
    changed_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_asl_application (application_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Journal des changements de statut des candidatures';


-- ============================================================
-- 8. AVIS & NOTATIONS ENTREPRISES
-- ============================================================

CREATE TABLE company_reviews (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id      BIGINT UNSIGNED     NOT NULL,
    user_id         BIGINT UNSIGNED     NOT NULL COMMENT 'Étudiant auteur',
    rating          TINYINT UNSIGNED    NOT NULL COMMENT '1 à 5 étoiles',
    title           VARCHAR(200)        NULL,
    comment         TEXT                NOT NULL,
    experience_type ENUM('internship','job','visit','other') NULL,
    year            YEAR                NULL COMMENT 'Année de l expérience',
    is_approved     TINYINT(1)          NOT NULL DEFAULT 0 COMMENT 'Modération admin',
    is_anonymous    TINYINT(1)          NOT NULL DEFAULT 0,
    helpful_count   INT UNSIGNED        NOT NULL DEFAULT 0,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_review (company_id, user_id),
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_reviews_company (company_id, is_approved),
    CONSTRAINT chk_rating CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Avis et notations des entreprises par les étudiants';


-- Votes "utile" sur les avis
CREATE TABLE review_votes (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    review_id       BIGINT UNSIGNED     NOT NULL,
    user_id         BIGINT UNSIGNED     NOT NULL,
    voted_at        DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_vote (review_id, user_id),
    FOREIGN KEY (review_id) REFERENCES company_reviews(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Votes "utile" sur les avis';


-- ============================================================
-- 9. RECHERCHE & SUGGESTIONS INTELLIGENTES
-- ============================================================

-- Historique des recherches (pour auto-complétion & analytics)
CREATE TABLE search_queries (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT UNSIGNED     NULL COMMENT 'NULL = visiteur anonyme',
    query           VARCHAR(255)        NOT NULL,
    type            ENUM('name','sector','location','mixed') NOT NULL DEFAULT 'mixed',
    results_count   SMALLINT UNSIGNED   NULL,
    ip_address      VARCHAR(45)         NULL,
    searched_at     DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_sq_query (query),
    INDEX idx_sq_type (type),
    INDEX idx_sq_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Historique des recherches pour auto-complétion et analytics';


-- Suggestions personnalisées ("Recherchées près de chez vous")
CREATE TABLE company_suggestions (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id      BIGINT UNSIGNED     NOT NULL,
    city_id         MEDIUMINT UNSIGNED  NULL COMMENT 'Suggestion locale (NULL = globale)',
    sector_id       SMALLINT UNSIGNED   NULL COMMENT 'Suggestion par secteur',
    score           FLOAT               NOT NULL DEFAULT 0.0 COMMENT 'Score de pertinence calculé',
    reason          ENUM('local','trending','new','featured','sector_match') NOT NULL DEFAULT 'featured',
    is_active       TINYINT(1)          NOT NULL DEFAULT 1,
    expires_at      DATETIME            NULL,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    FOREIGN KEY (city_id) REFERENCES cities(id) ON DELETE SET NULL,
    FOREIGN KEY (sector_id) REFERENCES sectors(id) ON DELETE SET NULL,
    INDEX idx_sugg_city (city_id, is_active),
    INDEX idx_sugg_score (score DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Suggestions d entreprises personnalisées par ville/secteur';


-- ============================================================
-- 10. MESSAGERIE / CHAT
-- ============================================================

CREATE TABLE conversations (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id      BIGINT UNSIGNED     NOT NULL,
    company_id      BIGINT UNSIGNED     NOT NULL,
    hr_contact_id   BIGINT UNSIGNED     NULL COMMENT 'Contact RH assigné',
    subject         VARCHAR(255)        NULL,
    status          ENUM('open','closed','archived') NOT NULL DEFAULT 'open',
    last_message_at DATETIME            NULL,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_conv (student_id, company_id),
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    FOREIGN KEY (hr_contact_id) REFERENCES company_hr_contacts(id) ON DELETE SET NULL,
    INDEX idx_conv_student (student_id),
    INDEX idx_conv_company (company_id),
    INDEX idx_conv_last (last_message_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Conversations entre étudiants et entreprises';


CREATE TABLE messages (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    conversation_id BIGINT UNSIGNED     NOT NULL,
    sender_id       BIGINT UNSIGNED     NOT NULL,
    body            TEXT                NOT NULL,
    attachment_path VARCHAR(255)        NULL,
    is_read         TINYINT(1)          NOT NULL DEFAULT 0,
    read_at         DATETIME            NULL,
    sent_at         DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_msg_conv (conversation_id, sent_at),
    INDEX idx_msg_unread (is_read, sender_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Messages du chat entre étudiant et RH';


-- ============================================================
-- 11. NOTIFICATIONS
-- ============================================================

CREATE TABLE notifications (
    id              CHAR(36)            NOT NULL PRIMARY KEY COMMENT 'UUID Laravel',
    type            VARCHAR(255)        NOT NULL COMMENT 'Classe de notification Laravel',
    notifiable_type VARCHAR(255)        NOT NULL,
    notifiable_id   BIGINT UNSIGNED     NOT NULL,
    data            JSON                NOT NULL,
    read_at         DATETIME            NULL,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_notif_notifiable (notifiable_type, notifiable_id),
    INDEX idx_notif_read (read_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Notifications système (compatible Laravel Notifications)';


-- ============================================================
-- 12. FAVORIS / SUIVI
-- ============================================================

CREATE TABLE bookmarks (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT UNSIGNED     NOT NULL,
    bookmarkable_type ENUM('company','job_offer') NOT NULL,
    bookmarkable_id BIGINT UNSIGNED     NOT NULL,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_bookmark (user_id, bookmarkable_type, bookmarkable_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_bm_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Favoris : entreprises et offres sauvegardés par un étudiant';


-- ============================================================
-- 13. ANALYTICS / VUES
-- ============================================================

CREATE TABLE page_views (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    viewable_type   ENUM('company','job_offer') NOT NULL,
    viewable_id     BIGINT UNSIGNED     NOT NULL,
    user_id         BIGINT UNSIGNED     NULL,
    ip_address      VARCHAR(45)         NULL,
    user_agent      VARCHAR(500)        NULL,
    referrer        VARCHAR(500)        NULL,
    viewed_at       DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_pv_viewable (viewable_type, viewable_id),
    INDEX idx_pv_date (viewed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Suivi des vues de fiches entreprises et offres';


-- ============================================================
-- 14. ADMINISTRATION & MODÉRATION
-- ============================================================

CREATE TABLE admin_reports (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reporter_id     BIGINT UNSIGNED     NOT NULL,
    reportable_type ENUM('company','job_offer','review','user') NOT NULL,
    reportable_id   BIGINT UNSIGNED     NOT NULL,
    reason          ENUM(
        'spam','fake','inappropriate',
        'misleading','harassment','other'
    )                                   NOT NULL,
    description     TEXT                NULL,
    status          ENUM('pending','reviewed','resolved','dismissed') NOT NULL DEFAULT 'pending',
    resolved_by     BIGINT UNSIGNED     NULL,
    resolved_at     DATETIME            NULL,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (reporter_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (resolved_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_ar_status (status),
    INDEX idx_ar_type (reportable_type, reportable_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Signalements soumis par les utilisateurs';


-- ============================================================
-- 15. SESSIONS LARAVEL (optionnel si config sessions = database)
-- ============================================================

CREATE TABLE sessions (
    id              VARCHAR(255)        NOT NULL PRIMARY KEY,
    user_id         BIGINT UNSIGNED     NULL,
    ip_address      VARCHAR(45)         NULL,
    user_agent      TEXT                NULL,
    payload         LONGTEXT            NOT NULL,
    last_activity   INT                 NOT NULL,
    INDEX idx_sessions_user (user_id),
    INDEX idx_sessions_activity (last_activity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Sessions Laravel (driver database)';


-- ============================================================
-- DONNÉES DE BASE (seed)
-- ============================================================

INSERT INTO countries (name, iso_code, continent) VALUES
('Congo', 'CG', 'Afrique'),
('République Démocratique du Congo', 'CD', 'Afrique'),
('Côte d\'Ivoire', 'CI', 'Afrique'),
('Cameroun', 'CM', 'Afrique'),
('Gabon', 'GA', 'Afrique'),
('France', 'FR', 'Europe');

INSERT INTO cities (country_id, name, region, latitude, longitude) VALUES
(1, 'Brazzaville',  'Pool',         -4.2661, 15.2832),
(1, 'Pointe-Noire', 'Kouilou',      -4.7761, 11.8635),
(1, 'Dolisie',      'Niari',        -4.1983, 12.6703),
(2, 'Kinshasa',     'Kinshasa',     -4.3317, 15.3214),
(3, 'Abidjan',      'District AA',   5.3599, -4.0083),
(4, 'Douala',       'Littoral',      4.0511,  9.7679),
(5, 'Libreville',   'Estuaire',      0.3924,  9.4536),
(6, 'Paris',        'Île-de-France',48.8566,  2.3522);

INSERT INTO sectors (name, slug, icon) VALUES
('Big Data & Intelligence Artificielle', 'big-data-ia',       'fa-brain'),
('Télécommunications',                   'telecommunications', 'fa-satellite-dish'),
('Construction & BTP',                   'construction-btp',   'fa-hard-hat'),
('Agro-industrie',                       'agro-industrie',     'fa-seedling'),
('Finance & Banque',                     'finance-banque',     'fa-landmark'),
('Santé & Pharmaceutique',               'sante-pharma',       'fa-stethoscope'),
('Énergie & Mines',                      'energie-mines',      'fa-bolt'),
('Commerce & Distribution',              'commerce',           'fa-store'),
('Transport & Logistique',               'transport-logistique','fa-truck'),
('Éducation & Formation',                'education-formation', 'fa-graduation-cap'),
('Technologies & Informatique',          'tech-informatique',  'fa-laptop-code'),
('Médias & Communication',               'medias-communication','fa-newspaper');

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- FIN DU SCRIPT
-- ============================================================
