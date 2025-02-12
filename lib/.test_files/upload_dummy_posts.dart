import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
}

  // Upload Dummy Posts
  final dummyPosts = [
    {
      "post_id": "post_001",
      "post_picture": "https://example.com/images/post_001.jpg",
      "username": "john_doe",
      "profile_pic": "https://example.com/profiles/john_doe.jpg",
      "liked_by": ["user_001", "user_002"],
      "created_at": DateTime.parse("2025-01-11T12:00:00Z"),
    },
    {
      "post_id": "post_002",
      "post_picture": "https://example.com/images/post_002.jpg",
      "username": "jane_smith",
      "profile_pic": "https://example.com/profiles/jane_smith.jpg",
      "liked_by": ["user_003"],
      "created_at": DateTime.parse("2025-01-11T12:10:00Z"),
    },
    {
      "post_id": "post_003",
      "post_picture": "https://example.com/images/post_003.jpg",
      "username": "mike_brown",
      "profile_pic": "https://example.com/profiles/mike_brown.jpg",
      "liked_by": [],
      "created_at": DateTime.parse("2025-01-11T12:20:00Z"),
    },
    {
      "post_id": "post_004",
      "post_picture": "https://example.com/images/post_004.jpg",
      "username": "linda_white",
      "profile_pic": "https://example.com/profiles/linda_white.jpg",
      "liked_by": ["user_001", "user_003", "user_004"],
      "created_at": DateTime.parse("2025-01-11T12:30:00Z"),
    },
  ];

  final postsCollection = FirebaseFirestore.instance.collection('posts');

  for (var post in dummyPosts) {
    await postsCollection.doc(post['post_id']).set(post);
  }

  print("Dummy posts uploaded successfully!");
}
