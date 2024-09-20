const FirebaseService = require('../services/firebaseServices');
const FaceService = require('../services/faceService');
const { Canvas, Image, ImageData } = require('canvas');
const canvas = require('canvas');
const fs = require('fs');
const { bucket } = require('../firebaseConfig');
const faceapi = require('face-api.js');
faceapi.env.monkeyPatch({ Canvas, Image, ImageData });

class PhotoController {
    static async processUploadedPhotos(req, res) {
        const user = req.body.user;
        if (!user) {
            return res.status(400).json({ message: 'User is required.' });
        }

        const userFolderPath = `${user}/user_photos`;
        console.log("In PhotoController, userFolderPath:", userFolderPath);

        try {
            const [files] = await bucket.getFiles({ prefix: userFolderPath });
            await FaceService.loadModels();

            const processingPromises = files.map(async (file) => {
                const filePath = file.name;
                if (FirebaseService.isPhotoProcessed(filePath)) return;

                const tempFilePath = await FirebaseService.downloadImage(filePath);
                const imageBuffer = fs.readFileSync(tempFilePath);
                const img = await canvas.loadImage(imageBuffer);

                const faceIds = await FaceService.processFaces(img, filePath);
                await FirebaseService.updatePhotoMetadata(filePath, faceIds);
                FirebaseService.cleanUp(tempFilePath);
            });

            await Promise.all(processingPromises); // Parallel face processing

            res.status(200).json({ message: 'Photos processed successfully.' });
        } catch (error) {
            console.error("Error processing photos:", error);
            res.status(500).json({ message: 'Error processing photos.', error: error.message });
        }
    }
}
module.exports = PhotoController;
