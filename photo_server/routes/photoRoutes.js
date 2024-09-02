const express = require('express');
const PhotoController = require('../controllers/photoController');
const router = express.Router();

// Middleware to parse JSON bodies
router.use(express.json());

// Define the route without multer
router.post('/process-photos', PhotoController.processUploadedPhotos);

module.exports = router;
