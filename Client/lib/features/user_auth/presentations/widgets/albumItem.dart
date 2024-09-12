import 'package:flutter/material.dart';

class AlbumItem extends StatelessWidget {
  final String albumName;
  final String thumbnailUrl;

  const AlbumItem({
    Key? key,
    required this.albumName,
    required this.thumbnailUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Handle the album click
        print("Album '$albumName' clicked");
      },
      child: Card(
        elevation: 4.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Album Thumbnail
            Expanded(
              child: thumbnailUrl.isNotEmpty
                  ? Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.photo_album,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
            ),
            // Album Name
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                albumName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
