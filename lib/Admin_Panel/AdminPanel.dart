import 'dart:io' show File;
import 'package:bookstore/view/auth_screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'ManualBookAddPage.dart';
import 'ApiBookAddPage.dart';
import 'ManageBooksPage.dart';
import 'OrderDetailsPage.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _selectedIndex = 0;
  String _userName = '';
  String _userImage = '';
  bool _isLoading = true;
  final List<Map<String, dynamic>> _books = [];
  final List<String> _pageTitles = [
    'Manual Book Add',
    'API Book Add',
    'Manage Books',
    'Order Details',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>?;
          setState(() {
            _userName = data?['name'] ?? 'Unknown User';
            _userImage = data?['image'] ?? 'assets/images/default_avatar.png';
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectProfileImage() async {
    final picker = ImagePicker();
    XFile? image;

    if (kIsWeb) {
      // Web: Choose image using the web picker
      image = await picker.pickImage(source: ImageSource.gallery);
    } else {
      // Mobile: Pick image from gallery
      image = await picker.pickImage(source: ImageSource.gallery);
    }

    if (image != null) {
      String imageUrl = await _uploadImage(image);
      await _saveUserData(imageUrl);
    }
  }

  Future<String> _uploadImage(XFile image) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference ref = FirebaseStorage.instance.ref().child('profile_images/$fileName');

    try {
      if (kIsWeb) {
        // For web, upload image data directly
        final data = await image.readAsBytes();
        await ref.putData(data);
      } else {
        // For mobile, use File to upload
        await ref.putFile(File(image.path));
      }

      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  Future<void> _saveUserData(String imageUrl) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {
            'name': _userName,
            'image': imageUrl,
          },
          SetOptions(merge: true),
        );
        setState(() {
          _userImage = imageUrl;
        });
        Get.snackbar("Success", "Profile updated successfully!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white);
      } catch (e) {
        print('Error saving user data: $e');
        Get.snackbar("Error", "Could not save profile data. Please try again.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      }
    } else {
      print('No user is currently signed in.');
    }
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.offAll(() => const Login_Screen());
    } catch (e) {
      print('Logout error: $e');
      Get.snackbar("Error", "Could not log out. Please try again.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldLogout = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Logout'),
              content: const Text('Do you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false), // Dismisses dialog
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true), // Confirms logout
                  child: const Text('Logout'),
                ),
              ],
            );
          },
        );
        return shouldLogout ?? false; // Proceed only if logout is confirmed
      },
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          _pageTitles[_selectedIndex],
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _generatePages()[_selectedIndex],
    ),);
  }

  List<Widget> _generatePages() {
    return [
      ManualBookAddPage(onBookAdded: _addBook),
      ApiBookAddPage(onBookAdded: _addBook),
      ManageBooksPage(
        books: _books,
        onUpdateBook: _updateBook,
        onDeleteBook: _deleteBook,
      ),
      const OrderDetailsPage(),
    ];
  }

  void _addBook(Map<String, dynamic> book) {
    setState(() {
      _books.add(book);
    });
  }

  void _updateBook(int index, Map<String, dynamic> updatedBook) {
    setState(() {
      _books[index] = updatedBook;
    });
  }

  void _deleteBook(int index) {
    setState(() {
      _books.removeAt(index);
    });
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.red),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _selectProfileImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(_userImage),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _userName,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),
          _buildListTile(Icons.add, 'Manual Book Add', 0),
          _buildListTile(Icons.cloud_download, 'API Book Add', 1),
          _buildListTile(Icons.library_books, 'Manage Books', 2),
          _buildListTile(Icons.shopping_cart, 'Order Details', 3),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              _logout();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(
          icon,
          color: _selectedIndex == index
              ? const Color.fromARGB(255, 213, 82, 53)
              : null),
      title: Text(
        title,
        style: TextStyle(
          color: _selectedIndex == index ? Colors.red : null,
        ),
      ),
      tileColor:
          _selectedIndex == index ? Colors.red.withOpacity(0.1) : null,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context);
      },
    );
  }
}
