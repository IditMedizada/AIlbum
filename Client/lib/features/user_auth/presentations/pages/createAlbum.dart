import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import 'package:my_app/features/user_auth/presentations/pages/photoDisplayPage.dart';

class CreateAlbum extends StatefulWidget {
  const CreateAlbum({super.key});
  
  @override
  CreateAlbumState createState() => CreateAlbumState();
}

class CreateAlbumState extends State<CreateAlbum> {
  final ImagePicker picker = ImagePicker();
  List<File> selectedImages = [];
  DateTime? startDate;
  DateTime? endDate;
  int photoCount = 1;
  final TextEditingController albumNameController = TextEditingController();
  Future<void> pickImage() async {
    final List<XFile> images = await picker.pickMultiImage();
    setState(() {
        selectedImages = images.map((image) => File(image.path)).toList();
    });
  }

  Future<void> pickersubmitData() async {
    if (selectedImages.isEmpty  || startDate == null || endDate == null) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    // Set the endDate to the end of the day
  final adjustedEndDate = endDate?.add(Duration(hours: 23, minutes: 59, seconds: 59));
  final uri = Uri.parse('http://192.168.1.36:5000/api/photos/create-album');
  String? user = FirebaseAuth.instance.currentUser?.uid;
  print("end date:" + (endDate?.toIso8601String() ?? ''));
  var request = http.MultipartRequest('POST', uri)
    ..fields['user'] = user ?? ''
    ..fields['startDate'] = startDate?.toIso8601String() ?? ''
    ..fields['endDate'] = adjustedEndDate?.toIso8601String() ?? ''
    ..fields['numPhotos'] = photoCount.toString()
    ..fields['albumName'] = albumNameController.text;

 for (var image in selectedImages) {
    request.files.add(await http.MultipartFile.fromPath('photos', image.path));
}


  var response = await request.send();

  if (response.statusCode == 200) {
    final responseBody = await response.stream.bytesToString();
    final responseData = jsonDecode(responseBody);
    print('create album response:' + responseData);
    final albumId = responseData['id']; 
    // Navigate to the photo display page with the albumId
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoDisplayPage(albumId: albumId),
      ),
    );
  } else {
    print("Failed to notify server");
  }
  }

  Future<void> selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != (isStartDate ? startDate : endDate)) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  
 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Create Album'),
    ),
    body: SingleChildScrollView( // Make the entire body scrollable
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add TextField for album name
            const Text('Album Name'),
            TextField(
              controller: albumNameController,
              decoration: const InputDecoration(
                hintText: 'Enter album name',
              ),
            ),
            const SizedBox(height: 16),
            selectedImages.isEmpty
                ? const Text('No images selected.')
                : SizedBox( // Wrap in SizedBox to control height
                    height: 200, // Adjust this height as needed
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(), // Disable GridView scrolling to avoid conflicts with SingleChildScrollView
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: selectedImages.length,
                      itemBuilder: (context, index) {
                        return Image.file(
                          selectedImages[index],
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: pickImage,
              child: const Text('Pick Images'),
            ),
            const SizedBox(height: 16),
            const Text('Select Start Date'),
            ElevatedButton(
              onPressed: () => selectDate(context, true),
              child: Text(startDate == null
                  ? 'Select Start Date'
                  : DateFormat('yyyy-MM-dd').format(startDate!)),
            ),
            const SizedBox(height: 16),
            const Text('Select End Date'),
            ElevatedButton(
              onPressed: () => selectDate(context, false),
              child: Text(endDate == null
                  ? 'Select End Date'
                  : DateFormat('yyyy-MM-dd').format(endDate!)),
            ),
            const SizedBox(height: 16),
            const Text('Number of Photos'),
            Slider(
              value: photoCount.toDouble(),
              min: 1,
              max: 100,
              divisions: 99,
              label: photoCount.toString(),
              onChanged: (value) {
                setState(() {
                  photoCount = value.toInt();
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: pickersubmitData,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    ),
  );
}
}