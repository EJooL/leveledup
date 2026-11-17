const { extractText, extractImages } = require('unpdf');

/**
 * Extracts text, page count, and checks whether a headshot/photo image is embedded on page 1
 * @param {Buffer} buffer - In-memory PDF buffer from multer
 * @param {string} fileName - Original uploaded file name
 * @returns {Promise<{ fileName: string, numPages: number, numChars: number, hasPhoto: boolean, text: string }>}
 */
async function parsePdfBuffer(buffer, fileName = 'resume.pdf') {
  if (!buffer || buffer.length === 0) {
    const error = new Error('File tidak dikirim atau dokumen kosong.');
    error.status = 400;
    throw error;
  }

  try {
    const uint8 = new Uint8Array(buffer);
    const result = await extractText(uint8, { mergePages: true });

    const numPages = result.totalPages || 1;
    const rawText =
      typeof result.text === 'string'
        ? result.text
        : (result.text || []).join('\n\n');
    const cleanedText = rawText.replace(/\r\n/g, '\n').trim();
    const numChars = cleanedText.length;

    if (numChars < 80) {
      const error = new Error(
        'PDF tidak dapat dibaca atau berbasis scan gambar (< 80 karakter teks). Silakan unggah PDF berbasis teks asli.'
      );
      error.status = 422;
      throw error;
    }

    // Check if Page 1 actually embeds a portrait/headshot raster image (60px..900px)
    let hasPhoto = false;
    try {
      const imagesOnPage1 = await extractImages(new Uint8Array(buffer), 1);
      if (Array.isArray(imagesOnPage1) && imagesOnPage1.length > 0) {
        hasPhoto = imagesOnPage1.some((img) => {
          const w = img.width || 0;
          const h = img.height || 0;
          const ratio = h > 0 ? w / h : 0;
          // Portrait or square-ish photo dimensions (exclude tiny icons <55px and full-page banners)
          return w >= 60 && h >= 60 && w <= 900 && h <= 900 && ratio >= 0.5 && ratio <= 1.5;
        });
      }
    } catch {
      hasPhoto = false;
    }

    return {
      fileName,
      numPages,
      numChars,
      hasPhoto,
      text: cleanedText,
    };
  } catch (err) {
    if (err.status) throw err;
    console.error('[PdfService] Error parsing PDF:', err);
    const error = new Error(`Gagal membaca file PDF: ${err.message}`);
    error.status = 422;
    throw error;
  }
}

module.exports = {
  parsePdfBuffer,
};
