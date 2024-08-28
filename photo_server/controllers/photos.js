const { uploadPhotoToFirebase, uploadKnownFacesToFirebase,viewFileContent } = require('../services/firebaseService');
const { processImage } = require('../services/faceRecognitionService');

exports.addPhoto = async (req, res) => {
    try {
        const file = req.file;
        const date = req.body.date;
        const user = req.body.user;
        console.log(user +" " + date);
        
        if (!file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }

        // Save the uploaded file to disk (optional) or process directly
        const buffer = file.buffer; // Get the file buffer
        const originalName = file.originalname;

        // Detect faces in the uploaded photo
        const faceIdsResult = await processImage(buffer);
        console.log("face: ", faceIdsResult.faceIds);

        // Upload photo to Firebase Storage
        const photoUrl = await uploadPhotoToFirebase(buffer, originalName,user, faceIdsResult.faceIds,date );
        console.log("before known" + photoUrl);
        const knownUrl = await uploadKnownFacesToFirebase(faceIdsResult.knownFaceIds.at(-1),faceIdsResult.knownFaceEncodings.at(-1),user );
        
        // Save metadata to Firebase Realtime Database
        // await addPhotoMetadataToFirebase(photoUrl, faceIdsResult.faceIds);
       
        console.log("after known  " + knownUrl);
        console.log("   \n");
        await viewFileContent(user);
        return res.status(200).json({ photoUrl, faceIds });
    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
};

// const addPhoto = async (req, res) => {
//     try{
//         console.log("ffff");
//         console.log(req.body);
//         const date = req.body.date;
//         console.log(date);
//         photo = req.file
//         console.log(photo.originalname);
//         await photosServices.addPhoto(date, req.file);
//         res.status(200).json();
//     }catch (error){
//         res.status(500).json({ error: 'Something went wrong' });
//     }
// }








