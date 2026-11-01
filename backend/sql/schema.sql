-- LeveledUp Database Schema
CREATE DATABASE IF NOT EXISTS leveledup_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE leveledup_db;

-- 1. Tabel Riwayat Scan
CREATE TABLE IF NOT EXISTS scans (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    scan_token VARCHAR(64) NOT NULL UNIQUE,       -- UUID / token unik per scan
    device_id VARCHAR(128) NULL,                  -- ID perangkat mobile (opsional)
    file_name VARCHAR(255) NOT NULL,
    num_pages INT NOT NULL DEFAULT 1,
    num_chars INT NOT NULL DEFAULT 0,
    overall_score INT NOT NULL DEFAULT 0,
    summary TEXT NOT NULL,
    mode ENUM('global', 'local') NOT NULL DEFAULT 'global',
    engine ENUM('rule-based', 'gemini', 'claude') NOT NULL DEFAULT 'rule-based',
    is_unlocked BOOLEAN NOT NULL DEFAULT FALSE,
    unlock_code_used VARCHAR(64) NULL,
    encrypted_token TEXT NULL,                    -- Segel AES-256 data berbayar
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_scan_token (scan_token),
    INDEX idx_device_id (device_id)
) ENGINE=InnoDB;

-- 2. Tabel Isu / Masalah Terdeteksi
CREATE TABLE IF NOT EXISTS scan_issues (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    scan_id BIGINT NOT NULL,
    issue_key VARCHAR(64) NOT NULL,              -- misal: photo, dob, duties
    category ENUM('personal_info', 'ats_readability', 'keyword_match', 'achievements', 'language_quality') NOT NULL,
    severity ENUM('critical', 'warning', 'suggestion') NOT NULL,
    title VARCHAR(255) NOT NULL,                 -- Gratis (selalu terbuka)
    detail TEXT NULL,                            -- Berbayar (terbuka jika unlocked)
    fix TEXT NULL,                               -- Berbayar
    rewrite_before TEXT NULL,                    -- Berbayar
    rewrite_after TEXT NULL,                     -- Berbayar
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (scan_id) REFERENCES scans(id) ON DELETE CASCADE,
    INDEX idx_scan_id (scan_id)
) ENGINE=InnoDB;

-- 3. Tabel Kecocokan Kata Kunci
CREATE TABLE IF NOT EXISTS scan_keywords (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    scan_id BIGINT NOT NULL,
    job_title VARCHAR(128) NULL,
    matched_keywords JSON NOT NULL,              -- Array kata kunci cocok
    missing_keywords JSON NOT NULL,              -- Array kata kunci hilang (terkunci sebelum bayar)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (scan_id) REFERENCES scans(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 4. Tabel CV Hasil Rewrite AI
CREATE TABLE IF NOT EXISTS scan_rewrites (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    scan_id BIGINT NOT NULL,
    applicant_name VARCHAR(128) NOT NULL,
    applicant_title VARCHAR(128) NOT NULL,
    contact_lines JSON NOT NULL,                 -- Array kontak bersih
    summary TEXT NOT NULL,
    sections JSON NOT NULL,                      -- Array of { heading: string, bullets: [] }
    changes JSON NOT NULL,                       -- Catatan hal yang diubah & placeholder
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (scan_id) REFERENCES scans(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 5. Tabel Kode Akses / Kupon Berbayar
CREATE TABLE IF NOT EXISTS access_codes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(64) NOT NULL UNIQUE,
    description VARCHAR(255) NULL,
    max_uses INT NOT NULL DEFAULT 1,
    times_used INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    expires_at DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_code (code)
) ENGINE=InnoDB;

-- Inisialisasi kode uji coba default
INSERT INTO access_codes (code, description, max_uses, times_used, is_active)
VALUES ('LEVELEDUPVIP2026', 'Kode Promo Peluncuran Mobile MVP', 1000, 0, TRUE)
ON DUPLICATE KEY UPDATE code=code;
