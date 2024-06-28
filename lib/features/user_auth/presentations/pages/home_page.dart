import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:exif/exif.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gallery_picker/gallery_picker.dart';
import 'package:all_gallery_images/model/StorageImages.dart';
import 'dart:async';
import 'package:all_gallery_images/all_gallery_images.dart';
import 'package:photo_manager/photo_manager.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<AssetEntity> assets = [];

  @override
  void initState() {
    super.initState();
    getImagesFromGallery();
  }

  Future<void> getImagesFromGallery() async {

    try {
      List<AssetEntity> fetchedAssets = await PhotoManager.getAssetListRange(start: 0, end: 1000000);

      setState(() {
        assets = fetchedAssets;
      });

      for(AssetEntity ass in assets){
        final file = await (ass.file);
        final file2 = File(file!.path) ;
        //take the date out from hereeeeeeeee
        final tags = await readExifFromBytes(file2.readAsBytesSync());

        if (tags.containsKey('EXIF DateTimeOriginal')) {
            final dateString = tags['EXIF DateTimeOriginal']?.printable;
            final imageDate = DateTime.parse(dateString!.replaceFirst(':', '-').replaceFirst(':', '-'));
            if (imageDate.isAfter(_startDate!) && imageDate.isBefore(_endDate!)) {}
        }




      }
    } catch (e) {
      // Handle error fetching assets
      print('Error fetching assets: $e');
    }
  }

 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('All Gallery Images'),
        ),
        body: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
          itemCount: assets.length,
          itemBuilder: (_, index) {
            return AssetThumbnail(
              asset: assets[index],
            );
          },
        ),
      ),
    );
  }
}
class AssetThumbnail extends StatelessWidget{
  const AssetThumbnail({super.key, required this.asset});
  final AssetEntity asset;
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: asset.thumbnailData.then((value) => value!),
      builder: (_, snapshot){
        final bytes = snapshot.data;
        if(bytes == null) return const CircularProgressIndicator();
        return Image.memory(bytes, fit: BoxFit.cover);
      },
    );
  }

}