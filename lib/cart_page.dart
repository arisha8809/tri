import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // For accessing CartModel
import 'dart:math'; // For the triangle animation
import 'models/cart_model.dart'; // Import CartModel

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> _cartItems = [];
  double _totalPrice = 0.0;
  String userName = 'N/A';  // Default value for username
  String userAddress = 'N/A';
  String userPhone = 'N/A';

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _fetchCartItems();
  }

  // Fetch user details (username, phone, address) from Firestore
  Future<void> _fetchUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userSnapshot.exists) {
        setState(() {
          userName = userSnapshot.data()?['username'] ?? 'N/A'; 
          userAddress = userSnapshot.data()?['address'] ?? 'N/A'; 
          userPhone = userSnapshot.data()?['phone_number'] ?? 'N/A'; 
        });
      }
    }
  }

  // Show dialog to edit user details
  void _showEditDialog() {
    final TextEditingController nameController = TextEditingController(text: userName);
    final TextEditingController phoneController = TextEditingController(text: userPhone);
    final TextEditingController addressController = TextEditingController(text: userAddress);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
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
                _updateUserDetails(
                  nameController.text,
                  phoneController.text,
                  addressController.text,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Update user details in Firestore
  Future<void> _updateUserDetails(String newName, String newPhone, String newAddress) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'username': newName,
        'phone_number': newPhone,
        'address': newAddress,
      });

      // Update local state after saving changes
      setState(() {
        userName = newName;
        userPhone = newPhone;
        userAddress = newAddress;
      });
    }
  }

  // Fetch cart items without restricting to one restaurant
  Future<void> _fetchCartItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      double totalPrice = 0.0;

      final cartItems = await Future.wait(cartSnapshot.docs.map((doc) async {
        final data = doc.data();
        final itemSnapshot = await FirebaseFirestore.instance
            .collection('items')
            .doc(doc.id)
            .get();
        final itemData = itemSnapshot.data() ?? {};

        totalPrice += (data['totalPrice'] as num).toDouble();
        return {
          'id': doc.id,
          'name': itemData['name'] ?? 'Unknown Item',
          'price': (data['price'] as num).toDouble(),
          'quantity': data['quantity'] ?? 1,
          'totalPrice': (data['totalPrice'] as num).toDouble(),
          'customization': data['customization'] ?? '', // Fetch customization if it exists
          'image': itemData['image'] ?? '',
        };
      }).toList());

      setState(() {
        _cartItems = cartItems;
        _totalPrice = totalPrice;
      });
    }
  }

  // Show dialog to input customization for cart items
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

  // Add or update customization for cart items
  Future<void> _addCustomization(String itemId, String customization) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(itemId);

      await cartRef.update({
        'customization': customization, // Save customization to cart
      });

      _fetchCartItems(); // Refetch cart items after adding customization
    }
  }

  // Update item quantity in the cart
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

      _fetchCartItems(); // Refetch cart items after update
    }
  }

  // Place the order and clear the cart
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
          'dishName': data['name'], // Storing dish name
          'price': (data['totalPrice'] as num).toDouble(),
          'quantity': data['quantity'],
          'totalPrice': (data['totalPrice'] as num).toDouble(),
          'customization': data['customization'] ?? '',
        };
      }).toList();

      // Save the order history
      await orderRef.set({
        'userId': user.uid,
        'orderDate': Timestamp.now(),
        'totalPrice': _totalPrice,
        'items': cartItems,
      });

      // Clear the cart after order is placed
      for (var doc in cartSnapshot.docs) {
        await cartRef.doc(doc.id).delete();
      }

      _fetchCartItems(); // Clear the cart UI after placing order
      _showLoadingAndConfirmationDialog(); // Show loading and confirmation dialog
    }
  }

  // Function to display the spinning triangle followed by confirmation
  void _showLoadingAndConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const SpinningTriangleDialog();
      },
    );

    // Simulate a delay (order processing time), then show confirmation
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context); // Close loading dialog
      _showThankYouScreen(); // Show thank you screen after order is confirmed
    });
  }

  // Show the Thank You screen after the order is placed
  void _showThankYouScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ThankYouScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Cart"),
      ),
      body: Column(
        children: [
          // Top section with Address and Edit option
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DEFAULT ADDRESS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(userName, style: const TextStyle(fontSize: 14)),
                Text(userAddress, style: const TextStyle(fontSize: 14)),
                Row(
                  children: [
                    Text(userPhone, style: const TextStyle(fontSize: 14)),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: _showEditDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),

          // Cart items section
          Expanded(
            child: _cartItems.isNotEmpty
                ? ListView.builder(
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return ListTile(
                        leading: item['image'].isNotEmpty
                            ? Image.network(
                                item['image'], // Display item image
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image, size: 60), // Fallback if no image
                        title: Text(item['name'], style: const TextStyle(fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('₹${item['price']} x ${item['quantity']}', style: const TextStyle(fontSize: 14)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed: () {
                                    _updateQuantity(item['id'], item['quantity'] - 1, item['price']);
                                  },
                                ),
                                Text(item['quantity'].toString(), style: const TextStyle(fontSize: 14)),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
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
                              child: const Text('Add Customization', style: TextStyle(fontSize: 12)),
                            ),
                            Text('Total: ₹${item['totalPrice']}', style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Text("Nothing added to cart yet.", style: TextStyle(fontSize: 14)),
                  ),
          ),

          // Total price and Place Order button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('₹$_totalPrice', style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        backgroundColor: Colors.green,
                      ),
                      onPressed: _cartItems.isNotEmpty ? _placeOrder : null,
                      child: const Text('Place Order', style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Spinning triangle loading animation
class SpinningTriangleDialog extends StatefulWidget {
  const SpinningTriangleDialog({super.key});

  @override
  _SpinningTriangleDialogState createState() => _SpinningTriangleDialogState();
}

class _SpinningTriangleDialogState extends State<SpinningTriangleDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _controller,
              child: CustomPaint(
                size: const Size(60, 60),
                painter: TrianglePainter(),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Processing Order...'),
          ],
        ),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    final Path path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class ThankYouScreen extends StatelessWidget {
  const ThankYouScreen({super.key});

  void _goToHomePage(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            const Text(
              'THANK YOU FOR ORDERING!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Your order has been confirmed'),

            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => _goToHomePage(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
