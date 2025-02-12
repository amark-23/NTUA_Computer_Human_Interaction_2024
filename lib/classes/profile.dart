import 'package:cloud_firestore/cloud_firestore.dart';

class Profile {
  String name;
  String username;
  String profileImage;
  int posts; // Add posts to the profile
  int followers;
  int following;
  String occupation;
  String location;

  Profile({
    required this.name,
    required this.username,
    required this.profileImage,
    required this.posts, // Include posts in the constructor
    required this.followers,
    required this.following,
    required this.occupation,
    required this.location,
  });

  // Method to fetch profile data based on the username and calculate posts
  static Future<Profile> fetchProfile(String userId) async {
    // Fetch the user's profile data from the 'profiles' collection
    QuerySnapshot profileSnapshot = await FirebaseFirestore.instance
        .collection('profils')
        .where('user_id', isEqualTo: userId)
        .get();

    if (profileSnapshot.docs.isEmpty) {
      throw Exception('Profile not found');
    }

    // The profile document should exist, fetch the first document
    var profileData = profileSnapshot.docs[0].data() as Map<String, dynamic>;

    // Fetch the user's username and profile image from the 'users' collection
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (!userSnapshot.exists) {
      throw Exception('User data not found');
    }

    var userData = userSnapshot.data() as Map<String, dynamic>;

    // Fetch the "following" list and calculate its length
    List<dynamic> followingList = userData['following'] ?? [];
    int followingCount = followingList.length;

    // Calculate the "followers" count dynamically
    QuerySnapshot allUsersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    int followersCount = 0;

    for (var userDoc in allUsersSnapshot.docs) {
      var otherUserData = userDoc.data() as Map<String, dynamic>;

      // Retrieve the 'following' list as List<dynamic>
      List<dynamic> otherUserFollowing = otherUserData['following'] ?? [];

      // Convert to List<String> for safe comparison
      List<String> otherUserFollowingIds =
          otherUserFollowing.map((e) => e.toString()).toList();

      if (otherUserFollowingIds.contains(userId)) {
        followersCount++;
      }
    }

    // Calculate the number of posts for the user based on the username
    int postsCount = await _getPostsCount(userData['username']);

    // Create and return the Profile object
    return Profile(
      name: profileData['name'] ?? 'Unknown',
      username: userData['username'] ?? 'Guest',
      profileImage: userData['profile_pic'] ?? 'assets/user_image.png',
      posts: postsCount, // Pass the calculated posts count
      followers: followingCount, // Dynamically calculated followers count
      following: followersCount, // Dynamically calculated following count
      occupation: profileData['occupation'] ?? 'Unknown',
      location: profileData['location'] ?? 'Unknown',
    );
  }

  // Helper function to calculate the number of posts for the given username
  static Future<int> _getPostsCount(String username) async {
    try {
      // Query the 'posts' collection and count the number of posts by the username
      QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('username', isEqualTo: username) // Filter by username
          .get();

      return postsSnapshot.docs.length; // Return the count of posts
    } catch (e) {
      print("Error fetching posts count: $e");
      return 0; // Return 0 in case of error
    }
  }
}
