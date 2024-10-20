import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_page.dart'; // Import existing CartPage
import 'share_popup.dart';
import 'home_page.dart' as home_page;
import 'profile_page.dart';

class FavouritesPage extends StatelessWidget {
  const FavouritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favourites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // Navigate to the existing CartPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()), // Linked to CartPage
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('items').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No items available.'));
          }

          final items = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index].data() as Map<String, dynamic>;
              final bool isLiked = (item['likedByUsers'] ?? []).contains(currentUserId);

              if (!isLiked) {
                return SizedBox.shrink(); // Don't show items that aren't liked
              }

              return Dismissible(
                key: Key(item['id'] ?? 'unknown_id'), // Added null check
                direction: DismissDirection.startToEnd,
                background: Container(
                  color: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  _removeFromFavorites(item['id'] ?? '', currentUserId, context); // Pass context
                },
                child: FavouriteItem(
                  image: item['image'] ?? '', // Provide default value if null
                  title: item['name'] ?? 'No name available', // Default for name
                  price: item['price'] != null ? '₹${item['price']}' : 'No price available', // Handle price null case
                  isVeg: item['isVeg'] ?? false, // Default for Veg status
                  restaurantId: item['restaurant_id'] ?? '', // Default for restaurant ID
                  itemId: item['id'] ?? '', // Default for item ID
                  priceValue: item['price'] != null ? (item['price'] as num).toDouble() : 0.0, // To use for cart
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Highlight the current tab (Favorites)
        onTap: (int index) {
          // Handle navigation based on the index
          switch (index) {
            case 0:
              // Already on the Favourites page, no need to navigate.
              break;
            case 1:
              // Navigate to Home page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const home_page.HomePage()),
              );
              break;
            case 2:
              // Navigate to Profile page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
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
      ),
    );
  }

  // Function to remove an item from favorites in Firestore with context
  void _removeFromFavorites(String itemId, String userId, BuildContext context) {
    // Remove the item from the user's favorites in Firestore
    FirebaseFirestore.instance.collection('items').doc(itemId).update({
      'likedByUsers': FieldValue.arrayRemove([userId])
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item removed from favourites'))
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing item from favourites: $error'))
      );
    });
  }
}

class FavouriteItem extends StatelessWidget {
  final String image;
  final String title;
  final String price;
  final double priceValue;
  final bool isVeg;
  final String restaurantId;
  final String itemId;

  const FavouriteItem({
    super.key,
    required this.image,
    required this.title,
    required this.price,
    required this.priceValue,
    required this.isVeg,
    required this.restaurantId,
    required this.itemId,
  });

  @override
  Widget build(BuildContext context) {
    // If restaurantId is empty or invalid, show "Restaurant not found" immediately
    if (restaurantId.isEmpty) {
      return _buildItemWithRestaurant(context, 'Restaurant not found');
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildItemWithRestaurant(context, 'Restaurant not found');
        }

        final restaurantName = snapshot.data!['name'] ?? 'Unknown Restaurant';

        return _buildItemWithRestaurant(context, restaurantName);
      },
    );
  }

  // Function to build the UI for a Favourite Item with Restaurant
  Widget _buildItemWithRestaurant(BuildContext context, String restaurantName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Food Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              image,
              height: 80,
              width: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.error, color: Colors.red, size: 80);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            (loadingProgress.expectedTotalBytes ?? 1)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          // Food Details (Name, Price, Veg/Non-Veg Icon, Restaurant Name)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      price,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isVeg ? Icons.check_box_outline_blank : Icons.stop_circle,
                      color: isVeg ? Colors.green : Colors.red,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Restaurant: $restaurantName',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Add to Cart Button
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: () {
              _addToCart({
                'image': image,
                'name': title,
                'price': priceValue,
                'quantity': 1,
                'totalPrice': priceValue, // Starting with one item
                'customization': '', // Initially no customization
                'restaurant_id': restaurantId,
              }, context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title added to cart')),
              );
            },
          ),
          // Share Button for each item
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Open Share popup when clicked
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SharePopup();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Function to add item to cart
  void _addToCart(Map<String, dynamic> item, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(itemId); // Use itemId as document ID for cart

      // Check if item is already in the cart
      final cartSnapshot = await cartRef.get();
      if (cartSnapshot.exists) {
        final currentQuantity = cartSnapshot.data()?['quantity'] ?? 1;
        await cartRef.update({
          'quantity': currentQuantity + 1, // Increase the quantity
          'totalPrice': (currentQuantity + 1) * item['price'], // Update total price
        });
      } else {
        // Add new item to the cart if it doesn't exist
        await cartRef.set(item);
      }
    }
  }
}
