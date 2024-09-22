const { bucket } = require('../firebaseConfig');
const path = require('path');
const os = require('os');
const fs = require('fs');

class FirebaseService {
    static async getAllFaceEncodings(user) {
        const faceEncodingsFolder = `${user}/face_encodings/`;
        const [files] = await bucket.getFiles({ prefix: faceEncodingsFolder });

        const faceEncodings = await Promise.all(
            files.map(async (file) => {
                const [metadata] = await file.getMetadata();
                const faceId = path.basename(file.name, '.json'); // Assuming faceId is the file name
                const photos = JSON.parse(metadata.metadata.photos); // Assuming photos are stored in metadata

                return { faceId, photos };
            })
        );

        return faceEncodings;
    }

    static async downloadImage(filePath) {
        const tempFilePath = path.join(os.tmpdir(), path.basename(filePath));
        await bucket.file(filePath).download({ destination: tempFilePath });
        return tempFilePath;
    }

    static async updatePhotoMetadata(filePath, faceIds) {
        await bucket.file(filePath).setMetadata({
            metadata: {
                processed: 'true',
                faceIds: JSON.stringify(faceIds)
            }
        });
    }

    static isPhotoProcessed(filePath) {
        try {
            const [metadata] = bucket.file(filePath).getMetadata();
            return metadata.metadata && metadata.metadata.processed === 'true';
        } catch (error) {
            // Handle the case where the metadata or file doesn't exist
            return false;
        }
    }

    static cleanUp(tempFilePath) {
        fs.unlinkSync(tempFilePath);
    }
}


module.exports = FirebaseService;
