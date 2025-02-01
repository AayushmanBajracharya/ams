import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  File? _image;
  String? _profileImageBase64;
  String _username = 'Loading...'; // Default value
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProfilePicture();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() => _isLoading = true);
      try {
        final userData =
            await _firestore.collection('users').doc(user.uid).get();

        if (userData.exists) {
          // Fetch the 'username' field from Firestore
          final username = userData.get('username') ?? 'No Name';
          // Check if the 'profile_image' field exists
          final imageBase64 =
              userData.data()?.containsKey('profile_image') == true
                  ? userData.get('profile_image')
                  : null;

          setState(() {
            _username = username; // Update the _username variable
            _nameController.text = username; // Set the name in the TextField
            _profileImageBase64 = imageBase64; // Update the profile image
          });
        } else {
          // If the document doesn't exist, create it with a default username
          await _firestore.collection('users').doc(user.uid).set({
            'username': 'No Name', // Default username
          });
          setState(() {
            _username = 'No Name';
            _nameController.text = _username;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Created default user document!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching user data: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in!')),
      );
    }
  }

  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    final imageBase64 = prefs.getString('profile_image_base64');
    if (imageBase64 != null) {
      setState(() {
        _profileImageBase64 = imageBase64;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageBytes = await File(pickedFile.path).readAsBytes();
      final imageBase64 = base64Encode(imageBytes);
      setState(() {
        _image = File(pickedFile.path);
        _profileImageBase64 = imageBase64;
      });
      await _saveProfilePictureBase64(imageBase64);
    }
  }

  Future<void> _saveProfilePictureBase64(String base64) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_base64', base64);

    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set(
          {
            'profile_image': base64,
          },
          SetOptions(
              merge: true)); // Merge with existing data or create the document
    }
  }

  Future<void> _showNameChangeDialog() async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Name'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(hintText: 'Enter new name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, _nameController.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await _updateName(newName);
    }
  }

  Future<void> _updateName(String newName) async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() => _isLoading = true);
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'username': newName, // Update the 'username' field in Firestore
        });
        setState(() {
          _username = newName; // Update the displayed name
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating name: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in!')),
      );
    }
  }

  Future<void> _changePassword() async {
    final user = _auth.currentUser;
    if (user != null) {
      final newPassword = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Change Password'),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Enter new password'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, _passwordController.text);
              },
              child: const Text('Change'),
            ),
          ],
        ),
      );

      if (newPassword != null && newPassword.isNotEmpty) {
        setState(() => _isLoading = true);
        try {
          await user.updatePassword(newPassword);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully!')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating password: $e')),
          );
        } finally {
          setState(() => _isLoading = false);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in!')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Show a confirmation dialog
      final confirmDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
              'Do you really want to permanently delete your account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Cancel
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true), // Confirm delete
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );

      // If the user confirms deletion
      if (confirmDelete == true) {
        setState(() => _isLoading = true);
        try {
          await user.delete(); // Delete the user from Firebase Auth
          await _firestore
              .collection('users')
              .doc(user.uid)
              .delete(); // Delete user data from Firestore
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully!')),
          );
          Navigator.of(context).popUntil(
              (route) => route.isFirst); // Navigate back to the first screen
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting account: $e')),
          );
        } finally {
          setState(() => _isLoading = false);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in!')),
      );
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.golosText(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: _profileImageBase64 != null
                                ? MemoryImage(
                                    base64Decode(_profileImageBase64!))
                                : null,
                            child: _profileImageBase64 == null
                                ? const Icon(Icons.camera_alt, size: 40)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _username, // Display the name fetched from Firestore
                          style: GoogleFonts.golosText(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _showNameChangeDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                          ),
                          child: Text(
                            'Edit Profile',
                            style: GoogleFonts.golosText(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSettingsOption(Icons.password, 'Change Password'),
                  _buildSettingsOption(Icons.delete, 'Delete Account'),
                  const SizedBox(height: 16),
                  _buildSettingsOption(Icons.logout, 'Log Out', isLogout: true),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingsOption(IconData icon, String title,
      {bool isLogout = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isLogout ? Colors.red : Colors.blue[800],
        ),
        title: Text(
          title,
          style: GoogleFonts.golosText(
            fontSize: 16,
            color: isLogout ? Colors.red : Colors.black,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (isLogout) {
            _handleLogout();
          } else if (title == 'Change Password') {
            _changePassword();
          } else if (title == 'Delete Account') {
            _deleteAccount();
          }
        },
      ),
    );
  }
}
