const faceapi = require('face-api.js');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const FirebaseService = require('../services/firebaseServices');
const { Canvas, Image, ImageData } = require('canvas');
faceapi.env.monkeyPatch({ Canvas, Image, ImageData });
const FaceEncodingModel = require('../models/faceEncodingModel');

// Load models
const MODEL_URL = path.join(__dirname, '../models');
faceapi.env.monkeyPatch({ Canvas, Image, ImageData });

class FaceService {
    // Load models for face detection and recognition
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
