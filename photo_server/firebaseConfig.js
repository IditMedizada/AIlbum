const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.cert(require('./ailbum-firebase-adminsdk-dg0c0-6270a59933.json')),
  storageBucket: 'gs://ailbum.appspot.com', // Replace with your bucket name
});

const bucket = admin.storage().bucket();
const firestore = admin.firestore();

module.exports = { admin, bucket, firestore };
