import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:bookstore/view/Category_Screen/item_details.dart';

class Wishlist extends StatelessWidget {
  const Wishlist({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        backgroundColor: Colors.orange.shade300,
      ),
      backgroundColor: Colors.white, // Set the background color to white

      body: FutureBuilder<List<WishlistItem>>(
        future: _fetchWishlistItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('Your wishlist is empty.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return Dismissible(
                key: Key(item.title),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) async {
                  await _removeFromWishlist(item.title);
                  snapshot.data!.removeAt(index);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${item.title} removed from wishlist')),
                  );
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemDetails(
                          title: item.title,
                          imageUrl: item.imageUrl,
                          description: item.description,
                          price: item.price,
                          isbn: item.isbn,
                          authors: item.authors,
                          
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported, size: 50),
                        ),
                      ),
                      title: Text(item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Author: ${item.authors}'),
                      trailing: Text('PKR ${item.price}',
                          style: const TextStyle(color: Colors.redAccent)),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<WishlistItem>> _fetchWishlistItems() async {
    firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .get();

      return snapshot.docs.map((doc) {
        return WishlistItem(
          title: doc['title'],
          authors: doc['author'],
          imageUrl: doc['imageUrl'],
          price: doc['price'],
          description: doc['description'] ?? 'No description available',
          isbn: doc['isbn'] ,
        );
      }).toList();
    }
    return [];
  }

  Future<void> _removeFromWishlist(String title) async {
    firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(title)
          .delete();
    }
  }
}

class WishlistItem {
  final String title;
  final String authors;
  final String imageUrl;
  final String price;
  final String description;
  final String isbn;

  WishlistItem({
    required this.title,
    required this.authors,
    required this.imageUrl,
    required this.price,
    required this.description,
    required this.isbn,
  });
}
