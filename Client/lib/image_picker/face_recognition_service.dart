import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:mime/mime.dart';

class FaceRecognitionService {
  final String _baseUrl = 'http://127.0.0.1:5000/recognize'; // Replace with your backend URL

  Future<List<String>> recognizeFaces(File userImage, List<File> galleryImages) async {
    final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));

    request.files.add(await http.MultipartFile.fromPath('user_image', userImage.path));

    for (var galleryImage in galleryImages) {
      request.files.add(await http.MultipartFile.fromPath('gallery_images', galleryImage.path));
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final decodedResponse = jsonDecode(responseBody);
      return List<String>.from(decodedResponse['matched_images']);
    } else {
      throw Exception('Failed to recognize faces');
}
}
}