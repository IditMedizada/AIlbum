const PhotoService = require('../services/photoService');
const faceapi = require('face-api.js');
const { bucket } = require('../firebaseConfig');
const FirebaseService = require('../services/firebaseServices');
const FaceService = require('../services/faceService');
const fs = require('fs');
const { Canvas, Image, ImageData } = require('canvas');
const canvas = require('canvas');
const admin = require('firebase-admin');

// Patch the environment with node-canvas
faceapi.env.monkeyPatch({ Canvas, Image, ImageData });

class AlbumController {
    static async deleteAlbum(req, res) {
        const { albumPath } = req.body;
        console.log("in delete album for this req: ",albumPath);
        if (!albumPath) {
            return res.status(400).json({ message: 'Album path is required.' });
        }

        try {
            // Extract user folder and album path from the provided albumPath
            const albumFolderPath = albumPath.split('#')[0]; // Remove the album name after `#`
            
            console.log(`Attempting to delete album at path: ${albumPath}`);

            // List all files in the album directory
            const [files] = await admin.storage().bucket().getFiles({ prefix: albumPath });

            if (files.length === 0) {
                console.log(`No files found in album path ${albumPath}`);
                return res.status(404).json({ message: `Album not found.` });
            }

            // Create a promise to delete each file in the album
            const deletePromises = files.map(file => file.delete());

            // Wait for all files to be deleted
            await Promise.all(deletePromises);

            console.log(`Successfully deleted album at path ${albumPath}`);
            return res.status(200).json({ message: `Album successfully deleted.` });
        } catch (error) {
            console.error(`Error deleting album at path ${albumPath}:`, error);
            return res.status(500).json({ message: 'Error deleting album.', error: error.message });
        }
    }


    static async createAlbum(req, res) {
        console.log("createAlbum",req.body);
        try {
            const { user, startDate, endDate, numPhotos , albumName } = req.body;
            const files = req.files; // Files array from the request

            if (!user || !Array.isArray(files) || !startDate || !endDate || !numPhotos || isNaN(numPhotos)) {
                return res.status(400).json({ message: 'Invalid input parameters' });
            }

            // Load face detection models
            await FaceService.loadModels();

            // Extract face IDs from the uploaded files
            const faceIds = await PhotoService.getFaceIdsFromFiles(files , user);

            // Retrieve and filter photos within the date range by face IDs
            const filteredPhotos = await PhotoService.getFilteredPhotos(user, startDate, endDate, faceIds);

            // Create the album with up to 'numPhotos' photos
            const albumPath = await PhotoService.createAlbum(user, filteredPhotos, parseInt(numPhotos, 10),albumName);
            console.log("done! ",albumPath);
            return res.status(200).json({ message: 'Album created successfully', albumPath });
        } catch (error) {
            console.error('Error creating album:', error);
            return res.status(500).json({ message: 'Error creating album', error: error.message });
        }
    }
}

module.exports = AlbumController;

// class AlbumController {
//     static async createAlbum(req, res) {
//         console.log("req body: ", req.body);
//         console.log("req file: ", req.files);

//         // Files should be available in req.files
//         if (!req.files || req.files.length === 0) {
//             return res.status(400).json({ error: 'No files were uploaded.' });
//         }

//         // Process files and other fields as needed
//         res.status(200).json({ message: 'Files received!' });

//         // try {

//             // console.log("req body: " ,req.body);
//             // console.log("req photo : " ,req.body.photo);
//     //         const user = req.body.user;
//     //         const startDate = req.body.startDate;
//     //         const endDate = req.body.endDate;
//     //         const numPhotos = req.body.numPhotos;

//     //          // Load face detection models
//     //          await FaceService.loadModels();

//     //          // Retrieve photos within the date range
//     //          const photos = await PhotoService.getPhotosWithinDateRange(user, startDate, endDate);
 
//     //          // Retrieve known face encodings
//     //          const faceEncodings = await PhotoService.getFaceEncodings(user);
 
//     //          // Process photos and filter them by matching faces
//     //          const filteredPhotos = await PhotoService.processAndFilterPhotos(user, photos, faceEncodings);
 
//     //          // Create the album with up to 'x' photos
//     //          const albumPath = await PhotoService.createAlbum(user, filteredPhotos, numPhotos);
 
//     //          return res.status(200).json({ message: 'Album created successfully', albumPath });
//     //      } catch (error) {
//     //          console.error('Error creating album:', error); // Improved error logging
//     //          return res.status(500).json({ message: 'Error creating album', error: error.message });
//     //      }
//     }
//  }
 
//  module.exports = AlbumController;