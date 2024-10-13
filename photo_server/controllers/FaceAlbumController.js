const PhotoService = require('../services/photoService');
const FirebaseService = require('../services/firebaseServices');

/**
 * Controller to handle operations related to creating default face albums.
 * This class provides a method to automatically create albums based on detected faces in the user's photos.
 */
class FaceAlbumController {

    /**
     * Create default albums for the user based on face encodings.
     * 
     * This method performs the following steps:
     * 1. Extract the user from the request body.
     * 2. Fetch the user's face encodings from Firebase.
     * 3. Use the `PhotoService` to delete any existing default albums and create new ones based on face encodings.
     * 4. Return the created albums in the response.
     * 
     * @param {Object} req - The HTTP request object.
     * @param {Object} res - The HTTP response object.
     * @returns {Object} - The HTTP response containing the status and result of the album creation.
     */
    static async createDefaultFaceAlbums(req, res) {
        try {
            // Extract the user from the request body
            const { user } = req.body;
            
            // If no user is provided, return an error response
            if (!user) {
                return res.status(400).json({ message: 'User is required.' });
            }

            // Fetch all face encodings for the user from Firebase
            const faceEncodings = await FirebaseService.getAllFaceEncodings(user);
            
            // If no face encodings are found, return a 404 response
            if (!faceEncodings || faceEncodings.length === 0) {
                return res.status(404).json({ message: 'No face encodings found for this user.' });
            }

            // Use the PhotoService to delete existing albums and create new default albums
            const createdAlbums = await PhotoService.deleteAndCreateDefaultAlbums(user, faceEncodings);

            // Return the created albums in the response
            return res.status(200).json({
                message: 'Default face albums created successfully',
                albums: createdAlbums,
            });

        } catch (error) {
            // Catch any errors and return a 500 response with the error message
            console.error('Error creating face albums:', error);
            return res.status(500).json({ message: 'Error creating face albums', error: error.message });
        }
    }
}

module.exports = FaceAlbumController;
