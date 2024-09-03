const { bucket } = require('../firebaseConfig');
const path = require('path');

class FaceEncodingModel {
    // Save a new face encoding or update an existing one
    static async saveFaceEncoding(faceId, descriptor, photoPath) {
        // Define the base folder path as the parent folder of the photo
        const baseFolderPathup = photoPath.substring(0, photoPath.lastIndexOf('/'));
        const baseFolderPath = baseFolderPathup.substring(0, baseFolderPathup.lastIndexOf('/')) + '/face_encodings';

        // Construct the path for the face encoding file
        const encodingFilePath = `${baseFolderPath}/${faceId}.json`;

        // Initialize faceData
        let faceData = { descriptor, photos: [photoPath] };

        try {
            // Check if the face ID already exists
            const [exists] = await bucket.file(encodingFilePath).exists();
            if (exists) {
                // Update existing face encoding
                const [content] = await bucket.file(encodingFilePath).download();
                const existingData = JSON.parse(content);
                faceData = {
                    ...existingData,
                    photos: Array.from(new Set([...existingData.photos, photoPath])) // Avoid duplicates
                };
            }
        } catch (error) {
            console.error(`Error checking face encoding: ${error.message}`);
        }

        // Save or update face encoding with associated photos
        await bucket.file(encodingFilePath).save(JSON.stringify(faceData), {
            contentType: 'application/json'
        });
    }

    // Add a new photo to an existing face encoding
    static async addPhotoToFace(faceId, photoPath) {
        console.log("in addPhotoToFace");
    
        const baseFolderPathup = photoPath.substring(0, photoPath.lastIndexOf('/'));
        const baseFolderPath = baseFolderPathup.substring(0, baseFolderPathup.lastIndexOf('/')) + '/face_encodings';
    
        // Construct the path for the face encoding file
        const encodingFilePath = `${baseFolderPath}/${faceId}.json`;
    
        try {
            // Retrieve the current metadata
            const [metadata] = await bucket.file(encodingFilePath).getMetadata();
            let photos = metadata.metadata && metadata.metadata.photos 
                ? JSON.parse(metadata.metadata.photos) 
                : [];
    
            // Add the new photo path if it's not already in the array
            if (!photos.includes(photoPath)) {
                photos.push(photoPath);
    
                // Update the metadata with the new photos array
                await bucket.file(encodingFilePath).setMetadata({
                    metadata: {
                        photos: JSON.stringify(photos)
                    }
                });
    
                console.log(`Updated face encoding with new photo path: ${photoPath}`);
            }
        } catch (error) {
            console.error(`Error updating face encoding: ${error.message}`);
        }
    }
    
    

    // Retrieve all face encodings
    static async getFaceEncodings() {
        const [files] = await bucket.getFiles({ prefix: 'face_encodings/' });
        const faceEncodings = [];

        for (const file of files) {
            const [content] = await file.download();
            faceEncodings.push({
                faceId: path.basename(file.name, '.json'),
                descriptor: JSON.parse(content)
            });
        }

        return faceEncodings;
    }
}

module.exports = FaceEncodingModel;
