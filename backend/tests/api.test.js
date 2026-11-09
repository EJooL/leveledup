const http = require('http');
const app = require('../server');

const SAMPLE_PDF = `%PDF-1.4
1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj
2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj
3 0 obj << /Type /Page /Parent 2 0 R /Resources << /Font << /F1 4 0 R >> >> /MediaBox [0 0 612 792] /Contents 5 0 R >> endobj
4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj
5 0 obj << /Length 210 >> stream
BT
/F1 12 Tf
72 712 Td
(Budi Santoso - Backend Engineer. Email: budi@test.com. Phone: +62812345678. Professional experience in Node.js, Express, MySQL, Docker, and REST API development. Responsible for system monitoring.) Tj
ET
endstream
endobj
xref
0 6
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000224 00000 n 
0000000295 00000 n 
trailer << /Size 6 /Root 1 0 R >>
startxref
558
%%EOF`;

const SAMPLE_CV_TEXT = `
Budi Santoso
Software Engineer - Backend & Mobile
Email: budi.santoso@example.com | Phone: +62 812 3456 7890
TTL: Jakarta, 15 Juli 2000 (Usia: 25 Tahun)
Agama: Islam | Status: Belum Menikah
Foto: Pas foto 4x6 terlampir

Ringkasan:
Pekerja keras (hard-working team player) yang berdedikasi tinggi dan mampu bekerja di bawah tekanan (able to work under pressure).

Pengalaman Kerja:
PT Solusi Teknologi Indonesia (Jan 2023 - Sekarang)
Software Engineer
- Bertanggung jawab mengelola dan memelihara sistem database MySQL dan server Node.js Express.
- Bertanggung jawab melakukan integrasi API payment gateway.
- Membantu tim frontend dalam penyambungan endpoint REST API.

Pendidikan:
S1 Sistem Informasi - Universitas Indonesia (2018 - 2022)

Keahlian:
Node.js, Express, MySQL, JavaScript, Git, Docker, REST API
`;

async function makeRequest(port, path, method, headers, body) {
  return new Promise((resolve, reject) => {
    const req = http.request(
      {
        hostname: '127.0.0.1',
        port,
        path,
        method,
        headers,
      },
      (res) => {
        let data = '';
        res.on('data', (chunk) => {
          data += chunk;
        });
        res.on('end', () => {
          try {
            const parsed = JSON.parse(data);
            resolve({ status: res.statusCode, headers: res.headers, body: parsed });
          } catch {
            resolve({ status: res.statusCode, headers: res.headers, body: data });
          }
        });
      }
    );

    req.on('error', reject);

    if (body) {
      req.write(body);
    }
    req.end();
  });
}

async function runTests() {
  console.log('🧪 ===============================================');
  console.log('🧪 Starting LeveledUp Backend Automated Test Suite');
  console.log('🧪 ===============================================\n');

  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(5099, '127.0.0.1', resolve));
  const port = 5099;
  console.log(`🌐 Test server listening on http://127.0.0.1:${port}\n`);

  let passedCount = 0;
  let failedCount = 0;

  function assert(condition, message) {
    if (condition) {
      console.log(`  ✅ PASS: ${message}`);
      passedCount++;
    } else {
      console.error(`  ❌ FAIL: ${message}`);
      failedCount++;
    }
  }

  try {
    // -----------------------------------------------------------------
    // TEST 1: Health Check (GET /api/health)
    // -----------------------------------------------------------------
    console.log('🔹 Test 1: GET /api/health');
    const healthRes = await makeRequest(port, '/api/health', 'GET', {});
    assert(healthRes.status === 200, `Returns HTTP 200 (Got ${healthRes.status})`);
    assert(healthRes.body.status === 'ok', 'Status is "ok"');
    assert(healthRes.body.service.includes('LeveledUp'), 'Service name is present');
    assert(healthRes.body.defaultPromoCode === 'LEVELEDUPVIP2026', 'Default promo code configured');

    // -----------------------------------------------------------------
    // TEST 2: PDF Parsing (POST /api/parse)
    // -----------------------------------------------------------------
    console.log('\n🔹 Test 2: POST /api/parse');
    
    // 2a. Missing file
    const noFileRes = await makeRequest(
      port,
      '/api/parse',
      'POST',
      { 'Content-Type': 'multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW' },
      '------WebKitFormBoundary7MA4YWxkTrZu0gW--\r\n'
    );
    assert(noFileRes.status === 400, `Missing file returns HTTP 400 (Got ${noFileRes.status})`);
    assert(noFileRes.body.code === 'FILE_MISSING', 'Error code is FILE_MISSING');

    // 2b. Valid PDF upload via multipart
    const boundary = '----BoundaryTest7MA4YWxkTrZu0gW';
    const multipartBody = Buffer.concat([
      Buffer.from(`--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="sample_cv.pdf"\r\nContent-Type: application/pdf\r\n\r\n`),
      Buffer.from(SAMPLE_PDF),
      Buffer.from(`\r\n--${boundary}--\r\n`),
    ]);

    const parseRes = await makeRequest(
      port,
      '/api/parse',
      'POST',
      {
        'Content-Type': `multipart/form-data; boundary=${boundary}`,
        'Content-Length': multipartBody.length,
      },
      multipartBody
    );
    assert(parseRes.status === 200, `Valid PDF returns HTTP 200 (Got ${parseRes.status})`);
    assert(typeof parseRes.body.text === 'string' && parseRes.body.text.length > 50, 'Extracted text is non-empty string');
    assert(parseRes.body.numPages >= 1, `numPages is >= 1 (Got ${parseRes.body.numPages})`);
    assert(parseRes.body.fileName === 'sample_cv.pdf', 'fileName matches upload');

    // -----------------------------------------------------------------
    // TEST 3: ATS Analysis (POST /api/analyze)
    // -----------------------------------------------------------------
    console.log('\n🔹 Test 3: POST /api/analyze');

    // 3a. Short text rejection
    const shortTextRes = await makeRequest(
      port,
      '/api/analyze',
      'POST',
      { 'Content-Type': 'application/json' },
      JSON.stringify({ text: 'Too short text' })
    );
    assert(shortTextRes.status === 400, `Short text returns HTTP 400 (Got ${shortTextRes.status})`);
    assert(shortTextRes.body.code === 'TEXT_TOO_SHORT', 'Error code is TEXT_TOO_SHORT');

    // 3b. Full CV analysis
    const analyzeBody = JSON.stringify({
      text: SAMPLE_CV_TEXT,
      fileName: 'Resume_Budi.pdf',
      deviceId: 'device-test-uuid-1234',
    });
    const analyzeRes = await makeRequest(
      port,
      '/api/analyze',
      'POST',
      { 'Content-Type': 'application/json' },
      analyzeBody
    );
    assert(analyzeRes.status === 200, `Valid analysis returns HTTP 200 (Got ${analyzeRes.status})`);
    assert(typeof analyzeRes.body.scanToken === 'string' && analyzeRes.body.scanToken.startsWith('scn_'), 'scanToken generated properly');
    assert(typeof analyzeRes.body.token === 'string' && analyzeRes.body.token.length > 20, 'Encrypted AES-256 token generated');
    
    const result = analyzeRes.body.result;
    assert(typeof result.overallScore === 'number', `Overall score is number (${result.overallScore})`);
    assert(result.overallScore <= 60, 'Indonesian bias habits penalized accurately (score <= 60)');
    assert(Array.isArray(result.issues) && result.issues.length >= 3, `Issues found: ${result.issues.length}`);

    // Gating check: Ensure FREE tier does NOT leak paid fields
    const hasLeakedDetail = result.issues.some((i) => i.detail !== undefined || i.fix !== undefined || i.rewrite !== undefined);
    assert(!hasLeakedDetail, 'Free preview correctly gates detail, fix, and rewrite');
    assert(result.keywordMatch && result.keywordMatch.missing === undefined, 'Free preview correctly gates missing keywords list');
    assert(typeof result.keywordMatch.missingCount === 'number', 'Free preview includes missingCount');

    // -----------------------------------------------------------------
    // TEST 4: Unlock Premium Content (POST /api/unlock)
    // -----------------------------------------------------------------
    console.log('\n🔹 Test 4: POST /api/unlock');

    // 4a. Invalid access code
    const invalidUnlockRes = await makeRequest(
      port,
      '/api/unlock',
      'POST',
      { 'Content-Type': 'application/json' },
      JSON.stringify({
        scanToken: analyzeRes.body.scanToken,
        token: analyzeRes.body.token,
        code: 'WRONGCODE999',
      })
    );
    assert(invalidUnlockRes.status === 402, `Invalid access code returns HTTP 402 (Got ${invalidUnlockRes.status})`);

    // 4b. Valid access code (LEVELEDUPVIP2026)
    const validUnlockRes = await makeRequest(
      port,
      '/api/unlock',
      'POST',
      { 'Content-Type': 'application/json' },
      JSON.stringify({
        scanToken: analyzeRes.body.scanToken,
        token: analyzeRes.body.token,
        code: 'LEVELEDUPVIP2026',
      })
    );
    assert(validUnlockRes.status === 200, `Valid access code returns HTTP 200 (Got ${validUnlockRes.status})`);
    const unlocked = validUnlockRes.body;
    assert(Array.isArray(unlocked.issues) && unlocked.issues.length > 0, 'Unlocked issues list returned');
    assert(unlocked.issues.some((i) => typeof i.detail === 'string' && i.detail.length > 0), 'Unlocked issues contain full detail explanations');
    assert(unlocked.issues.some((i) => typeof i.fix === 'string' && i.fix.length > 0), 'Unlocked issues contain concrete fixes');
    assert(unlocked.issues.some((i) => i.rewrite && i.rewrite.before && i.rewrite.after), 'Unlocked issues contain Before vs After rewrites');
    assert(Array.isArray(unlocked.keywordMatch.missing), 'Unlocked keywordMatch contains full missing keywords list');

    // -----------------------------------------------------------------
    // TEST 5: AI Resume Rewrite (POST /api/rewrite)
    // -----------------------------------------------------------------
    console.log('\n🔹 Test 5: POST /api/rewrite');

    // 5a. Unauthorized request (no code)
    const unauthRewriteRes = await makeRequest(
      port,
      '/api/rewrite',
      'POST',
      { 'Content-Type': 'application/json' },
      JSON.stringify({
        scanToken: 'scn_unauthorized',
        text: SAMPLE_CV_TEXT,
      })
    );
    assert(unauthRewriteRes.status === 402, `Unauthorized rewrite returns HTTP 402 (Got ${unauthRewriteRes.status})`);

    // 5b. Authorized rewrite with VIP code
    const authRewriteRes = await makeRequest(
      port,
      '/api/rewrite',
      'POST',
      { 'Content-Type': 'application/json' },
      JSON.stringify({
        scanToken: analyzeRes.body.scanToken,
        text: SAMPLE_CV_TEXT,
        code: 'LEVELEDUPVIP2026',
      })
    );
    assert(authRewriteRes.status === 200, `Authorized rewrite returns HTTP 200 (Got ${authRewriteRes.status})`);
    assert(authRewriteRes.body.cv && typeof authRewriteRes.body.cv.name === 'string', 'Rewritten CV contains applicant name');
    assert(Array.isArray(authRewriteRes.body.cv.contact), 'Rewritten CV contains cleaned contact lines');
    assert(Array.isArray(authRewriteRes.body.cv.sections) && authRewriteRes.body.cv.sections.length >= 2, 'Rewritten CV contains professional sections');
    assert(Array.isArray(authRewriteRes.body.cv.changes), 'Rewritten CV contains changes documentation');
    
    // Check Anti-Fabrication compliance: ensure square bracket placeholders exist
    const bulletsText = JSON.stringify(authRewriteRes.body.cv.sections);
    const hasPlaceholders = bulletsText.includes('[') && bulletsText.includes(']');
    assert(hasPlaceholders, 'Anti-Fabrication / Zero-Hallucination placeholders [placeholder] correctly applied');

  } finally {
    server.close();
  }

  console.log('\n📊 ===============================================');
  console.log(`📊 Test Results: ${passedCount} PASSED, ${failedCount} FAILED`);
  console.log('📊 ===============================================\n');

  if (failedCount > 0) {
    process.exit(1);
  }
}

runTests().catch((err) => {
  console.error('Fatal test error:', err);
  process.exit(1);
});

