import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderslistScreen extends StatelessWidget {
  const OrderslistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white, // Set background color of the entire screen
        appBar: AppBar(
          title: const Text('My Orders'),
          backgroundColor: Colors.white, // White background for the AppBar
          elevation: 0, // Optional: to remove the shadow of the AppBar
          bottom: const TabBar(
            tabs: [
              Tab(text: "All Orders"),
              Tab(text: "To Ship"),
              Tab(text: "Complete"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OrdersListTab(filter: "all"), // All Orders Tab
            OrdersListTab(filter: "shipping"), // To Ship Tab
            OrdersListTab(filter: "delivered"), // Complete Tab
          ],
        ),
      ),
    );
  }
}

class OrdersListTab extends StatelessWidget {
  final String filter;

  const OrdersListTab({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error fetching orders: ${snapshot.error}'));
        }

        var orders = snapshot.data?.docs;

        if (orders == null || orders.isEmpty) {
          return const Center(child: Text('No orders found.'));
        }

        // Filter orders based on the selected tab
        List<QueryDocumentSnapshot> filteredOrders;
        if (filter == "all") {
          filteredOrders = orders;
        } else if (filter == "shipping") {
          filteredOrders = orders.where((order) {
            final data = order.data() as Map<String, dynamic>?;
            return data != null && data['orderStatus'] == 'In Shipping';
          }).toList();
        } else {
          filteredOrders = orders.where((order) {
            final data = order.data() as Map<String, dynamic>?;
            return data != null && data['orderStatus'] == 'Delivered';
          }).toList();
        }

        if (filteredOrders.isEmpty) {
          return const Center(child: Text('No orders in this category.'));
        }

        return ListView.builder(
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            var order = filteredOrders[index].data() as Map<String, dynamic>;
            String orderId = order['orderId']?.toString().trim() ?? 'Unknown ID';
            String imageUrl = order['imageUrl'] ?? '';
            String title = order['bookTitle'] ?? 'No Title';
            double price = (order['totalAmount'] ?? 0) is int
                ? (order['totalAmount'] as int).toDouble()
                : order['totalAmount'] ?? 0.0; // Fix for int -> double conversion
            int quantity = order['quantity'] ?? 0;
            String orderStatus = order['orderStatus'] ?? 'Not specified';

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white, // White background for the order container
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  _showOrderDetailsModal(context, order);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      imageUrl.isNotEmpty
                          ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Icons.image_not_supported),
                      const SizedBox(width: 16), // Space between image and text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Order ID: $orderId'),
                            Text('Price: PKR ${price.toStringAsFixed(0)}'),
                            Text('Quantity: $quantity'),
                            Text('Order Status: $orderStatus'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showOrderDetailsModal(BuildContext context, Map<String, dynamic> orderData) {
    final DateTime orderDate = (orderData['createdAt'] as Timestamp).toDate();
    final String orderStatus = orderData['orderStatus'] ?? 'Pending';
    final String trackingNumber = orderData['trackingNumber'] ?? 'Not Available';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white, // White background for the modal
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 5),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Order Details',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.purple[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(orderStatus == 'Delivered' ? 'Delivered' : 'In Progress',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 8),
                          Text(
                            orderStatus == 'Delivered' ? 'Your package has been delivered.' : 'Your package is in progress.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[700], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: () {
                        _showOrderTimeline(context, orderData);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Tap here for Delivery Status',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('User Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const Divider(thickness: 1.5),
                    const SizedBox(height: 8),
                    Text('Name: ${orderData['userName']}', style: const TextStyle(color: Colors.black87)),
                    Text('Phone: ${orderData['userPhone']}', style: const TextStyle(color: Colors.black87)),
                    Text('Address: ${orderData['userAddress']}', style: const TextStyle(color: Colors.black87)),
                    const SizedBox(height: 20),

                    const Text('Order Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const Divider(thickness: 1.5),
                    const SizedBox(height: 8),
                    if (orderData['imageUrl'] != null)
                      Center(child: Image.network(orderData['imageUrl'], height: 150, fit: BoxFit.cover)),
                    const SizedBox(height: 8),
                    Text('Product: ${orderData['bookTitle']}', style: const TextStyle(color: Colors.black87)),
                    Text('Quantity: ${orderData['quantity']}', style: const TextStyle(color: Colors.black87)),
                    Text('Total Amount: PKR ${orderData['totalAmount']}', style: const TextStyle(color: Colors.black87)),
                    const SizedBox(height: 20),

                    const Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const Divider(thickness: 1.5),
                    const SizedBox(height: 8),
                    Text('Order ID: ${orderData['orderId']}', style: const TextStyle(color: Colors.black87)),
                    Text('Tracking Number: $trackingNumber', style: const TextStyle(color: Colors.black87)),
                    Text('Placed on: ${orderDate.toLocal().toString().split(' ')[0]}', style: const TextStyle(color: Colors.black87)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showOrderTimeline(BuildContext context, Map<String, dynamic> orderData) {
    List<dynamic> timelineData = orderData['timeline'] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white, // White background for the timeline modal
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 5),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Delivery Detail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const Divider(thickness: 1.5),
                const SizedBox(height: 8),
                Text('Order ID: ${orderData['orderId']}', style: const TextStyle(color: Colors.black87)),
                Text('Tracking Number: ${orderData['trackingNumber']}', style: const TextStyle(color: Colors.black87)),
                Text('Placed on: ${orderData['createdAt']?.toDate().toLocal().toString().split(' ')[0]}', style: const TextStyle(color: Colors.black87)),
                const SizedBox(height: 20),

                const Text('Order Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const Divider(thickness: 1.5),
                const SizedBox(height: 8),

                // Build the timeline items from the fetched data
                Column(
                  children: List.generate(timelineData.length, (index) {
                    String status = timelineData[index]['status'];
                    DateTime date = (timelineData[index]['date'] as Timestamp).toDate();
                    return _buildTimelineItem(status, date, index, timelineData.length);
                  }),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineItem(String status, DateTime date, int index, int totalItems) {
    bool isLastItem = index == totalItems - 1;

    return Row(
      children: [
        // Vertical line
        Column(
          children: [
            Container(
              width: 2,
              height: isLastItem ? 0 : 30, // Hide line for last item
              color: Colors.grey,
            ),
            const SizedBox(height: 10), // Space between line and circle
            const Icon(Icons.circle, size: 12, color: Colors.blue), // Status indicator
            const SizedBox(height: 10), // Space below circle
          ],
        ),
        const SizedBox(width: 8), // Space between line and text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Text(status, style: const TextStyle(fontSize: 14))),
              Center(
                child: Text(
                  date.toLocal().toString().split(' ')[0],
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
