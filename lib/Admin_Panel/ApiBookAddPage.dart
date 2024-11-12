import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApiBookAddPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onBookAdded;

  const ApiBookAddPage({super.key, required this.onBookAdded});

  @override
  _ApiBookAddPageState createState() => _ApiBookAddPageState();
}

class _ApiBookAddPageState extends State<ApiBookAddPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<dynamic> books = [];
  String searchQuery = "";
  final TextEditingController _priceController = TextEditingController(); // Controller for price input
  final Set<String> addedBookIsbns = {};
  String selectedCategory = "Fiction"; // Default category

  // List of categories
  final List<String> categories = [
    "Fiction",
    "Classic",
    "Romance",
    "Mystery",
    "Fantasy",
    "History",
    "Comic",
    "Crime",
  ];

  Future<void> searchBooks(String query) async {
    if (query.isEmpty) return;
    final url = 'https://www.googleapis.com/books/v1/volumes?q=$query';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          books = data['items'] ?? [];
        });
      } else {
        throw Exception('Failed to load books');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load books. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  void showBookDetails(Map<String, dynamic> book) {
    _priceController.clear(); // Clear price input field when book details are shown

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(book['title'] ?? 'No Title'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (book['thumbnail'] != null && book['thumbnail'] != '')
                  Image.network(book['thumbnail'], width: 100),
                const SizedBox(height: 10),
                Text('Authors: ${book['authors'] ?? 'Unknown'}'),
                Text('ISBN: ${book['isbn'] ?? 'N/A'}'),
                const SizedBox(height: 10),
                Text('Description: ${book['description'] ?? 'No Description'}'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Select Category'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Enter Price (PKR)',
                  ),
                ),
              ],
            ),
          ),
          actions: _buildDialogActions(book),
        );
      },
    );
  }

  List<Widget> _buildDialogActions(Map<String, dynamic> book) {
    return [
      TextButton(
        child: const Text('Add'),
        onPressed: () => _addBook(book),
      ),
      TextButton(
        child: const Text('Cancel'),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ];
  }

  void _addBook(Map<String, dynamic> book) async {
    final price = int.tryParse(_priceController.text);

    if (price == null || price <= 0) {
      Get.snackbar('Error', 'Price must be a valid positive number.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    if (addedBookIsbns.contains(book['isbn'])) {
      Get.snackbar('Error', 'This book has already been added.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      Navigator.of(context).pop();
      return;
    }

    try {
      // Generate a unique ID for the book
      String bookId = _firestore.collection('books').doc().id;

      await _firestore.collection('books').doc(bookId).set({
        'id': bookId, // Unique ID
        'title': book['title'],
        'authors': book['authors'] ?? [],
        'isbn': book['isbn'] ?? 'N/A',
        'price': price, // Use the user-inputted price
        'category': selectedCategory,
        'description': book['description'] ?? '',
        'thumbnail': book['thumbnail'] ?? '',
        'addedAt': Timestamp.now(),
      });

      addedBookIsbns.add(book['isbn']);
      widget.onBookAdded(book);

      Get.snackbar('Success', 'Book added successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add book to Firestore.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Search and Add Book'),
      ),
      backgroundColor: Colors.white, // Set the background color to white
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (value) {
                  searchQuery = value;
                },
                decoration: InputDecoration(
                  labelText: 'Search Books',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => searchBooks(searchQuery),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index]['volumeInfo'];
                  final title = book['title'] ?? 'No Title';
                  final authors = (book['authors'] ?? []).join(', ');
                  final thumbnail = book['imageLinks']?['thumbnail'] ?? '';
                  final isbn = book['industryIdentifiers']?[0]['identifier'] ?? 'N/A';
                  final description = book['description'] ?? 'No Description';

                  return ListTile(
                    leading: thumbnail.isNotEmpty
                        ? Image.network(thumbnail, width: 50, fit: BoxFit.cover)
                        : const Icon(Icons.book, size: 50),
                    title: Text(title),
                    subtitle: Text(authors),
                    onTap: () {
                      showBookDetails({
                        'title': title,
                        'authors': authors,
                        'thumbnail': thumbnail,
                        'isbn': isbn,
                        'description': description,
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
