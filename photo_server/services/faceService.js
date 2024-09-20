const { Canvas, Image, ImageData } = require('canvas');
const faceapi = require('face-api.js');
const path = require('path');
const FaceEncodingModel = require('../models/faceEncodingModel');
faceapi.env.monkeyPatch({ Canvas, Image, ImageData });
const MODEL_URL = path.join(__dirname, '../models');
const { v4: uuidv4 } = require('uuid');
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

    static async processFaces(filePath, photoPath) {
        try {
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
                    faceId = uuidv4(); // Generate a new unique face ID
                    await FaceEncodingModel.saveFaceEncoding(faceId, descriptor, photoPath);
                }

                faceIds.push(faceId);
            }

            return faceIds;
        } catch (error) {
            console.error('Error processing faces:', error);
            throw error;
        }
    }
}



module.exports = FaceService;
