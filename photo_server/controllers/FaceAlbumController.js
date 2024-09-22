const PhotoService = require('../services/photoService');
const FirebaseService = require('../services/firebaseServices');

class FaceAlbumController {
    static async createDefaultFaceAlbums(req, res) {
        try {
            const { user } = req.body; // Get user from the request
            if (!user) {
                return res.status(400).json({ message: 'User is required.' });
            }

            // Get face encodings from Firebase
            const faceEncodings = await FirebaseService.getAllFaceEncodings(user);
            if (!faceEncodings || faceEncodings.length === 0) {
                return res.status(404).json({ message: 'No face encodings found for this user.' });
            }

            // Create default albums for each face encoding
            const createdAlbums = await PhotoService.createDefaultFaceAlbum(user, faceEncodings);

            return res.status(200).json({
                message: 'Default face albums created successfully',
                albums: createdAlbums,
            });
        } catch (error) {
            console.error('Error creating face albums:', error);
            return res.status(500).json({ message: 'Error creating face albums', error: error.message });
        }
    }
}

module.exports = FaceAlbumController;
