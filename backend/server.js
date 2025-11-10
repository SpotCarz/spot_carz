require('dotenv').config();
const express = require('express');
const cors = require('cors');
const verifyImageRouter = require('./routes/verifyImage');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Verification API is running' });
});

// API routes
app.use('/api', verifyImageRouter);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message,
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Verification API server running on port ${PORT}`);
  console.log(`📝 Health check: http://localhost:${PORT}/health`);
});

