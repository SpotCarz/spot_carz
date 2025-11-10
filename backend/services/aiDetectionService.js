const axios = require('axios');
const FormData = require('form-data');

/**
 * Detects if image is AI-generated using Hive Moderation API
 * @param {Buffer} imageBuffer - Image file buffer
 * @returns {Object} AI generation probability and details
 */
async function detectAIGeneration(imageBuffer) {
  const apiKey = process.env.HIVE_API_KEY;

  if (!apiKey) {
    console.warn('⚠️  Hive API key not configured, using fallback detection');
    return await fallbackAIDetection(imageBuffer);
  }

  try {
    const formData = new FormData();
    formData.append('image', imageBuffer, {
      filename: 'image.jpg',
      contentType: 'image/jpeg',
    });

    const response = await axios.post(
      'https://api.thehive.ai/api/v2/task/sync',
      formData,
      {
        headers: {
          ...formData.getHeaders(),
          'Authorization': `Token ${apiKey}`,
        },
        timeout: 15000, // 15 second timeout
      }
    );

    const data = response.data;
    
    // Hive API returns various detection results
    // Look for AI generation indicators
    let aiProbability = 0.5; // Default neutral
    
    if (data.status?.output) {
      const output = data.status.output;
      
      // Check for AI generation indicators
      // Hive API structure may vary, adjust based on actual response
      if (output.generated || output.ai_generated) {
        aiProbability = 0.8; // High probability of AI generation
      } else if (output.authentic || output.real) {
        aiProbability = 0.2; // Low probability (likely real)
      }
    }

    return {
      probability: aiProbability,
      source: 'hive',
      details: data,
    };
  } catch (error) {
    console.error('Hive AI detection error:', error.message);
    return await fallbackAIDetection(imageBuffer);
  }
}

/**
 * Fallback AI detection using basic heuristics
 * @param {Buffer} imageBuffer - Image file buffer
 * @returns {Object} Basic AI generation probability
 */
async function fallbackAIDetection(imageBuffer) {
  // Basic heuristics:
  // 1. Check image size (AI images often have specific dimensions)
  // 2. Check for common AI artifacts (this is simplified)
  
  // For now, return neutral probability
  // In production, you could add more sophisticated heuristics
  
  return {
    probability: 0.5, // Neutral - requires manual review
    source: 'fallback',
    details: {
      message: 'Using fallback detection - manual review recommended',
    },
  };
}

/**
 * Alternative: IsItAI API (if available)
 */
async function detectWithIsItAI(imageBuffer) {
  const apiKey = process.env.ISITAI_API_KEY;

  if (!apiKey) {
    return null;
  }

  try {
    const base64Image = imageBuffer.toString('base64');
    
    const response = await axios.post(
      'https://api.isitai.com/v1/detect',
      {
        image: base64Image,
      },
      {
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        timeout: 15000,
      }
    );

    return {
      probability: response.data.ai_probability || 0.5,
      source: 'isitai',
      details: response.data,
    };
  } catch (error) {
    console.error('IsItAI detection error:', error.message);
    return null;
  }
}

module.exports = {
  detectAIGeneration,
  detectWithIsItAI,
  fallbackAIDetection,
};

