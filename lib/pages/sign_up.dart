import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _verifyPasswordController =
      TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _signup() async {
    String username = _usernameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String verifyPassword = _verifyPasswordController.text.trim();

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        verifyPassword.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    if (password != verifyPassword) {
      _showError("Passwords do not match");
      return;
    }

    try {
      // Check if username already exists
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (query.docs.isNotEmpty) {
        _showError("Username already taken");
        return;
      }

      // Add user details to Firestore
      await _firestore.collection('users').add({
        'username': username,
        'email': email,
        'password': password, // Ideally, hash the password before storing
        'following': [],
        'profile_pic':
            'https://res.cloudinary.com/dm5wyzkma/image/upload/v1736636053/depositphotos_11472630-stock-photo-runner-woman-running_sxdzys.jpg',
      });

      Future<void> addProfile(String username) async {
        try {
          // Query the "users" collection to find the document with the matching username
          final querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: username)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            // Get the user ID from the first document in the query result
            final userId = querySnapshot.docs.first.id;

            // Now add the document to the "profils" collection
            await FirebaseFirestore.instance.collection("profils").add({
              'bio': '',
              'location': '',
              'name': username,
              'occupation': '',
              'user_id': userId, // Add the userId to the new profile
            });

            print('Profile created for $username with user ID $userId.');
          } else {
            print('No user found with the username $username.');
          }
        } catch (e) {
          print('Error creating profile: $e');
        }
      }

      addProfile(username);

      // Show success toast
      Fluttertoast.showToast(
        msg: "User Created Successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      // Return to the previous page
      Navigator.pop(context);
    } catch (e) {
      _showError("An error occurred: $e");
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(color: Colors.white),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: screenWidth,
                height: screenHeight,
                decoration: const ShapeDecoration(
                  color: Color(0xFF4749B5),
                  shape: RoundedRectangleBorder(side: BorderSide(width: 1)),
                ),
              ),
            ),
            Positioned(
              left: screenWidth * 0.01,
              top: screenHeight * 0.05,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create your Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: screenWidth * 0.52,
                        height: 2,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildInputField(screenWidth, screenHeight, "Username",
                _usernameController, false, 0.15),
            _buildInputField(screenWidth, screenHeight, "E-mail",
                _emailController, false, 0.3),
            _buildInputField(screenWidth, screenHeight, "Password",
                _passwordController, true, 0.45),
            _buildInputField(screenWidth, screenHeight, "Verify Password",
                _verifyPasswordController, true, 0.6),
            Positioned(
              left: screenWidth * 0.25,
              top: screenHeight * 0.78,
              child: InkWell(
                onTap: _signup,
                child: Container(
                  width: screenWidth * 0.5,
                  height: screenHeight * 0.07,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Color(0xFF944FC3),
                        fontSize: 20,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Positioned _buildInputField(
      double screenWidth,
      double screenHeight,
      String label,
      TextEditingController controller,
      bool obscureText,
      double top) {
    return Positioned(
      left: screenWidth * 0.05,
      top: screenHeight * top,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            width: screenWidth * 0.9,
            height: screenHeight * 0.06,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              decoration: InputDecoration(
                hintText: 'Enter your $label'.toLowerCase(),
                hintStyle: const TextStyle(color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
