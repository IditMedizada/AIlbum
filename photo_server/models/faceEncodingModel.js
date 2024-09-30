const { bucket } = require('../firebaseConfig');
const path = require('path');
const expectedEncodingLength = 128;
class FaceEncodingModel {
    // Save a new face encoding or update an existing one
    static async saveFaceEncoding(faceId, descriptor, photoPath) {
     

        const baseFolderPathup = photoPath.substring(0, photoPath.lastIndexOf('/'));
        const baseFolderPath = baseFolderPathup.substring(0, baseFolderPathup.lastIndexOf('/')) + '/face_encodings';
        const encodingFilePath = `${baseFolderPath}/${faceId}.json`;
    
        // Check descriptor length
        if (descriptor.length !== expectedEncodingLength) {
            throw new Error(`Invalid descriptor length: expected ${expectedEncodingLength}, got ${descriptor.length}`);
        }
    
        let faceData = { descriptor, photos: [photoPath] };
    
        try {
            const [exists] = await bucket.file(encodingFilePath).exists();
            if (exists) {
                const [content] = await bucket.file(encodingFilePath).download();
                const existingData = JSON.parse(content);
                faceData = {
                    ...existingData,
                    photos: Array.from(new Set([...existingData.photos, photoPath])) // Avoid duplicates
                };
            }
        } catch (error) {
            console.error(`Error checking face encoding: ${error.message}`);
        }
    
        await bucket.file(encodingFilePath).save(JSON.stringify(faceData), {
            contentType: 'application/json'
        });
    }
    

    // Add a new photo to an existing face encoding
    static async addPhotoToFace(faceId, photoPath) {
        console.log("in addPhotoToFace");
    
        const baseFolderPathup = photoPath.substring(0, photoPath.lastIndexOf('/'));
        const baseFolderPath = baseFolderPathup.substring(0, baseFolderPathup.lastIndexOf('/')) + '/face_encodings';
    
        // Construct the path for the face encoding file
        const encodingFilePath = `${baseFolderPath}/${faceId}.json`;
    
        try {
            // Retrieve the current metadata
            const [metadata] = await bucket.file(encodingFilePath).getMetadata();
            let photos = metadata.metadata && metadata.metadata.photos 
                ? JSON.parse(metadata.metadata.photos) 
                : [];
    
            // Add the new photo path if it's not already in the array
            if (!photos.includes(photoPath)) {
                photos.push(photoPath);
    
                // Update the metadata with the new photos array
                await bucket.file(encodingFilePath).setMetadata({
                    metadata: {
                        photos: JSON.stringify(photos)
                    }
                });
                console.log("photos for id: ",faceId," are: ", photos);
                console.log(`Updated face encoding with new photo path: ${photoPath}`);
            }
        } catch (error) {
            console.error(`Error updating face encoding: ${error.message}`);
        }
    }
    
    static async getAllFaceEncodingsForUser(user) {
        const faceEncodingsFolder = `${user}/face_encodings/`;
        console.log(`Fetching face encodings from: ${faceEncodingsFolder}`); // Log the path being used
    
        const [files] = await bucket.getFiles({ prefix: faceEncodingsFolder });
        console.log(`Number of files found: ${files.length}`); // Log the number of files found in Firebase
    
        const faceEncodings = await Promise.all(
            files.map(async (file) => {
                const [content] = await file.download();
                const encoding = JSON.parse(content);
                console.log(`Fetched encoding for faceId ${path.basename(file.name, '.json')}`); // Log each faceId
                return {
                    faceId: path.basename(file.name, '.json'),
                    descriptor: encoding.descriptor,
                };
            })
        );
    
        console.log(`Total face encodings fetched: ${faceEncodings.length}`); // Log the number of encodings fetched
        return faceEncodings;
    }
    

    // Retrieve all face encodings
    static async getFaceEncodings(photoPath) {
        const baseFolderPathup = photoPath.substring(0, photoPath.lastIndexOf('/'));
        const baseFolderPath = baseFolderPathup.substring(0, baseFolderPathup.lastIndexOf('/')) + '/face_encodings/';
        console.log("baseFolderPath: ", baseFolderPath);
        const [files] = await bucket.getFiles({ prefix: baseFolderPath });
        const faceEncodings = [];
    
        for (const file of files) {
            try {
                const [content] = await file.download();
                const contentStr = content.toString('utf8');
                
                try {
                    const jsonContent = JSON.parse(contentStr);
                  
                    // Validate descriptor length
                    if (!Array.isArray(jsonContent.descriptor) || jsonContent.descriptor.length !== expectedEncodingLength) {
                        console.warn(`Invalid descriptor length for file ${file.name}`);
                        continue; // Skip invalid file
                    }
                    
                    faceEncodings.push({
                        faceId: path.basename(file.name, '.json'),
                        descriptor: jsonContent.descriptor
                    });
                } catch (parseError) {
                    console.error(`Failed to parse JSON for file ${file.name}:`, parseError);
                }
            } catch (e) {
                console.error("Error processing file: ", e);
            }
        }
    
        return faceEncodings;
    }
    
    
}

module.exports = FaceEncodingModel;
