const firebaseService = require('../services/firebaseServices');
const faceService = require('../services/faceService');

exports.processImage = async (req, res) => {
    try {
        const { imageUrl } = req.body;
        const faceIds = await faceService.processImage(imageUrl);
        await firebaseService.updateImageMetadata(imageUrl, { faceIds });
        res.status(200).json({ message: 'Image processed successfully', faceIds });
    } catch (error) {
        console.error('Error processing image:', error);
        res.status(500).json({ error: 'Error processing image' });
    }
};
