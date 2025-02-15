import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

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
  String _username = 'Loading...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() => _isLoading = true);
      try {
        final userData =
            await _firestore.collection('users').doc(user.uid).get();

        if (userData.exists) {
          final username = userData.get('username') ?? 'No Name';
          setState(() {
            _username = username;
            _nameController.text = username;
          });
        } else {
          await _firestore.collection('users').doc(user.uid).set({
            'username': 'No Name',
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
          'username': newName,
        });
        setState(() {
          _username = newName;
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
      final confirmDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
              'Do you really want to permanently delete your account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );

      if (confirmDelete == true) {
        setState(() => _isLoading = true);
        try {
          await user.delete();
          await _firestore.collection('users').doc(user.uid).delete();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully!')),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
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
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _username,
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
