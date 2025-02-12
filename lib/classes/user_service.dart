import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  // Firestore instance
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch the userId by username
  static Future<String> getUserIdByUsername(String username) async {
    try {
      // Query the 'users' collection for the document where 'username' matches
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1) // Get only the first match
          .get();

      // Check if any documents match the query
      if (query.docs.isNotEmpty) {
        // Return the document ID (userId)
        return query.docs.first.id;
      } else {
        throw Exception("User with username '$username' not found.");
      }
    } catch (e) {
      // Handle errors (e.g., network issues, Firebase issues)
      throw Exception("Error fetching userId: $e");
    }
  }
}
