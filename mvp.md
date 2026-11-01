# LeveledUp Mobile — Minimum Viable Product (MVP) Specification

Dokumen spesifikasi produk, teknis, arsitektur backend, dan database (MVP) untuk mengimplementasikan **LeveledUp CV Scanner** versi mobile dengan stack:
- **Mobile Frontend:** **Flutter (Dart)**
- **Backend API:** **Node.js (Express.js)**
- **Database:** **MySQL**

---

## 1. Ringkasan Eksekutif & Visi Produk

**LeveledUp Mobile** adalah aplikasi scanner dan optimasi CV berbasis standar ATS (*Applicant Tracking System*) internasional, yang dirancang khusus untuk pelamar kerja asal Indonesia yang ingin menembus lowongan kerja di perusahaan global, remote internasional, atau multinasional (AS, Eropa, Inggris, Singapura, dll.).

### 1.1 Masalah Utama (Problem)
- **Oversharing & Data Bias:** CV khas Indonesia umumnya menyertakan pas foto, tanggal lahir, status pernikahan, agama, gender, dan NIK. Bagi perusahaan global (khususnya AS/Inggris/Kanada), data ini berisiko bias hukum dan sering kali langsung didiskualifikasi secara otomatis.
- **Ditolak Robot ATS:** Desain grafis berlebihan (tabel ganda, kolom rumit, ikon grafis) membuat teks CV tidak terbaca oleh parser ATS.
- **Gaya Daftar Tugas vs. Pencapaian:** Poin pengalaman kerja hanya berupa deskripsi tugas administratif pasif (*"bertanggung jawab mengelola..."*) tanpa metrik dan hasil terukur (*quantified achievements*).
- **Bahasa Inggris Kaku:** Terjemahan harfiah dan frasa klise yang menurunkan impresi profesional pertama.

### 1.2 Solusi & Nilai Utama (Value Proposition)
1. **Scan Cepat & Transparan (Gratis):** Pengguna mengunggah PDF CV langsung dari HP melalui Flutter File Picker, mendapatkan Skor ATS (0–100) dan ringkasan masalah dalam 5 kategori internasional.
2. **Solusi & Panduan Terperinci (Berbayar):** Menjelaskan alasan mendalam mengapa setiap poin bermasalah, langkah perbaikan konkret, serta contoh rewrite sebelum & sesudah (*before vs after*).
3. **Perbaiki CV Otomatis (*AI Resume Rewrite*):** AI menulis ulang CV menjadi format teks ramah ATS, membuang data bias, dan mengonversi tugas menjadi poin pencapaian dengan aturan **Anti-Fabrikasi / Zero-Hallucination**.
4. **Privasi Tanpa Kompromi:** File PDF mentah hanya diproses di memori server untuk ekstraksi teks dan tidak disimpan permanen di disk atau database.

---

## 2. Batasan Ruang Lingkup (Scope & Non-Goals)

### 2.1 Di Dalam Ruang Lingkup MVP (In-Scope)
- **1 Mode Tunggal:** Mode Global (Standar ATS Internasional / Perusahaan Luar Negeri).
- **Format File:** Hanya dokumen **PDF** asli berbasis teks (maksimal 4 MB).
- **Tier Gratis (Freemium):**
  - Skor keseluruhan (0–100) dan label kesiapan (*Siap kirim, Perlu polesan, Perlu perbaikan, Berisiko tersaring*).
  - Jumlah dan kategori masalah yang ditemukan.
  - Judul masalah (tanpa membuka detail solusi perbaikan).
  - Indikator kecocokan kata kunci (jumlah *matched* vs *missing*).
- **Tier Berbayar (Unlocked):**
  - Rincian penjelasan tiap masalah + cara perbaikan spesifik.
  - Contoh penulisan ulang (*Rewrite Before & After*).
  - Daftar kata kunci yang hilang (*missing keywords*).
  - Ekspor Laporan Analisis (HTML / teks).
  - Fitur **Perbaiki CV Otomatis** (AI rewrite lengkap + ekspor ke Markdown, Plain Text, HTML).
- **Mekanisme Akses:** Kode akses (*voucher/promo code*) yang tersimpan dan divalidasi di database MySQL.

### 2.2 Di Luar Ruang Lingkup MVP (Non-Goals / Post-MVP)
- ❌ **Mode Lokal (Perusahaan Indonesia):** Ditunda (karena aturan lokal berlawanan: foto justru sering diwajibkan).
- ❌ **Talent Pool / Job Board:** Tidak ada fitur berbagi CV ke rekruter luar.
- ❌ **Cover Letter & Interview Prep:** Fokus 100% pada diagnostik dan penulisan ulang CV.
- ❌ **Autentikasi Akun Rumit:** MVP menggunakan sesi berbasis *device ID* / token; riwayat scan disimpan lokal di HP (Flutter Secure Storage / SQLite lokal) dan di MySQL via token referensi.
- ❌ **OCR untuk PDF Gambar/Scan:** Jika teks tidak bisa diekstrak (< 80 karakter), tolak dengan pesan edukasi agar pengguna mengunggah PDF teks asli.

---

## 3. Alur Pengguna & Antarmuka Mobile (User Journey)

```
[1. Flutter Home Screen]
         │ (Pilih file .pdf via file_picker)
         ▼
[2. Validasi & Parsing di Node.js]
         │ (POST /api/parse: Cek ukuran <= 4MB, ekstrak teks >= 80 char)
         ▼
[3. Scanning Screen (Animasi Flutter)]
         │ (POST /api/analyze: Gemini/Claude + Simpan ke MySQL)
         ▼
[4. Results Screen — Free Preview]
   ├── Skor Cincin (0-100 via CustomPainter) & 5 Kategori
   ├── Judul Masalah Terdeteksi (Detail terkunci 🔒)
   ├── Preview Kata Kunci
   └── CTA: "Buka Rincian Solusi & Rewrite"
         │
         ├──► [Modal / Dialog Unlock] (Kirim kode akses ke POST /api/unlock)
         │           │
         │           ▼
[5. Results Screen — Unlocked]
   ├── Semua detail penjelasan, solusi, & Before/After terbuka
   ├── Tombol "Ekspor Laporan Analisis"
   └── Section "Perbaiki CV Otomatis" (AI Rewrite)
         │ (Tekan: Mulai Tulis Ulang -> POST /api/rewrite)
         ▼
[6. CV Rewrite Result & Export]
   ├── Preview CV Baru (Highlight [placeholder] dengan RichText)
   ├── Daftar perubahan & hal yang wajib diisi pengguna
   └── Share Sheet via share_plus: Salin Teks, Ekspor .MD, .TXT, atau .HTML
```

### 3.1 Layar 1: Beranda & Picker Dokumen
- Tampilan modern bertema gelap (*Dark Mode*: latar `#09090b` dengan aksen terakota `#b5462f`).
- Headline: *"Taklukkan Filter ATS. Amankan Panggilan Interview."*
- Card Unggah Dokumen:
  - Membuka file picker sistem operasi via package `file_picker`.
  - Validasi instan di Flutter: ekstensi `.pdf` dan ukuran file $\le$ 4 MB.
  - Catatan privasi: *"CV Anda diproses secara aman dan tidak disimpan permanen di server."*

### 3.2 Layar 2: Animasi Scanning (Feedback Proses)
- Mengurangi *perceived wait time* selama AI memproses (10–30 detik).
- Tahapan status animasi bertahap (menggunakan `AnimationController` / `Timer`):
  1. *Mengekstrak teks dokumen PDF...*
  2. *Memeriksa struktur & keterbacaan ATS...*
  3. *Mengevaluasi standar bias internasional...*
  4. *Menyusun skor dan rekomendasi...*

### 3.3 Layar 3: Dashboard Hasil (Free Preview)
- **Score Ring Card:** Cincin skor 0–100 digambar menggunakan `CustomPainter` Flutter:
  - `80 - 100`: Hijau zamrud (`#10b981`) — Siap kirim
  - `60 - 79`: Kuning amber (`#f59e0b`) — Perlu polesan
  - `40 - 59`: Oranye (`#f97316`) — Perlu perbaikan
  - `< 40`: Merah (`#ef4444`) — Berisiko tersaring
- **Ringkasan Masalah per Kategori:** Grid 5 kategori ATS dengan badge jumlah masalah.
- **Daftar Masalah (Gated Card):**
  - Menampilkan *Severity badge* (`critical`, `warning`, `suggestion`).
  - Menampilkan *Kategori* dan *Judul Masalah*.
  - Baris terkunci (*Locked Row*): Ikon gembok bertuliskan *"Rincian & solusi tersedia di versi lengkap"*.
- **Bottom Navigation / Floating Action CTA:** *"Buka Rincian & Perbaiki CV"*.

### 3.4 Layar 4: Buka Akses / Dialog Unlock
- Dialog input kode akses (*Access Code*).
- Flutter mengirim token dan kode ke endpoint Node.js Express `/api/unlock`.
- Node.js memvalidasi kode di tabel MySQL `access_codes` dan mengembalikan data lengkap.

### 3.5 Layar 5: Hasil Lengkap & Perbaiki CV Otomatis
- **Detail Masalah:** Penjelasan lengkap + boks solusi + boks perbandingan *Before* (dicoret merah) vs *After* (hijau).
- **Section "Perbaiki CV Otomatis":**
  - Tombol *"Mulai Tulis Ulang"*.
  - Menampilkan CV hasil susun ulang AI menggunakan `RichText` dengan latar warna amber pada teks dalam tanda kurung siku `[placeholder]`.
  - Tombol aksi:
    - **Salin ke Clipboard** (`Clipboard.setData`).
    - **Ekspor Dokumen** via package `share_plus` (`.md`, `.txt`, `.html`).

---

## 4. Aturan Analisis Domain (5 Kategori ATS Global)

Algoritma pendeteksi (rule-based maupun prompt AI) mematuhi 5 pilar berikut:

| Kategori | ID Kategori | Masalah yang Dideteksi | Mengapa Fatal di Luar Negeri? |
| :--- | :--- | :--- | :--- |
| **Data Pribadi** | `personal_info` | Foto diri, tanggal/tempat lahir, umur, status nikah, agama, gender, NIK/KTP, golongan darah, tinggi/berat badan, hobi. | Di AS/UK/Kanada, meminta/menyertakan data ini berisiko tuntutan diskriminasi (EEOC). Banyak HR otomatis membuang CV berfoto untuk menghindari bias hukum. |
| **Keterbacaan ATS** | `ats_readability` | Tabel rumit, tata letak multi-kolom yang tumpang tindih, header/footer grafis, font tak lazim. | Parser ATS membaca dokumen secara linear dari kiri ke kanan. Tabel dan multi-kolom membuat riwayat pekerjaan bercampur aduk. |
| **Kecocokan Kata Kunci** | `keyword_match` | Ketiadaan keahlian inti atau *industry-standard keywords* untuk posisi target yang disimpulkan dari CV. | ATS menggunakan sistem pencocokan kata kunci untuk memberi peringkat pelamar sebelum dilihat rekruter. |
| **Pencapaian Terukur** | `achievements` | Poin pengalaman hanya daftar tugas rutin pasif (*"Bertanggung jawab atas...", "Mengelola tim"*). | Standar global mewajibkan pola **Konteks → Aksi → Hasil Terukur** (*Action Verb + Context + Quantifiable Metric*). |
| **Kualitas Bahasa Inggris** | `language_quality` | Terjemahan kaku, frasa klise (*"hard-working", "able to work under pressure"*), tata bahasa pasif. | Untuk pekerjaan remote/internasional, CV adalah portofolio kemampuan komunikasi bahasa Inggris Anda. |

### 4.1 Aturan Emas Anti-Fabrikasi (Zero-Hallucination Policy)
> **KRITIS:** AI **DILARANG MENGARANG ANGKA ATAU FAKTA**.
> Jika sebuah poin pengalaman tidak mencantumkan metrik di CV asli, AI **WAJIB** menggunakan placeholder kurung siku:
> - ✅ Benar: *"Menumbuhkan tim dari [jumlah awal] ke [jumlah akhir] orang"*
> - ✅ Benar: *"Memangkas latensi query sebesar [X]% dengan indexing"*
> - ❌ **DILARANG:** *"Menumbuhkan tim menjadi 10 orang"* (jika angka 10 tidak ada di CV). Angka karangan dapat mencelakakan pelamar saat proses interview latar belakang (*background check*).

### 4.2 Sistem Pembobotan Skor (Rule-Based Penalty)
- Skor awal: `100`
- Pengurangan per masalah:
  - `critical`: `-11` poin
  - `warning`: `-7` poin
  - `suggestion`: `-3` poin
- Skor minimum dibatasi di angka `10`.

---

## 5. Arsitektur Teknis: Flutter + Node.js Express + MySQL

```
┌─────────────────────────────────────────────────────────────┐
│                 Mobile App: Flutter (Dart)                  │
│       • file_picker (PDF)        • dio / http               │
│       • flutter_secure_storage   • share_plus               │
└──────────────┬──────────────────────────────▲───────────────┘
               │ (HTTP / JSON over REST)      │
               │                              │
               │ 1. POST /api/parse (PDF)     │
               │ 2. POST /api/analyze         │
               │ 3. POST /api/unlock          │
               │ 4. POST /api/rewrite         │
               ▼                              │
┌─────────────────────────────────────────────┴───────────────┐
│              Backend API: Node.js (Express.js)              │
│                                                             │
│  • Routes: parse.js, analyze.js, unlock.js, rewrite.js      │
│  • Middleware: Multer (Memory Storage), Rate-Limiter, CORS  │
│  • Services: LLM Runner (Gemini/Claude), Token (AES-256)    │
│  • PDF Parser: unpdf / pdf-parse                            │
└──────────────┬──────────────────────────────▲───────────────┘
               │ (SQL via mysql2 / Pool)      │
               ▼                              │
┌─────────────────────────────────────────────┴───────────────┐
│                  Relational Database: MySQL                 │
│                                                             │
│  • scans (metadata & status)                                │
│  • scan_issues (masalah per kategori & detail berbayar)     │
│  • scan_keywords (matched & missing keywords)               │
│  • rewrites (hasil generate CV terstruktur)                 │
│  • access_codes (manajemen kupon & kode akses berbayar)     │
└─────────────────────────────────────────────────────────────┘
```

### 5.1 Skema Database MySQL (DDL)

Berikut adalah struktur tabel MySQL lengkap untuk menyimpan riwayat scan, isu, kata kunci, rewrite, dan kode akses:

```sql
-- Buat database
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
```

---

### 5.2 Spesifikasi Endpoint API (Node.js Express)

Semua endpoint RESTful siap dihubungkan ke client Flutter melalui `dio` atau `http`:

#### 1. `POST /api/parse`
Menerima upload dokumen PDF dan mengembalikan teks hasil ekstraksi.
- **Middleware:** `multer({ storage: multer.memoryStorage(), limits: { fileSize: 4 * 1024 * 1024 } })`
- **Content-Type:** `multipart/form-data`
- **Request:** Field form `file` (Binary PDF).
- **Response (200 OK):**
  ```json
  {
    "fileName": "Resume_Budi.pdf",
    "numPages": 2,
    "numChars": 4512,
    "text": "Budi Santoso\nSoftware Engineer\nEmail: budi@example.com..."
  }
  ```
- **Error Codes:**
  - `400`: File tidak dikirim.
  - `413`: Ukuran file melebihi batas 4 MB.
  - `415`: Format bukan PDF.
  - `422`: PDF tidak dapat dibaca / berbasis scan gambar (< 80 karakter teks).

#### 2. `POST /api/analyze`
Melakukan analisis skor ATS. Data hasil scan disimpan ke MySQL (`scans`, `scan_issues`, `scan_keywords`).
- **Content-Type:** `application/json`
- **Request Body:**
  ```json
  {
    "text": "Budi Santoso\nSoftware Engineer...",
    "fileName": "Resume_Budi.pdf",
    "deviceId": "flutter-device-uuid-1234"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "scanToken": "scn_9f8e7d6c5b4a",
    "result": {
      "mode": "global",
      "overallScore": 68,
      "summary": "CV Anda memiliki struktur dasar yang baik, namun terdeteksi beberapa data pribadi yang melanggar standar global...",
      "issues": [
        {
          "id": "photo",
          "category": "personal_info",
          "severity": "critical",
          "title": "CV menyertakan foto diri"
        },
        {
          "id": "duties",
          "category": "achievements",
          "severity": "warning",
          "title": "Sebagian poin masih bergaya daftar tugas, belum pencapaian terukur"
        }
      ],
      "keywordMatch": {
        "jobTitle": "Backend Engineer",
        "matched": ["Golang", "PostgreSQL", "Docker"],
        "missingCount": 4
      },
      "meta": {
        "fileName": "Resume_Budi.pdf",
        "analyzedAtLabel": "Dianalisis AI",
        "engine": "gemini"
      }
    },
    "token": "dGhpcy1pcy1hbi1hZXMtZ2NtLWVuY3J5cHRlZC10b2tlbg..."
  }
  ```

#### 3. `POST /api/unlock`
Membuka rincian berbayar menggunakan kode akses.
- **Logika Backend:**
  1. Cek validitas kode di tabel MySQL `access_codes` (`is_active = TRUE`, `times_used < max_uses`, `expires_at > NOW()`).
  2. Buka segel token enkripsi AES-256-GCM.
  3. Update `is_unlocked = TRUE` dan increment `times_used` di database.
  4. Kembalikan data lengkap (termasuk `detail`, `fix`, `rewrite`, dan daftar kata kunci yang hilang).
- **Request Body:**
  ```json
  {
    "scanToken": "scn_9f8e7d6c5b4a",
    "token": "dGhpcy1pcy1hbi1hZXMtZ2NtLWVuY3J5cHRlZC10b2tlbg...",
    "code": "LEVELEDUPVIP2026"
  }
  ```
- **Response (200 OK):** Mengembalikan objek `AnalysisResult` lengkap.
- **Error Codes:** `400` (Token tidak valid), `402` (Kode akses salah / sudah habis kuotanya).

#### 4. `POST /api/rewrite`
Membuat CV versi baru yang ramah ATS menggunakan panggilan AI kedua.
- **Request Body:**
  ```json
  {
    "scanToken": "scn_9f8e7d6c5b4a",
    "text": "Budi Santoso\nSoftware Engineer...",
    "code": "LEVELEDUPVIP2026",
    "fileName": "Resume_Budi.pdf"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "cv": {
      "name": "Budi Santoso",
      "title": "Senior Backend Engineer",
      "contact": ["budi.santoso@email.com", "+62 812 3456 7890", "linkedin.com/in/budisantoso"],
      "summary": "Results-driven Backend Engineer with 4+ years of experience building high-throughput microservices. Proven track record in optimizing database queries and scaling distributed architectures.",
      "sections": [
        {
          "heading": "Professional Experience",
          "bullets": [
            "Architected and deployed Golang microservices, reducing API response times by [X]% for over [jumlah] daily active users.",
            "Spearheaded database indexing on MySQL, improving query latency by [X]%.",
            "Collaborated with cross-functional teams to integrate CI/CD pipelines, cutting deployment cycle from [waktu awal] to [waktu akhir]."
          ]
        },
        {
          "heading": "Education",
          "bullets": ["B.S. in Computer Science, Universitas Indonesia (2018 - 2022)"]
        },
        {
          "heading": "Skills",
          "bullets": [
            "Languages: Golang, Python, Dart/Flutter",
            "Databases & Cloud: MySQL, Redis, Docker, GCP"
          ]
        }
      ],
      "changes": [
        "Menghapus pas foto, status pernikahan, dan tanggal lahir sesuai standar anti-bias internasional.",
        "Mengubah kalimat pasif deskripsi tugas menjadi pencapaian berbasis aksi (STAR method).",
        "Menambahkan penanda [placeholder] pada metrik persentase dan jumlah pengguna yang perlu Anda isi dengan data riil."
      ]
    }
  }
  ```

---

## 6. Model Data & Kontrak Tipe untuk Flutter (Dart)

Berikut adalah definisi model Dart siap pakai (lengkap dengan `fromJson` & `toJson`) untuk repositori Flutter:

```dart
// lib/models/cv_analysis_model.dart

enum IssueSeverity { critical, warning, suggestion }

enum IssueCategory {
  personalInfo,
  atsReadability,
  keywordMatch,
  achievements,
  languageQuality,
}

class RewriteExample {
  final String before;
  final String after;

  RewriteExample({required this.before, required this.after});

  factory RewriteExample.fromJson(Map<String, dynamic> json) {
    return RewriteExample(
      before: json['before'] ?? '',
      after: json['after'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'before': before, 'after': after};
}

class Issue {
  final String id;
  final String category;
  final String severity;
  final String title;
  final String? detail;
  final String? fix;
  final RewriteExample? rewrite;

  Issue({
    required this.id,
    required this.category,
    required this.severity,
    required this.title,
    this.detail,
    this.fix,
    this.rewrite,
  });

  bool get isLocked => detail == null || detail!.isEmpty;

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'] ?? '',
      category: json['category'] ?? 'personal_info',
      severity: json['severity'] ?? 'warning',
      title: json['title'] ?? '',
      detail: json['detail'],
      fix: json['fix'],
      rewrite: json['rewrite'] != null ? RewriteExample.fromJson(json['rewrite']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'severity': severity,
    'title': title,
    'detail': detail,
    'fix': fix,
    'rewrite': rewrite?.toJson(),
  };
}

class KeywordMatch {
  final String? jobTitle;
  final List<String> matched;
  final List<String> missing;

  KeywordMatch({
    this.jobTitle,
    required this.matched,
    required this.missing,
  });

  factory KeywordMatch.fromJson(Map<String, dynamic> json) {
    return KeywordMatch(
      jobTitle: json['jobTitle'],
      matched: List<String>.from(json['matched'] ?? []),
      missing: List<String>.from(json['missing'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'jobTitle': jobTitle,
    'matched': matched,
    'missing': missing,
  };
}

class AnalysisResult {
  final String mode;
  final int overallScore;
  final String summary;
  final List<Issue> issues;
  final KeywordMatch? keywordMatch;
  final String fileName;
  final String engine;

  AnalysisResult({
    required this.mode,
    required this.overallScore,
    required this.summary,
    required this.issues,
    this.keywordMatch,
    required this.fileName,
    required this.engine,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return AnalysisResult(
      mode: json['mode'] ?? 'global',
      overallScore: json['overallScore'] ?? 0,
      summary: json['summary'] ?? '',
      issues: (json['issues'] as List<dynamic>? ?? [])
          .map((item) => Issue.fromJson(item as Map<String, dynamic>))
          .toList(),
      keywordMatch: json['keywordMatch'] != null
          ? KeywordMatch.fromJson(json['keywordMatch'])
          : null,
      fileName: meta['fileName'] ?? 'CV.pdf',
      engine: meta['engine'] ?? 'gemini',
    );
  }
}

class ImprovedCvSection {
  final String heading;
  final List<String> bullets;

  ImprovedCvSection({required this.heading, required this.bullets});

  factory ImprovedCvSection.fromJson(Map<String, dynamic> json) {
    return ImprovedCvSection(
      heading: json['heading'] ?? '',
      bullets: List<String>.from(json['bullets'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {'heading': heading, 'bullets': bullets};
}

class ImprovedCV {
  final String name;
  final String title;
  final List<String> contact;
  final String summary;
  final List<ImprovedCvSection> sections;
  final List<String> changes;

  ImprovedCV({
    required this.name,
    required this.title,
    required this.contact,
    required this.summary,
    required this.sections,
    required this.changes,
  });

  factory ImprovedCV.fromJson(Map<String, dynamic> json) {
    return ImprovedCV(
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      contact: List<String>.from(json['contact'] ?? []),
      summary: json['summary'] ?? '',
      sections: (json['sections'] as List<dynamic>? ?? [])
          .map((s) => ImprovedCvSection.fromJson(s as Map<String, dynamic>))
          .toList(),
      changes: List<String>.from(json['changes'] ?? []),
    );
  }
}
```

---

## 7. Arsitektur Proyek Mobile: Flutter & Dart

### 7.1 Struktur Folder Flutter yang Direkomendasikan
```
lib/
├── main.dart
├── core/
│   ├── constants/            # Warna (#b5462f, #09090b), URL endpoint API
│   ├── network/              # Dio client / HTTP interceptors
│   └── storage/              # FlutterSecureStorage helper (token & access code)
├── models/
│   └── cv_analysis_model.dart # Definisi class data contract di atas
├── providers/ / blocs/       # State management (Riverpod / Bloc / Provider)
│   ├── upload_provider.dart
│   ├── analysis_provider.dart
│   └── rewrite_provider.dart
├── screens/
│   ├── home_screen.dart       # Layar uploader hero
│   ├── scanning_screen.dart   # Animasi progres scan
│   ├── results_screen.dart    # Dashboard hasil (cincin skor + daftar masalah)
│   └── rewrite_screen.dart    # Layar hasil perbaikan CV & ekspor
└── widgets/
    ├── score_ring_painter.dart # CustomPainter cincin skor melingkar
    ├── issue_card.dart         # Card isu (locked vs unlocked state)
    └── placeholder_text.dart   # RichText penyorot [kurung siku]
```

### 7.2 Dependensi Utama di `pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.7.0                     # HTTP client handal untuk file upload & stream
  file_picker: ^8.1.4             # Pemilih dokumen PDF dari iOS & Android
  flutter_secure_storage: ^9.2.2  # Penyimpanan lokal token & kunci terenkripsi
  flutter_riverpod: ^2.6.1        # State management modern & reactive
  share_plus: ^10.1.2             # Native share sheet untuk ekspor file
  path_provider: ^2.1.4           # Mengakses direktori sementara untuk unduhan file
  google_fonts: ^6.2.1            # Tipografi modern (Outfit, Inter, JetBrains Mono)
```

---

## 8. Arsitektur Proyek Backend: Node.js Express + MySQL

### 8.1 Struktur Folder Node.js Express
```
backend/
├── package.json
├── .env.example
├── server.js               # Entrypoint Express app
├── config/
│   ├── db.js               # MySQL2 Connection Pool
│   └── ai.js               # Inisialisasi Gemini (@google/genai) / Claude
├── middleware/
│   ├── upload.js           # Multer configuration (in-memory)
│   ├── rateLimiter.js      # Express-rate-limit per IP / deviceId
│   └── errorHandler.js     # Centralized error handler
├── routes/
│   ├── parseRoutes.js      # /api/parse
│   ├── analyzeRoutes.js    # /api/analyze
│   ├── unlockRoutes.js     # /api/unlock
│   └── rewriteRoutes.js    # /api/rewrite
├── services/
│   ├── pdfService.js       # Ekstraksi teks PDF via unpdf
│   ├── ruleBasedService.js # Heuristik gratis tanpa LLM
│   ├── aiAnalysisService.js# Prompt + schema analyzer
│   ├── aiRewriteService.js # Prompt rewrite CV
│   └── tokenService.js     # AES-256-GCM cipher/decipher
└── sql/
    └── schema.sql          # Skema database DDL MySQL di atas
```

### 8.2 Dependensi Utama Backend (`package.json`)
```json
{
  "name": "leveledup-backend",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "@google/genai": "^2.13.0",
    "cors": "^2.8.5",
    "dotenv": "^16.4.7",
    "express": "^4.21.2",
    "express-rate-limit": "^7.5.0",
    "helmet": "^8.0.0",
    "multer": "^1.4.5-lts.1",
    "mysql2": "^3.12.0",
    "unpdf": "^1.6.2",
    "zod": "^3.24.2"
  },
  "devDependencies": {
    "nodemon": "^3.1.9"
  }
}
```

---

## 9. Rencana Tahapan Rilis Mobile (Milestone Roadmap)

| Fase | Target | Fitur Utama |
| :--- | :--- | :--- |
| **Fase 1 (MVP)** | 2–3 Minggu | • Pemilih file PDF dengan `file_picker` di Flutter.<br>• Backend Node.js Express (`/api/parse` & `/api/analyze`).<br>• Database MySQL untuk mencatat `scans`, `scan_issues`, dan `access_codes`.<br>• CustomPainter Cincin Skor & Tampilan 5 Kategori.<br>• Sistem Buka Akses via Kode Akses manual (`/api/unlock`).<br>• Fitur Perbaiki CV Otomatis (`/api/rewrite`) + Salin Teks / Ekspor File via `share_plus`. |
| **Fase 2 (Monetisasi)** | 4 Minggu | • Integrasi Pembayaran Otomatis: Midtrans Snap / Xendit QRIS (khusus Indonesia) atau In-App Purchase Google Play & App Store.<br>• Callback webhook dari payment gateway ke Node.js untuk otomatisasi pembukaan akses di MySQL.<br>• Riwayat scan lokal di Flutter. |
| **Fase 3 (Penyempurnaan)** | 6 Minggu | • Job Description Matcher: Input teks lowongan kerja untuk mencocokkan kata kunci spesifik.<br>• Offline heuristic mode: Fallback ke rule-based lokal jika offline. |

---

## 10. Panduan Langkah Demi Langkah Memulai Repositori Baru

1. **Setup Database MySQL:**
   - Jalankan script DDL dari bagian 5.1 pada server MySQL lokal atau cloud (misal: AWS RDS, PlanetScale, DigitalOcean Managed Database, atau VPS cPanel).
2. **Setup Backend Node.js Express:**
   - Inisialisasi project `npm init -y` dan pasang dependensi dari bagian 8.2.
   - Konfigurasikan file `.env` dengan kredensial MySQL (`DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`), `GOOGLE_GENAI_API_KEY`, dan `UNLOCK_SECRET`.
   - Implementasikan 4 route utama sesuai kontrak di bagian 5.2.
3. **Setup Frontend Flutter:**
   - Jalankan `flutter create leveledup_mobile`.
   - Pasang package dari bagian 7.2 (`dio`, `file_picker`, `flutter_riverpod`, `flutter_secure_storage`, `share_plus`).
   - Salin class model Dart dari bagian 6 ke `lib/models/cv_analysis_model.dart`.
4. **Hubungkan Mobile ke Backend:**
   - Arahkan `dio.options.baseUrl` ke IP/domain server Express Anda (misal `http://10.0.2.2:5000` untuk emulator Android atau `https://api.leveledup.com` di produksi).
5. **Uji Validasi:**
   - Unggah contoh file PDF `contoh-cv.pdf`, periksa hasil parsing dan respon cincin skor, lalu uji buka akses menggunakan kode `LEVELEDUPVIP2026`.
