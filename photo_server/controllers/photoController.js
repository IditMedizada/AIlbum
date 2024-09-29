const FirebaseService = require('../services/firebaseServices');
const FaceService = require('../services/faceService');
const faceapi = require('face-api.js');
const { bucket } = require('../firebaseConfig');  // Correctly importing bucket from firebaseConfig
const { Canvas, Image, ImageData } = require('canvas');
const canvas = require('canvas');

// Patch the environment with node-canvas
faceapi.env.monkeyPatch({ Canvas, Image, ImageData });

// Map to track user request queues and locks
const userLocks = new Map();  // Locks to prevent concurrent requests
const userQueues = new Map();  // Queue to store requests for each user

class PhotoController {
    static async processUploadedPhotos(req, res) {
        const user = req.body.user;
        console.log("request for user : ", user);

        if (!user) {
            return res.status(400).json({ message: 'User is required.' });
        }

        // If a request for the user is already being processed, enqueue the request
        if (userLocks.has(user)) {
            console.log(`Request for user ${user} is already in progress. Enqueueing this request.`);
            enqueueUserRequest(user, req, res);
            return;
        }

        // Lock the user to indicate a request is being processed
        userLocks.set(user, true);

        try {
            await processUserPhotos(req, res, user);
        } finally {
            // Once processing is complete, unlock and process the next request in the queue (if any)
            userLocks.delete(user);
            processNextUserRequest(user);
        }
    }
}

// Process photos for the user
async function processUserPhotos(req, res, user) {
    const userFolderPath = `${user}/user_photos`;
    console.log("User folder path:", userFolderPath);

    try {
        console.log("Attempting to retrieve files from bucket...");
        const [files] = await bucket.getFiles({ prefix: userFolderPath });

        if (!files || files.length === 0) {
            console.log(`No files found for user: ${user}`);
            return res.status(200).json({ message: 'No files to process.' });
        }

        console.log(`Found ${files.length} files for user ${user}.`);
        await FaceService.loadModels();
        console.log("Face models loaded successfully.");

        for (const file of files) {
            const filePath = file.name;

            const isProcessed = await FirebaseService.isPhotoProcessed(filePath);
            if (isProcessed) {
                console.log(`Skipping already processed file: ${filePath}`);
                continue;
            }

            console.log(`Processing file: ${filePath}`);

            // Use the new method to download the image as a buffer directly
            const imageBuffer = await FirebaseService.downloadImageToBuffer(filePath);
            console.log(`Image loaded for file: ${filePath}`);

            // Load the image using node-canvas
            const img = await canvas.loadImage(imageBuffer);

            const faceIds = await FaceService.processFaces(img, filePath, user);
            console.log(`Face IDs processed: ${faceIds}`);

            await FirebaseService.updatePhotoMetadata(filePath, faceIds);
            console.log(`Metadata updated for file: ${filePath}`);
        }

        res.status(200).json({ message: 'Photos processed successfully.' });
    } catch (error) {
        console.error("Error during photo processing:", error);
        res.status(500).json({ message: 'An error occurred while processing photos.', error: error.message });
    }
}

// Helper function to enqueue the request for the user
function enqueueUserRequest(user, req, res) {
    if (!userQueues.has(user)) {
        userQueues.set(user, []);
    }
    userQueues.get(user).push({ req, res });
}

// Helper function to process the next request for the user, if any
function processNextUserRequest(user) {
    if (!userQueues.has(user) || userQueues.get(user).length === 0) {
        return;
    }

    const nextRequest = userQueues.get(user).shift();  // Get the next request in the queue
    PhotoController.processUploadedPhotos(nextRequest.req, nextRequest.res);
}

module.exports = PhotoController;
