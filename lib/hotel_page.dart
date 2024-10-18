import 'package:flutter/material.dart';
import 'package:tri/cart_page.dart';  // Import the Cart Page
import 'package:tri/favourites_page.dart' as fav_page;
import 'package:tri/profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/animation.dart';

class HotelPage extends StatefulWidget {
  final String restaurant_id; // Add restaurantId as a parameter

  const HotelPage({super.key, required this.restaurant_id}); // Make restaurantId a required parameter

  @override
  HotelPageState createState() => HotelPageState();
}

class HotelPageState extends State<HotelPage> with SingleTickerProviderStateMixin {
  final int _currentIndex = 1; // Set to 1 for Home, indicating current page
  final FirebaseAuth auth = FirebaseAuth.instance; // Access Firebase Auth
  late AnimationController _controller;
  late Animation<Offset> _cartAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _cartAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.2, 0.2),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Method to show a centered message
  void _showCenteredMessage(String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );

    overlay?.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 1)).then((value) => overlayEntry.remove());
  }

  // Like or Dislike a dish
  Future<void> _toggleLike(String itemId, bool isLiked) async {
    final user = auth.currentUser;
    if (user == null) return;

    final DocumentReference itemRef =
        FirebaseFirestore.instance.collection('items').doc(itemId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot itemSnapshot = await transaction.get(itemRef);

      if (!itemSnapshot.exists) {
        throw Exception("Item does not exist!");
      }

      int currentLikes = itemSnapshot['likes'] ?? 0;
      List likedByUsers = List.from(itemSnapshot['likedByUsers'] ?? []);

      if (isLiked) {
        // Dislike the item
        currentLikes -= 1;
        likedByUsers.remove(user.uid);
      } else {
        // Like the item
        currentLikes += 1;
        likedByUsers.add(user.uid);
      }

      // Update Firestore
      transaction.update(itemRef, {
        'likes': currentLikes,
        'likedByUsers': likedByUsers,
      });
    }).then((_) {
      // Show message after updating Firestore
      String message = isLiked ? "Item removed from favourites" : "Item added to favourites";
      _showCenteredMessage(message);
    }).catchError((error) {
      // Handle errors
      print('Error toggling like: $error');
    });
  }

  // Add item to cart
  Future<void> _addToCart(String itemId, String name, double price) async {
    final user = auth.currentUser;
    if (user == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(itemId);

    final doc = await cartRef.get();
    if (doc.exists) {
      // If the item is already in the cart, update the quantity and total price
      cartRef.update({
        'quantity': FieldValue.increment(1),
        'totalPrice': FieldValue.increment(price),
      });
    } else {
      // Add new item to the cart with initial quantity of 1
      cartRef.set({
        'name': name,
        'price': price,
        'quantity': 1,
        'totalPrice': price,
        'customization': '', // Initialize customization as empty string
      });
    }

    // Show animation and pop-up
    _controller.forward().then((_) {
      _controller.reverse();
      _showCenteredMessage("Item added to cart");
    });
  }

  // Method to increase quantity of an item
  Future<void> _increaseQuantity(String itemId, double price) async {
    final user = auth.currentUser;
    if (user == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(itemId);

    cartRef.update({
      'quantity': FieldValue.increment(1),
      'totalPrice': FieldValue.increment(price),
    });
  }

  // Method to decrease quantity of an item
  Future<void> _decreaseQuantity(String itemId, double price) async {
    final user = auth.currentUser;
    if (user == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(itemId);

    final doc = await cartRef.get();
    if (doc.exists) {
      int currentQuantity = doc['quantity'];
      if (currentQuantity > 1) {
        cartRef.update({
          'quantity': FieldValue.increment(-1),
          'totalPrice': FieldValue.increment(-price),
        });
      } else {
        cartRef.delete(); // Remove item from cart if quantity reaches 0
      }
    }
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => fav_page.FavouritesPage()),
        );
        break;
      case 1:
        // Stay on Hotel Page
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Page'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()), // Navigate to Cart Page
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('items')
            .where('restaurant_id', isEqualTo: widget.restaurant_id) // Filter by restaurantId
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No items available for this restaurant.'));
          }

          final items = snapshot.data!.docs;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final itemId = item.id;
              final itemData = item.data() as Map<String, dynamic>;
              final isLiked = (itemData['likedByUsers'] ?? []).contains(auth.currentUser?.uid);

              return SlideTransition(
                position: _cartAnimation,
                child: HotelMenuItem(
                  itemId: itemId,
                  imageUrl: itemData['image'],
                  name: itemData['name'],
                  price: itemData['price'].toString(),
                  likes: itemData['likes'].toString(),
                  isLiked: isLiked,
                  onLikeToggle: () => _toggleLike(itemId, isLiked),
                  onAddToCart: () => _addToCart(itemId, itemData['name'], (itemData['price'] as num).toDouble()),
                  onIncreaseQuantity: () => _increaseQuantity(itemId, (itemData['price'] as num).toDouble()),
                  onDecreaseQuantity: () => _decreaseQuantity(itemId, (itemData['price'] as num).toDouble()),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favourites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: _onItemTapped,
      ),
    );
  }
}

class HotelMenuItem extends StatelessWidget {
  final String itemId;
  final String imageUrl;
  final String name;
  final String price;
  final String likes;
  final bool isLiked;
  final VoidCallback onLikeToggle;
  final VoidCallback onAddToCart;
  final VoidCallback onIncreaseQuantity;
  final VoidCallback onDecreaseQuantity;

  const HotelMenuItem({
    super.key,
    required this.itemId,
    required this.imageUrl,
    required this.name,
    required this.price,
    required this.likes,
    required this.isLiked,
    required this.onLikeToggle,
    required this.onAddToCart,
    required this.onIncreaseQuantity,
    required this.onDecreaseQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                return const Icon(Icons.error, color: Colors.red, size: 80);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹$price',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: onDecreaseQuantity, // Decrease quantity
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: onIncreaseQuantity, // Increase quantity
                    ),
                  ],
                ),
                TextButton(
                  onPressed: onAddToCart,
                  child: const Text('Add to Cart', style: TextStyle(color: Colors.green)),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                onPressed: onLikeToggle, // Toggle like/dislike on press
              ),
              Text(likes),
            ],
          ),
        ],
      ),
    );
  }
}
