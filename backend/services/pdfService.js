const { extractText } = require('unpdf');

/**
 * Extracts text and metadata from a PDF buffer using unpdf
 * @param {Buffer} buffer - In-memory PDF buffer from multer
 * @param {string} fileName - Original uploaded file name
 * @returns {Promise<{ fileName: string, numPages: number, numChars: number, text: string }>}
 */
async function parsePdfBuffer(buffer, fileName = 'resume.pdf') {
  if (!buffer || buffer.length === 0) {
    const error = new Error('File tidak dikirim atau dokumen kosong.');
    error.status = 400;
    throw error;
  }

  try {
    const result = await extractText(new Uint8Array(buffer), { mergePages: true });
    
    const numPages = result.totalPages || 1;
    const rawText = typeof result.text === 'string' ? result.text : (result.text || []).join('\n\n');
    const cleanedText = rawText.replace(/\r\n/g, '\n').trim();
    const numChars = cleanedText.length;

    // Check if PDF has enough readable text (< 80 chars indicates scanned image or unparseable)
    if (numChars < 80) {
      const error = new Error('PDF tidak dapat dibaca atau berbasis scan gambar (< 80 karakter teks). Silakan unggah PDF berbasis teks asli.');
      error.status = 422;
      throw error;
    }

    return {
      fileName,
      numPages,
      numChars,
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
