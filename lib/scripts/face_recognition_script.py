import face_recognition
from typing import List
import os

def load_image_file(file_path: str):
    return face_recognition.load_image_file(file_path)

def get_face_encodings(image):
    return face_recognition.face_encodings(image)

def compare_faces(known_face_encodings, face_encoding_to_check):
    return face_recognition.compare_faces(known_face_encodings, face_encoding_to_check)

def filter_images_with_face(known_face_encoding, image_paths: List[str]) -> List[str]:
    filtered_images = []
    for image_path in image_paths:
        image = load_image_file(image_path)
        face_encodings = get_face_encodings(image)
        if any(compare_faces([known_face_encoding], face_encoding) for face_encoding in face_encodings):
            filtered_images.append(image_path)
    return filtered_images

# Example usage
if __name__ == "__main__":
    known_image_path = "path_to_known_image.jpg"
    image_paths = ["path_to_image1.jpg", "path_to_image2.jpg", ...]

    known_image = load_image_file(known_image_path)
    known_face_encodings = get_face_encodings(known_image)

    if known_face_encodings:
        known_face_encoding = known_face_encodings[0]
        filtered_images = filter_images_with_face(known_face_encoding, image_paths)
        print(filtered_images)
