
const express = require('express');
const multer = require('multer');
const photosController = require('../controllers/photos.js');
const router = express.Router();

// Set up Multer for file uploads
const upload = multer({ storage: multer.memoryStorage() }); // Use memory storage to keep file in memory

// Add photo to db - api/photos
router.post('/photos', upload.single('photo'), photosController.addPhoto);

module.exports = router;
