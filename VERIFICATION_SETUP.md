# Image Authenticity Verification System - Setup Guide

This guide will help you set up the image authenticity verification system for SpotCarz.

## Overview

The verification system performs three main checks:
1. **EXIF Metadata Extraction** - Checks for camera info, GPS, timestamps
2. **Reverse Image Search** - Checks if image exists on the internet
3. **AI Generation Detection** - Detects if image is AI-generated

## Architecture

```
Flutter App
    ↓ (uploads image)
Backend API (Node.js/Express)
    ↓
    ├─→ EXIF Service (extracts metadata)
    ├─→ Reverse Image Search (TinEye API)
    └─→ AI Detection (Hive Moderation API)
    ↓
Verification Score (0-100)
    ↓
Firestore (stores results)
```

## Backend Setup

### 1. Navigate to Backend Directory

```bash
cd backend
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Configure Environment Variables

Create a `.env` file in the `backend` directory:

```bash
# Server
PORT=3000

# TinEye API (Reverse Image Search)
TINEYE_API_KEY=your_key_here
TINEYE_API_SECRET=your_secret_here

# Hive Moderation API (AI Detection)
HIVE_API_KEY=your_key_here

# Firebase (Optional - for storing results)
FIREBASE_SERVICE_ACCOUNT={"type":"service_account",...}
```

### 4. Get API Keys

#### TinEye API (Required for Reverse Image Search)

1. Go to https://tineye.com/api/
2. Sign up for a free account
3. Navigate to API section
4. Copy your API Key and Secret
5. **Free Tier**: 500 searches/month

**Add to `.env`:**
```
TINEYE_API_KEY=your_tineye_api_key
TINEYE_API_SECRET=your_tineye_api_secret
```

#### Hive Moderation API (Required for AI Detection)

1. Go to https://thehive.ai/
2. Sign up for an account
3. Navigate to API Keys section
4. Generate a new API key
5. **Free Tier**: Limited requests/month

**Add to `.env`:**
```
HIVE_API_KEY=your_hive_api_key
```

#### Alternative: IsItAI API (Optional)

If Hive API is not available:

1. Go to https://isitai.com/
2. Sign up and get API key
3. **Add to `.env`:**
```
ISITAI_API_KEY=your_isitai_api_key
```

#### Firebase Setup (Optional - for Storing Results)

1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project (or create new)
3. Go to Project Settings → Service Accounts
4. Click "Generate New Private Key"
5. Download the JSON file
6. Convert JSON to single-line string (or use file path)

**Option 1: Single-line JSON string**
```bash
# Convert JSON to single line (remove newlines)
cat firebase-service-account.json | tr -d '\n' > firebase-single-line.json
```

Then in `.env`:
```
FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"..."}
```

**Option 2: Use file path** (modify `firestoreService.js` to read from file)

### 5. Start the Backend Server

**Development mode (with auto-reload):**
```bash
npm run dev
```

**Production mode:**
```bash
npm start
```

Server will run on `http://localhost:3000`

Test it:
```bash
curl http://localhost:3000/health
```

## Flutter App Setup

### 1. Update API URL

In `lib/services/verification_service.dart`, update the base URL:

```dart
static const String _baseUrl = String.fromEnvironment(
  'VERIFICATION_API_URL',
  defaultValue: 'http://localhost:3000/api', // Change to your backend URL
);
```

**For production**, use your deployed backend URL:
- Local development: `http://localhost:3000/api`
- Deployed backend: `https://your-api.herokuapp.com/api`

### 2. Install Dependencies

The `http` package is already added to `pubspec.yaml`. Run:

```bash
flutter pub get
```

### 3. Usage Example

```dart
import 'dart:io';
import 'package:spot_carz/services/verification_service.dart';
import 'package:spot_carz/widgets/verification_result_widget.dart';
import 'package:spot_carz/widgets/verification_progress_widget.dart';

// In your widget
final verificationService = VerificationService();
File? selectedImage;

Future<void> verifyImage() async {
  if (selectedImage == null) return;
  
  // Show progress
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const VerificationProgressWidget(),
  );
  
  try {
    // Get user ID from auth service
    final userId = AuthService().currentUser?.id ?? 'anonymous';
    
    // Verify image
    final result = await verificationService.verifyImageAuthenticity(
      imageFile: selectedImage!,
      userId: userId,
    );
    
    // Close progress dialog
    Navigator.pop(context);
    
    // Show result
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: VerificationResultWidget(result: result),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  } catch (e) {
    Navigator.pop(context); // Close progress
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Verification failed: $e')),
    );
  }
}
```

## Integration with Existing Upload Flow

Update your `database_service.dart` to include verification:

```dart
Future<CarSpot> createCarSpot({
  required String brand,
  required String model,
  required String year,
  File? imageFile,
}) async {
  // ... existing code ...
  
  if (imageFile != null) {
    // Verify image before uploading
    final verificationService = VerificationService();
    final userId = _supabase.currentUser!.id;
    
    final verificationResult = await verificationService.verifyImageAuthenticity(
      imageFile: imageFile,
      userId: userId,
    );
    
    // Check if image passed verification
    if (verificationResult.status == VerificationStatus.likelyFake) {
      throw Exception('Image failed authenticity verification. Please use an original photo.');
    }
    
    // Upload image (existing code)
    final imageUrl = await uploadImage(imageFile);
    // ...
  }
  
  // ... rest of existing code ...
}
```

## Verification Score Breakdown

| Score Range | Status | Meaning |
|------------|--------|---------|
| 81-100 | ✅ Authentic | Image appears genuine |
| 50-80 | ⚠️ Suspicious | Requires manual review |
| 0-49 | ❌ Likely Fake | High probability of being fake |

### Score Calculation

- **EXIF Metadata** (30 points max)
  - Complete (camera + GPS + timestamp): +30
  - Partial (some metadata): +15
  - Missing: -10

- **Reverse Image Search** (30 points max)
  - No matches found: +15
  - 1-3 matches: +5 to +10
  - 4-10 matches: 0 to +5
  - 10+ matches: -15 to 0

- **AI Detection** (40 points max)
  - Low AI probability (<30%): +20
  - Medium AI probability (30-70%): 0
  - High AI probability (>70%): -20

## Deployment

### Backend Deployment Options

#### Option 1: Heroku

```bash
cd backend
heroku create spotcarz-verification-api
heroku config:set TINEYE_API_KEY=your_key
heroku config:set TINEYE_API_SECRET=your_secret
heroku config:set HIVE_API_KEY=your_key
git push heroku main
```

#### Option 2: Railway

1. Connect GitHub repository
2. Add environment variables in dashboard
3. Deploy automatically

#### Option 3: Render

1. Create new Web Service
2. Connect repository
3. Add environment variables
4. Deploy

### Update Flutter App

After deploying backend, update the API URL in `verification_service.dart`:

```dart
static const String _baseUrl = 'https://your-api.herokuapp.com/api';
```

## Troubleshooting

### Backend Issues

**"API credentials not configured" warning:**
- Check `.env` file exists and has correct keys
- Restart server after adding keys

**"Firebase not initialized" warning:**
- Firebase is optional - verification still works without it
- Results just won't be saved to database

**Port already in use:**
- Change `PORT` in `.env` to different port (e.g., 3001)

### Flutter Issues

**Connection refused:**
- Check backend is running
- Verify API URL is correct
- For Android emulator, use `10.0.2.2` instead of `localhost`

**Timeout errors:**
- Increase timeout in `verification_service.dart`
- Check network connection
- Verify backend is accessible

## Testing

### Test Backend

```bash
# Health check
curl http://localhost:3000/health

# Test verification (replace with actual image path)
curl -X POST http://localhost:3000/api/verifyImage \
  -F "image=@test-image.jpg" \
  -F "userId=test-user-123"
```

### Test Flutter Integration

1. Run backend server
2. Run Flutter app
3. Select/take an image
4. Call verification function
5. Check result widget displays correctly

## Cost Estimates

### Free Tier Limits

- **TinEye**: 500 searches/month (free)
- **Hive Moderation**: Limited free tier
- **Firebase**: Generous free tier

### Paid Options

If you exceed free limits:
- TinEye: ~$0.01 per search
- Hive: Contact for pricing
- Firebase: Pay-as-you-go (very affordable)

## Security Considerations

1. **API Keys**: Never commit `.env` file to git
2. **Rate Limiting**: Add rate limiting to prevent abuse
3. **Image Size**: 10MB limit is enforced
4. **User Authentication**: Verify user ID on backend
5. **CORS**: Configure CORS for production domain

## Next Steps

1. Set up API keys
2. Test backend locally
3. Integrate into Flutter app
4. Deploy backend
5. Update Flutter app with production URL
6. Test end-to-end flow

## Support

For issues or questions:
- Check backend logs: `npm run dev` shows detailed logs
- Check Flutter console for errors
- Verify API keys are correct
- Test backend endpoints with curl/Postman

