const { bucket } = require('../firebaseConfig');

class FaceEncodingModel {
    static async saveFaceEncoding(faceId, descriptor) {
        const encodingFilePath = `face_encodings/${faceId}.json`;
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
