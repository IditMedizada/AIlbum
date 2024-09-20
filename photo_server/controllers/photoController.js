const FirebaseService = require('../services/firebaseServices');
const FaceService = require('../services/faceService');
const faceapi = require('face-api.js');
const { bucket } = require('../firebaseConfig');
const fs = require('fs');
const { Canvas, Image, ImageData } = require('canvas');
const canvas = require('canvas');

// Patch the environment with node-canvas
faceapi.env.monkeyPatch({ Canvas, Image, ImageData });

class PhotoController {
    static async processUploadedPhotos(req, res) {
        console.log("Request body:", req.body);

        const user = req.body.user;
        if (!user) {
            return res.status(400).json({ message: 'User is required.' });
        }

        const userFolderPath = `${user}/user_photos`;
        console.log("In PhotoController, userFolderPath:", userFolderPath);

        try {
            // List all files in the user's folder
            const [files] = await bucket.getFiles({ prefix: userFolderPath });
            console.log(`Found ${files.length} files for user ${user}.`);

            await FaceService.loadModels();

            for (const file of files) {
                const filePath = file.name;

                // Check if the photo has already been processed
                if ( FirebaseService.isPhotoProcessed(filePath)) {
                    console.log(`Skipping already processed file: ${filePath}`);
                    continue;
                }

                console.log("Processing file:", filePath);
                const tempFilePath = await FirebaseService.downloadImage(filePath); // Download the image to a temp path
                const imageBuffer = fs.readFileSync(tempFilePath); // Read the image from the temp path

                // Load the image using node-canvas
                const img = await canvas.loadImage(imageBuffer);

                const faceIds = await FaceService.processFaces(img,filePath);
                await FirebaseService.updatePhotoMetadata(filePath, faceIds);

                FirebaseService.cleanUp(tempFilePath); // Clean up the temp file
            }

            res.status(200).json({ message: 'Photos processed successfully.' });
        } catch (error) {
            console.error("Error processing photos:", error);
            res.status(500).json({ message: 'An error occurred while processing photos.', error: error.message });
        }
    }
}

module.exports = PhotoController;