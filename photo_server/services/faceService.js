const faceapi = require('face-api.js');
const { v4: uuidv4 } = require('uuid');
const canvas = require('canvas');
const path = require('path');
const { Canvas, Image, ImageData } = canvas;
faceapi.env.monkeyPatch({ Canvas, Image, ImageData });

const MODEL_URL = path.join(__dirname, '../models');
const FaceEncodingModel = require('../models/faceEncodingModel');

class FaceService {
    // Load models for use (ensure models are loaded before processing images)
    static async loadModels() {
        await Promise.all([
            faceapi.nets.tinyFaceDetector.loadFromDisk(MODEL_URL),
            faceapi.nets.faceLandmark68Net.loadFromDisk(MODEL_URL),
            faceapi.nets.ssdMobilenetv1.loadFromDisk(MODEL_URL),
            faceapi.nets.faceRecognitionNet.loadFromDisk(MODEL_URL)
        ]);
    }
    
    // Process faces in the image and associate them with photo
    static async processFaces(img, photoPath) {
        const detections = await faceapi.detectAllFaces(img)
            .withFaceLandmarks()
            .withFaceDescriptors();

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
                // Always add the current photo path to the face encoding
                
               
            } else {
                faceId = uuidv4();
                await FaceEncodingModel.saveFaceEncoding(faceId, descriptor, photoPath); // Save new face encoding with photo path
                // Always add the current photo path to the face encoding
            }
            await FaceEncodingModel.addPhotoToFace(faceId, photoPath);

            faceIds.push(faceId);
        }

        return faceIds;
    }
}

module.exports = FaceService;
