const express = require('express');
const PhotoController = require('../controllers/photoController');
const AlbumController = require('../controllers/albumController');
const FaceAlbumController = require('../controllers/FaceAlbumController');
const router = express.Router();
const multer = require('multer');
const upload = multer({ dest: 'uploads/' });
// Middleware to parse JSON bodies
router.use(express.json());

// Define the route for processing photos
router.post('/process-photos', PhotoController.processUploadedPhotos);

router.post('/create-default-face-albums', FaceAlbumController.createDefaultFaceAlbums);
router.post('/create-album', upload.array('photos'), AlbumController.createAlbum);
router.post('/delete-album', AlbumController.deleteAlbum);
module.exports = router;
