import 'dart:io' show File, Platform;
import 'package:bookstore/view/more/OrderListScreen.dart';
import 'package:bookstore/const/images.dart';
import 'package:bookstore/view/auth_screens/login_screen.dart';
import 'package:bookstore/view/more/reviewrating.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

// Import other pages
import 'package:bookstore/view/Profile_Screen/EditProfileScreen.dart';
import 'package:bookstore/view/more/wishlist.dart';
import 'package:bookstore/view/Cart_Screen/cart_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  String userName = '';
  String userEmail = '';
  String profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>?;

          if (data != null) {
            setState(() {
              userName = data['name'] ?? 'Unknown User';
              userEmail = data['email'] ?? 'No email';
              profileImageUrl = data['profileImage'] ?? '';
            });
          } else {
            Get.snackbar('Error', 'User document data is null.');
          }
        } else {
          Get.snackbar('Error', 'User document does not exist.');
        }
      } catch (e) {
        Get.snackbar('Error', 'Error fetching user data: $e');
      }
    } else {
      Get.snackbar('Error', 'No authenticated user found.');
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Get.offAll(() => const Login_Screen());
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.isNotEmpty) {
        Uint8List? fileBytes = result.files.first.bytes;
        String fileName = result.files.first.name;
        String? imageUrl = await _uploadImageToStorage(fileBytes, fileName);
        if (imageUrl != null) {
          await _updateProfileImage(imageUrl);
        }
      } else {
        Get.snackbar('No Image', 'No image selected.');
      }
    } else if (Platform.isAndroid || Platform.isIOS) {
      try {
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          String? imageUrl = await _uploadImageToStorage(File(image.path));
          if (imageUrl != null) {
            await _updateProfileImage(imageUrl);
          }
        } else {
          Get.snackbar('No Image', 'No image selected.');
        }
      } catch (e) {
        Get.snackbar('Error', 'Error picking image: $e');
      }
    } else {
      Get.snackbar('Unsupported Platform', 'Unsupported platform.');
    }
  }

  Future<void> _updateProfileImage(String imageUrl) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({'profileImage': imageUrl});
        setState(() {
          profileImageUrl = imageUrl;
        });
      } catch (e) {
        Get.snackbar('Error', 'Error updating profile image: $e');
      }
    }
  }

  Future<String?> _uploadImageToStorage(dynamic file, [String? fileName]) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        Reference ref = _storage.ref().child('profile_images').child(fileName ?? '${user.uid}.jpg');
        UploadTask uploadTask;

        if (file is File) {
          uploadTask = ref.putFile(file);
        } else if (file is Uint8List) {
          uploadTask = ref.putData(file);
        } else {
          print('Error: Unsupported file type.');
          return null;
        }

        TaskSnapshot snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      } catch (e) {
        Get.snackbar('Error', 'Error uploading image: $e');
      }
    }
    return null;
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 36,
                      backgroundImage: profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : const AssetImage(imgProfile2) as ImageProvider,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: ListView(
                children: [
                  _buildMenuItem(Icons.person, "My Information", () {
                    Get.to(() => const EditProfileScreen());
                  }),
                  _buildMenuItem(Icons.shopping_bag, "Orders", () {
                    Get.to(() => const OrderslistScreen()); // Navigate to the OrdersScreen to list orders
                  }),

                  _buildMenuItem(Icons.heart_broken, "Wishlist", () {
                    Get.to(() => const Wishlist());
                  }),
                  _buildMenuItem(Icons.reviews_outlined, "Review", () {
                    Get.to(() => const ReviewPage());
                  }),
                  _buildMenuItem(Icons.local_offer, "Add to Cart", () {
                    Get.to(() => const CartScreen());
                  }),
                 
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _logout,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      "Log Out",
                      style: TextStyle(color: Colors.green, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),);
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
        shadowColor: Colors.black.withOpacity(0.2),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          tileColor: Colors.white,
          leading: Icon(icon, color: Colors.black),
          title: Text(
            title,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }
}
