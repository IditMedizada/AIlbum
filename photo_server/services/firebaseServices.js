const { bucket } = require('../firebaseConfig'); // Importing the Firebase Storage bucket configuration
const path = require('path'); // Node.js module for handling file paths
const os = require('os'); // Node.js module for OS-specific operations
const fs = require('fs'); // Node.js module for file system operations

// FirebaseService class: Contains methods to interact with Firebase Storage for photo processing and metadata management
class FirebaseService {
    // Method to check if the photo has already been processed
    static async isPhotoProcessed(filePath) {
        try {
            const [metadata] = await bucket.file(filePath).getMetadata();
            return metadata.metadata && metadata.metadata.processed === 'true';
        } catch (error) {
            console.error(`Error checking if photo is processed: ${error}`);
            return false;
        }
    }

    static async getAllFaceEncodings(user) {
        const faceEncodingsFolder = `${user}/face_encodings/`;
        const [files] = await bucket.getFiles({ prefix: faceEncodingsFolder }); // Fetch all files in the folder

        const faceEncodings = await Promise.all(
            files.map(async (file) => {
                const [metadata] = await file.getMetadata();
                const faceId = path.basename(file.name, '.json'); // Assuming faceId is the file name
                const photos = JSON.parse(metadata.metadata.photos); // Assuming photos are stored in metadata

                return { faceId, photos };
            })
        );

        return faceEncodings;
    }


    // Method to download the image directly to a buffer
    static async downloadImageToBuffer(filePath) {
        const file = bucket.file(filePath);
        const [data] = await file.download();
        return data;
    }

    // Method to update photo metadata
    static async updatePhotoMetadata(filePath, faceIds) {
        const file = bucket.file(filePath);
        await file.setMetadata({
            metadata: {
                processed: 'true',
                faceIds: JSON.stringify(faceIds),
            },
        });
    }
}

module.exports = FirebaseService;
