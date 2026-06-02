// Simple Express server for Container Security Demo
const express = require('express');
const app = express();
const PORT = 3000;

// Health check endpoint (used by HEALTHCHECK in Dockerfile)
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// Main endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'DevSecOps Container Security Demo',
    user: process.env.USER || 'unknown',
    uid: process.getuid ? process.getuid() : 'N/A',
    pid: process.pid
  });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
