const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const faceapi = require('face-api.js');
const canvas = require('canvas');
const { Canvas, Image, ImageData } = canvas;
faceapi.env.monkeyPatch({ Canvas, Image, ImageData });
const FaceEncodingModel = require('../models/faceEncodingModel');

class PhotoService {
    // Extract face IDs from provided photos
    static async getFaceIdsFromFiles(files , user) {
        const faceIds = new Set();

        for (const file of files) {
            const tempFilePath = file.path;
            const photoFaceIds = await this.processFacesForAlbum(tempFilePath, user);
            
            photoFaceIds.forEach(id => faceIds.add(id));
        }

        console.log("face ids from album create: ", faceIds);

        return Array.from(faceIds); // Convert Set to Array
    }

    static async processFacesForAlbum(filePath, user) {
        try {
            // Load the image from the file path using node-canvas
            const img = await canvas.loadImage(filePath);

            // Pass the loaded image to face-api.js for face detection
            const detections = await faceapi.detectAllFaces(img)
                .withFaceLandmarks()
                .withFaceDescriptors();

            const photoPath = `${user}/user_photos/blabla`;
            const faceEncodings = await FaceEncodingModel.getFaceEncodings(photoPath);
            const faceIds = [];

            for (const detection of detections) {
                const descriptor = Array.from(detection.descriptor);
                let matchingFaceId = null;

                for (const face of faceEncodings) {
                    const distance = faceapi.euclideanDistance(new Float32Array(face.descriptor), descriptor);
                    if (distance < 0.6) {  // Similarity threshold
                        matchingFaceId = face.faceId;
                        break;
                    }
                }

                let faceId;
                if (matchingFaceId) {
                    faceId = matchingFaceId;
                } else {
                    faceId = uuidv4();
                }

                faceIds.push(faceId);
            }

            return faceIds;
        } catch (error) {
            console.error('Error processing faces for album:', error);
            throw error;
        }
    }

    // Retrieves photos metadata within the date range and filters by face IDs
    static async getFilteredPhotos(user, startDate, endDate, faceIds) {
        const photosPath = `${user}/user_photos`;
        const photos = [];

        const [files] = await admin.storage().bucket().getFiles({ prefix: photosPath });
        for (const file of files) {
            const metadata = file.metadata;
            const photoDate = new Date(metadata.metadata.photoDate);

            if (photoDate >= new Date(startDate) && photoDate <= new Date(endDate)) {
                const photoFaceIds = JSON.parse(metadata.metadata.faceIds || '[]');
                const matchedFaces = photoFaceIds.filter(id => faceIds.includes(id)).length;

                if (matchedFaces > 0) {
                    photos.push({
                        path: file.name,
                        photoDate: photoDate,
                        matchedFaces
                    });
                }
            }
        }

        console.log("photos found: ",photos);

        return photos.sort((a, b) => b.matchedFaces - a.matchedFaces); // Sort by number of matched faces
    }

    // Create album in Firebase
    static async createAlbum(user, photos, numPhotos , albumName) {
        const albumPath = `${user}/user_albums/${uuidv4()}#${albumName}`;
        const album = photos.slice(0, numPhotos);

        const promises = album.map(photo => 
            admin.storage().bucket().file(photo.path).copy(`${albumPath}/${path.basename(photo.path)}`)
        );
        await Promise.all(promises);

        return albumPath;
    }
    static async createDefaultFaceAlbum(user, faceEncodings) {
        // Iterate over each face encoding to create an album for it
        const albumPromises = faceEncodings.map(async (encoding) => {
            const faceId = encoding.faceId;
            const photos = encoding.photos;

            if (!photos || photos.length < 7) {
                console.log(`Skipping album creation for faceId ${faceId} as it has less than 7 photos.`);
                return null;
            }
            

            const albumName = `default`; 
            const albumPath = `${user}/user_albums/${uuidv4()}#${albumName}`;
            console.log(`Creating default album for faceId ${faceId} at ${albumPath}`);

            // Copy each photo to the album path
            const copyPromises = photos.map((photo) => {
                if (!photo) {
                    throw new Error('Invalid photo path');
                }

                const sourceFilePath = `${photo}`; // Use the full photo path
                const destinationFilePath = `${albumPath}/${path.basename(photo)}`;

                console.log(`Copying from ${sourceFilePath} to ${destinationFilePath}`);

                return admin
                    .storage()
                    .bucket()
                    .file(sourceFilePath)
                    .copy(destinationFilePath)
                    .catch((error) => {
                        console.error(`Error copying file ${sourceFilePath}:`, error);
                        throw error;
                    });
            });

            await Promise.all(copyPromises);
            return albumPath;
        });

        const createdAlbums = await Promise.all(albumPromises);
        return createdAlbums.filter(album => album !== null); // Return only successfully created albums
    }

}

module.exports = PhotoService;