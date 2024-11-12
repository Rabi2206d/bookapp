import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManualBookAddPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onBookAdded;

  const ManualBookAddPage({super.key, required this.onBookAdded});

  @override
  _ManualBookAddPageState createState() => _ManualBookAddPageState();
}

class _ManualBookAddPageState extends State<ManualBookAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _thumbnailController = TextEditingController();
  final _isbnController = TextEditingController(); // New ISBN controller

  final List<String> categories = [
    "Fiction",
    "Classic",
    "Romance",
    "Mystery",
    "Fantasy",
    "History",
    "Comic",
    "Crime"
  ];

  String? selectedCategory;
  bool _isNewArrival = true; // New field for marking as a new arrival
  XFile? _pickedImage;
  Uint8List? _webImageBytes;
  bool _isUploading = false;
  List<Map<String, dynamic>> newArrivals = [];

  @override
  void initState() {
    super.initState();
    _fetchNewArrivals();
  }

  Future<void> _fetchNewArrivals() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('books')
          .where('isNewArrival', isEqualTo: true)
          .get();

      setState(() {
        newArrivals = snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      _showSnackbar('Error fetching new arrivals: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedImage = pickedFile;
          _thumbnailController.clear();
          if (kIsWeb) _loadWebImage(pickedFile);
        });
      } else {
        _showSnackbar('No image selected');
      }
    } catch (e) {
      _showSnackbar('Error picking image: $e');
    }
  }

  void _loadWebImage(XFile pickedFile) async {
    final bytes = await pickedFile.readAsBytes();
    setState(() {
      _webImageBytes = bytes;
    });
  }

  Future<String?> _uploadImage() async {
    if (_pickedImage == null) return null;
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef =
          FirebaseStorage.instance.ref().child('book_images').child(fileName);

      if (kIsWeb) {
        await storageRef.putData(_webImageBytes!);
      } else {
        await storageRef.putFile(File(_pickedImage!.path));
      }

      return await storageRef.getDownloadURL();
    } catch (e) {
      _showSnackbar('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveBookToFirestore(Map<String, dynamic> book) async {
    try {
      await FirebaseFirestore.instance.collection('books').add(book);
      _showSnackbar('Book added successfully!');
      widget.onBookAdded(book);
    } catch (e) {
      _showSnackbar('Error adding book: $e');
    }
  }

  Future<void> _addBook() async {
    if (_formKey.currentState!.validate()) {
      if (selectedCategory == null) {
        _showSnackbar('Please select a category.');
        return;
      }

      setState(() {
        _isUploading = true;
      });

      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await _uploadImage();
      } else {
        imageUrl = _thumbnailController.text.isNotEmpty
            ? _thumbnailController.text
            : null;
      }

      final book = {
        'title': _titleController.text,
        'authors': _authorController.text
            .split(',')
            .map((author) => author.trim())
            .toList(),
        'thumbnail': imageUrl ?? 'No image available',
        'description': _descriptionController.text,
        'isbn': _isbnController.text,
        'price': int.parse(_priceController.text),
        'category': selectedCategory,
        'created_at': Timestamp.now(),
        'isNewArrival': _isNewArrival,
      };

      await _saveBookToFirestore(book);
      await _fetchNewArrivals(); // Fetch new arrivals after adding a book

      setState(() {
        _isUploading = false;
        _clearForm();
      });
    } else {
      _showSnackbar('Please fill all fields correctly.');
    }
  }

  void _clearForm() {
    _titleController.clear();
    _authorController.clear();
    _priceController.clear();
    _descriptionController.clear();
    _isbnController.clear();
    _pickedImage = null;
    _webImageBytes = null;
    selectedCategory = null;
    _thumbnailController.clear();
    _isNewArrival = true;
  }

  void _showSnackbar(String message) {
    Get.snackbar(
      'Notice',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  Widget _buildImagePreview() {
    if (_pickedImage == null) {
      return const Text('No image selected');
    }
    return kIsWeb && _webImageBytes != null
        ? Image.memory(_webImageBytes!, height: 150, fit: BoxFit.cover)
        : Image.file(File(_pickedImage!.path), height: 150, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Book Details'),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.white, // Set the background color to white

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextFormField(
                _titleController,
                'Book Title',
                'Enter a title',
              ),
              const SizedBox(height: 10),
              _buildTextFormField(
                _authorController,
                'Author(s)',
                'Enter an author',
              ),
              const SizedBox(height: 10),
              _buildTextFormField(
                _priceController,
                'Price',
                'Enter a valid integer',
                keyboardType: TextInputType.number,
                validator: _validatePrice,
              ),
              const SizedBox(height: 10),
              _buildTextFormField(
                _isbnController,
                'ISBN',
                'Enter a valid ISBN',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an ISBN';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _buildCategoryDropdown(),
              const SizedBox(height: 10),
              _buildTextFormField(
                _descriptionController,
                'Description',
                'Enter a description',
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              _buildTextFormField(
                _thumbnailController,
                'Thumbnail URL (optional)',
                'Enter a valid URL',
                maxLines: 1,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!Uri.tryParse(value)!.hasScheme) {
                      return 'Enter a valid URL';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                title: const Text('Mark as New Arrival'),
                value: _isNewArrival,
                onChanged: (value) {
                  setState(() {
                    _isNewArrival = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              _buildImagePreview(),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo),
                label: const Text('Upload Image'),
              ),
              const SizedBox(height: 20),
              _isUploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _addBook,
                      child: const Text('Add Book'),
                    ),
              const SizedBox(height: 20),
              const Text('New Arrivals',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              _buildNewArrivalsList(),
            ],
          ),
        ),
      ),
    );
  }

  TextFormField _buildTextFormField(
    TextEditingController controller,
    String label,
    String validationMessage, {
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator:
          validator ?? (value) => value!.isEmpty ? validationMessage : null,
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Select Category'),
      value: selectedCategory,
      items: categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedCategory = value;
        });
      },
      validator: (value) => value == null ? 'Please select a category' : null,
    );
  }

  String? _validatePrice(String? value) {
    if (value == null || value.isEmpty) return 'Enter a price';
    final n = int.tryParse(value);
    if (n == null || n <= 0) return 'Enter a valid positive integer';
    return null;
  }

  Widget _buildNewArrivalsList() {
    if (newArrivals.isEmpty) {
      return const Text('No new arrivals available');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: newArrivals.length,
      itemBuilder: (context, index) {
        final book = newArrivals[index];
        return ListTile(
          title: Text(book['title']),
          subtitle: Text('By: ${book['authors'].join(', ')}'),
          trailing: Text('PKR ${book['price']}'),
        );
      },
    );
  }
}
