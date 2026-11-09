import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  /// Automatically selects localhost for Web/Desktop/iOS and 10.0.2.2 for Android Emulator
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }

  static const String parseEndpoint = '/api/parse';
  static const String analyzeEndpoint = '/api/analyze';
  static const String unlockEndpoint = '/api/unlock';
  static const String rewriteEndpoint = '/api/rewrite';
  static const String healthEndpoint = '/api/health';

  static const String defaultVipCode = 'LEVELEDUPVIP2026';

  /// Built-in sample CV text for instant 1-tap demo testing on emulator/desktop
  static const String sampleCvText = '''
Budi Santoso
Software Engineer - Backend & Mobile
Email: budi.santoso@example.com | Phone: +62 812 3456 7890
TTL: Jakarta, 15 Juli 2001 (Usia: 24 Tahun)
Agama: Islam | Status: Belum Menikah
NIK: 3174051507010002
Foto: Pas foto 4x6 terlampir

Ringkasan:
Pekerja keras (hard-working team player) yang berdedikasi tinggi dan mampu bekerja di bawah tekanan (able to work under pressure).

Pengalaman Kerja:
PT Solusi Teknologi Nusantara (Jan 2023 - Sekarang)
Backend & Mobile Developer
- Bertanggung jawab mengelola dan memelihara sistem database MySQL dan server Node.js Express.
- Bertanggung jawab melakukan integrasi API payment gateway dan autentikasi.
- Membantu tim mobile dalam pembuatan aplikasi Flutter.

Pendidikan:
S1 Teknik Informatika - Universitas Indonesia (2019 - 2023)

Keahlian:
Node.js, Express, MySQL, Flutter, Dart, Git, REST API
Hobi: Membaca, Traveling, Bermain Game
''';
}

