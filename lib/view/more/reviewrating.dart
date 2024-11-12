import 'package:bookstore/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        backgroundColor: whiteColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Pending Reviews"),
            Tab(text: "Completed Reviews"),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingReviews(),
          _buildCompletedReviews(),
        ],
      ),
    );
  }

  // Widget to show Pending Reviews
  Widget _buildPendingReviews() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('reviewstatus', isEqualTo: 'pending')
          .where('orderStatus', isEqualTo: 'Delivered')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var orders = snapshot.data!.docs;
        if (orders.isEmpty) {
          return const Center(child: Text("No pending reviews"));
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            var order = orders[index];
            return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 3,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  title: Text(order['bookTitle']),
                  subtitle: Text('Quantity: ${order['quantity']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.rate_review),
                    onPressed: () {
                      // Fetch the user data and open the review dialog
                      _openReviewDialog(
                        order.id,
                        order['bookTitle'],
                        order['quantity'],
                        order['userName'], // Get the user name from the order
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Widget to show Completed Reviews with swipe to delete functionality
  Widget _buildCompletedReviews() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('productReview').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var reviews = snapshot.data!.docs;
        if (reviews.isEmpty) {
          return const Center(child: Text("No completed reviews"));
        }

        return ListView.builder(
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            var review = reviews[index];
            return Dismissible(
              key: Key(review.id), // Unique key for each review
              direction:
                  DismissDirection.endToStart, // Swipe from right to left
              onDismissed: (direction) async {
                // 1. Update the review status back to "pending" in the "orders" collection
                String orderId =
                    review['orderId']; // The order ID from the review document
                await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(orderId)
                    .update({
                  'reviewstatus':
                      'pending', // Change the review status back to pending
                });

                // 2. Delete the review from the "productReview" collection
                await FirebaseFirestore.instance
                    .collection('productReview')
                    .doc(review.id)
                    .delete();

                // Show a snackbar message to the user
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review moved back to pending')),
                );
              },
              background: Container(
                color: Colors.red, // Background color for the swipe action
                alignment: Alignment.centerRight,
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 3,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    title: Text(review['bookTitle']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quantity: ${review['quantity']}'),
                        const SizedBox(height: 8),
                        // Rating in stars
                        RatingBar.builder(
                          initialRating: review['rating'].toDouble(),
                          minRating: 1,
                          itemSize: 20,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemPadding:
                              const EdgeInsets.symmetric(horizontal: 2.0),
                          onRatingUpdate: (rating) {},
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Comment: ${review['comment']}'),
                        const SizedBox(height: 8),
                        // Display the user name of the reviewer
                        Text('Reviewed by: ${review['userName']}'),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Open a dialog for submitting a review
  void _openReviewDialog(
      String orderId, String title, int quantity, String userName) {
    final ratingController = TextEditingController();
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Submit Your Review"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RatingBar.builder(
                  initialRating: 0,
                  minRating: 1,
                  itemSize: 30,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  onRatingUpdate: (rating) {
                    ratingController.text = rating.toString();
                  },
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Write your comment here...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                var rating = double.parse(ratingController.text);
                var comment = commentController.text;

                // Update Firestore with the review and change the review status
                await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(orderId)
                    .update({
                  'reviewstatus': 'complete',
                });

                // Add review to the productReview collection
                await FirebaseFirestore.instance
                    .collection('productReview')
                    .add({
                  'userName': userName,
                  'bookTitle': title,
                  'quantity': quantity,
                  'rating': rating,
                  'comment': comment,
                  'orderId': orderId, // Store orderId to associate with order
                });

                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
