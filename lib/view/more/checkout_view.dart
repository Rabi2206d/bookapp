import 'package:bookstore/view/more/checkout_message_view.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookstore/common/color_extension.dart';
import 'package:bookstore/common_widget/round_button.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CheckoutView extends StatefulWidget {
  final String title;
  final int price;
  final String imageUrl;

  const CheckoutView({
    super.key,
    required this.title,
    required this.price,
    required this.imageUrl, required List<String> selectedItems,
  });


  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  List<Map<String, String>> paymentArr = [
    {"name": "Cash on delivery", "icon": "assets/img/cash.png"},
    {"name": "Credit Card", "icon": "assets/img/visa_icon.png"},
    {"name": "PayPal", "icon": "assets/img/paypal.png"},
  ];

  List<Map<String, dynamic>> savedCards = [];
  int selectMethod = -1;
  double deliveryPrice = 150.0;
  int quantity = 1;

  String? userName;
  String? userPhone;
  String? userAddress;

  String cardNumber = '';
  String cardHolderName = '';
  String expiryDate = '';
  String cvvCode = '';
  bool isCvvFocused = false;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _fetchSavedCards();
  }

  void _fetchUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name'];
          userPhone = userDoc['phone'];
          userAddress = userDoc['address'];
        });
      }
    }
  }

  void _fetchSavedCards() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      QuerySnapshot cardsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cards')
          .get();

      setState(() {
        savedCards = cardsSnapshot.docs.map((doc) {
          return {
            'cardNumber': doc['cardNumber'] as String,
            'expiryDate': doc['expiryDate'] as String,
            'cardHolderName': doc['cardHolderName'] as String,
          };
        }).toList();
      });
    }
  }

  bool _isValidCardHolderName(String name) {
    return name.isNotEmpty && name.length <= 40;
  }

  bool _isValidCardNumber(String number) {
    return number.length == 16 && RegExp(r'^\d+$').hasMatch(number);
  }

  bool _isValidCvv(String cvv) {
    return cvv.length == 3 && RegExp(r'^\d+$').hasMatch(cvv);
  }

  bool _isValidExpiryDate(String expiry) {
    return expiry.length == 4 && RegExp(r'^\d+$').hasMatch(expiry);
  }

  bool _validateCreditCard() {
    if (!_isValidCardHolderName(cardHolderName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Card holder name must be provided and up to 40 characters.")),
      );
      return false;
    }
    if (!_isValidCardNumber(cardNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Card number must be exactly 16 digits.")),
      );
      return false;
    }
    if (!_isValidCvv(cvvCode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("CVV must be exactly 3 digits.")),
      );
      return false;
    }
    if (!_isValidExpiryDate(expiryDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Expiry date must be in MM/YY format.")),
      );
      return false;
    }
    return true;
  }

  void _saveCardInformation() async {
    if (_validateCreditCard()) {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cards')
            .add({
          'cardNumber': cardNumber,
          'expiryDate': expiryDate,
          'cardHolderName': cardHolderName,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Card information saved successfully.")),
        );

        _fetchSavedCards();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double originalTotal = (widget.price * quantity) + deliveryPrice;
    double discountAmount =
        (quantity >= 3 && quantity <= 5) ? originalTotal * 0.10 : 0.0;
    double total = originalTotal - discountAmount;

    return Scaffold(
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 46),
              _buildHeader(context),
              _buildDivider(),
              _buildPersonalInformation(),
              _buildDivider(),
              _buildDeliveryAddress(),
              _buildDivider(),
              _buildPaymentMethod(),
              if (selectMethod == 1) _buildCreditCardInput(),
              _buildDivider(),
              if (selectMethod == 1) _buildSavedCards(),
              _buildDivider(),
              _buildOrderSummary(total, discountAmount),
              _buildDivider(),
              _buildSendOrderButton(context, total, widget.title),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Image.asset("assets/img/btn_back.png", width: 20, height: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Checkout",
              style: TextStyle(
                color: TColor.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: TColor.secondaryText.withOpacity(0.5), height: 20);
  }

  Widget _buildPersonalInformation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Personal Information",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: TColor.secondaryText.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName ?? "User Name: Not provided",
                  style: TextStyle(color: TColor.secondaryText),
                ),
                Text(
                  userPhone ?? "User Phone: Not provided",
                  style: TextStyle(color: TColor.secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Delivery Address",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              if (userAddress == null) {
                _fetchUserDetails();
              } else {
                _showEditAddressDialog(); // New method for editing
              }
            },
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: TColor.secondaryText.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      userAddress ?? "Please enter your address",
                      style: TextStyle(color: TColor.secondaryText),
                    ),
                  ),
                  Icon(Icons.edit, color: TColor.primaryText), // Edit icon
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditAddressDialog() {
    final TextEditingController addressController =
        TextEditingController(text: userAddress);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Your Address"),
          content: TextField(
            controller: addressController,
            decoration: const InputDecoration(labelText: "Address"),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                setState(() {
                  userAddress = addressController.text;
                });
                // Save the updated address to Firestore
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({
                    'address': userAddress,
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentMethod() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Payment Method",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Column(
            children: List.generate(paymentArr.length, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectMethod = index;
                    if (index != 1) {
                      cardNumber = '';
                      cardHolderName = '';
                      expiryDate = '';
                      cvvCode = '';
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selectMethod == index
                          ? TColor.primaryText
                          : TColor.secondaryText.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset(paymentArr[index]['icon']!,
                          width: 30, height: 30),
                      const SizedBox(width: 10),
                      Text(paymentArr[index]['name']!,
                          style: TextStyle(color: TColor.primaryText)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardInput() {
    // Only show credit card fields if there are no saved cards
    if (savedCards.isNotEmpty) {
      return const SizedBox(); // Return an empty widget if saved cards are available
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Credit Card Information",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            decoration: const InputDecoration(labelText: "Card Holder Name"),
            maxLength: 30,
            onChanged: (value) {
              setState(() {
                cardHolderName = value;
              });
            },
          ),
          TextField(
            decoration: const InputDecoration(labelText: "Card Number"),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly
            ], // Allow only digits
            maxLength: 16,
            onChanged: (value) {
              setState(() {
                cardNumber = value.replaceAll(
                    RegExp(r'[^0-9]'), ''); // Remove non-numeric characters
              });
            },
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration:
                      const InputDecoration(labelText: "Expiry Date (MM/YY)"),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ], // Allow only digits
                  onChanged: (value) {
                    setState(() {
                      expiryDate = value.replaceAll(RegExp(r'[^0-9]'),
                          ''); // Remove non-numeric characters
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: "CVV"),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ], // Allow only digits
                  maxLength: 3,
                  onChanged: (value) {
                    setState(() {
                      cvvCode = value.replaceAll(RegExp(r'[^0-9]'),
                          ''); // Remove non-numeric characters
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _saveCardInformation,
            child: const Text("Save Card Information"),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Saved Cards",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Column(
            children: savedCards.map((card) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: TColor.secondaryText.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "Card Number: ${card['cardNumber']!.replaceRange(0, 12, '**** **** **** ')}"),
                          Text("Expiry Date: ${card['expiryDate']}"),
                          Text("Card Holder: ${card['cardHolderName']}"),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteCard(card['cardNumber']),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _deleteCard(String cardNumber) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      QuerySnapshot cardsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cards')
          .where('cardNumber', isEqualTo: cardNumber)
          .get();

      for (var doc in cardsSnapshot.docs) {
        await doc.reference.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Card deleted successfully.")),
        );
      }

      _fetchSavedCards(); // Refresh the saved cards list
    }
  }
 final TextEditingController _specialInstructionsController = TextEditingController();
  Widget _buildOrderSummary(double total, double discountAmount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),
          const Text("Order Summary",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          _buildBookDetailTile(),
          const SizedBox(height: 4),
          Text(
            "Total Book Price: PKR ${widget.price * quantity}",
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "Delivery Price: PKR $deliveryPrice",
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Divider(color: TColor.secondaryText.withOpacity(0.5)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text("PKR ${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          if (discountAmount > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Discount Applied: 10%",
                  style: TextStyle(color: Colors.green, fontSize: 14),
                ),
                Text(
                  "You saved: PKR ${discountAmount.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
            ),
          Divider(color: TColor.secondaryText.withOpacity(0.7)),
          const SizedBox(height: 15),
          const Text("Special Instructions",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 15),
          TextField(
            controller: _specialInstructionsController,
            maxLines: 5, 
            decoration: const InputDecoration(
              labelText: 'Order Notes',
              border: OutlineInputBorder(),
              hintText: 'Add any special instructions...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookDetailTile() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: TColor.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TColor.secondaryText.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Image.network(widget.imageUrl,
                    width: 50, height: 70, fit: BoxFit.cover),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("PKR ${widget.price}",
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    if (quantity > 1) quantity--;
                  });
                },
                icon: Icon(Icons.remove, color: TColor.primaryText),
              ),
              Text("$quantity", style: const TextStyle(fontSize: 16)),
              IconButton(
                onPressed: () {
                  if (quantity < 5) {
                    setState(() {
                      quantity++;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("You can buy only 5 quantities."),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: Icon(Icons.add, color: TColor.primaryText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOrderConfirmationDialog(
      BuildContext context, double totalAmount, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Your Order"),
          content: Text(
              "Total Amount: PKR ${totalAmount.toStringAsFixed(2)}\nBook Title: $title"),
          actions: [
            TextButton(
              onPressed: () {
                _placeOrder(title, totalAmount);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Confirm"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

Widget _buildSendOrderButton(BuildContext context, double totalAmount, String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
    child: RoundButton(
      title: "Place Order",
      onPressed: () {
        if (selectMethod < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please select a payment method.")),
          );
          return; // Don't proceed if no payment method is selected
        }

        if (selectMethod == 1 && savedCards.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please save a credit card before placing an order.")),
          );
          return; // Don't proceed if no saved cards are available
        }

        _showOrderConfirmationDialog(context, totalAmount, title);
      },
    ),
  );
}

Future<void> _placeOrder(String title, double totalAmount) async {
  User? user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You must be logged in to place an order.")),
    );
    return;
  }

  // Create an order ID
  String orderId = DateTime.now().millisecondsSinceEpoch.toString();
  String specialInstructions = _specialInstructionsController.text;

  String paymentMethod;
  if (selectMethod == 0) {
    paymentMethod = "Cash on delivery";
  } else if (selectMethod == 1) {
    paymentMethod = "cardNumber"; // Store the card number if Credit Card is selected
  } else if (selectMethod == 2) {
    paymentMethod = "PayPal";
  } else {
    Get.snackbar("Error", "Please select a valid payment method.");
    return;
  }

  try {
    await FirebaseFirestore.instance.collection('orders').add({
      'orderId': orderId,
      'userId': user.uid,
      'userName': userName,
      'userPhone': userPhone,
      'userAddress': userAddress,
      'imageUrl': widget.imageUrl,
      'bookTitle': title,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'quantity': quantity,
      'specialInstructions': specialInstructions,
      'orderStatus': 'Not Approved',
      'reviewstatus': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    Get.snackbar("Success", "Order placed successfully.");
    
    // Show confirmation message
    _showCheckoutMessage(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error placing order: $e")),
    );
  }
}

void _showCheckoutMessage(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: false, // Prevent dismissal on tap outside
    enableDrag: false, // Disable dragging
    builder: (context) {
      return Container(
        color: Colors.white, // Background color of the modal
        child: const CheckoutMessageView(), // Your checkout message view
      );
    },
  );
}

}

