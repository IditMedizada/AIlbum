const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
admin.initializeApp({
    credential: admin.credential.cert(require('../ailbum-firebase-adminsdk-dg0c0-6270a59933.json')),
    storageBucket: 'gs://ailbum.appspot.com', // Replace with your bucket name
});

const bucket = admin.storage().bucket();

exports.uploadPhotoToFirebase = async (buffer, filename, user, faceIds,date) => {
    try {

        const file = bucket.file(`photos/${user}/${filename}`);
        await file.save(buffer);
        // Set metadata including face IDs
        const metadata = {
            metadata: {
                faceIds: JSON.stringify(faceIds), 
                user: user,
                date: date
            }
        };
        await file.setMetadata(metadata);
        return `https://storage.googleapis.com/${bucket.name}/photos/${user}/${filename}`;
    } catch (error) {
        console.error("Error uploading photo to Firebase Storage:", error);
        throw error;
}
};

exports.uploadKnownFacesToFirebase = async (knownFaces, knownFaceEncodings, user) => {
    try {
        console.log("known faces start " + knownFaces);
        const file = bucket.file(`known_faces/${user}/${knownFaces}`);
        const buffer = Buffer.from(JSON.stringify(knownFaceEncodings));
        await file.save(buffer);
        
        // Set metadata
        const metadata = {
            metadata: {
                contentType: 'application/json',  // Set the appropriate content type
                metadata: {
                    user: user,
                    knownFacesId: knownFaces
                }
            }
        };
        await file.setMetadata(metadata);
        
        return `https://storage.googleapis.com/${bucket.name}/known_faces/${user}/${knownFaces}`;
    } catch (error) {
        console.error("Error uploading known faces to Firebase Storage:", error);
        throw error;
    }
};


exports.addPhotoMetadataToFirebase = async (photoUrl, faceIds) => {
    try {
        console.log("biiiiii");
        console.log("faceId  " + faceIds);
        const db = admin.database();
        console.log("heree1");
        const ref = db.ref('photos').push();
        console.log("heree2");
        await ref.set({
            photoUrl,
            faceIds,
            timestamp: admin.database.ServerValue.TIMESTAMP,
        });
        console.log("end biiiii 1");
    } catch (error) {
        console.error("Error in addPhotoMetadataToFirebase:", error);
    }

};


exports.viewFileContent = async(user) =>{
    try {
        const file = bucket.file(`known_faces/${user}/1`);
        const [contents] = await file.download();
        console.log('File content:', contents.toString('utf-8'));
    } catch (error) {
        console.error('Error reading file:', error);
    }
};

