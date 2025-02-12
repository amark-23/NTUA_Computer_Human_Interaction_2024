import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  final String profileId; // Firebase document ID
  final String profilePic;
  final String name;
  final String occupation;
  final String location;

  const EditProfilePage({
    super.key,
    required this.profileId,
    required this.profilePic,
    required this.name,
    required this.occupation,
    required this.location,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _occupationController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _occupationController = TextEditingController(text: widget.occupation);
    _locationController = TextEditingController(text: widget.location);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _occupationController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    try {
      // Retrieve updated values from text fields
      final updatedName = _nameController.text.trim();
      final updatedOccupation = _occupationController.text.trim();
      final updatedLocation = _locationController.text.trim();

      // Query Firestore to find the document with matching user_id
      final querySnapshot = await FirebaseFirestore.instance
          .collection('profils')
          .where('user_id', isEqualTo: widget.profileId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Assuming user_id is unique, take the first matching document
        final documentId = querySnapshot.docs.first.id;

        // Update the document with the retrieved ID
        await FirebaseFirestore.instance
            .collection('profils')
            .doc(documentId)
            .update({
          'name': updatedName,
          'occupation': updatedOccupation,
          'location': updatedLocation,
        });

        // Navigate back to the previous page
        Navigator.pop(context);

        // Optionally, show a confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
      } else {
        // Handle case where no matching document is found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No profile found with the given user ID.')),
        );
      }
    } catch (e) {
      // Handle Firestore errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Colors.indigo[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(widget.profilePic),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _occupationController,
                decoration: InputDecoration(
                  labelText: 'Occupation',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile, // Call the save method
                child: Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[300],
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
