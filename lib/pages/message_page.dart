import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'other_profile.dart';

class MessagesPage extends StatefulWidget {
  final String userId;

  const MessagesPage({super.key, required this.userId});

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.indigo,
        child: PersonalMessages(userId: widget.userId),
      ),
    );
  }
}

class PersonalMessages extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String userId;

  PersonalMessages({super.key, required this.userId});

  void _showSearchOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.indigo.shade700,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SearchOverlay(userId: userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.indigo,
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Text(
                'Personal Messages',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Divider(
                thickness: 3,
                height: 15,
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection('messages')
                      .where('SenderID', isEqualTo: userId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final List<QueryDocumentSnapshot> allMessages =
                        snapshot.data!.docs;
                    final Map<String, QueryDocumentSnapshot>
                        uniqueConversations = {};

// Step 1: Filter and find the most recent message for each conversation
                    for (var message in allMessages) {
                      final senderId = message['SenderID'];
                      final receiverId = message['ReceiverID'];
                      final otherUserId =
                          senderId == userId ? receiverId : senderId;

                      // Get all messages between the two users
                      final messageTime = message['Time'] as Timestamp?;

                      // Skip messages without a valid time
                      if (messageTime == null) continue;

                      // Step 2: Sort messages based on Time and ensure we store only the most recent one
                      if (!uniqueConversations.containsKey(otherUserId) ||
                          messageTime.toDate().compareTo(
                                  uniqueConversations[otherUserId]!['Time']
                                      .toDate()) >
                              0) {
                        // Store the most recent message for this user
                        uniqueConversations[otherUserId] = message;
                      }
                    }

// Step 3: Extract the most recent messages for each user
                    final messages = uniqueConversations.values.toList();

                    return ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        //final content = message['Content'] ??
                        ''; // Most recent message content
                        final senderId = message['SenderID'];
                        final receiverId = message['ReceiverID'];
                        final otherUserId =
                            senderId == userId ? receiverId : senderId;

                        return FutureBuilder<DocumentSnapshot>(
                          future: firestore
                              .collection('users')
                              .doc(otherUserId)
                              .get(),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData ||
                                !userSnapshot.data!.exists) {
                              return const CircularProgressIndicator();
                            }

                            final userData = userSnapshot.data!.data()
                                as Map<String, dynamic>;
                            final username = userData['username'];
                            final profilePic = userData['profile_pic'] ?? '';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(profilePic),
                              ),
                              title: Text(
                                'Chat with $username',
                                style: const TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DirectMessagesPage(
                                      senderId: userId,
                                      receiverId: otherUserId,
                                    ),
                                  ),
                                );
                              },
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
        Positioned(
          top: 50,
          right: 16,
          child: IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 28),
            onPressed: () => _showSearchOverlay(context),
          ),
        ),
      ],
    );
  }
}

class DirectMessagesPage extends StatefulWidget {
  final String senderId;
  final String receiverId;

  const DirectMessagesPage({
    super.key,
    required this.senderId,
    required this.receiverId,
  });

  @override
  _DirectMessagesPageState createState() => _DirectMessagesPageState();
}

class _DirectMessagesPageState extends State<DirectMessagesPage> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  void _sendMessage(String content) async {
    if (content.trim().isNotEmpty) {
      await firestore.collection('messages').add({
        'Content': content,
        'SenderID': widget.senderId,
        'ReceiverID': widget.receiverId,
        'Time': Timestamp.now(),
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot>(
          future: firestore.collection('users').doc(widget.receiverId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading...');
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text('Unknown User');
            }

            final user = snapshot.data!;
            final username = user['username'] ?? 'Unknown User';

            return Text('Chat with $username');
          },
        ),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('messages')
                  .where('SenderID',
                      whereIn: [widget.senderId, widget.receiverId])
                  .where('ReceiverID',
                      whereIn: [widget.senderId, widget.receiverId])
                  .orderBy('Time', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No messages yet',
                        style: TextStyle(
                            color: Color.fromARGB(255, 63, 63, 63),
                            fontSize: 16.0)),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final content = message['Content'];
                    final isMe = message['SenderID'] == widget.senderId;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[700],
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Text(
                          content,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _sendMessage(_controller.text),
                  icon: const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SearchOverlay extends StatefulWidget {
  final String userId;

  const SearchOverlay({super.key, required this.userId});

  @override
  _SearchOverlayState createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<DocumentSnapshot> searchResults = [];

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    final result = await firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    setState(() {
      // Exclude the current user from the search results
      searchResults = result.docs
          .where((doc) => doc.id != widget.userId) // Exclude own userId
          .toList();
    });
  }

  Future<String?> getUserIdFromUsername(String username) async {
    try {
      final querySnapshot = await firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id; // Return the userId
      } else {
        return null; // No user found with the given username
      }
    } catch (e) {
      print('Error fetching userId for username $username: $e');
      return null; // Handle errors gracefully
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            onChanged: _searchUsers,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by username',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              filled: true,
              fillColor: Colors.indigo.shade400,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (searchResults.isEmpty)
            const Center(
              child: Text(
                'No users found',
                style: TextStyle(color: Colors.white70),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final user =
                    searchResults[index].data() as Map<String, dynamic>;
                final username = user['username'];
                final profilePic = user['profile_pic'] ?? '';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(profilePic),
                  ),
                  title: Text(
                    username,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    final searchId = await getUserIdFromUsername(username);

                    if (searchId != null) {
                      Navigator.of(context).pop(); // Close the search overlay
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OtherProfilePage(
                            userId: widget.userId,
                            currentId: searchId,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Error: User ID not found for $username'),
                        ),
                      );
                    }
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
