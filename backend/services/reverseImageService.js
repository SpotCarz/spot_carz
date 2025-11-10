const axios = require('axios');
const FormData = require('form-data');

/**
 * Performs reverse image search using TinEye API
 * @param {Buffer} imageBuffer - Image file buffer
 * @returns {Object} Match confidence and results
 */
async function performReverseImageSearch(imageBuffer) {
  const apiKey = process.env.TINEYE_API_KEY;
  const apiSecret = process.env.TINEYE_API_SECRET;

  if (!apiKey || !apiSecret) {
    console.warn('⚠️  TinEye API credentials not configured, skipping reverse image search');
    return {
      confidence: 0.5, // Neutral confidence when service unavailable
      matches: 0,
      error: 'API credentials not configured',
    };
  }

  try {
    // Convert buffer to base64
    const base64Image = imageBuffer.toString('base64');

    // TinEye API endpoint
    const url = 'https://api.tineye.com/rest/search/';

    const formData = new FormData();
    formData.append('image', imageBuffer, {
      filename: 'image.jpg',
      contentType: 'image/jpeg',
    });

    const response = await axios.post(url, formData, {
      auth: {
        username: apiKey,
        password: apiSecret,
      },
      headers: formData.getHeaders(),
      timeout: 10000, // 10 second timeout
    });

    const results = response.data.results || [];
    const matchCount = results.length;

    // Calculate confidence: fewer matches = higher confidence (more authentic)
    // 0 matches = 1.0 confidence (very authentic)
    // 10+ matches = 0.0 confidence (likely fake)
    const confidence = Math.max(0, 1 - (matchCount / 10));

    return {
      confidence: confidence,
      matches: matchCount,
      results: results.slice(0, 5), // Return top 5 matches
    };
  } catch (error) {
    console.error('Reverse image search error:', error.message);
    
    // Fallback: return neutral confidence
    return {
      confidence: 0.5,
      matches: 0,
      error: error.message,
    };
  }
}

/**
 * Alternative: Google Custom Search API for reverse image search
 * (Fallback if TinEye is not available)
 */
async function performGoogleReverseSearch(imageBuffer) {
  const apiKey = process.env.GOOGLE_API_KEY;
  const searchEngineId = process.env.GOOGLE_SEARCH_ENGINE_ID;

  if (!apiKey || !searchEngineId) {
    return null;
  }

  try {
    // Convert to base64
    const base64Image = imageBuffer.toString('base64');

    // Google Custom Search API with image
    const url = `https://www.googleapis.com/customsearch/v1?key=${apiKey}&cx=${searchEngineId}&searchType=image&imgSize=large`;

    // Note: Google Custom Search doesn't directly support image upload
    // This would require using Google Vision API or similar
    // For now, return null to use TinEye as primary method
    
    return null;
  } catch (error) {
    console.error('Google reverse search error:', error.message);
    return null;
  }
}

module.exports = {
  performReverseImageSearch,
  performGoogleReverseSearch,
};

