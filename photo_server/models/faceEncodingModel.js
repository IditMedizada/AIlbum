const { bucket } = require('../firebaseConfig');

class FaceEncodingModel {
    static async saveFaceEncoding(faceId, descriptor,photoPath) {
        const baseFolderPathup = photoPath.substring(0, photoPath.lastIndexOf('/'));
        const baseFolderPath = baseFolderPathup.substring(0, baseFolderPathup.lastIndexOf('/')) + '/face_encodings';

        // Construct the path for the face encoding file
        const encodingFilePath = `${baseFolderPath}/${faceId}.json`;
        await bucket.file(encodingFilePath).save(JSON.stringify(descriptor), {
            contentType: 'application/json'
        });
    }

    static async getFaceEncodings() {
        const [files] = await bucket.getFiles({ prefix: 'face_encodings/' });
        const faceEncodings = [];

        for (const file of files) {
            const [content] = await file.download();
            faceEncodings.push({
                faceId: file.name.split('/')[1].replace('.json', ''),
                descriptor: JSON.parse(content)
            });
        }

        return faceEncodings;
    }
}

module.exports = FaceEncodingModel;
