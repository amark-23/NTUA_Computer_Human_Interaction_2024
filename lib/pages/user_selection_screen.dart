import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  _UserSelectionScreenState createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _login(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password.')),
        );
      } else {
        final userDoc = querySnapshot.docs.first;
        final userId = userDoc.id;

        // Add userId to the "logged_in" collection
        await FirebaseFirestore.instance.collection('logged_in').add({
          'user_id': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Navigate to the home screen with user details
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {
            'userId': userId,
            'username': userDoc['username'],
            'profilePic': userDoc['profile_pic'] ??
                'https://example.com/default_profile_pic.png',
          },
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: screenWidth,
            height: screenHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: Colors.white),
            child: Stack(
              children: [
                // Background
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: screenWidth,
                    height: screenHeight,
                    decoration: const BoxDecoration(color: Color(0xFF4749B5)),
                  ),
                ),
                // Back Button
                Positioned(
                  left: 0,
                  top: screenHeight * 0.04,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/intro');
                    },
                  ),
                ),
                // Title
                Positioned(
                  left: screenWidth * 0.25,
                  top: screenHeight * 0.05,
                  child: const Text(
                    'Login to your Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Email Field
                Positioned(
                  left: 36,
                  top: screenHeight * 0.15,
                  child: const Text(
                    'E-mail',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Positioned(
                  left: 36,
                  top: screenHeight * 0.2,
                  child: Container(
                    width: screenWidth * 0.8,
                    height: 43,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        hintText: 'Enter your email',
                      ),
                    ),
                  ),
                ),
                // Password Field
                Positioned(
                  left: 36,
                  top: screenHeight * 0.3,
                  child: const Text(
                    'Password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Positioned(
                  left: 36,
                  top: screenHeight * 0.35,
                  child: Container(
                    width: screenWidth * 0.8,
                    height: 43,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        hintText: 'Enter your password',
                      ),
                    ),
                  ),
                ),
                // Login Button
                Positioned(
                  left: screenWidth * 0.35,
                  top: screenHeight * 0.5,
                  child: InkWell(
                    onTap: () => _login(context),
                    child: Container(
                      width: screenWidth * 0.3,
                      height: 37,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFB2BCFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Log In!',
                          style: TextStyle(
                            color: Color(0xFF0002AB),
                            fontSize: 16,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: screenWidth * 0.31,
                  top: screenHeight * 0.6,
                  child: InkWell(
                    onTap: () {
                      // Navigate to password reset page
                    },
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Quick login section (User icons)
                // Quick login section (User icons)
                Positioned(
                  left: MediaQuery.of(context).size.width * 0.05,
                  top: MediaQuery.of(context).size.height * 0.7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: 100,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('logged_in')
                              .snapshots(), // Stream to listen to real-time changes
                          builder: (context, loggedInSnapshot) {
                            if (loggedInSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (loggedInSnapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error: ${loggedInSnapshot.error}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }

                            if (!loggedInSnapshot.hasData ||
                                loggedInSnapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No logged-in users.',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }

                            // Extract logged-in user IDs
                            final loggedInUserIds = loggedInSnapshot.data!.docs
                                .map((doc) => doc['user_id'])
                                .toSet();

                            return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .snapshots(), // Real-time updates from the 'users' collection
                              builder: (context, usersSnapshot) {
                                if (usersSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (usersSnapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      'Error: ${usersSnapshot.error}',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  );
                                }

                                if (!usersSnapshot.hasData ||
                                    usersSnapshot.data!.docs.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No users available.',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                }

                                // Filter users based on logged-in user IDs
                                final filteredUsers =
                                    usersSnapshot.data!.docs.where((doc) {
                                  return loggedInUserIds.contains(doc.id);
                                }).toList();

                                if (filteredUsers.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No logged-in users available.',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: filteredUsers.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 15),
                                  itemBuilder: (context, index) {
                                    final userDoc = filteredUsers[index];
                                    final userId = userDoc.id;
                                    final username =
                                        userDoc['username'] ?? 'Unknown User';
                                    final profilePic = userDoc['profile_pic'] ??
                                        'https://example.com/default_profile_pic.png'; // Default image URL

                                    return Column(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            // Quick login navigation
                                            Navigator.pushReplacementNamed(
                                              context,
                                              '/home',
                                              arguments: {
                                                'userId': userId,
                                                'username': username,
                                                'profilePic': profilePic,
                                              },
                                            );
                                          },
                                          child: CircleAvatar(
                                            radius: 30,
                                            backgroundImage:
                                                NetworkImage(profilePic),
                                            onBackgroundImageError: (_, __) =>
                                                const Icon(Icons.person,
                                                    color: Colors.white),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          username,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
