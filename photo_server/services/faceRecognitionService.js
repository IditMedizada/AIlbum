const faceapi = require('face-api.js');
const canvas = require('canvas');
const path = require('path');
const firebaseService = require('../services/firebaseService');

// Monkey patch the canvas library for face-api.js
const { Canvas, Image, ImageData } = canvas;
faceapi.env.monkeyPatch({ Canvas, Image, ImageData });

// Load Face API models
const MODEL_URL = path.join(__dirname, '../models');
Promise.all([
  faceapi.nets.tinyFaceDetector.loadFromDisk(MODEL_URL),
  faceapi.nets.faceLandmark68Net.loadFromDisk(MODEL_URL),
  faceapi.nets.faceRecognitionNet.loadFromDisk(MODEL_URL)
]).then(() => console.log('Face API models loaded'));

// Known face encodings and IDs
const knownFaceEncodings = [];
const knownFaceIds = [];

exports.processImage = async (imageBase64) => {
  try {
    // Convert base64 string to a buffer
    const imageBuffer = Buffer.from(imageBase64, 'base64');
    // Load image into canvas
    const image = await canvas.loadImage(imageBuffer);
    const canvasImage = faceapi.createCanvasFromMedia(image);

    // Configure TinyFaceDetector options
    const options = new faceapi.TinyFaceDetectorOptions({ 
      inputSize: 608, 
      scoreThreshold: 0.3 
    });

    // Detect faces and extract face descriptors
    const detections = await faceapi.detectAllFaces(canvasImage, options)
      .withFaceLandmarks()
      .withFaceDescriptors();

    const faceIds = [];
    console.log(`Number of faces detected: ${detections.length}`);

    for (const detection of detections) {
      const faceEncoding = detection.descriptor;

      // Compare detected face with known faces
      const distances = knownFaceEncodings.map(encoding =>
        faceapi.euclideanDistance(encoding, faceEncoding)
      );

      const bestMatchIndex = distances.indexOf(Math.min(...distances));

      if (distances[bestMatchIndex] < 0.6) {
        // Match found
        faceIds.push(knownFaceIds[bestMatchIndex]);
      } else {
        // No match, create a new ID
        const newId = (knownFaceEncodings.length + 1).toString();
        knownFaceEncodings.push(faceEncoding);
        knownFaceIds.push(newId);
        faceIds.push(newId);
      }
    }
    console.log("Known faces: " + knownFaceIds);
    console.log("ID faces: " + faceIds);

    // Return the recognized face IDs
    return { faceIds, knownFaceIds, knownFaceEncodings };
  } catch (error) {
    console.error('Error processing image:', error);
    throw error;
  }
};
