import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../classes/profile.dart'; // Import the Profile class
import '../widgets/tap_bar.dart'; // Import the TapBar widget
import '../pages/message_page.dart';

class OtherProfilePage extends StatefulWidget {
  final String userId; // User ID to fetch the other user's profile
  final String currentId;

  const OtherProfilePage(
      {super.key, required this.userId, required this.currentId});

  @override
  _OtherProfilePageState createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Profile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _profileFuture =
        Profile.fetchProfile(widget.currentId); // Fetch profile data
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return FutureBuilder<Profile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        print(widget.userId);
        print(widget.currentId);
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('No data available'));
        }

        Profile profile = snapshot.data!;

        return Scaffold(
          body: Column(
            children: [
              Container(
                width: screenWidth,
                height: screenHeight,
                color: Colors.indigo[300],
                child: Stack(
                  children: [
                    Positioned(
                      left: screenWidth * 0.05,
                      top: screenHeight * 0.08,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: screenWidth * 0.06,
                        ),
                      ),
                    ),

                    // Profile Header
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        width: screenWidth,
                        padding: EdgeInsets.only(
                          top: screenHeight * 0.08,
                          left: screenWidth * 0.02,
                          right: screenWidth * 0.025,
                          bottom: screenHeight * 0.55,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(width: screenWidth * 0.30),
                                Text(
                                  profile.username,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.05,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.30),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Row(
                              children: [
                                Container(
                                  width: screenWidth * 0.24,
                                  height: screenWidth * 0.24,
                                  decoration: ShapeDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(profile.profileImage),
                                      fit: BoxFit.fill,
                                    ),
                                    shape: const OvalBorder(),
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.05),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 30.0),
                                  child: Row(
                                    children: [
                                      _statColumn('Posts', profile.posts),
                                      SizedBox(width: screenWidth * 0.07),
                                      _statColumn(
                                          'Followers', profile.followers),
                                      SizedBox(width: screenWidth * 0.07),
                                      _statColumn(
                                          'Following', profile.following),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Profile Details
                    Positioned(
                      left: screenWidth * 0.05,
                      top: screenHeight * 0.27,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            profile.occupation,
                            style: TextStyle(
                              color: const Color(0xFF8E8E8E),
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            'Lives in ${profile.location}',
                            style: TextStyle(
                              color: const Color(0xFFD4E0ED),
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action Buttons
                    Positioned(
                      left: screenWidth * 0.03,
                      top: screenHeight * 0.38,
                      child: SizedBox(
                        width: screenWidth * 0.94,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(widget.currentId)
                                    .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Container(
                                      height: screenHeight * 0.045,
                                      alignment: Alignment.center,
                                      child: const CircularProgressIndicator(),
                                    );
                                  }

                                  if (snapshot.hasError || !snapshot.hasData) {
                                    return Container(
                                      height: screenHeight * 0.045,
                                      alignment: Alignment.center,
                                      child: const Text('Error'),
                                    );
                                  }

                                  // Get the 'following' list of the current user
                                  List<dynamic> followingList =
                                      snapshot.data?.get('following') ?? [];
                                  bool isFollowing =
                                      followingList.contains(widget.userId);

                                  return GestureDetector(
                                    onTap: () async {
                                      if (isFollowing) {
                                        // Unfollow logic: Remove the userId from the following list
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(widget.currentId)
                                            .update({
                                          'following': FieldValue.arrayRemove(
                                              [widget.userId])
                                        });
                                      } else {
                                        // Follow logic: Add the userId to the following list
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(widget.currentId)
                                            .update({
                                          'following': FieldValue.arrayUnion(
                                              [widget.userId])
                                        });
                                      }

                                      // Rebuild UI after updating
                                      setState(() {});
                                    },
                                    child: Container(
                                      height: screenHeight * 0.045,
                                      decoration: ShapeDecoration(
                                        color: isFollowing
                                            ? const Color.fromARGB(255, 65, 126,
                                                196) // "Following" state color
                                            : const Color.fromARGB(255, 44, 132,
                                                231), // Default "Follow" color
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5.73),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          isFollowing
                                              ? 'Following'
                                              : 'Follow', // Dynamic text
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: screenWidth * 0.04,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => DirectMessagesPage(
                                        senderId:
                                            widget.userId, // Current user's ID
                                        receiverId: widget
                                            .currentId, // Profile user's ID
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: screenHeight * 0.045,
                                  decoration: ShapeDecoration(
                                    color: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.73),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Message',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.04,
                                        fontFamily: 'Inter',
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
                    ),

                    // Tab Bar
                    Positioned(
                      left: screenWidth * 0.03,
                      top: screenHeight * 0.44,
                      child: TapBar(
                        userId: widget.currentId,
                        profileId: widget.userId,
                        tabController: _tabController,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statColumn(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
