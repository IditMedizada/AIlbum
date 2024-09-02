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

    static cleanUp(tempFilePath) {
        fs.unlinkSync(tempFilePath);
    }
}

module.exports = FirebaseService;
