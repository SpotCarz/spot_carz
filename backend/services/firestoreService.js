const admin = require('firebase-admin');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  try {
    const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;
    
    if (serviceAccount) {
      // Parse service account from environment variable (JSON string)
      const serviceAccountJson = JSON.parse(serviceAccount);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccountJson),
      });
    } else {
      // Try to use default credentials (for Firebase hosting/Cloud Functions)
      admin.initializeApp();
    }
  } catch (error) {
    console.warn('⚠️  Firebase Admin not initialized:', error.message);
    console.warn('Verification results will not be saved to Firestore');
  }
}

const db = admin.firestore();
const COLLECTION_NAME = 'image_verifications';

/**
 * Saves verification result to Firestore
 * @param {Object} verificationResult - Verification result object
 */
async function saveVerificationResult(verificationResult) {
  try {
    if (!admin.apps.length) {
      console.warn('Firebase not initialized, skipping database save');
      return;
    }

    const docRef = db.collection(COLLECTION_NAME).doc();
    
    await docRef.set({
      ...verificationResult,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ Verification result saved to Firestore: ${docRef.id}`);
    return docRef.id;
  } catch (error) {
    console.error('Failed to save verification result:', error);
    throw error;
  }
}

/**
 * Retrieves verification history for a user
 * @param {String} userId - User ID
 * @param {Number} limit - Maximum number of results (default: 50)
 */
async function getVerificationHistory(userId, limit = 50) {
  try {
    if (!admin.apps.length) {
      console.warn('Firebase not initialized, returning empty history');
      return [];
    }

    const snapshot = await db
      .collection(COLLECTION_NAME)
      .where('userId', '==', userId)
      .orderBy('timestamp', 'desc')
      .limit(limit)
      .get();

    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));
  } catch (error) {
    console.error('Failed to fetch verification history:', error);
    throw error;
  }
}

module.exports = {
  saveVerificationResult,
  getVerificationHistory,
};

