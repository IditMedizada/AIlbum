// ignore_for_file: avoid_print

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:my_app/notInUse/faces.dart';
import 'dart:async';
import 'package:photo_manager/photo_manager.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<AssetEntity> assets = [];
  DateTime startDate = DateTime.now();
  DateTime endDate =  DateTime.now();

  @override
  void initState() {
    super.initState();
  }

  Future<void> selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
        
      });
      await getImagesFromGallery();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Face_rec(assets: assets),
        ),
      );

    }
  }

  Future<void> getImagesFromGallery() async {

    try {
      AssetPathEntity? path ;
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(createTimeCond: DateTimeCond(min:startDate , max: endDate)),
      );
      setState(() {
        path = paths.first;
      });
      final List<AssetEntity> fetchedAssets = await path!.getAssetListRange(start: 0, end: 100000);
      


      setState(() {
        assets = fetchedAssets;
      });

   
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
          actions: [
            IconButton(
              icon: const Icon(Icons.date_range),
              onPressed: () {
                selectDateRange(context);
                
              },
              
            ),
          ],
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