const faceapi = require('face-api.js');
const { v4: uuidv4 } = require('uuid');
const canvas = require('canvas');
const path = require('path');
const { Canvas, Image, ImageData } = canvas;
faceapi.env.monkeyPatch({ Canvas, Image, ImageData });
const MODEL_URL = path.join(__dirname, '../models');
const FaceEncodingModel = require('../models/faceEncodingModel');

Promise.all([
    faceapi.nets.tinyFaceDetector.loadFromDisk(MODEL_URL),
    faceapi.nets.faceLandmark68Net.loadFromDisk(MODEL_URL),
    faceapi.nets.ssdMobilenetv1.loadFromDisk(MODEL_URL),
    faceapi.nets.faceRecognitionNet.loadFromDisk(MODEL_URL)
    ]);

class FaceService {
    static async loadModels() {
        Promise.all([
            faceapi.nets.tinyFaceDetector.loadFromDisk(MODEL_URL),
            faceapi.nets.faceLandmark68Net.loadFromDisk(MODEL_URL),
            faceapi.nets.ssdMobilenetv1.loadFromDisk(MODEL_URL),
            faceapi.nets.faceRecognitionNet.loadFromDisk(MODEL_URL)
            ]);
    }
    
    static async processFaces(img,photoPath) {
        const detections = await faceapi.detectAllFaces(img)
            .withFaceLandmarks()
            .withFaceDescriptors();

        const faceEncodings = await FaceEncodingModel.getFaceEncodings();
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
                await FaceEncodingModel.saveFaceEncoding(faceId, descriptor,photoPath);
            }

            faceIds.push(faceId);
        }

        return faceIds;
    }
}

module.exports = FaceService;
