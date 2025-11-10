# SpotCarz Image Verification API

Backend API for verifying image authenticity in the SpotCarz app.

## Features

- ✅ EXIF metadata extraction
- 🔍 Reverse image search (TinEye API)
- 🤖 AI generation detection (Hive Moderation API)
- 📊 Verification score calculation (0-100)
- 💾 Firestore integration for storing results

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment Variables

Copy `.env.example` to `.env` and fill in your API keys:

```bash
cp .env.example .env
```

### 3. Get API Keys

#### TinEye API (Reverse Image Search)
1. Sign up at https://tineye.com/api/
2. Get your API key and secret
3. Free tier: 500 searches/month

#### Hive Moderation API (AI Detection)
1. Sign up at https://thehive.ai/
2. Get your API key
3. Free tier available

#### Firebase (Optional - for storing results)
1. Go to Firebase Console
2. Download service account JSON
3. Convert to single-line JSON string or set path

### 4. Run the Server

**Development:**
```bash
npm run dev
```

**Production:**
```bash
npm start
```

Server will run on `http://localhost:3000`

## API Endpoints

### POST `/api/verifyImage`

Verifies an image for authenticity.

**Request:**
- Method: `POST`
- Content-Type: `multipart/form-data`
- Body:
  - `image`: Image file (max 10MB)
  - `userId`: User ID string

**Response:**
```json
{
  "imageUrl": "uploaded/user123/1234567890_image.jpg",
  "userId": "user123",
  "verificationScore": 85,
  "status": "authentic",
  "aiGeneratedProbability": 0.15,
  "reverseImageMatchConfidence": 0.9,
  "metadataStatus": "complete",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "metadata": {
    "make": "Apple",
    "model": "iPhone 14 Pro",
    "dateTime": "2024-01-15T10:25:00",
    "gps": {
      "latitude": 40.7128,
      "longitude": -74.0060
    }
  }
}
```

**Status Values:**
- `authentic`: Score > 80
- `suspicious`: Score 50-80
- `likelyFake`: Score < 50

### GET `/api/verificationHistory?userId=user123`

Retrieves verification history for a user.

**Response:**
```json
[
  {
    "id": "doc123",
    "imageUrl": "...",
    "verificationScore": 85,
    "status": "authentic",
    "timestamp": "2024-01-15T10:30:00.000Z",
    ...
  }
]
```

## Verification Score Calculation

The verification score (0-100) is calculated from:

1. **EXIF Metadata** (0-30 points)
   - Complete metadata: +30
   - Partial metadata: +15
   - No metadata: -10

2. **Reverse Image Search** (0-30 points)
   - No matches found: +15
   - Few matches: +5 to +10
   - Many matches: -15 to 0

3. **AI Detection** (0-40 points)
   - Low AI probability: +20
   - Medium AI probability: 0
   - High AI probability: -20

## Error Handling

If any service fails, the API will:
- Continue with available checks
- Return partial results
- Include error messages in response
- Flag for manual review if needed

## Deployment

### Deploy to Heroku

```bash
heroku create spotcarz-verification-api
heroku config:set TINEYE_API_KEY=your_key
heroku config:set TINEYE_API_SECRET=your_secret
heroku config:set HIVE_API_KEY=your_key
git push heroku main
```

### Deploy to Railway

1. Connect your GitHub repository
2. Add environment variables in Railway dashboard
3. Deploy automatically

### Deploy to Vercel/Netlify

These platforms are optimized for serverless functions. Consider refactoring to serverless functions for better performance.

## Testing

Test the API with curl:

```bash
curl -X POST http://localhost:3000/api/verifyImage \
  -F "image=@test-image.jpg" \
  -F "userId=test-user-123"
```

## License

ISC

