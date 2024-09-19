const { Canvas, Image, ImageData, loadImage } = require('canvas'); // Import loadImage explicitly
const faceapi = require('face-api.js');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const FaceEncodingModel = require('../models/faceEncodingModel');

faceapi.env.monkeyPatch({ Canvas, Image, ImageData });

const MODEL_URL = path.join(__dirname, '../models');

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
    static async processFaces(filePath, photoPath) {
        const detections = await faceapi.detectAllFaces(filePath)
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
                await FaceEncodingModel.addPhotoToFace(faceId, photoPath);
            } else {
                faceId = uuidv4();
                await FaceEncodingModel.saveFaceEncoding(faceId, descriptor, photoPath); // Save new face encoding with photo path
                // Always add the current photo path to the face encoding
                await FaceEncodingModel.addPhotoToFace(faceId, photoPath);
                
            }
            
            faceIds.push(faceId);
        }

        return faceIds;
    }
}

module.exports = FaceService;
