import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:my_app/features/user_auth/presentations/pages/faces.dart';
import 'dart:async';
import 'package:photo_manager/photo_manager.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<AssetEntity> assets = [];
  DateTime startDate = DateTime.now();
  DateTime endDate =  DateTime.now();

  // final FaceRecognitionService faceRecognitionService = FaceRecognitionService();
  // File? userImage;
  // List<File> galleryImages=[];
  // List<String> matchedImages=[];
  // final ImagePicker picker = ImagePicker();

  // // chose face for face rec
  // Future<void> captureUserImage() async{
  //   final image = await picker.pickImage(source: ImageSource.camera);
  //   setState(() {
  //     if(image != null){
  //       userImage = File(image.path);
  //     }
  //   });

  // }

  // Future<void> recognizeFaces()async{
  //   // assets.forEach((image) async{
  //   //   final filePath = await LecleFlutterAbsolutePath.getAbsolutePath(image.);
  //   // })
  //   // if(userImage == null || galleryImages.isEmpty)return;
  //   // final imagesList = await faceRecognitionService.recognizeFaces(userImage!, galleryImages);
  //   // setState(() {
  //   //   assets=imagesList;
  //   // });
  // }


  @override
  void initState() {
    super.initState();
    selectDateRange(context);
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
              icon: Icon(Icons.date_range),
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