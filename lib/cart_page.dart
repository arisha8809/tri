import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> _cartItems = [];
  double _totalPrice = 0.0;
  String userName = '';
  String userAddress = '';
  String userPhone = '';

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _fetchCartItems();
  }

  Future<void> _fetchUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userSnapshot.exists) {
        setState(() {
          userName = userSnapshot['name'] ?? '';
          userAddress = userSnapshot['address'] ?? '';
          userPhone = userSnapshot['phone_number'] ?? ''; // Existing phone_number field
        });
      }
    }
  }

  Future<void> _fetchCartItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      double totalPrice = 0.0;
      final cartItems = cartSnapshot.docs.map((doc) {
        final data = doc.data();
        totalPrice += (data['totalPrice'] as num).toDouble(); // Type handling for price
        return {
          'id': doc.id,
          'name': data['name'],
          'price': (data['price'] as num).toDouble(),
          'quantity': data['quantity'],
          'totalPrice': (data['totalPrice'] as num).toDouble(),
          'customization': data['customization'] ?? '', // Add customization field
        };
      }).toList();

      setState(() {
        _cartItems = cartItems;
        _totalPrice = totalPrice;
      });
    }
  }

  Future<void> _updateQuantity(String itemId, int newQuantity, double price) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(itemId);

      if (newQuantity == 0) {
        await cartRef.delete(); // Remove item if quantity is 0
      } else {
        await cartRef.update({
          'quantity': newQuantity,
          'totalPrice': newQuantity * price,
        });
      }

      _fetchCartItems(); // Refetch cart items
    }
  }

  Future<void> _placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart');
      final orderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orderHistory')
          .doc();

      final cartSnapshot = await cartRef.get();
      final cartItems = cartSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'itemId': doc.id,
          'quantity': data['quantity'],
          'totalPrice': (data['totalPrice'] as num).toDouble(),
          'customization': data['customization'] ?? '',
        };
      }).toList();

      await orderRef.set({
        'orderDate': Timestamp.now(),
        'totalPrice': _totalPrice,
        'items': cartItems,
      });

      // Clear the cart
      for (var doc in cartSnapshot.docs) {
        await cartRef.doc(doc.id).delete();
      }

      _fetchCartItems(); // Clear the cart UI
    }
  }

  void _addCustomization(String itemId, String customization) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(itemId);

      await cartRef.update({
        'customization': customization,
      });

      _fetchCartItems(); // Refetch cart items after adding customization
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Cart"),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Display user details
                  ListTile(
                    title: Text('Customer Details'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Name: $userName'),
                        Text('Phone: $userPhone'),
                        Text('Address: $userAddress'),
                      ],
                    ),
                  ),
                  const Divider(),
                  
                  // Display cart items
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return ListTile(
                        leading: Image.network(
                          'https://via.placeholder.com/80', // Placeholder for item image
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                        title: Text(item['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('₹${item['price']}'),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    _updateQuantity(item['id'], item['quantity'] - 1, item['price']);
                                  },
                                ),
                                Text('${item['quantity']}'),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    _updateQuantity(item['id'], item['quantity'] + 1, item['price']);
                                  },
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                _showCustomizationDialog(item['id'], item['customization']);
                              },
                              child: const Text('Add Customization'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Total price and place order button at the bottom
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Total: ₹$_totalPrice', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _placeOrder,
                  child: const Text('Place Order'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Show dialog for customization input
  void _showCustomizationDialog(String itemId, String currentCustomization) {
    final TextEditingController customizationController =
        TextEditingController(text: currentCustomization);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Customization'),
          content: TextField(
            controller: customizationController,
            decoration: const InputDecoration(labelText: 'Customization'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addCustomization(itemId, customizationController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
