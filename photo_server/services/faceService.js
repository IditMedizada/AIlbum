const faceapi = require('face-api.js');
//A library that provides deep learning-based face detection, face landmark detection,
// and face recognition capabilities.
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const { Canvas, Image, ImageData } = require('canvas');
faceapi.env.monkeyPatch({ Canvas, Image, ImageData });
const FaceEncodingModel = require('../models/faceEncodingModel');

// Load models
const MODEL_URL = path.join(__dirname, '../models');
faceapi.env.monkeyPatch({ Canvas, Image, ImageData });
//This is used to "monkey patch" (i.e., extend) the environment so that face-api.js
// can work with the Canvas, Image, and ImageData objects from the canvas library.
// This makes the face-api.js library compatible with Node.js 
//(since it's designed to work with HTML elements in browsers).

class FaceService {
    // Loads the pre-trained face detection and recognition models from the local directory.
    static async loadModels() {
        await Promise.all([
            faceapi.nets.tinyFaceDetector.loadFromDisk(MODEL_URL),
            faceapi.nets.faceLandmark68Net.loadFromDisk(MODEL_URL),
            faceapi.nets.ssdMobilenetv1.loadFromDisk(MODEL_URL),
            faceapi.nets.faceRecognitionNet.loadFromDisk(MODEL_URL)
        ]);
    }

    // Process faces in the image and associate them with the photo
    static async processFaces(image, photoPath, user) {
        const detections = await faceapi.detectAllFaces(image)
            .withFaceLandmarks()
            .withFaceDescriptors();

        const faceEncodings = await FaceEncodingModel.getFaceEncodings(photoPath);
        const faceIds = [];

        for (const detection of detections) {
            const descriptor = Array.from(detection.descriptor);
            let matchingFaceId = null;

            for (const face of faceEncodings) {
                const distance = faceapi.euclideanDistance(new Float32Array(face.descriptor), descriptor);
                if (distance < 0.6) {
                    matchingFaceId = face.faceId;
                    break;
                }
            }

            let faceId;
            if (matchingFaceId) {
                faceId = matchingFaceId;
                await FaceEncodingModel.addPhotoToFace(faceId, photoPath);
            } else {
                faceId = uuidv4();
                await FaceEncodingModel.saveFaceEncoding(faceId, descriptor, photoPath);
                await FaceEncodingModel.addPhotoToFace(faceId, photoPath);
            }

            faceIds.push(faceId);
        }

        return faceIds;
    }
}

module.exports = FaceService;
