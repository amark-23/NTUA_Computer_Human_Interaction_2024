import 'package:flutter/material.dart';
//import '../pages/profile_page.dart'; // Import the user's profile page
import '../pages/other_profile.dart'; // Import the other user's profile page
import '../classes/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firebase Firestore functionality
import 'package:fluttertoast/fluttertoast.dart';

class BottomFrame extends StatelessWidget {
  final bool isLiked;
  final ValueChanged<bool> onLikeToggle;
  final String username;
  final String profilePicUrl;
  final double iconSize;
  final String currentUserId; // The userId of the person operating the app
  final String postId; // The ID of the post

  const BottomFrame({
    super.key,
    required this.isLiked,
    required this.onLikeToggle,
    required this.username,
    required this.profilePicUrl,
    required this.currentUserId, // Pass the current user's ID
    required this.postId, // The postId is passed as a parameter
    this.iconSize = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 208,
      decoration: BoxDecoration(
        color: const Color.fromARGB(
            0, 255, 255, 255), // Fully transparent background
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info: Username and Profile Image
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(profilePicUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Displaying the dynamic username
                GestureDetector(
                  onTap: () async {
                    // Fetch the userId based on the username
                    String userId =
                        await UserService.getUserIdByUsername(username);

                    // Navigate to the appropriate page
                    if (userId == currentUserId) {
                    } else {
                      // If it's another user's profile
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OtherProfilePage(
                              userId: currentUserId, currentId: userId),
                        ),
                      );
                    }
                  },
                  child: Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      // Highlight it as clickable
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Action Icons: Like and Comment
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 25.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Like Icon
                GestureDetector(
                  onTap: () => onLikeToggle(!isLiked),
                  child: Image.asset(
                    isLiked
                        ? 'assets/icons/heart_filled.png'
                        : 'assets/icons/heart_outline.png',
                    width: iconSize,
                    height: iconSize,
                  ),
                ),
                const SizedBox(width: 80),
                // Comment Icon
                GestureDetector(
                  onTap: () {
                    // Call the comment overlay with the username and postId
                    _showCommentOverlay(context, postId);
                  },
                  child: Image.asset(
                    'assets/icons/comment_icon.png',
                    width: iconSize,
                    height: iconSize,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Function to show the comment overlay
  void _showCommentOverlay(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController commentController = TextEditingController();
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 500,
            height: 79,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 5, 130, 1),
                  child: Text(
                    'Send your comment!',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: Color.fromARGB(255, 72, 112, 241),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: ShapeDecoration(
                    color: Color(0xFFD9D9D9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          maxLines: 1,
                          decoration: InputDecoration(
                            hintText: 'Enter your comment...',
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          String comment = commentController.text.trim();
                          if (comment.isNotEmpty) {
                            // Use currentUserId as senderId directly
                            String senderId = currentUserId;

                            // Send the comment
                            _sendComment(comment, senderId, postId);
                          }
                          Navigator.pop(context);
                        },
                        child: Icon(
                          Icons.arrow_upward,
                          color: Colors.green,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Function to send the comment as a message
  void _sendComment(String comment, String senderId, String postId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Fetch the username by postId
    String username = await getUsernameByPostId(postId);

    if (username.isNotEmpty) {
      // Fetch the userId of the post creator based on the username
      String receiverId = await getUserIdByUsername(username);

      if (receiverId.isNotEmpty) {
        // Check if the sender and receiver are the same
        if (senderId == receiverId) {
          // Show a FlutterToast notification
          Fluttertoast.showToast(
            msg: "Cannot send comments to yourself",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        } else {
          // Store the comment as a message in Firestore
          await firestore.collection('messages').add({
            'Content': comment, // The comment content
            'SenderID': senderId, // The user who is commenting
            'ReceiverID': receiverId, // The user who created the post
            'Time': Timestamp.now(), // Timestamp of the comment
          });
          print('Comment sent: $comment');
        }
      } else {
        print('Error: Receiver ID not found for username $username');
      }
    } else {
      print('Error: Username not found for post');
    }
  }

  // 1. Function to get the username by postId
  Future<String> getUsernameByPostId(String postId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Fetch the post document using postId
    DocumentSnapshot postDoc =
        await firestore.collection('posts').doc(postId).get();

    if (postDoc.exists) {
      // Get the userId of the post creator from the post document
      String userId = await getUserIdByUsername(postDoc['username']);

      // Now fetch the username from the users collection using the userId
      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        return userDoc['username']; // Return the username
      } else {
        print('User not found');
        return ''; // Return empty string if user is not found
      }
    } else {
      print('Post not found');
      return ''; // Return empty string if the post is not found
    }
  }

  // 2. Function to get the userId by username
  Future<String> getUserIdByUsername(String username) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Query Firestore to find the user by username
    QuerySnapshot querySnapshot = await firestore
        .collection('users') // Assuming users are stored in 'users' collection
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Get the first document from the query results
      DocumentSnapshot userDoc = querySnapshot.docs.first;
      return userDoc.id; // Return the userId (document ID)
    } else {
      print('User not found');
      return ''; // Return empty string if user is not found
    }
  }
}
