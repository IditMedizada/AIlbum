const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const faceapi = require('face-api.js');
const canvas = require('canvas');
const { Canvas, Image, ImageData } = canvas;
faceapi.env.monkeyPatch({ Canvas, Image, ImageData });
const FaceEncodingModel = require('../models/faceEncodingModel');

/**
 * PhotoService class provides utility functions to manage photos,
 * face encodings, and albums in Firebase Storage for a user.
 */
class PhotoService {

    /**
     * Extract face IDs from provided photos.
     * 
     * @param {Array} files - Array of photo file objects.
     * @param {string} user - The user for whom the face IDs are being extracted.
     * @returns {Array} - An array of unique face IDs found in the photos.
     */
    static async getFaceIdsFromFiles(files, user) {
        const faceIds = new Set();  // Use a set to store unique face IDs

        for (const file of files) {
            const tempFilePath = file.path;
            const photoFaceIds = await this.processFacesForAlbum(tempFilePath, user);
            photoFaceIds.forEach(id => faceIds.add(id));
        }

        console.log("Face IDs from album creation: ", faceIds);

        return Array.from(faceIds);  // Convert the set of unique IDs to an array
    }

    /**
     * Process faces in a single image to detect and encode faces.
     * 
     * @param {string} filePath - The path of the photo file.
     * @param {string} user - The user for whom the face IDs are being processed.
     * @returns {Array} - An array of face IDs detected in the image.
     */
    static async processFacesForAlbum(filePath, user) {
        try {
            // Load image using node-canvas
            const img = await canvas.loadImage(filePath);

            // Detect all faces and get their landmarks and descriptors
            const detections = await faceapi.detectAllFaces(img)
                .withFaceLandmarks()
                .withFaceDescriptors();

            // Simulating the use of the user's photo path to get existing face encodings
            const photoPath = `${user}/user_photos/sample_photo`;
            const faceEncodings = await FaceEncodingModel.getFaceEncodings(photoPath);
            const faceIds = [];

            // Loop through each detection to match or create new face IDs
            for (const detection of detections) {
                const descriptor = Array.from(detection.descriptor);
                let matchingFaceId = null;

                // Compare the face descriptors with existing encodings
                for (const face of faceEncodings) {
                    const distance = faceapi.euclideanDistance(new Float32Array(face.descriptor), descriptor);
                    if (distance < 0.6) {  // If similarity is below the threshold, consider it a match
                        matchingFaceId = face.faceId;
                        break;
                    }
                }

                // Assign a new face ID if no match is found
                let faceId;
                if (matchingFaceId) {
                    faceId = matchingFaceId;
                } else {
                    faceId = uuidv4();  // Generate a new face ID if no match is found
                }

                faceIds.push(faceId);
            }

            return faceIds;  // Return the detected face IDs
        } catch (error) {
            console.error('Error processing faces for album:', error);
            throw error;
        }
    }

    /**
     * Retrieve photos within a date range and filter them by face IDs.
     * 
     * @param {string} user - The user whose photos are being filtered.
     * @param {string} startDate - The start date for filtering photos.
     * @param {string} endDate - The end date for filtering photos.
     * @param {Array} faceIds - Array of face IDs to match in the photos.
     * @returns {Array} - Array of filtered photos sorted by the number of matched faces.
     */
    static async getFilteredPhotos(user, startDate, endDate, faceIds) {
        const photosPath = `${user}/user_photos`;
        const photos = [];

        const [files] = await admin.storage().bucket().getFiles({ prefix: photosPath });
        for (const file of files) {
            const metadata = file.metadata;
            const photoDate = new Date(metadata.metadata.photoDate);

            // Check if the photo's date falls within the specified date range
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

        console.log("Photos found: ", photos);

        // Sort the photos by the number of matched faces
        return photos.sort((a, b) => b.matchedFaces - a.matchedFaces);
    }

    /**
     * Create a new album for the user with selected photos.
     * 
     * @param {string} user - The user for whom the album is being created.
     * @param {Array} photos - Array of photos to be included in the album.
     * @param {number} numPhotos - The number of photos to include in the album.
     * @param {string} albumName - The name of the album.
     * @returns {string} - The path of the created album.
     */
    static async createAlbum(user, photos, numPhotos, albumName) {
        const albumPath = `${user}/user_albums/${uuidv4()}#${albumName}`;
        const album = photos.slice(0, numPhotos);  // Limit the number of photos to the specified count

        // Copy photos to the new album folder in parallel
        const copyPromises = album.map(photo => {
            const sourceFilePath = `${photo.path}`;
            const destinationFilePath = `${albumPath}/${path.basename(photo.path)}`;

            return admin.storage().bucket().file(sourceFilePath).copy(destinationFilePath)
                .catch(error => {
                    console.error(`Error copying file ${sourceFilePath}:`, error);
                    throw error;
                });
        });

        // Wait for all copy operations to finish
        await Promise.all(copyPromises);

        return albumPath;
    }

    /**
     * Delete all default albums for the user from Firebase Storage.
     * 
     * @param {string} user - The user whose default albums are to be deleted.
     * @returns {Promise<void>} - Resolves when the albums are deleted.
     */
    static async deleteExistingDefaultAlbums(user) {
        const defaultAlbumPrefix = `${user}/user_albums/`;
        const [albums] = await admin.storage().bucket().getFiles({ prefix: defaultAlbumPrefix });

        // Filter and delete only default albums
        const deletePromises = albums
            .filter(album => album.name.includes('#default'))
            .map(album => admin.storage().bucket().file(album.name).delete());

        if (deletePromises.length > 0) {
            console.log(`Deleting ${deletePromises.length} existing default albums for user ${user}`);
            await Promise.all(deletePromises);
            console.log(`Deleted all default albums for user ${user}`);
        }
    }

    /**
     * Create default face albums for a user by grouping photos based on face encodings.
     * 
     * @param {string} user - The user for whom the albums are being created.
     * @param {Array} faceEncodings - Array of face encodings associated with the user.
     * @returns {Array} - Array of paths of created albums.
     */
    static async createDefaultFaceAlbum(user, faceEncodings) {
        const albumPromises = faceEncodings.map(async (encoding) => {
            const faceId = encoding.faceId;
            const photos = encoding.photos;

            // Skip album creation if there are less than 7 photos for the face ID
            if (!photos || photos.length < 7) {
                console.log(`Skipping album creation for faceId ${faceId} as it has less than 7 photos.`);
                return null;
            }

            const albumName = `default`;
            const albumPath = `${user}/user_albums/${uuidv4()}#${albumName}`;
            console.log(`Creating default album for faceId ${faceId} at ${albumPath}`);

            const copyPromises = photos.map(photo => {
                const sourceFilePath = `${photo}`;
                const destinationFilePath = `${albumPath}/${path.basename(photo)}`;

                return admin.storage().bucket().file(sourceFilePath).copy(destinationFilePath)
                    .catch(error => {
                        console.error(`Error copying file ${sourceFilePath}:`, error);
                        throw error;
                    });
            });

            // Execute all copy operations in parallel
            await Promise.all(copyPromises);
            return albumPath;
        });

        // Wait for all albums to be created and return their paths
        const createdAlbums = await Promise.all(albumPromises);
        return createdAlbums.filter(album => album !== null);  // Only return successfully created albums
    }

    /**
     * Delete existing default albums for a user and create new ones based on face encodings.
     * 
     * @param {string} user - The user for whom the albums are being deleted and recreated.
     * @param {Array} faceEncodings - Array of face encodings associated with the user.
     * @returns {Array} - Array of paths of newly created albums.
     */
    static async deleteAndCreateDefaultAlbums(user, faceEncodings) {
        // Step 1: Delete existing default albums
        await this.deleteExistingDefaultAlbums(user);

        // Step 2: Create new default albums based on face encodings
        return await this.createDefaultFaceAlbum(user, faceEncodings);
    }
}

module.exports = PhotoService;

