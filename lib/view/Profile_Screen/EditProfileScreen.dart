import 'package:bookstore/view/auth_screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  String userName = '';
  String userPhoneNumber = '';
  String userAddress = '';
  bool isLoading = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, String>> savedCards = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchSavedCards();
  }

  Future<void> _fetchUserData() async {
    String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        DocumentSnapshot snapshot =
            await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (snapshot.exists) {
          setState(() {
            userName = snapshot['name'] ?? 'No Name';
            userPhoneNumber = snapshot['phone'] ?? 'No Phone Number';
            userAddress = snapshot['address'] ?? 'No Address';
            isLoading = false;
          });
        } else {
          Get.snackbar("Error", "User data not found.");
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        Get.snackbar("Error", "Failed to fetch user data: $e");
        setState(() {
          isLoading = false;
        });
      }
    } else {
      Get.snackbar("Error", "User not logged in.");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchSavedCards() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
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
      } catch (e) {
        Get.snackbar("Error", "Failed to fetch saved cards: $e");
      }
    }
  }

  Future<void> _updateUserData(String field, String newValue) async {
    String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({field: newValue});
        Get.snackbar("Success", "$field updated successfully.");
      } catch (e) {
        Get.snackbar("Error", "Failed to update $field: $e");
      }
    }
  }

 Future<void> _deleteAccount() async {
  User? user = _auth.currentUser;
  if (user != null) {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      await user.delete();
      Get.offAll(() => const Login_Screen(), arguments: {'message': 'Your account has been deleted.'});
    } catch (e) {
      Get.snackbar("Error", "Failed to delete account: $e");
    }
  }
}


  void _showAccountDeletionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('Are you sure you want to delete your account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return PasswordChangeDialog(
          onSave: _changePassword,
        );
      },
    );
  }

  Future<void> _changePassword(String oldPassword, String newPassword) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        AuthCredential credential =
            EmailAuthProvider.credential(email: user.email!, password: oldPassword);
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
        Get.snackbar("Success", "Password changed successfully.");
      } catch (e) {
        Get.snackbar("Error", "Failed to change password: $e");
      }
    }
  }

Widget _buildTile(IconData icon, String title, String detail, [String? field, Function()? onTap]) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          blurRadius: 5,
          spreadRadius: 1,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: InkWell(
      onTap: onTap ?? (field != null ? () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) => SmallModal(
            title: title,
            field: field,
            detail: detail,
            onSave: (newValue) {
              // Validate phone number
              if (field == 'phone') {
                if (newValue.length != 11 || !RegExp(r'^\d+$').hasMatch(newValue)) {
                  Get.snackbar("Error", "Phone number must be exactly 11 digits and contain only numbers.");
                  return; // Do not proceed if validation fails
                }
              }

              // Update state and Firestore
              setState(() {
                if (field == 'name') userName = newValue;
                if (field == 'phone') userPhoneNumber = newValue;
                if (field == 'address') userAddress = newValue;
              });
              _updateUserData(field, newValue);
            },
          ),
        );
      } : null),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        leading: Icon(icon),
        title: Text(title),
        subtitle: detail.isNotEmpty ? Text(detail) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    ),
  );
}



  Widget _buildCardTile(Map<String, String> card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        title: Text("**** **** **** ${card['cardNumber']?.substring(12)}"),
        subtitle: Text("Expiry Date: ${card['expiryDate']}"),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showCardDeletionDialog(card['cardNumber']!),
        ),
      ),
    );
  }

  void _showCardDeletionDialog(String cardNumber) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Card'),
          content: const Text('Are you sure you want to delete this card?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteCard(cardNumber);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCard(String cardNumber) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cards')
            .where('cardNumber', isEqualTo: cardNumber)
            .get()
            .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.delete();
          }
        });

        Get.snackbar("Success", "Card deleted successfully.");
        _fetchSavedCards(); // Refresh the card list
      } catch (e) {
        Get.snackbar("Error", "Failed to delete card: $e");
      }
    }
  }

  void _showSavedCardsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          height: 400,
          child: Column(
            children: [
              Text('Saved Cards', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: savedCards.map((card) {
                    return ListTile(
                      title: Text("**** **** **** ${card['cardNumber']?.substring(12)}"),
                      subtitle: Text("Expiry Date: ${card['expiryDate']}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the modal
                          _showEditCardModal(card); // Show the edit modal
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditCardModal(Map<String, String> card) {
    final cardNumberController = TextEditingController(text: card['cardNumber']);
    final expiryDateController = TextEditingController(text: card['expiryDate']);
    final cardHolderNameController = TextEditingController(text: card['cardHolderName']);
    final cvcController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cardNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Card Number'),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
              ),
              TextField(
                controller: expiryDateController,
                decoration: const InputDecoration(labelText: 'Expiry Date (MM/YY)'),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
                
              ),
              TextField(
                controller: cardHolderNameController,
                decoration: const InputDecoration(labelText: 'Card Holder Name'),
                inputFormatters: [LengthLimitingTextInputFormatter(40)],
              ),
              TextField(
                controller: cvcController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'CVC'),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_validateCardData(cardNumberController.text, expiryDateController.text, cardHolderNameController.text, cvcController.text)) {
                  _updateCard(card['cardNumber']!, cardNumberController.text, expiryDateController.text, cardHolderNameController.text, cvcController.text);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  bool _validateCardData(String cardNumber, String expiryDate, String cardHolderName, String cvc) {
    if (cardNumber.length != 16 || !RegExp(r'^[0-9]+$').hasMatch(cardNumber)) {
      Get.snackbar("Error", "Card number must be 16 digits long and numeric.");
      return false;
    }
    if (cardHolderName.length > 40 || !RegExp(r'^[a-zA-Z\s]+$').hasMatch(cardHolderName)) {
      Get.snackbar("Error", "Card holder name must be alphabetic and up to 40 characters.");
      return false;
    }
    if (cvc.length != 3 || !RegExp(r'^[0-9]+$').hasMatch(cvc)) {
      Get.snackbar("Error", "CVC must be 3 digits long and numeric.");
      return false;
    }
    return true;
  }

  Future<void> _updateCard(String oldCardNumber, String newCardNumber, String expiryDate, String cardHolderName, String cvc) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        QuerySnapshot cardsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cards')
            .where('cardNumber', isEqualTo: oldCardNumber)
            .get();

        for (var doc in cardsSnapshot.docs) {
          await doc.reference.update({
            'cardNumber': newCardNumber,
            'expiryDate': expiryDate,
            'cardHolderName': cardHolderName,
            'cvc': cvc,
          });
        }

        Get.snackbar("Success", "Card updated successfully.");
        _fetchSavedCards(); // Refresh the card list
      } catch (e) {
        Get.snackbar("Error", "Failed to update card: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white, // Set the background color to white

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildTile(Icons.person, 'User Name', userName, 'name'),
                _buildTile(Icons.phone, 'Phone Number', userPhoneNumber, 'phone'),
                _buildTile(Icons.home, 'Address', userAddress, 'address'),
                _buildTile(Icons.lock, 'Change Password', '', null, _showChangePasswordDialog),
                _buildTile(Icons.payment, 'Saved Cards', '', null, () {
                  _showSavedCardsModal();
                }),
                ...savedCards.map((card) => _buildCardTile(card)),
                _buildTile(Icons.delete, 'Request Account Deletion', '', null, _showAccountDeletionDialog),
              ],
            ),
    );
  }
}

class SmallModal extends StatefulWidget {
  final String title;
  final String field;
  final String detail;
  final ValueChanged<String> onSave;

  const SmallModal({
    super.key,
    required this.title,
    required this.field,
    required this.detail,
    required this.onSave,
  });

  @override
  _SmallModalState createState() => _SmallModalState();
}

class _SmallModalState extends State<SmallModal> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.detail);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: widget.title,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              widget.onSave(_controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class PasswordChangeDialog extends StatelessWidget {
  final void Function(String, String) onSave;

  const PasswordChangeDialog({super.key, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    return AlertDialog(
      title: const Text('Change Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: oldPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Old Password'),
          ),
          TextField(
            controller: newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New Password'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            onSave(oldPasswordController.text, newPasswordController.text);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
