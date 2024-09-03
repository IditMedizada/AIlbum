const express = require('express');
const imageController = require('../controllers/imageController');
const faceController = require('../controllers/faceController');

const router = express.Router();

router.post('/process-image', imageController.processImage);
router.get('/get-face/:faceId', faceController.getFace);

module.exports = router;
