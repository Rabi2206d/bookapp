import 'dart:async';
import 'package:bookstore/view/more/checkout_view.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';

class ItemDetails extends StatefulWidget {
  final String title;
  final String imageUrl;
  final String description;
  final String price;
  final String isbn;
  final String authors;

  const ItemDetails({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.price,
    required this.isbn,
    required this.authors,
  });

  @override
  _ItemDetailsState createState() => _ItemDetailsState();
}

class _ItemDetailsState extends State<ItemDetails> {
  bool isFavorited = false;
  bool isLoadingNewArrivals = true;
  bool isLoadingReviews = true;
  bool isLoadingAllReviews =
      false; // To track if more reviews are being fetched
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> books = [];
  List<Map<String, dynamic>> reviews = [];
  double? _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  int reviewsToShow = 3; // Show only 3 reviews initially
  int totalReviewsCount = 0; // Track total reviews count

  @override
  void initState() {
    super.initState();
    _checkIfFavorited();
    _fetchNewArrivals();
    _fetchReviews(); // Fetch reviews for the book
  }

  Future<void> _checkIfFavorited() async {
    firebase_auth.User? user = _auth.currentUser;
    if (user != null) {
      String userId = user.uid;
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(widget.title)
          .get();

      setState(() {
        isFavorited = doc.exists;
      });
    }
  }

  Future<void> _addToCart() async {
    firebase_auth.User? user = _auth.currentUser;
    if (user != null) {
      String userId = user.uid;
      DocumentReference userCartRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(widget.title);

      try {
        DocumentSnapshot doc = await userCartRef.get();
        if (doc.exists) {
          Get.snackbar('Cart', '"${widget.title}" is already in your cart.');
          return;
        }

        await userCartRef.set({
          'title': widget.title,
          'author': widget.authors,
          'imageUrl': widget.imageUrl,
          'price': widget.price,
          'email': user.email,
          'name': user.displayName,
        });
        Get.snackbar('Cart', 'Added "${widget.title}" to cart.');
      } catch (e) {
        Get.snackbar('Error', 'Error adding to cart: $e');
      }
    } else {
      Get.snackbar('Login Required', 'Please log in to add to cart.');
    }
  }

  void _shareItem() {
    final shareContent =
        'Check out "${widget.title}" by ${widget.authors}. Price: PKR ${widget.price}';
    Share.share(shareContent);
  }

  Future<void> _fetchNewArrivals() async {
    setState(() {
      isLoadingNewArrivals = true;
    });

    try {
      var snapshot = await _firestore
          .collection('books')
          .where('isNewArrival', isEqualTo: true)
          .limit(12)
          .get();

      setState(() {
        books = snapshot.docs.map((doc) {
          return {
            'title': doc['title'] ?? 'Unknown Title',
            'author': (doc['authors'] as List<dynamic>?)?.join(', ') ??
                'Unknown Author',
            'imageUrl': doc['thumbnail'] ?? '',
            'isbn': doc['isbn'] ?? 'N/A',
            'description': doc['description'] ?? 'No description available',
            'price': doc['price']?.toString() ?? '0',
          };
        }).toList();
      });
    } catch (e) {
      Get.snackbar('Error', 'Error fetching new arrivals: $e');
    } finally {
      setState(() {
        isLoadingNewArrivals = false;
      });
    }
  }

  Future<void> _fetchReviews({bool loadMore = false}) async {
    if (loadMore) {
      setState(() {
        isLoadingAllReviews =
            true; // Show loading indicator when fetching more reviews
      });
    } else {
      setState(() {
        isLoadingReviews = true;
      });
    }

    try {
      var snapshot = await _firestore.collection('reviews').get();
      totalReviewsCount = snapshot.docs.length; // Total reviews count

      setState(() {
        reviews = snapshot.docs.map((doc) {
          return {
            'username': doc['username'] ?? 'Anonymous',
            'rating': doc['rating'] ?? 0,
            'comment': doc['comment'] ?? 'No comment',
            'timestamp': doc['timestamp']?.toDate() ?? DateTime.now(),
          };
        }).toList();
      });
    } catch (e) {
      Get.snackbar('Error', 'Error fetching reviews: $e');
    } finally {
      setState(() {
        if (loadMore) {
          isLoadingAllReviews = false;
        } else {
          isLoadingReviews = false;
        }
      });
    }
  }

  Future<void> _submitReview() async {
    firebase_auth.User? user = _auth.currentUser;
    if (user != null && _rating != null) {
      String userId = user.uid;

      // Fetch user data to get the username
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      String userName = 'Anonymous'; // Default value

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('name')) {
          userName = data['name'] ?? 'Anonymous';
        }
      }

      // Save the review with the correct username
      DocumentReference reviewRef = _firestore.collection('reviews').doc();

      try {
        await reviewRef.set({
          'rating': _rating,
          'comment': _commentController.text,
          'username': userName, // Use the fetched username
          'timestamp': FieldValue.serverTimestamp(),
        });
        Get.snackbar('Review Submitted', 'Your review has been submitted!');
        _fetchReviews(); // Fetch updated reviews after submitting
      } catch (e) {
        Get.snackbar('Error', 'Failed to submit review: $e');
      }
    } else {
      Get.snackbar('Login Required', 'Please log in to submit a review.');
    }
  }

  Widget _buildNewArrivalsList() {
    return NewArrivals(books: books);
  }

  // Method to display rating stars (user can click to rate the book)
  Widget _buildRatingStars() {
    return Row(
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < (_rating ?? 0) ? Icons.star : Icons.star_border,
            color: Colors.orange,
          ),
          onPressed: () {
            setState(() {
              _rating = index + 1.0;
            });
          },
        );
      }),
    );
  }

  // Method to display the rating stars in a review
  Widget _buildRatingStarsDisplay(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.orange,
        );
      }),
    );
  }

  // Card for displaying reviews
  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.white, // White background for the card
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          title: Text(review['username'],
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRatingStarsDisplay(review['rating']),
              const SizedBox(height: 4),
              Text(review['comment']),
              const SizedBox(height: 4),
              Text(
                'Reviewed on: ${review['timestamp'].toString()}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

 Widget _buildReviewsSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'User Reviews',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      isLoadingReviews
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              height: reviews.length > reviewsToShow ? 300 : reviews.length * 100.0,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // Disable scroll on ListView
                itemCount: reviewsToShow > reviews.length
                    ? reviews.length
                    : reviewsToShow,
                itemBuilder: (context, index) {
                  return _buildReviewCard(reviews[index]);
                },
              ),
            ),
      if (reviewsToShow < totalReviewsCount)
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                reviewsToShow = totalReviewsCount; // Show all reviews
              });
              _fetchReviews(loadMore: true); // Fetch more reviews
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 42, 121, 43),
            ),
            child: const Text(
              'Load More Reviews',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
    ],
  );
}

  Future<void> _toggleFavorite() async {
    firebase_auth.User? user = _auth.currentUser;
    if (user != null) {
      String userId = user.uid;
      DocumentReference userWishlistRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(widget.title);

      try {
        if (isFavorited) {
          await userWishlistRef.delete();
          Get.snackbar('Wishlist', 'Removed "${widget.title}" from wishlist.');
        } else {
          await userWishlistRef.set({
            'title': widget.title,
            'author': widget.authors,
            'imageUrl': widget.imageUrl,
            'price': widget.price,
            'isbn': widget.isbn,
            'description': widget.description,
            'email': user.email,
            'name': user.displayName,
          });
          Get.snackbar('Wishlist', 'Added "${widget.title}" to wishlist.');
        }
        setState(() {
          isFavorited = !isFavorited;
        });
      } catch (e) {
        Get.snackbar('Error', 'Error saving to wishlist: $e');
      }
    } else {
      Get.snackbar('Login Required', 'Please log in to add to wishlist.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color.fromARGB(255, 195, 89, 27),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              isFavorited ? Icons.favorite : Icons.favorite_outline,
              color: isFavorited
                  ? Colors.red
                  : const Color.fromARGB(255, 62, 58, 58),
            ),
          ),
          IconButton(
            onPressed: _shareItem,
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Book image
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                      child: Icon(Icons.image_not_supported, size: 80));
                },
              ),
            ),
            const SizedBox(height: 16),
            // Title, Authors, ISBN, Price and Buttons (unchanged)
            Text(widget.title,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('by ${widget.authors}',
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 12),
            Text('ISBN: ${widget.isbn}',
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 12),
            Text('Price: PKR ${widget.price}',
                style: const TextStyle(color: Colors.red, fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 42, 121, 43),
              ),
              child: const Text('Add to Cart',
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutView(
                      title: widget.title,
                      price: double.parse(widget.price).toInt(),
                      imageUrl: widget.imageUrl,
                      selectedItems: const [],
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 195, 89, 27),
              ),
              child:
                  const Text('Buy Now', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 16),
            Text(widget.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),

            // Rating and Review Section
            const SizedBox(height: 16),
            const Text('Rate this book:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            _buildRatingStars(),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Leave a comment...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 42, 121, 43),
              ),
              child: const Text('Submit Review',
                  style: TextStyle(color: Colors.white)),
            ),

            // Reviews Section (Now limited to 3 reviews)
            const SizedBox(height: 16),
            _buildReviewsSection(),
            // Reviews Section
            const SizedBox(height: 16),
            // New Arrivals Section
            const Text('New Arrivals',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            isLoadingNewArrivals
                ? const Center(child: CircularProgressIndicator())
                : _buildNewArrivalsList(),
          ],
        ),
      ),
    );
  }
}

class NewArrivals extends StatefulWidget {
  final List<Map<String, dynamic>> books;

  const NewArrivals({super.key, required this.books});

  @override
  _NewArrivalsState createState() => _NewArrivalsState();
}

class _NewArrivalsState extends State<NewArrivals> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _startAutoScroll();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 7), (Timer timer) {
      if (_currentPage < (widget.books.length / 2).ceil() - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 340,
          width: double.infinity,
          child: GestureDetector(
            onPanUpdate: (details) {
              if (details.delta.dx > 0) {
                // User swiped right
                if (_currentPage > 0) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeIn,
                  );
                }
              } else if (details.delta.dx < 0) {
                // User swiped left
                if (_currentPage < (widget.books.length / 2).ceil() - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeIn,
                  );
                }
              }
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: (widget.books.length / 2).ceil(),
              itemBuilder: (context, index) {
                return _buildBookRow(index);
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildDots(),
      ],
    );
  }

  Widget _buildBookRow(int index) {
    int firstBookIndex = index * 2;
    int secondBookIndex = firstBookIndex + 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (firstBookIndex < widget.books.length)
          _buildBookCard(firstBookIndex),
        if (secondBookIndex < widget.books.length)
          _buildBookCard(secondBookIndex),
      ],
    );
  }

  Widget _buildBookCard(int index) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Image.network(
              widget.books[index]['imageUrl'],
              width: 140,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                    child: Icon(Icons.image_not_supported, size: 60));
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.books[index]['title'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              'PKR ${widget.books[index]['price']}',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 6),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemDetails(
                      title: widget.books[index]['title'],
                      imageUrl: widget.books[index]['imageUrl'],
                      description: widget.books[index]['description'],
                      price: widget.books[index]['price'],
                      isbn: widget.books[index]['isbn'],
                      authors: widget.books[index]['author'],
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 195, 89, 27),
              ),
              child: const Text('View Details',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate((widget.books.length / 2).ceil(), (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: _currentPage == index ? 12.0 : 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index ? Colors.black : Colors.grey,
          ),
        );
      }),
    );
  }
}
