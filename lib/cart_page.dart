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
          // Fetch 'username' instead of 'name'
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
          'name': data['name'] ?? 'Unknown Item', // Fallback if name is null
          'price': (data['price'] as num).toDouble(),
          'quantity': data['quantity'] ?? 1, // Default quantity to 1
          'totalPrice': (data['totalPrice'] as num).toDouble(),
          'customization': data['customization'] ?? '', // Handle customization field
          'image': data['image'] ?? '', // Handle missing images
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

  // Add or update customization for cart items
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

  // Update user details in Firestore
  Future<void> _updateUserDetails(String newName, String newPhone, String newAddress) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'username': newName, // Update username instead of name
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
      _showConfirmationDialog(); // Show order confirmation dialog
    }
  }

  // Show the order confirmation dialog
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Order?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("NO", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showThankYouScreen();
            },
            child: const Text("YES", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
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
            trailing: TextButton(
              onPressed: _showEditDialog, // Edit button triggers the dialog
              child: const Text('Edit'),
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
                          item['image'], // Display item image
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image, size: 80), // Fallback if no image
                  title: Text(item['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('₹${item['price']} x ${item['quantity']}'),
                      TextButton(
                        onPressed: () {
                          _showCustomizationDialog(item['id'], item['customization']);
                        },
                        child: const Text('Add Customization'),
                      ),
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
