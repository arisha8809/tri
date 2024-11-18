import 'package:flutter/material.dart';
import 'package:tri/cart_page.dart';  // Import the Cart Page
import 'package:tri/favourites_page.dart' as fav_page;
import 'package:tri/profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/animation.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'models/cart_model.dart'; // Import CartModel

class HotelPage extends StatefulWidget {
  final String restaurant_id;

  const HotelPage({super.key, required this.restaurant_id});

  @override
  HotelPageState createState() => HotelPageState();
}

class HotelPageState extends State<HotelPage> with SingleTickerProviderStateMixin {
  final FirebaseAuth auth = FirebaseAuth.instance;
  late AnimationController _controller;
  late Animation<Offset> _cartAnimation;
  String? restaurantName;
  String? restaurantImage;
  bool isLoading = true;
  String searchQuery = "";
  TextEditingController _searchController = TextEditingController();
  Map<String, List<DocumentSnapshot>> categorizedItems = {};

  int _currentIndex = 1; // Initialize _currentIndex for BottomNavigationBar

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

    _fetchRestaurantDetails();
    _fetchCategorizedItems(); // Fetch items once on initialization
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _fetchRestaurantDetails() async {
    try {
      print("id${widget.restaurant_id}");
      DocumentSnapshot restaurantSnapshot = await FirebaseFirestore.instance
          .collection('restaurant')
          .doc(widget.restaurant_id)
          .get();

      restaurantName = restaurantSnapshot['name'];
      restaurantImage = restaurantSnapshot['image'];

      if (restaurantSnapshot.exists) {
        setState(() {
          restaurantName = restaurantSnapshot['name'];
          restaurantImage = restaurantSnapshot['image'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching restaurant details: $e');
    }
  }

  Future<void> _fetchCategorizedItems() async {
    try {
      QuerySnapshot itemSnapshot = await FirebaseFirestore.instance
          .collection('items')
          .where('restaurant_id', isEqualTo: widget.restaurant_id)
          .get();

      final Map<String, List<DocumentSnapshot>> tempCategorizedItems = {};

      for (var item in itemSnapshot.docs) {
        final itemData = item.data() as Map<String, dynamic>;
        final category = itemData['category']
            .toString()
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');

        if (!tempCategorizedItems.containsKey(category)) {
          tempCategorizedItems[category] = [];
        }
        tempCategorizedItems[category]!.add(item);
      }

      setState(() {
        categorizedItems = tempCategorizedItems;
      });
    } catch (e) {
      print('Error fetching categorized items: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text;
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
      cartRef.update({
        'quantity': FieldValue.increment(1),
        'totalPrice': FieldValue.increment(price),
      });
    } else {
      cartRef.set({
        'name': name,
        'price': price,
        'quantity': 1,
        'totalPrice': price,
        'customization': '',
      });
    }

    _controller.forward().then((_) {
      _controller.reverse();
      _showCenteredMessage("Item added to cart");
    });
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
        currentLikes -= 1;
        likedByUsers.remove(user.uid);
      } else {
        currentLikes += 1;
        likedByUsers.add(user.uid);
      }

      transaction.update(itemRef, {
        'likes': currentLikes,
        'likedByUsers': likedByUsers,
      });
    }).then((_) {
      String message = isLiked ? "Item removed from favourites" : "Item added to favourites";
      _showCenteredMessage(message);
    }).catchError((error) {
      print('Error toggling like: $error');
    });
  }

  // Increase and decrease quantity methods
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
        cartRef.delete();
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => fav_page.FavouritesPage()),
        );
        break;
      case 1:
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
    final cartItemCount = Provider.of<CartModel>(context).itemCount; // Access cart item count

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search for dishes...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search),
              ),
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: restaurantImage != null
                        ? Image.network(restaurantImage!, height: 200, fit: BoxFit.cover)
                        : const Icon(Icons.image, size: 200),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: categorizedItems.length,
                    itemBuilder: (context, index) {
                      final category = categorizedItems.keys.elementAt(index);
                      final items = categorizedItems[category]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (context, itemIndex) {
                              final item = items[itemIndex];
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
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
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
}

class HotelMenuItem extends StatefulWidget {
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
  _HotelMenuItemState createState() => _HotelMenuItemState();
}

class _HotelMenuItemState extends State<HotelMenuItem> {
  int _quantity = 0;
  bool _addedToCart = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.imageUrl,
                width: 120,
                height: 120,
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
                    widget.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₹${widget.price}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _addedToCart
                      ? Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  if (_quantity > 1) {
                                    _quantity--;
                                    widget.onDecreaseQuantity();
                                  } else {
                                    _addedToCart = false;
                                    _quantity = 0;
                                    widget.onDecreaseQuantity();
                                  }
                                });
                              },
                            ),
                            Text('$_quantity'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  _quantity++;
                                  widget.onIncreaseQuantity();
                                });
                              },
                            ),
                          ],
                        )
                      : GestureDetector(
                          onTap: () {
                            setState(() {
                              _addedToCart = true;
                              _quantity = 1;
                              widget.onAddToCart();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'Add to Cart',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(widget.isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                  onPressed: widget.onLikeToggle,
                ),
                Text(widget.likes),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
