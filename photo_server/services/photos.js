const faceapi = require('face-api.js');
const canvas = require('canvas');
const path = require('path');
const fs = require('fs');
const firebaseService = require('../services/firebaseService');

// Load Face API models
const MODEL_URL = path.join(__dirname, '../models');
Promise.all([
  faceapi.nets.ssdMobilenetv1.loadFromDisk(MODEL_URL),
  faceapi.nets.faceLandmark68Net.loadFromDisk(MODEL_URL),
  faceapi.nets.faceRecognitionNet.loadFromDisk(MODEL_URL)
]).then(() => console.log('Face API models loaded'));

const knownFaceEncodings = [];
const knownFaceIds = [];

exports.processImage = async (imageBase64) => {
  const imageBuffer = Buffer.from(imageBase64, 'base64');
  const image = await canvas.loadImage(imageBuffer);
  
  const detections = await faceapi.detectAllFaces(image)
    .withFaceLandmarks()
    .withFaceDescriptors();

  const faceIds = [];
  for (const detection of detections) {
    const faceEncoding = detection.descriptor;
    const distances = faceapi.faceDistance(knownFaceEncodings, faceEncoding);
    const bestMatchIndex = distances.indexOf(Math.min(...distances));

    if (distances[bestMatchIndex] < 0.6) {
      faceIds.push(knownFaceIds[bestMatchIndex]);
    } else {
      const newId = (knownFaceEncodings.length + 1).toString();
      knownFaceEncodings.push(faceEncoding);
      knownFaceIds.push(newId);
      faceIds.push(newId);
    }
  }

  return { faceIds };
};






// const express = require('express');
// const bodyParser = require('body-parser');
// const admin = require('firebase-admin');
// const faceapi = require('face-api.js');
// const canvas = require('canvas');
// const fs = require('fs');
// const path = require('path');
// const serviceAccount = require('./firebase_credentials.json');

// const Photo = require('../models/photo.js');
// const CONNECTION_STRING="mongodb://127.0.0.1:27017/allbum"

// const addPhoto = async(date, file) =>{
//  try{
//         console.log("this is date" + date);
//         console.log("this is file:" + file);
//         const photo = new Photo({
//             photo : file.originalname,
//             date : date,
//         });

//         return await photo.save();

//     }catch (error){
//         console.log('Something went wrong' + error);

//     }    
// };
//     // try{
//     //     console.log("jjjjjj");
//     //     const photo = new Photo({
//     //         photo : file.originalname,
//     //         date : date,
//     //     });

//     //     return await photo.save();

//     // }catch (error){
//     //     console.log('Something went wrong' + error);

//     // }    



// // Initialize Firebase Admin SDK
// admin.initializeApp({
//   credential: admin.credential.cert(serviceAccount),
//   databaseURL: 'https://your-database-name.firebaseio.com/'  // Replace with your Firebase Realtime Database URL
// });

// const facesRef = admin.database().ref('faces');
// const photosRef = admin.storage().bucket().file('photos'); // Firebase Storage bucket reference

// // Set up Face API with Canvas
// faceapi.env.monkeyPatch({ Canvas: canvas.Canvas, Image: canvas.Image, ImageData: canvas.ImageData });

// // Load Face API Models
// const MODEL_URL = path.join(__dirname, '/models'); // Path to face-api.js models
// Promise.all([
//   faceapi.nets.ssdMobilenetv1.loadFromDisk(MODEL_URL),
//   faceapi.nets.faceLandmark68Net.loadFromDisk(MODEL_URL),
//   faceapi.nets.faceRecognitionNet.loadFromDisk(MODEL_URL)
// ]).then(() => console.log('Models loaded'));

// // Initialize Express
// const app = express();
// app.use(bodyParser.json({ limit: '50mb' }));
// app.use(bodyParser.urlencoded({ extended: true }));

// // Load known faces from Firebase
// async function loadKnownFaces() {
//   const snapshot = await facesRef.once('value');
//   const facesData = snapshot.val() || {};
//   const knownFaceEncodings = [];
//   const knownFaceIds = [];

//   for (const faceId in facesData) {
//     const face = facesData[faceId];
//     knownFaceIds.push(face.id);
//     knownFaceEncodings.push(face.encoding);
//   }

//   return { knownFaceEncodings, knownFaceIds };
// }

// let knownFaceEncodings = [];
// let knownFaceIds = [];
// loadKnownFaces().then(result => {
//   knownFaceEncodings = result.knownFaceEncodings;
//   knownFaceIds = result.knownFaceIds;
// });

// // Endpoint to handle image upload and face recognition
// app.post('/upload', async (req, res) => {
//   try {
//     const { imageBase64 } = req.body;

//     if (!imageBase64) {
//       return res.status(400).json({ error: 'No image data provided' });
//     }

//     // Decode base64 image
//     const imageBuffer = Buffer.from(imageBase64, 'base64');
//     const image = await canvas.loadImage(imageBuffer);

//     // Detect faces in the image
//     const detections = await faceapi.detectAllFaces(image)
//       .withFaceLandmarks()
//       .withFaceDescriptors();

//     const faceIds = [];
//     for (const detection of detections) {
//       const faceEncoding = detection.descriptor;

//       // Compare face descriptors with known faces
//       const distances = faceapi.faceDistance(knownFaceEncodings, faceEncoding);
//       const bestMatchIndex = distances.indexOf(Math.min(...distances));

//       if (distances[bestMatchIndex] < 0.6) { // Adjust threshold as needed
//         faceIds.push(knownFaceIds[bestMatchIndex]);
//       } else {
//         const newId = (knownFaceEncodings.length + 1).toString();
//         knownFaceEncodings.push(faceEncoding);
//         knownFaceIds.push(newId);
//         facesRef.push({
//           id: newId,
//           encoding: Array.from(faceEncoding) // Convert to array for Firebase storage
//         });
//         faceIds.push(newId);
//       }
//     }

//     // Save the photo to Firebase Storage
//     const photoFile = path.join(__dirname, 'uploads', `${Date.now()}.jpg`);
//     fs.writeFileSync(photoFile, imageBuffer);
//     await admin.storage().bucket().upload(photoFile, {
//       destination: `photos/${Date.now()}.jpg`
//     });
//     fs.unlinkSync(photoFile); // Remove local file after upload

//     res.json({ face_ids: faceIds });
//   } catch (error) {
//     console.error(error);
//     res.status(500).json({ error: 'An error occurred during face recognition' });
//   }
// });

// const PORT = process.env.PORT || 3000;
// app.listen(PORT, () => {
//   console.log(`Server is running on port ${PORT}`);
// });



// module.exports = { addPhoto };