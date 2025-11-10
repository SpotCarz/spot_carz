const express = require('express');
const multer = require('multer');
const { verifyImage } = require('../services/verificationService');
const { saveVerificationResult } = require('../services/firestoreService');

const router = express.Router();

// Configure multer for file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    // Accept only image files
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  },
});

/**
 * POST /api/verifyImage
 * 
 * Verifies image authenticity by:
 * 1. Extracting EXIF metadata
 * 2. Performing reverse image search
 * 3. Detecting AI generation
 * 4. Calculating verification score
 */
router.post('/verifyImage', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file provided' });
    }

    const userId = req.body.userId;
    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }

    console.log(`🔍 Starting verification for user: ${userId}`);

    // Perform verification
    const verificationResult = await verifyImage({
      imageBuffer: req.file.buffer,
      imageName: req.file.originalname,
      userId: userId,
    });

    // Save to Firestore
    try {
      await saveVerificationResult(verificationResult);
    } catch (dbError) {
      console.error('Failed to save to database:', dbError);
      // Continue even if database save fails
    }

    res.json(verificationResult);
  } catch (error) {
    console.error('Verification error:', error);
    res.status(500).json({
      error: 'Verification failed',
      message: error.message,
    });
  }
});

/**
 * GET /api/verificationHistory
 * 
 * Retrieves verification history for a user
 */
router.get('/verificationHistory', async (req, res) => {
  try {
    const userId = req.query.userId;
    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }

    const { getVerificationHistory } = require('../services/firestoreService');
    const history = await getVerificationHistory(userId);
    res.json(history);
  } catch (error) {
    console.error('Failed to fetch verification history:', error);
    res.status(500).json({
      error: 'Failed to fetch verification history',
      message: error.message,
    });
  }
});

module.exports = router;

