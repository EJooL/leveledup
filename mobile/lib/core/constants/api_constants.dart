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
  static const String winsEndpoint = '/api/wins';
  static const String mergeWinsCvEndpoint = '/api/wins/merge-cv';
  static const String progressEndpoint = '/api/progress';
  static const String questToggleEndpoint = '/api/progress/quest-toggle';
  static const String careerModeEndpoint = '/api/progress/mode';
  static const String healthEndpoint = '/api/health';

  static const String defaultVipCode = 'LEVELEDUPVIP2026';

  /// Feature flag: hides Daily Check-In from UI without deleting code or data
  static const bool enableDailyCheckIn = false;

  /// Sample Bahasa Indonesia CV for instant testing
  static const String sampleCvTextId = '''
Budi Santoso
Software Engineer - Backend & Mobile
Email: budi.santoso@example.com | Phone: +62 812 3456 7890
TTL: Jakarta, 15 Juli 2001 (Usia: 24 Tahun)
Agama: Islam | Status: Belum Menikah
NIK: 3174051507010002
Foto: Pas foto 4x6 terlampir

Ringkasan:
Pekerja keras yang berdedikasi tinggi dan mampu bekerja di bawah tekanan.

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

  /// Sample English CV for instant testing
  static const String sampleCvTextEn = '''
Budi Santoso
Software Engineer - Backend & Mobile
Email: budi.santoso@example.com | Phone: +62 812 3456 7890
Date of Birth: July 15, 2001 (Age: 24)
Marital Status: Single | Religion: Islam
Photo: Headshot attached

Summary:
A hard-working team player able to work under pressure and handle multiple tasks.

Experience:
Nusantara Tech Solutions (Jan 2023 - Present)
Backend & Mobile Developer
- Responsible for managing and maintaining the company MySQL database and Node.js Express servers.
- Responsible for integrating payment gateway APIs and user authentication.
- Assisted the mobile team in developing cross-platform Flutter applications.

Education:
B.S. in Computer Science - Universitas Indonesia (2019 - 2023)

Skills:
Node.js, Express, MySQL, Flutter, Dart, Git, REST API
Hobbies: Reading, Traveling, Gaming
''';

  static const String sampleCvText = sampleCvTextId;
}
