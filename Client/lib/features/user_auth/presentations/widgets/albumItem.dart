import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/features/user_auth/presentations/pages/photoDisplayPage.dart';

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
        String? userId = FirebaseAuth.instance.currentUser?.uid;
        String albumId = '$userId/user_albums/$albumName';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoDisplayPage(albumId: albumId),
          ),
        );
        print("Album '$albumId' clicked");
      },
      child: Card(
        elevation: 4.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Album Thumbnail with larger size
            Container(
              height: 150, // Increase the height to make the image larger
              child: thumbnailUrl.isNotEmpty
                  ? Image.network(
                      thumbnailUrl,
                      fit: BoxFit.contain, // Ensure the image is not cropped
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
