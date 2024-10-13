const PhotoService = require('../services/photoService');
const faceapi = require('face-api.js');
const { bucket } = require('../firebaseConfig');
const FirebaseService = require('../services/firebaseServices');
const FaceService = require('../services/faceService');
const fs = require('fs');
const { Canvas, Image, ImageData } = require('canvas');
const canvas = require('canvas');
const admin = require('firebase-admin');

// Patch the environment with node-canvas for face-api.js usage
faceapi.env.monkeyPatch({ Canvas, Image, ImageData });

class AlbumController {
    /**
     * Deletes an album and all its photos from Firebase Storage.
     * @param {Object} req - The request object containing the album path to be deleted.
     * @param {Object} res - The response object to send the status of the deletion.
     */
    static async deleteAlbum(req, res) {
        const { albumPath } = req.body;  // Get the album path from the request body
        console.log("in delete album for this req: ", albumPath);

        if (!albumPath) {
            return res.status(400).json({ message: 'Album path is required.' });
        }

        try {
            // Extract the folder path before the album name (i.e., without the part after `#`)
            const albumFolderPath = albumPath.split('#')[0]; 
            console.log(`Attempting to delete album at path: ${albumPath}`);

            // List all files under the album folder
            const [files] = await admin.storage().bucket().getFiles({ prefix: albumPath });

            if (files.length === 0) {
                console.log(`No files found in album path ${albumPath}`);
                return res.status(404).json({ message: `Album not found.` });
            }

            // Create a promise to delete each file in the album
            const deletePromises = files.map(file => file.delete());

            // Wait for all deletion promises to complete
            await Promise.all(deletePromises);

            console.log(`Successfully deleted album at path ${albumPath}`);
            return res.status(200).json({ message: `Album successfully deleted.` });
        } catch (error) {
            console.error(`Error deleting album at path ${albumPath}:`, error);
            return res.status(500).json({ message: 'Error deleting album.', error: error.message });
        }
    }

    /**
     * Creates a new album based on provided user, date range, number of photos, and album name.
     * Photos are selected based on the face detection results.
     * @param {Object} req - The request object containing user information, date range, number of photos, and files.
     * @param {Object} res - The response object to send the status of album creation.
     */
    static async createAlbum(req, res) {
        console.log("createAlbum", req.body);
        try {
            const { user, startDate, endDate, numPhotos, albumName } = req.body;
            const files = req.files;  // Get uploaded files from the request

            // Validate input parameters
            if (!user || !Array.isArray(files) || !startDate || !endDate || !numPhotos || isNaN(numPhotos)) {
                return res.status(400).json({ message: 'Invalid input parameters' });
            }

            // Load face detection models using the FaceService
            await FaceService.loadModels();

            // Extract face IDs from the uploaded files using face detection
            const faceIds = await PhotoService.getFaceIdsFromFiles(files, user);

            // Filter and retrieve photos for the user within the specified date range, filtered by face IDs
            const filteredPhotos = await PhotoService.getFilteredPhotos(user, startDate, endDate, faceIds);

            // Create an album with the specified number of photos (up to `numPhotos`)
            const albumPath = await PhotoService.createAlbum(user, filteredPhotos, parseInt(numPhotos, 10), albumName);
            console.log("done! ", albumPath);

            return res.status(200).json({ message: 'Album created successfully', albumPath });
        } catch (error) {
            console.error('Error creating album:', error);
            return res.status(500).json({ message: 'Error creating album', error: error.message });
        }
    }
}

module.exports = AlbumController;
