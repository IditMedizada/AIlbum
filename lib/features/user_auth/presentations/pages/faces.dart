import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_face_api_beta/flutter_face_api.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/features/user_auth/presentations/pages/MatchedImagesPage.dart';
import 'package:photo_manager/photo_manager.dart';


class Faces extends State<Face_rec> {
  var faceSdk = FaceSDK.instance;
  late List<Future<Uint8List?>> assetBytesFutures;
  late List<Uint8List?> assetBytesList;
  List<Uint8List?> assetBytesListMatch=[];

  var _status = "nil";
  var _similarityStatus = "nil";
  var _livenessStatus = "nil";
  var _uiImage1 = Image.asset('assets/images/portrait.png');
  // var _uiImage2 = Image.asset('assets/images/portrait.png');

  set status(String val) => setState(() => _status = val);
  set similarityStatus(String val) => setState(() => _similarityStatus = val);
  set livenessStatus(String val) => setState(() => _livenessStatus = val);
  set uiImage1(Image val) => setState(() => _uiImage1 = val);
  // set uiImage2(Image val) => setState(() => _uiImage2 = val);

  MatchFacesImage? mfImage1;

  void init() async {
    super.initState();
    assetBytesFutures = List.generate(widget.assets.length, (index) => fetchBytesForAsset(widget.assets[index]));
    assetBytesList = List.filled(widget.assets.length, null);
    fetchAssetBytes();
    if (!await initialize()) return;
    status = "Ready";
  }


  Future<void> fetchAssetBytes() async {
    try {
      List<Uint8List?> results = await Future.wait(assetBytesFutures);
      setState(() {
        assetBytesList = results;
      });
    } catch (e) {
      print('Error fetching asset bytes: $e');
      // Handle error appropriately
    }
  }

  Future<Uint8List?> fetchBytesForAsset(AssetEntity asset) async {
    try {
      var file = await asset.file;
      if (file != null) {
        return await file.readAsBytes();
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching bytes for asset: $e');
      return null;
    }
  }

  matchAssets() async {
    for (var asset in assetBytesList) {
      await setImage(asset!, ImageType.PRINTED);
    }

    navigateToMatchedImagesPage();
    return;

  }

  void navigateToMatchedImagesPage() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MatchedImagesPage(assetBytesListMatch: assetBytesListMatch),
    ),
  );
}


  matchFaces(MatchFacesImage? mfImage2) async {

    status = "Processing...";

    var request = MatchFacesRequest([mfImage1!, mfImage2!]);
    var response = await faceSdk.matchFaces(request);
    var split = await faceSdk.splitComparedFaces(response.results, 0.75);
    var match = split.matchedFaces;
    similarityStatus = "failed";
    if (match.isNotEmpty) {
      similarityStatus = (match[0].similarity * 100).toStringAsFixed(2) + "%";
      setState(() {
        assetBytesListMatch.add(mfImage2.image);

      });
      assetBytesListMatch.add(mfImage2.image);
    }
    status = "Ready";
    return;
  }

  clearResults() {
    status = "Ready";
    similarityStatus = "nil";
    livenessStatus = "nil";
    // uiImage2 = Image.asset('assets/images/portrait.png');
    uiImage1 = Image.asset('assets/images/portrait.png');
  }

  // If 'assets/regula.license' exists, init using license(enables offline match)
  // otherwise init without license.
  Future<bool> initialize() async {
    status = "Initializing...";
    var license = await loadAssetIfExists("assets/regula.license");
    InitConfig? config = null;
    if (license != null) config = InitConfig(license);
    var (success, error) = await faceSdk.initialize(config: config);
    if (!success) {
      status = error!.message;
      print("${error.code}: ${error.message}");
    }
    return success;
  }

  Future<ByteData?> loadAssetIfExists(String path) async {
    try {
      return await rootBundle.load(path);
    } catch (_) {
      return null;
    }
  }

  setImage(Uint8List bytes, ImageType type) {
    similarityStatus = "nil";
    var mfImage = MatchFacesImage(bytes, type);
    matchFaces(mfImage);

  }

  setRecImage(Uint8List bytes, ImageType type) {
    similarityStatus = "nil";
    var mfImage = MatchFacesImage(bytes, type);
    
    mfImage1 = mfImage;
    uiImage1 = Image.memory(bytes);

  }

  Widget useGallery() {
    return textButton("Use gallery", () async {
      Navigator.pop(context);
      var image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        setRecImage(File(image.path).readAsBytesSync(), ImageType.PRINTED);
      }
    });
  }

  Widget useCamera() {
    return textButton("Use camera", () async {
      Navigator.pop(context);
      var response = await faceSdk.startFaceCapture();
      var image = response.image;
      if (image != null) setRecImage(image.image, image.imageType);
    });
  }

  Widget image(Image image, Function() onTap) => GestureDetector(
        onTap: onTap,
        child: Image(height: 150, width: 150, image: image.image),
      );

  Widget button(String text, Function() onPressed) {
    return Container(
      child: textButton(text, onPressed,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all<Color>(Colors.black12),
          )),
      width: 250,
    );
  }

  Widget text(String text) => Text(text, style: TextStyle(fontSize: 18));
  Widget textButton(String text, Function() onPressed, {ButtonStyle? style}) =>
      TextButton(
        child: Text(text),
        onPressed: onPressed,
        style: style,
      );

  setImageDialog(BuildContext context, int number) => showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text("Select option"),
          actions: [useGallery(), useCamera()],
        ),
      );

  @override
  Widget build(BuildContext bc) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text(_status))),
      body: Container(
        margin: EdgeInsets.fromLTRB(0, 0, 0, MediaQuery.of(bc).size.height / 8),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            image(_uiImage1, () => setImageDialog(bc, 1)),
            Container(margin: EdgeInsets.fromLTRB(0, 0, 0, 15)),
            button("Match", () => matchAssets()),
            button("Clear", () => clearResults()),
            Container(margin: EdgeInsets.fromLTRB(0, 15, 0, 0)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                text("Similarity: " + _similarityStatus),
                Container(margin: EdgeInsets.fromLTRB(20, 0, 0, 0)),
                text("Liveness: " + _livenessStatus)
              ],
            )
          ],
        ),
      ),
    );
  }

  

  @override
  void initState() {
    super.initState();
    init();
  }
}

class Face_rec extends StatefulWidget {
  final List<AssetEntity> assets;

  Face_rec({required this.assets});

  @override
  Faces createState() => Faces();
}
