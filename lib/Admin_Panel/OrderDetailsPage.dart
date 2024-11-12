import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({super.key});

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  List<Map<String, dynamic>> _orders = [];
  String? selectedCurrentOrderStatus;
  String? selectedNewDeliveryStatus;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  String generateRandomTrackingNumber({int length = 14}) {
    const chars = '0123456789';
    Random random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _fetchOrders() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('orders').get();
      setState(() {
        _orders = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Add the document ID to the data
          return data;
        }).toList();
      });
    } catch (e) {
      print('Failed to fetch orders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch orders")),
      );
    }
  }

  Future<void> _updateOrderStatus(String orderId) async {
    try {
      DocumentReference orderDoc = FirebaseFirestore.instance.collection('orders').doc(orderId);
      DocumentSnapshot snapshot = await orderDoc.get();

      if (!snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order not found")),
        );
        return;
      }

      String? existingTrackingNumber = (snapshot.data() as Map<String, dynamic>)['trackingNumber'];
      String trackingNumber = existingTrackingNumber ?? generateRandomTrackingNumber();

      // Update the order status and tracking number
      await orderDoc.update({
        'orderStatus': selectedCurrentOrderStatus,
        'deliveryStatus': selectedNewDeliveryStatus,
        'trackingNumber': trackingNumber,
        'timeline': FieldValue.arrayUnion([
          {
            'status': selectedNewDeliveryStatus,
            'date': Timestamp.now(),
          }
        ])
      });

      _fetchOrders(); // Refresh the order list after the update
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order status updated to $selectedCurrentOrderStatus with tracking number $trackingNumber")),
      );
    } catch (e) {
      print('Failed to update order status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update order status")),
      );
    }
  }

  Future<void> _deleteOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).delete();
      _fetchOrders(); // Refresh the order list after deletion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order deleted successfully")),
      );
    } catch (e) {
      print('Failed to delete order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete order")),
      );
    }
  }

  void _showOrderTimeline(List<dynamic> timeline) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
          ),
          child: ListView.builder(
            itemCount: timeline.length,
            itemBuilder: (context, index) {
              var item = timeline[index];
              return ListTile(
                title: Text(item['status']),
                subtitle: Text(item['date'].toDate().toString()),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the background color to white
      body: _orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (order['imageUrl'] != null)
                          Image.network(
                            order['imageUrl'],
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Order ID: ${order['orderId']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text('User: ${order['userName']}'),
                        Text('Phone: ${order['userPhone']}'),
                        Text('Address: ${order['userAddress']}'),
                        Text('Book Title: ${order['bookTitle']}'),
                        Text('Total Amount: \$${order['totalAmount']}'),
                        Text('Quantity: ${order['quantity']}'),
                        Text('Special Instructions: ${order['specialInstructions'] ?? 'None'}'),
                        const SizedBox(height: 10),
                        Text('Current Order Status: ${order['orderStatus']}'),
                        Text('Current Delivery Status: ${order['deliveryStatus']}'),
                        if (order['trackingNumber'] != null)
                          Text('Tracking Number: ${order['trackingNumber']}'),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            _showOrderTimeline(order['timeline']);
                          },
                          child: const Text('View Timeline'),
                        ),
                        const SizedBox(height: 10),
                        DropdownButton<String>(
                          value: selectedCurrentOrderStatus,
                          hint: const Text('Select current order status'),
                          items: <String>[
                            'Not Approved',
                            'Cancelled',
                            'Approved',
                            'In Shipping',
                            'Delivered',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCurrentOrderStatus = newValue;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButton<String>(
                          value: selectedNewDeliveryStatus,
                          hint: const Text('Select new delivery status'),
                          items: <String>[
                            'Order Placed',
                            'Dispatch in Progress',
                            'Ready for Pickup',
                            'In Transit',
                            'Out for Delivery',
                            'Delivered',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedNewDeliveryStatus = newValue;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            if (selectedNewDeliveryStatus != null) {
                              _updateOrderStatus(order['id']);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please select a new delivery status")),
                              );
                            }
                          },
                          child: const Text('Change Status'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            // Confirm deletion
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Confirm Deletion"),
                                  content: const Text("Are you sure you want to delete this order?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // Close the dialog
                                      },
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _deleteOrder(order['id']);
                                        Navigator.of(context).pop(); // Close the dialog
                                      },
                                      child: const Text("Delete"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Delete Order'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
