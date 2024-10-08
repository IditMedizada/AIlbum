// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/features/client_side/presentations/pages/albums.dart';
import 'dart:io';
import 'package:my_app/features/client_side/presentations/pages/photoDisplayPage.dart';
import 'package:my_app/features/client_side/presentations/widgets/BaseScreen.dart';

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
    final List<XFile>? images = await picker.pickMultiImage(); // Allow multiple images to be picked
    if (images != null) {
      setState(() {
        selectedImages = images.map((image) => File(image.path)).toList(); // Add all selected images
      });
    }
  }

  Future<void> pickersubmitData() async {
    if (selectedImages.isEmpty || startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final adjustedEndDate = endDate?.add(const Duration(hours: 23, minutes: 59, seconds: 59));
    final uri = Uri.parse('http://192.168.1.15:5000/api/photos/create-album');
    String? user = FirebaseAuth.instance.currentUser?.uid;

    var request = http.MultipartRequest('POST', uri)
      ..fields['user'] = user ?? ''
      ..fields['startDate'] = startDate?.toIso8601String() ?? ''
      ..fields['endDate'] = adjustedEndDate?.toIso8601String() ?? ''
      ..fields['numPhotos'] = photoCount.toString()
      ..fields['albumName'] = albumNameController.text;

    for (var image in selectedImages) {
      request.files.add(await http.MultipartFile.fromPath('photos', image.path)); // Upload all selected images
    }

    setState(() {
      isLoading = true; // Show loading spinner while uploading
    });

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final responseData = jsonDecode(responseBody);
      final albumId = responseData['albumPath'];

      setState(() {
        isLoading = false; // Stop loading after upload
      });

      // Navigate to PhotoDisplayPage after successful album creation
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
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.white, // Adjust primary color
              onPrimary: Colors.blueAccent, // Adjust text color on primary button (OK)
              surface: Colors.blueAccent,
              onSurface: Colors.white, // Text color for Cancel button
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
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
  return BaseScreen( // Wrapping with BaseScreen to apply the animated background
    child: Scaffold(
      backgroundColor: Colors.transparent, // Make the background transparent to see the animated background
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text(
          'Create New Album',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Albums()),
              (route) => false,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildSectionTitle('Album Title'),
            const SizedBox(height: 8),
            TextField(
              controller: albumNameController,
              decoration: InputDecoration(
                hintText: 'Enter album name',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Selected Images'),
            const SizedBox(height: 8),
            selectedImages.isNotEmpty
                ? _buildImageGrid()
                : _buildEmptyImageContainer(),
            const SizedBox(height: 30),
            Center(
              child: FloatingActionButton.extended(
                onPressed: pickImage,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Select Photos',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.blueAccent,
                elevation: 5,
                heroTag: 'selectPhotosFAB',
              ),
            ),
            const SizedBox(height: 30),
            _buildDateSelectors(),
            const SizedBox(height: 30),
            _buildSectionTitle('Number of Photos'),
            Slider(
              value: photoCount.toDouble(),
              min: 1,
              max: selectedImages.length > 100 ? selectedImages.length.toDouble() : 100,
              divisions: selectedImages.length > 100 ? selectedImages.length : 99,
              activeColor: Colors.blueAccent,
              inactiveColor: Colors.grey.shade300,
              label: photoCount.toString(),
              onChanged: (value) {
                setState(() {
                  photoCount = value.toInt();
                });
              },
            ),
            const SizedBox(height: 40),
            Center(
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.blueAccent)
                  : FloatingActionButton.extended(
                      onPressed: pickersubmitData,
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        'Create Album',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.blueAccent,
                      elevation: 5,
                      heroTag: 'createAlbumFAB',
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.grey.shade800,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: selectedImages.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            selectedImages[index],
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  Widget _buildEmptyImageContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          'No images selected',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }

  Widget _buildDateSelectors() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDateButton('Start Date', startDate, true),
        const SizedBox(width: 10),
        _buildDateButton('End Date', endDate, false),
      ],
    );
  }

  Widget _buildDateButton(String label, DateTime? date, bool isStartDate) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () => selectDate(context, isStartDate),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date == null ? label : DateFormat('yyyy-MM-dd').format(date),
              style: const TextStyle(color: Colors.white),
            ),
            const Icon(Icons.calendar_today, color: Colors.white),
          ],
        ),
      ),
    );
  }
}