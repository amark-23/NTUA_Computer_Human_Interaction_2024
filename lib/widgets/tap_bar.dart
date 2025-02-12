import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/bottom_frame.dart';
import 'gpsrecorder.dart'; // Import the GPS recorder screen
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import for Google Maps and LatLng

Future<String?> getUserIdByUsername(String username) async {
  try {
    // Reference to the 'users' collection
    var usersCollection = FirebaseFirestore.instance.collection('users');

    // Query for the username
    var querySnapshot = await usersCollection
        .where('username', isEqualTo: username)
        .limit(1) // Ensures only one result is returned
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Get the first document from the query result
      var doc = querySnapshot.docs.first;

      // Return the document ID (user_id)
      return doc.id; // This is the user_id (document ID)
    } else {
      // If no user with that username is found, return null
      return "none";
    }
  } catch (e) {
    // Handle errors if any
    print('Error fetching user_id: $e');
    return "none";
  }
}

class TapBar extends StatefulWidget {
  final TabController tabController;
  final String userId; // Only the userId is passed now
  final String profileId;

  const TapBar(
      {super.key,
      required this.tabController,
      required this.userId, // Pass only userId
      required this.profileId});

  @override
  _TapBarState createState() => _TapBarState();
}

class _TapBarState extends State<TapBar> {
  late Future<Map<String, String>>
      userInfoFuture; // To store username and profile pic
  late String username;
  late String profilePic;

  @override
  void initState() {
    super.initState();
    // Initialize the user information future
    userInfoFuture = _fetchUserInfo(widget.userId);
  }

  Future<Map<String, String>> _fetchUserInfo(String userId) async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        final userData = userSnapshot.data()!;
        username = userData['username'] ?? 'Unknown';
        profilePic = userData['profile_pic'] ?? 'assets/user_image.png';
        return {'username': username, 'profile_pic': profilePic};
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      print("Error fetching user data: $e");
      return {'username': 'Unknown', 'profile_pic': 'assets/user_image.png'};
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Opacity(
      opacity: 1,
      child: SizedBox(
        width: screenWidth * 0.9,
        height: 400,
        child: Column(
          children: [
            // Tap Bar (Icons with text)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildIcon(0, widget.tabController.index == 0,
                    'assets/icons/navigation1.png'),
                _buildIcon(1, widget.tabController.index == 1,
                    'assets/icons/navigation2.png'),
                _buildIcon(2, widget.tabController.index == 2,
                    'assets/icons/navigation3.png'),
              ],
            ),
            Expanded(
              child: FutureBuilder<Map<String, String>>(
                future: userInfoFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData) {
                    return const Center(child: Text('User data not found.'));
                  } else {
                    username = snapshot.data!['username']!;
                    profilePic = snapshot.data!['profile_pic']!;

                    return TabBarView(
                      controller: widget.tabController,
                      physics: BouncingScrollPhysics(),
                      children: [
                        _TabContentTab1(
                          username: username,
                          userId: widget.profileId,
                          profilePic: profilePic,
                        ),
                        _TabContentTab2(
                          userId: widget.userId,
                          profile_name:
                              widget.profileId, // Pass profile_name here
                        ),
                        _TabContentTab3(
                            IdyouLookto: widget.userId,
                            IdyouLookfrom: widget.profileId),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(int index, bool isSelected, String iconPath) {
    return GestureDetector(
      onTap: () {
        widget.tabController.animateTo(index); // Switch tabs when tapped
        setState(() {}); // Force a rebuild to update the selected tab
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            iconPath,
            width: 30,
            height: 30,
            color: isSelected ? Colors.white : Colors.grey,
          ),
          Container(
            margin: const EdgeInsets.only(top: 5),
            height: 3,
            width: 80,
            color: isSelected ? Colors.white : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class ImageViewPage extends StatefulWidget {
  final Map<String, dynamic> post;
  final String userId;
  final String profilePic; // Receive profilePic as a parameter

  const ImageViewPage(
      {super.key,
      required this.post,
      required this.userId,
      required this.profilePic});

  @override
  _ImageViewPageState createState() => _ImageViewPageState();
}

class _ImageViewPageState extends State<ImageViewPage> {
  late bool isLiked;

  @override
  void initState() {
    super.initState();
    // Initialize the 'isLiked' value based on the initial liked status
    isLiked = widget.post['likedBy'].contains(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fullscreen Image
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Image.network(
              widget.post['postPicture'],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // Back Button (Arrow) at the top-left
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 30,
              ),
              onPressed: () {
                Navigator.pop(context); // Pop the current screen to go back
              },
            ),
          ),

          // Bottom Frame with User Info
          Align(
            alignment: Alignment.bottomCenter,
            child: BottomFrame(
              postId: widget.post['postId'],
              username: widget.post['username'],
              isLiked: isLiked, // Pass the current like status
              onLikeToggle: (bool liked) {
                _toggleLike(liked);
              },
              profilePicUrl: widget.profilePic, // Use the passed profilePic
              currentUserId: widget.userId,
            ),
          ),
        ],
      ),
    );
  }

  // Function to toggle like and update Firestore
  void _toggleLike(bool liked) {
    setState(() {
      isLiked = liked;
    });

    final postId = widget.post['postId'];
    List<String> likedBy = List<String>.from(widget.post['likedBy']);
    if (liked) {
      likedBy.add(widget.userId); // Add userId to liked list
    } else {
      likedBy.remove(widget.userId); // Remove userId from liked list
    }

    // Update Firestore document with the new likedBy list
    FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .update({'liked_by': likedBy});
  }
}

class _TabContentTab1 extends StatelessWidget {
  final String userId;
  final String username;
  final String profilePic; // Receive profilePic as a parameter

  const _TabContentTab1({
    required this.userId,
    required this.username,
    required this.profilePic,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchPostsByUsername(username),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No posts available.'));
        } else {
          List<Map<String, dynamic>> posts = snapshot.data!;
          // Sort posts by the 'created_at' field in descending order
          posts.sort((a, b) {
            Timestamp aTimestamp = a['createdAt'];
            Timestamp bTimestamp = b['createdAt'];
            return bTimestamp.compareTo(aTimestamp);
          });

          return SingleChildScrollView(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12.0), // Add consistent padding
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Number of columns
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                var post = posts[index];
                return GestureDetector(
                  onTap: () {
                    // Navigate to the new ImageViewPage and pass the profilePic URL
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageViewPage(
                          post: post,
                          userId: userId,
                          profilePic:
                              profilePic, // Pass profilePic to the new page
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(post['postPicture']),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                );
              },
            ),
          );
        }
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchPostsByUsername(
      String username) async {
    try {
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('username', isEqualTo: username)
          .get();

      List<Map<String, dynamic>> posts = postsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "postId": doc.id,
          "username": data['username'],
          "postPicture": data['post_picture'],
          "likedBy": List<String>.from(data['liked_by']),
          "createdAt": data['created_at'],
        };
      }).toList();

      return posts;
    } catch (e) {
      print("Error fetching posts: $e");
      return [];
    }
  }
}

class _TabContentTab2 extends StatefulWidget {
  final String userId;
  final String profile_name; // Add profile_name here

  const _TabContentTab2({required this.userId, required this.profile_name});

  @override
  _TabContentTab2State createState() => _TabContentTab2State();
}

class _TabContentTab2State extends State<_TabContentTab2> {
  // Adjust map's initial camera bounds based on user routes
  LatLngBounds _getLatLngBounds(List<LatLng> route) {
    double? south, north, west, east;

    for (var point in route) {
      if (south == null || point.latitude < south) south = point.latitude;
      if (north == null || point.latitude > north) north = point.latitude;
      if (west == null || point.longitude < west) west = point.longitude;
      if (east == null || point.longitude > east) east = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(south!, west!),
      northeast: LatLng(north!, east!),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchRecentRoutes(String userId) async {
    try {
      final routeSnapshot = await FirebaseFirestore.instance
          .collection('routes')
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(5) // Fetch up to 5 most recent routes
          .get();

      if (routeSnapshot.docs.isEmpty) {
        print("No routes found for user $userId");
        return [];
      }

      return routeSnapshot.docs.map((doc) {
        final routeData = doc.data();
        List<LatLng> routePoints = [];

        // Adding start point
        var start = routeData['start'];
        if (start != null) {
          routePoints.add(LatLng(start['latitude'], start['longitude']));
        }

        // Adding intermediate route points
        var route = routeData['route'] as List<dynamic>? ?? [];
        for (var point in route) {
          routePoints.add(LatLng(point['latitude'], point['longitude']));
        }

        // Adding end point
        var end = routeData['end'];
        if (end != null) {
          routePoints.add(LatLng(end['latitude'], end['longitude']));
        }

        // Extracting timestamp
        final timestamp = routeData['timestamp'] as Timestamp?;
        final formattedDateTime = timestamp != null
            ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
            : 'Unknown Date';

        return {
          'routePoints': routePoints,
          'formattedDateTime': formattedDateTime,
        };
      }).toList();
    } catch (e) {
      print("Error fetching routes: $e");
      return []; // Return an empty list on error
    }
  }

  void _navigateToRouteRecorder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationRecorderWithMap(userId: widget.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Check if the user is viewing their own profile
          if (widget.userId ==
              widget.profile_name) // Condition to display the button
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
              child: ElevatedButton(
                onPressed: _navigateToRouteRecorder,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  backgroundColor: Colors.green, // Set button color to green
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        25), // Rounded corners for the button
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.gps_fixed, // GPS tracker icon
                      color: Colors.white, // White icon color
                      size: 20, // Adjust the size of the icon
                    ),
                    const SizedBox(width: 8), // Add space between icon and text
                    const Text(
                      "Record Route",
                      style: TextStyle(
                        color: Colors.white, // White text color
                        fontSize: 16, // Text size
                        fontWeight: FontWeight.bold, // Make the text bold
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Show Google Maps with recent routes
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchRecentRoutes(widget.userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                    child: Text('\nNo recent routes! Record your first one!'));
              } else {
                final routes = snapshot.data!;
                return Column(
                  children: List.generate(routes.length, (index) {
                    final routeData = routes[index];
                    final route = routeData['routePoints'] as List<LatLng>;
                    final formattedDateTime =
                        routeData['formattedDateTime'] as String;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Route $formattedDateTime', // Route Title
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 300, // Map height
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(15), // Rounded corners
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    15), // Apply rounded corners
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target:
                                        route.first, // Temporary initial focus
                                    zoom:
                                        15, // Zoom level for better visibility
                                  ),
                                  onMapCreated:
                                      (GoogleMapController controller) {
                                    // Calculate bounds for the entire route
                                    LatLngBounds bounds =
                                        _getLatLngBounds(route);
                                    controller.animateCamera(
                                        CameraUpdate.newLatLngBounds(
                                            bounds, 50));
                                  },
                                  polylines: {
                                    Polyline(
                                      polylineId:
                                          PolylineId('route_${index + 1}'),
                                      points: route,
                                      color: Colors.blue,
                                      width: 5,
                                    ),
                                  },
                                  markers: {
                                    Marker(
                                      markerId: MarkerId('start_${index + 1}'),
                                      position: route.first,
                                      infoWindow: InfoWindow(title: 'Start'),
                                    ),
                                    Marker(
                                      markerId: MarkerId('end_${index + 1}'),
                                      position: route.last,
                                      infoWindow: InfoWindow(title: 'End'),
                                    ),
                                  },
                                  myLocationEnabled:
                                      false, // Disable showing current location
                                  zoomControlsEnabled: true, // Optional
                                  compassEnabled: true, // Optional
                                  mapType: MapType.normal, // Optional
                                  scrollGesturesEnabled:
                                      false, // Disable scrolling
                                  zoomGesturesEnabled: false, // Disable zoom
                                )),
                          ),
                          SizedBox(height: 40)
                        ],
                      ),
                    );
                  }),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _TabContentTab3 extends StatelessWidget {
  final String IdyouLookto;
  final String IdyouLookfrom;

  _TabContentTab3({required this.IdyouLookto, required this.IdyouLookfrom});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('achievements').snapshots(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Error state
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // No data state
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No achievements available.'));
        }

        var achievements = snapshot.data!.docs;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Achievements',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                // List of achievements
                for (var achievement in achievements)
                  _buildAchievementItem(achievement, context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementItem(
      DocumentSnapshot achievement, BuildContext context) {
    List<dynamic> madeItList = achievement['made_it'] ?? [];
    bool isMadeIt = madeItList.contains(IdyouLookto);

    // Set opacity depending on whether the profileId is in made_it list
    double opacity = isMadeIt ? 1 : 0.5; // Transparency when not "made it"

    // Only allow tapping if the two IDs are the same
    return GestureDetector(
      onTap: () {
        if (IdyouLookto == IdyouLookfrom) {
          // Toggle the profileId in made_it list
          if (isMadeIt) {
            // Remove profileId from the made_it list
            FirebaseFirestore.instance
                .collection('achievements')
                .doc(achievement.id)
                .update({
              'made_it': FieldValue.arrayRemove([IdyouLookto]),
            });
          } else {
            // Add profileId to the made_it list
            FirebaseFirestore.instance
                .collection('achievements')
                .doc(achievement.id)
                .update({
              'made_it': FieldValue.arrayUnion([IdyouLookto]),
            });
          }
        }
      },
      child: Opacity(
        opacity: opacity,
        child: Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(
                255, 255, 255, 255), // Background color of pill shape
            borderRadius:
                BorderRadius.circular(30), // Pill shape (rounded corners)
            border: Border.all(
              color: isMadeIt
                  ? Colors.green
                  : Color.fromARGB(255, 255, 255, 255), // Border color
              width: 4,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.star, color: Colors.yellow),
              SizedBox(width: 12),
              Text(
                achievement['name'] ?? 'Unknown Achievement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue, // Text color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
