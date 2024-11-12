import 'package:bookstore/view/more/checkout_view.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class RoundButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  const RoundButton({super.key, required this.title, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300, // Set your desired width here
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 255, 175, 0), // Lighter orange
            Color.fromARGB(255, 255, 140, 0), // Darker orange
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 231, 166, 27).withOpacity(0.5),
            blurRadius: 12, // Increased blur for a softer shadow
            offset: const Offset(0, 6), // Adjusted offset for depth
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white, // Changed text color to white for better contrast
            fontWeight: FontWeight.bold,
            fontSize: 18, // Increased font size for better readability
            letterSpacing: 1.2, // Added letter spacing for a cleaner look
          ),
        ),
      ),
    );
  }
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final double deliveryPrice = 150.0;
  double total = 0.0;
  Map<String, int> quantities = {};
  Map<String, double> prices = {};
  String? selectedItemId;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      QuerySnapshot cartSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      total = 0.0;
      quantities.clear();
      prices.clear();

      for (var doc in cartSnapshot.docs) {
        double price = double.tryParse(doc['price'] ?? '0') ?? 0.0;
        quantities[doc.id] = 1; // Default quantity is 1
        prices[doc.id] = price;
        total += price;
      }

      setState(() {
        total += deliveryPrice;
      });
    } catch (e) {
      Get.snackbar("Error", "Failed to load cart items.");
    }
  }

  Future<void> _removeItem(String docId) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(docId)
          .delete();

      setState(() {
        quantities.remove(docId);
        prices.remove(docId);
        total -= (prices[docId] ?? 0.0);
      });
    } catch (e) {
      Get.snackbar("Error", "Failed to remove item from cart.");
    }
  }

  void _updateQuantity(String docId, int newQuantity) {
    setState(() {
      quantities[docId] = newQuantity;
    });
    _calculateTotal();
  }

  void _calculateTotal() {
    total = deliveryPrice + quantities.entries.fold(0.0, (sum, entry) {
      return sum + (prices[entry.key] ?? 0.0) * entry.value;
    });
    setState(() {});
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
        title: const Text("Cart", style: TextStyle(color: Colors.black)),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.withOpacity(0.15), height: 3),
        ),
      ),
      backgroundColor: Colors.white, // Set the background color to white

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('cart')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Cart is Empty!'));
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      String docId = doc.id;
                      double price = double.tryParse(doc['price'] ?? '0') ?? 0.0;

                      return Dismissible(
                        key: Key(docId),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await _confirmDismiss(doc['title']);
                        },
                        onDismissed: (direction) {
                          _removeItem(docId);
                          Get.snackbar("Removed", "${doc['title']} removed from cart");
                        },
                        child: _buildBookDetailTile(
                          title: doc['title'],
                          imageUrl: doc['imageUrl'],
                          price: price,
                          quantity: quantities[docId] ?? 1,
                          isSelected: selectedItemId == docId,
                          onSelected: (isSelected) {
                            setState(() {
                              if (isSelected == true) {
                                selectedItemId = docId; // Only allow one item to be selected
                              } else {
                                selectedItemId = null;
                              }
                            });
                          },
                          onQuantityChanged: (newQuantity) {
                            _updateQuantity(docId, newQuantity);
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          _buildOrderSummary(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: RoundButton(
              title: "Buy",
              onPressed: () async {
                if (selectedItemId != null) {
                  var doc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .collection('cart')
                      .doc(selectedItemId)
                      .get();

                  if (doc.exists) {
                    String title = doc['title'];
                    double price = prices[selectedItemId] ?? 0.0;
                    String imageUrl = doc['imageUrl'];

                    // Navigate to CheckoutView with the required arguments
                    Get.to(() => CheckoutView(
                      title: title,
                      price: price.toInt(), // Assuming price should be an int
                      imageUrl: imageUrl,
                       selectedItems: const [],
                    ));

                    // Remove the item from Firestore
                    await _removeItem(selectedItemId!);
                  }
                } else {
                  Get.snackbar("No Item Selected", "Please select an item to proceed.");
                }
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  Future<bool> _confirmDismiss(String title) async {
    return await Get.defaultDialog(
      title: "Confirm",
      middleText: "Are you sure you want to remove $title from the cart?",
      onConfirm: () => Get.back(result: true),
      onCancel: () => Get.back(result: false),
    ) ?? false;
  }

  Widget _buildBookDetailTile({
    required String title,
    required String imageUrl,
    required double price,
    required bool isSelected,
    required ValueChanged<bool?> onSelected,
    required Function(int) onQuantityChanged, 
    required int quantity,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: onSelected,
          ),
          Image.network(imageUrl, width: 50, height: 70, fit: BoxFit.cover),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("PKR ${price.toStringAsFixed(2)}", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    double selectedTotal = (prices[selectedItemId] ?? 0.0) * (quantities[selectedItemId] ?? 0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Order Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          if (selectedItemId != null)
            Text("Total for Selected Item: PKR ${selectedTotal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.black, fontSize: 16)),
          Text("Delivery Price: PKR $deliveryPrice", style: const TextStyle(color: Color.fromARGB(255, 243, 240, 240), fontSize: 14)),
          const SizedBox(height: 8),
          Divider(color: Colors.grey.withOpacity(0.5)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Sub-total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text("PKR ${(selectedTotal + deliveryPrice).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }
}
