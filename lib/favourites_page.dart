import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // Import Provider for cart count
import 'cart_page.dart';
import 'share_popup.dart';
import 'home_page.dart' as home_page;
import 'profile_page.dart';
import 'models/cart_model.dart'; // Import CartModel for cart item count

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  _FavouritesPageState createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final cartItemCount = Provider.of<CartModel>(context).itemCount; // Access cart item count

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favourites'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartPage()),
                  );
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.red,
                    child: Text(
                      '$cartItemCount',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('items').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading favourites.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No favourites found.'));
          }

          final items = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index].data() as Map<String, dynamic>;
              final bool isLiked = (item['likedByUsers'] ?? []).contains(currentUserId);

              if (!isLiked) {
                return const SizedBox.shrink();
              }

              return Dismissible(
                key: Key(item['id'] ?? 'unknown_id'),
                direction: DismissDirection.startToEnd,
                background: Container(
                  color: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  _removeFromFavorites(item['id'] ?? '', currentUserId, context);
                },
                child: FavouriteItem(
                  image: item['image'] ?? '',
                  title: item['name'] ?? 'Unknown Item',
                  price: item['price'] != null ? '₹${item['price']}' : 'No Price Available',
                  isVeg: item['isVeg'] ?? false,
                  restaurantId: item['restaurant_id'] ?? '',
                  itemId: item['id'] ?? '',
                  priceValue: item['price'] != null ? (item['price'] as num).toDouble() : 0.0,
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (int index) {
          switch (index) {
            case 0:
              break; // Already on the Favourites page
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const home_page.HomePage()),
              );
              break;
            case 2:
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
      ),
    );
  }

  void _removeFromFavorites(String itemId, String userId, BuildContext context) {
    FirebaseFirestore.instance.collection('items').doc(itemId).update({
      'likedByUsers': FieldValue.arrayRemove([userId])
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item removed from favourites')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing item: $error')),
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
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('restaurant').doc(restaurantId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildItemWithRestaurant(context, 'Restaurant not found');
        }

        final restaurantName = snapshot.data!['name'] ?? 'Unknown Restaurant';

        return _buildItemWithRestaurant(context, restaurantName);
      },
    );
  }

  Widget _buildItemWithRestaurant(BuildContext context, String restaurantName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              image,
              height: 80,
              width: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error, color: Colors.red, size: 80);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
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
                    Text(price, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                    const SizedBox(width: 8),
                    Icon(
                      isVeg ? Icons.check_box_outline_blank : Icons.stop_circle,
                      color: isVeg ? Colors.green : Colors.red,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Restaurant: $restaurantName', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: () {
              _addToCart({
                'image': image,
                'name': title,
                'price': priceValue,
                'quantity': 1,
                'totalPrice': priceValue,
                'customization': '',
                'restaurant_id': restaurantId,
              }, context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title added to cart')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SharePopup(
                    name: title,
                    hotelName: restaurantName,
                    imagePath: image,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _addToCart(Map<String, dynamic> item, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cartRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart').doc(itemId);

      final cartSnapshot = await cartRef.get();
      if (cartSnapshot.exists) {
        final currentQuantity = cartSnapshot.data()?['quantity'] ?? 1;
        await cartRef.update({
          'quantity': currentQuantity + 1,
          'totalPrice': (currentQuantity + 1) * item['price'],
        });
      } else {
        await cartRef.set(item);
      }
    }
  }
}
