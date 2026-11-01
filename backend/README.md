# LeveledUp Backend API (Express.js + MySQL)

Dokumentasi implementasi backend REST API untuk aplikasi mobile **LeveledUp** (ATS CV Scanner & Optimizer) sesuai spesifikasi dokumen [mvp.md](../mvp.md).

---

## 📁 Struktur Direktori Backend

```
backend/
├── .env                  # Konfigurasi environment lokal (XAMPP / DB / Port)
├── .env.example          # Template konfigurasi environment
├── package.json          # Dependensi & script eksekusi
├── server.js             # Entrypoint Express.js server
├── config/
│   ├── db.js             # MySQL connection pool (mysql2/promise)
│   └── ai.js             # Inisialisasi Google GenAI SDK (Gemini)
├── middleware/
│   ├── upload.js         # Multer in-memory storage (maksimal 4 MB, khusus .pdf)
│   ├── rateLimiter.js    # Rate limiting berbasis IP & x-device-id
│   └── errorHandler.js   # Centralized error handler
├── routes/
│   ├── parseRoutes.js    # POST /api/parse
│   ├── analyzeRoutes.js  # POST /api/analyze
│   ├── unlockRoutes.js   # POST /api/unlock
│   └── rewriteRoutes.js  # POST /api/rewrite
├── services/
│   ├── pdfService.js     # Ekstraksi teks & metadata PDF via unpdf
│   ├── ruleBasedService.js # Heuristik 5 pilar ATS & sistem penalti skor
│   ├── aiAnalysisService.js# Prompt analisis ATS (Gemini / fallback otomatis)
│   ├── aiRewriteService.js # Prompt perbaikan CV anti-fabrikasi (STAR method)
│   └── tokenService.js   # Enkripsi & dekripsi segel token AES-256-GCM
├── sql/
│   ├── schema.sql        # Skema DDL MySQL lengkap (5 tabel + seed kode promo)
│   └── initDb.js         # Script otomatis inisialisasi & sinkronisasi database
└── tests/
    └── api.test.js       # Automated test suite (35 assertions mencakup semua endpoint)
```

---

## 🗄️ Panduan Database MySQL (XAMPP & phpMyAdmin)

Database disesuaikan dengan konfigurasi standar XAMPP:
- **Host:** `localhost`
- **Port:** `3306`
- **User:** `root`
- **Password:** *(kosong)*
- **Nama Database:** `leveledup_db`

### Cara 1: Menggunakan phpMyAdmin (UI)
1. Buka **XAMPP Control Panel** dan klik **Start** pada modul **Apache** dan **MySQL**.
2. Buka browser dan kunjungi: **`http://localhost/phpmyadmin`**
3. Klik tab **Import** pada menu atas.
4. Pilih file: `backend/sql/schema.sql` lalu klik tombol **Import** di bawah.
5. Database `leveledup_db` beserta 5 tabel (`scans`, `scan_issues`, `scan_keywords`, `scan_rewrites`, `access_codes`) dan kode promo `LEVELEDUPVIP2026` akan langsung aktif.

> ⚠️ **Catatan Bentrokan Port 3306 di Windows:**  
> Jika modul MySQL di XAMPP gagal start karena port 3306 sedang digunakan oleh Windows service bawaan (`MySQL80`), Anda dapat mematikan service tersebut melalui PowerShell:
> ```powershell
> Stop-Service -Name MySQL80
> ```
> Lalu klik **Start** kembali pada MySQL di XAMPP Control Panel.

### Cara 2: Script Otomatis
Setelah XAMPP MySQL berjalan:
```bash
cd backend
npm run init-db
```

---

## 🚀 Menjalankan Server Backend

### 1. Install Dependensi (Sudah selesai)
```bash
cd backend
npm install
```

### 2. Jalankan Automated Test Suite
```bash
npm test
```
*Akan menjalankan 35 assertions untuk menguji seluruh rute, validasi ukuran file, pembatasan free-tier, unlock kode akses, dan aturan zero-hallucination rewrite.*

### 3. Jalankan Server Development
```bash
npm run dev
```
Server akan berjalan di: **`http://localhost:5000`**  
Endpoint Health Check: **`http://localhost:5000/api/health`**

---

## 🔌 Spesifikasi Endpoint REST API

### 1. `POST /api/parse`
Menerima berkas PDF dari Flutter mobile (maks. 4MB) dan mengekstrak teks.
- **Header:** `Content-Type: multipart/form-data`
- **Form Key:** `file` (File PDF)
- **Response (200 OK):**
```json
{
  "fileName": "Resume_Budi.pdf",
  "numPages": 2,
  "numChars": 4512,
  "text": "Budi Santoso\nSoftware Engineer..."
}
```

### 2. `POST /api/analyze`
Menganalisis teks CV berdasarkan 5 pilar ATS global (Anti-Bias, Keterbacaan ATS, Kecocokan Kata Kunci, Pencapaian Terukur, Kualitas Bahasa Inggris).
- **Header:** `Content-Type: application/json`
- **Body:**
```json
{
  "text": "Budi Santoso...",
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
    "summary": "CV Anda memiliki struktur dasar yang baik...",
    "issues": [
      {
        "id": "photo",
        "category": "personal_info",
        "severity": "critical",
        "title": "CV menyertakan foto diri atau penanda foto"
      }
    ],
    "keywordMatch": {
      "jobTitle": "Backend Engineer",
      "matched": ["Node.js", "MySQL", "Docker"],
      "missingCount": 4
    },
    "meta": {
      "fileName": "Resume_Budi.pdf",
      "analyzedAtLabel": "Dianalisis Sistem (Aturan ATS Global)",
      "engine": "rule-based"
    }
  },
  "token": "dGhpcy1pcy1hbi1hZXMtZ2NtLWVuY3J5cHRlZC10b2tlbg..."
}
```

### 3. `POST /api/unlock`
Membuka rincian berbayar (penjelasan detail masalah, langkah solusi, contoh Before vs After, dan daftar kata kunci yang hilang).
- **Header:** `Content-Type: application/json`
- **Body:**
```json
{
  "scanToken": "scn_9f8e7d6c5b4a",
  "token": "dGhpcy1pcy1hbi1hZXMtZ2NtLWVuY3J5cHRlZC10b2tlbg...",
  "code": "LEVELEDUPVIP2026"
}
```
- **Response (200 OK):** Mengembalikan objek `AnalysisResult` lengkap tanpa data yang digembok.

### 4. `POST /api/rewrite`
Menulis ulang CV ke dalam format teks ramah ATS berbahasa Inggris dengan prinsip **Anti-Fabrikasi / Zero-Hallucination** (menggunakan penanda kurung siku `[placeholder]` pada metrik yang belum ada).
- **Header:** `Content-Type: application/json`
- **Body:**
```json
{
  "scanToken": "scn_9f8e7d6c5b4a",
  "text": "Budi Santoso...",
  "code": "LEVELEDUPVIP2026",
  "fileName": "Resume_Budi.pdf"
}
```
- **Response (200 OK):**
```json
{
  "cv": {
    "name": "Budi Santoso",
    "title": "Backend Engineer",
    "contact": ["budi.santoso@example.com", "+62 812 3456 7890", "..."],
    "summary": "...",
    "sections": [
      {
        "heading": "Professional Experience",
        "bullets": [
          "Optimized MySQL database query performance, slashing latency by [X]% for [team size] engineers."
        ]
      }
    ],
    "changes": [
      "Menghapus pas foto, status pernikahan, dan tanggal lahir...",
      "Mengonversi kalimat pasif menjadi pencapaian berbasis aksi (STAR method)...",
      "Menambahkan penanda [placeholder] pada metrik persentase..."
    ]
  }
}
```

---

## 🔑 Konfigurasi AI Gemini (Opsional)
Jika Anda memiliki API Key dari Google AI Studio:
1. Buka file `backend/.env`.
2. Isi variabel `GEMINI_API_KEY`:
   ```env
   GEMINI_API_KEY=AIzaSy...
   ```
3. Jika dibiarkan kosong, backend akan secara otomatis beralih ke **Rule-Based Heuristic ATS Engine** tanpa error sedikitpun.
