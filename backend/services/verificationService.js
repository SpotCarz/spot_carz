const { extractExifMetadata } = require('./exifService');
const { performReverseImageSearch } = require('./reverseImageService');
const { detectAIGeneration } = require('./aiDetectionService');

/**
 * Main verification service that combines all checks
 * @param {Object} params - Verification parameters
 * @param {Buffer} params.imageBuffer - Image file buffer
 * @param {String} params.imageName - Original image filename
 * @param {String} params.userId - User ID
 * @returns {Object} Complete verification result
 */
async function verifyImage({ imageBuffer, imageName, userId }) {
  console.log('🔍 Starting image verification...');

  // Initialize result object
  let exifResult = null;
  let reverseSearchResult = null;
  let aiDetectionResult = null;

  // Step 1: Extract EXIF metadata
  console.log('📸 Extracting EXIF metadata...');
  try {
    exifResult = extractExifMetadata(imageBuffer);
  } catch (error) {
    console.error('EXIF extraction failed:', error);
    exifResult = {
      hasMetadata: false,
      metadata: {},
      status: 'missing',
      error: error.message,
    };
  }

  // Step 2: Perform reverse image search
  console.log('🔎 Performing reverse image search...');
  try {
    reverseSearchResult = await performReverseImageSearch(imageBuffer);
  } catch (error) {
    console.error('Reverse image search failed:', error);
    reverseSearchResult = {
      confidence: 0.5,
      matches: 0,
      error: error.message,
    };
  }

  // Step 3: Detect AI generation
  console.log('🤖 Detecting AI generation...');
  try {
    aiDetectionResult = await detectAIGeneration(imageBuffer);
  } catch (error) {
    console.error('AI detection failed:', error);
    aiDetectionResult = {
      probability: 0.5,
      source: 'error',
      error: error.message,
    };
  }

  // Step 4: Calculate verification score
  const verificationScore = calculateVerificationScore({
    exifResult,
    reverseSearchResult,
    aiDetectionResult,
  });

  // Step 5: Determine status
  const status = getVerificationStatus(verificationScore);

  // Step 6: Map metadata status
  const metadataStatus = exifResult?.status || 'missing';

  // Construct result
  const result = {
    imageUrl: `uploaded/${userId}/${Date.now()}_${imageName}`, // Placeholder URL
    userId: userId,
    verificationScore: verificationScore,
    status: status,
    aiGeneratedProbability: aiDetectionResult?.probability || 0.5,
    reverseImageMatchConfidence: reverseSearchResult?.confidence || 0.5,
    metadataStatus: metadataStatus,
    timestamp: new Date().toISOString(),
    metadata: exifResult?.metadata || {},
    errorMessage: null,
  };

  // Add error message if any critical service failed
  const errors = [];
  if (exifResult?.error) errors.push(`EXIF: ${exifResult.error}`);
  if (reverseSearchResult?.error) errors.push(`Reverse search: ${reverseSearchResult.error}`);
  if (aiDetectionResult?.error) errors.push(`AI detection: ${aiDetectionResult.error}`);

  if (errors.length > 0) {
    result.errorMessage = errors.join('; ');
  }

  console.log(`✅ Verification complete. Score: ${verificationScore}, Status: ${status}`);
  
  return result;
}

/**
 * Calculates verification score (0-100) based on all checks
 */
function calculateVerificationScore({ exifResult, reverseSearchResult, aiDetectionResult }) {
  let score = 50; // Start with neutral score

  // EXIF Metadata contribution (0-30 points)
  if (exifResult?.status === 'complete') {
    score += 30; // Full metadata = +30
  } else if (exifResult?.status === 'partial') {
    score += 15; // Partial metadata = +15
  } else {
    score -= 10; // No metadata = -10 (suspicious)
  }

  // Reverse image search contribution (0-30 points)
  const reverseConfidence = reverseSearchResult?.confidence || 0.5;
  score += (reverseConfidence - 0.5) * 30; // Scale to ±15 points

  // AI detection contribution (0-40 points)
  const aiProbability = aiDetectionResult?.probability || 0.5;
  // Lower AI probability = higher score
  score += (1 - aiProbability - 0.5) * 40; // Scale to ±20 points

  // Clamp score between 0 and 100
  score = Math.max(0, Math.min(100, Math.round(score)));

  return score;
}

/**
 * Determines verification status based on score
 */
function getVerificationStatus(score) {
  if (score > 80) {
    return 'authentic';
  } else if (score >= 50) {
    return 'suspicious';
  } else {
    return 'likelyFake';
  }
}

module.exports = {
  verifyImage,
  calculateVerificationScore,
  getVerificationStatus,
};

