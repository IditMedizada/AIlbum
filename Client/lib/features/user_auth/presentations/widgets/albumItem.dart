import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/features/user_auth/presentations/pages/photoDisplayPage.dart';

class AlbumItem extends StatelessWidget {
  final String albumName;
  final String thumbnailUrl;
  final String albumId;
  const AlbumItem({
    Key? key,
    required this.albumId,
    required this.albumName,
    required this.thumbnailUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Handle the album click
        String? userId = FirebaseAuth.instance.currentUser?.uid;
        String albumIdd = '$userId/user_albums/$albumId';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoDisplayPage(albumId: albumIdd, albumName: albumName),
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
            AspectRatio(
              aspectRatio: 16 / 9, // Aspect ratio of the thumbnail
              child: thumbnailUrl.isNotEmpty
                  ? Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover, // Cover the area without distortion
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
              padding: const EdgeInsets.all(6.0),
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
