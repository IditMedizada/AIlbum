import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/features/user_auth/presentations/pages/albums.dart';
import 'dart:io';

import 'package:my_app/features/user_auth/presentations/pages/photoDisplayPage.dart';
bool isLoading = false; 

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
  final adjustedEndDate = endDate?.add(const Duration(hours: 23, minutes: 59, seconds: 59));
  final uri = Uri.parse('http://192.168.1.36:5000/api/photos/create-album');
  String? user = FirebaseAuth.instance.currentUser?.uid;
  var request = http.MultipartRequest('POST', uri)
    ..fields['user'] = user ?? ''
    ..fields['startDate'] = startDate?.toIso8601String() ?? ''
    ..fields['endDate'] = adjustedEndDate?.toIso8601String() ?? ''
    ..fields['numPhotos'] = photoCount.toString()
    ..fields['albumName'] = albumNameController.text;

 for (var image in selectedImages) {
    request.files.add(await http.MultipartFile.fromPath('photos', image.path));
}

  setState(() {
      isLoading = true; // Set loading to true before the request
    });
  var response = await request.send();

  if (response.statusCode == 200) {
    final responseBody = await response.stream.bytesToString();
    final responseData = jsonDecode(responseBody);
    final albumId = responseData['albumPath']; 
    setState(() {
      isLoading = false; // Set loading to false after the request
    });    // Navigate to the photo display page with the albumId
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoDisplayPage(albumId: albumId, albumName: albumNameController.text),
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
Widget build(BuildContext context) {
  // Define a common button style
  final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: Colors.blue,
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
  );

  return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Albums()),
            (route) => false,
          );
        },
      ),
      title: const Text('Create Album'),
    ),
    body:   
    SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SizedBox(
                width: 250,
                child: TextField(
                  controller: albumNameController,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: 'Add a title',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              width: double.infinity,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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

            ElevatedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Select photo'),
              style: buttonStyle,
            ),
            const SizedBox(height: 16),

            // Start and End date selection side by side
            const Text(
              'Select Dates',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => selectDate(context, true),
                    icon: const Icon(Icons.calendar_today, color: Colors.white),
                    label: Text(startDate == null
                        ? 'Start Date'
                        : DateFormat('yyyy-MM-dd').format(startDate!)),
                    style: buttonStyle,
                  ),
                ),
                const SizedBox(width: 10), // Add some spacing
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => selectDate(context, false),
                    icon: const Icon(Icons.calendar_today, color: Colors.white),
                    label: Text(endDate == null
                        ? 'End Date'
                        : DateFormat('yyyy-MM-dd').format(endDate!)),
                    style: buttonStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'Select Number of Photos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),            
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

            Center(
              child: isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: pickersubmitData,
                      style: buttonStyle,
                      child: const Text('Continue'),
                    ),
            ),
          ],
        ),
      ),
    ),
      
  );
}

}



