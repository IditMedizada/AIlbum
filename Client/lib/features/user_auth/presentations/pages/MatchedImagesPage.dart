import 'dart:typed_data';

import 'package:flutter/material.dart';

class MatchedImagesPage extends StatelessWidget {
  final List<Uint8List?> assetBytesListMatch;

  MatchedImagesPage({required this.assetBytesListMatch});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Matched Images'),
      ),
      body: ListView.builder(
        itemCount: assetBytesListMatch.length,
        itemBuilder: (context, index) {
          if (assetBytesListMatch[index] != null) {
            return ListTile(
              leading: Image.memory(assetBytesListMatch[index]!),
              title: Text('Matched Image ${index + 1}'),
            );
          } else {
            return ListTile(
              title: Text('Error loading matched image ${index + 1}'),
            );
          }
        },
      ),
    );
  }
}
