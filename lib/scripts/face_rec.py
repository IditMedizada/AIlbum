from flask import Flask, request, jsonify
import face_recognition
import numpy as np
from PIL import Image
import io

face_rec = Flask(_name_)

@face_rec.route('/recognize', methods=['POST'])
def recognize():
    # Get the user's image
    user_image_file = request.files['user_image']
    user_image = face_recognition.load_image_file(user_image_file)
    user_face_encodings = face_recognition.face_encodings(user_image)
    
    if not user_face_encodings:
        return jsonify({"error": "No faces found in the user image"}), 400
    
    user_face_encoding = user_face_encodings[0]

    matched_images = []

    # Get gallery images
    gallery_image_files = request.files.getlist('gallery_images')

    for gallery_image_file in gallery_image_files:
        gallery_image = face_recognition.load_image_file(gallery_image_file)
        gallery_face_encodings = face_recognition.face_encodings(gallery_image)

        for gallery_face_encoding in gallery_face_encodings:
            matches = face_recognition.compare_faces([user_face_encoding], gallery_face_encoding)
            if True in matches:
                matched_images.append(gallery_image_file.filename)
                break

    return jsonify({"matched_images": matched_images})

if _name_ == '_main_':
    face_rec.run(debug=True)