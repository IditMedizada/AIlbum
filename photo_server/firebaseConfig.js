const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.cert(require('./ailbum-firebase-adminsdk-dg0c0-43b2fbeb0a.json')),
  storageBucket: 'gs://ailbum.appspot.com', 
});

const bucket = admin.storage().bucket();
const firestore = admin.firestore();

module.exports = { admin, bucket, firestore };
