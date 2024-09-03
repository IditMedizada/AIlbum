const { bucket } = require('../firebaseConfig');
const path = require('path');
const os = require('os');
const fs = require('fs');

class FirebaseService {
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

    static async isPhotoProcessed(filePath) {
        try {
            const [metadata] = await bucket.file(filePath).getMetadata();
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

