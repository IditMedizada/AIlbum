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

            // Retrieve processed photos
            const processedPhotos = await getProcessedPhotosForUser(user); // Implement this function as needed

            // Filter out already processed photos
            const newFiles = files.filter(file => !processedPhotos.includes(file.name));

            console.log(`Processing ${newFiles.length} new files.`);

            for (const file of newFiles) {
                console.log("Processing file:", file.name);
                const filePath = file.name;
                const tempFilePath = await FirebaseService.downloadImage(filePath); // Download the image to a temp path
                const imageBuffer = fs.readFileSync(tempFilePath); // Read the image from the temp path

                // Load the image using node-canvas
                const img = await canvas.loadImage(imageBuffer);

                const faceIds = await FaceService.processFaces(img);
                await FirebaseService.updatePhotoMetadata(filePath, faceIds);

                FirebaseService.cleanUp(tempFilePath); // Clean up the temp file
            }

            res.status(200).json({ message: 'New photos processed successfully.' });
        } catch (error) {
            console.error("Error processing photos:", error);
            res.status(500).json({ message: 'An error occurred while processing photos.', error: error.message });
        }
    }
}

module.exports = PhotoController;
