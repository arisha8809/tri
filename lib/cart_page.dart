import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math'; // For the triangle animation

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

  // Fetch cart items from Firestore
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
        totalPrice += (data['totalPrice'] as num).toDouble(); // Ensure double type for prices
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Item',
          'price': (data['price'] as num).toDouble(),
          'quantity': data['quantity'] ?? 1, 
          'totalPrice': (data['totalPrice'] as num).toDouble(),
          'customization': data['customization'] ?? '', 
          'image': data['image'] ?? '', 
        };
      }).toList();

      setState(() {
        _cartItems = cartItems;
        _totalPrice = totalPrice;
      });
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
          'itemId': doc.id,
          'quantity': data['quantity'],
          'totalPrice': (data['totalPrice'] as num).toDouble(),
          'customization': data['customization'] ?? '',
        };
      }).toList();

      // Save the order history
      await orderRef.set({
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
          // User details section
          ListTile(
            title: const Text('Customer Details'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Username: $userName'),
                Text('Phone: $userPhone'),
                Text('Address: $userAddress'),
              ],
            ),
          ),
          const Divider(),

          // Cart items section
          Expanded(
            child: ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return ListTile(
                  leading: item['image'].isNotEmpty
                      ? Image.network(
                          item['image'], 
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image, size: 80),
                  title: Text(item['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('₹${item['price']} x ${item['quantity']}'),
                    ],
                  ),
                  trailing: Text('Total: ₹${item['totalPrice']}'),
                );
              },
            ),
          ),

          // Total price and Place Order button
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
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
    )..repeat(); // Start rotating the triangle
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

// Custom painter for the triangle
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

// Thank you screen after order confirmation
class ThankYouScreen extends StatelessWidget {
  const ThankYouScreen({super.key});

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
          ],
        ),
      ),
    );
  }
}
