import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:get/get.dart'; // Import GetX for snackbar
import 'package:image_picker/image_picker.dart'; // Import Image Picker

class ManageBooksPage extends StatefulWidget {
  final Function(int, Map<String, dynamic>) onUpdateBook;
  final Function(int) onDeleteBook;

  const ManageBooksPage({
    super.key,
    required this.onUpdateBook,
    required this.onDeleteBook, required List<Map<String, dynamic>> books,
  });

  @override
  _ManageBooksPageState createState() => _ManageBooksPageState();
}

class _ManageBooksPageState extends State<ManageBooksPage> {
  List<Map<String, dynamic>> _books = []; // List to hold books
  final List<String> _categories = [
    "Fiction", "Classic", "Romance", "Mystery",
    "Fantasy", "History", "Comic", "Crime"
  ];
  bool _isLoading = true; // Loading state
  final ImagePicker picker = ImagePicker(); // Image Picker instance

  @override
  void initState() {
    super.initState();
    _fetchBooks(); // Fetch books from Firestore when the page is initialized
  }

  // Function to fetch books from Firestore
  Future<void> _fetchBooks() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('books').get();
      setState(() {
        _books = snapshot.docs.map((doc) {
          final data = doc.data();

          // Ensure authors is a string and trim it
          if (data['authors'] is String) {
            data['authors'] = [data['authors'].replaceFirst('by ', '').trim()]; // Convert string to list and clean it
          } else if (data['authors'] is! List) {
            data['authors'] = ['Unknown Author']; // Fallback if authors is not a string or list
          }

          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching books: $e');
      Get.snackbar("Error", "Could not fetch books. Please try again.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Manage Books'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBooks, // Call fetchBooks when pressed
          ),
        ],
      ),
      backgroundColor: Colors.white, // Set the background color to white

      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : _books.isEmpty
              ? _buildEmptyMessage()
              : _buildBookList(),
    );
  }

  Widget _buildEmptyMessage() {
    return const Center(child: Text('No books added yet.'));
  }

  Widget _buildBookList() {
    return ListView.builder(
      itemCount: _books.length,
      itemBuilder: (context, index) {
        return _buildBookTile(context, _books[index], index);
      },
    );
  }

  Widget _buildBookTile(BuildContext context, Map<String, dynamic> book, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      child: ListTile(
        leading: _buildThumbnail(book['thumbnail']),
        title: Text(book['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: _buildBookDetails(book),
        trailing: _buildActionButtons(context, book, index),
      ),
    );
  }

  Widget _buildThumbnail(String thumbnail) {
    return ClipOval(
      child: thumbnail.isNotEmpty
          ? Image.network(
              thumbnail,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.book, size: 50);
              },
            )
          : const Icon(Icons.book, size: 50),
    );
  }

  Column _buildBookDetails(Map<String, dynamic> book) {
    final authors = (book['authors'] is List)
        ? book['authors'].join(', ')
        : 'Unknown Author'; // Fallback if authors is not a list

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Author: $authors', style: const TextStyle(color: Colors.grey)),
        Text('ISBN: ${book['isbn']}', style: const TextStyle(color: Colors.grey)),
        Text('Description: ${book['description']}', style: const TextStyle(color: Colors.grey),maxLines: 3,),
        Text('Price: PKR.${book['price']}', style: const TextStyle(color: Colors.grey)),
        Text('Category: ${book['category'] ?? 'N/A'}', style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> book, int index) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () => _editBook(context, book, index),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDelete(context, index),
        ),
      ],
    );
  }

  void _editBook(BuildContext context, Map<String, dynamic> book, int index) async {
    final updatedBook = await _editBookDialog(context, book);
    if (updatedBook != null) {
      try {
        // Update the book in Firestore
        await FirebaseFirestore.instance
            .collection('books')
            .doc(book['id'])
            .update(updatedBook);

        // Refresh the book list after the update
        await _fetchBooks();

        Get.snackbar('Success', 'Book updated successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white);
      } catch (e) {
        print('Error updating book: $e');
        Get.snackbar('Error', 'Could not update the book. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      }
    }
  }

  void _confirmDelete(BuildContext context, int index) async {
    final confirmed = await _showDeleteConfirmationDialog(context);
    if (confirmed == true) {
      try {
        // Delete the book from Firestore
        await FirebaseFirestore.instance
            .collection('books')
            .doc(_books[index]['id'])
            .delete();

        // Update the local list
        setState(() {
          _books.removeAt(index); // Remove the book from the list
        });

        Get.snackbar('Success', 'Book deleted successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white);
      } catch (e) {
        print('Error deleting book: $e');
        Get.snackbar('Error', 'Could not delete the book. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      }
    }
  }

  Future<Map<String, dynamic>?> _editBookDialog(BuildContext context, Map<String, dynamic> book) {
    final titleController = TextEditingController(text: book['title']);
    final authorController = TextEditingController(text: (book['authors'] is List) ? book['authors'].join(', ') : book['authors']);
    final isbnController = TextEditingController(text: book['isbn']);
    final descrptionController = TextEditingController(text: book['description']);
    final priceController = TextEditingController(text: book['price'].toString());
    final thumbnailController = TextEditingController(text: book['thumbnail']);
    String? selectedCategory = book['category'];

    return showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              'Edit Book Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.redAccent,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(titleController, 'Title'),
                  const SizedBox(height: 10),
                  _buildTextField(authorController, 'Authors'),
                  const SizedBox(height: 10),
                  _buildTextField(isbnController, 'ISBN'),
                  const SizedBox(height: 10),
                   _buildTextField(descrptionController, 'Description'),
                  const SizedBox(height: 10) ,
                  _buildTextField(priceController, 'Price', TextInputType.number),
                  const SizedBox(height: 10),
                  _buildTextField(thumbnailController, 'Thumbnail URL'),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    hint: const Text('Select Category'),
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog without saving
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Validate inputs and construct the updated book data
                  if (titleController.text.isNotEmpty &&
                      authorController.text.isNotEmpty &&
                      isbnController.text.isNotEmpty &&
                      priceController.text.isNotEmpty &&
                      selectedCategory != null) {
                    Navigator.of(context).pop({
                      'title': titleController.text,
                      'authors': authorController.text.split(',').map((author) => author.trim()).toList(),
                      'isbn': isbnController.text,
                      'description': descrptionController.text,
                      'price': double.tryParse(priceController.text),
                      'thumbnail': thumbnailController.text,
                      'category': selectedCategory,
                    });
                  } else {
                    Get.snackbar('Error', 'Please fill in all fields correctly.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
  }

  Widget _buildTextField(TextEditingController controller, String label, [TextInputType keyboardType = TextInputType.text]) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this book?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Close the dialog with false
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Close the dialog with true
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
