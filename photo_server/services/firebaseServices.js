const { bucket } = require('../firebaseConfig');
const path = require('path');
const os = require('os');
const fs = require('fs');
const { Storage } = require('@google-cloud/storage');
const storage = new Storage({
    retryOptions: {
        maxRetries: 5, // Limit the number of retries
        retryDelayMultiplier: 2, // Exponential backoff
        maxRetryDelay: 120 * 1000, // Max delay between retries (2 minutes)
        totalTimeout: 1800, // Total timeout for all retries (30 minutes)
    },
    // Increase default HTTP client timeout
    clientOptions: {
        timeout: 15 * 60 * 1000, // 15 minutes timeout
    },
});

// Retry options
const options = {
    resumable: true, // Enable resumable uploads
    validation: false, // Disable validation for better speed
    timeout: 15 * 60 * 1000, // 15-minute timeout per upload
};

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
                faceIds: JSON.stringify(faceIds),
            },
        });
    }

    static isPhotoProcessed(filePath) {
        try {
            const [metadata] = bucket.file(filePath).getMetadata();
            return metadata.metadata && metadata.metadata.processed === 'true';
        } catch (error) {
            return false;
        }
    }

    static cleanUp(tempFilePath) {
        fs.unlinkSync(tempFilePath);
    }

    // Upload with retry logic and extended timeout settings
    static async uploadFileWithRetry(bucketName, filePath, destination) {
        let retryCount = 0;
        const maxRetries = 5; // Set maximum number of retries
        const retryDelay = 5000; // Delay between retries (in milliseconds)

        while (retryCount < maxRetries) {
            try {
                console.log(`Uploading ${filePath} to ${bucketName} (Attempt ${retryCount + 1})...`);

                await storage.bucket(bucketName).upload(filePath, {
                    destination: destination,
                    ...options,
                });

                console.log(`${filePath} uploaded to ${bucketName} successfully.`);
                break;
            } catch (error) {
                if (error.code === 'ECONNRESET' || error.code === 'ENOTFOUND' || error.code === 'ECONNABORTED') {
                    retryCount++;
                    console.log(`Retrying upload (${retryCount}/${maxRetries}) due to ECONNRESET or network issues...`);
                    await new Promise((res) => setTimeout(res, retryDelay));
                } else if (error.message.includes('Client network socket disconnected before secure TLS connection was established')) {
                    retryCount++;
                    console.log(`Retrying upload (${retryCount}/${maxRetries}) due to TLS connection issue...`);
                    await new Promise((res) => setTimeout(res, retryDelay));
                } else {
                    console.error('Upload failed:', error);
                    break; // Break if the error is not retryable
                }
            }
        }

        if (retryCount === maxRetries) {
            console.error(`Failed to upload ${filePath} after ${maxRetries} attempts.`);
        }
    }
}


module.exports = FirebaseService;