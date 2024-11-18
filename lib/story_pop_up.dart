import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui'; // For the blur effect

class StoryPopUp extends StatelessWidget {
  final String itemId;

  const StoryPopUp({Key? key, required this.itemId}) : super(key: key);

  Future<Map<String, dynamic>> _fetchItemDetails() async {
    final itemSnapshot = await FirebaseFirestore.instance.collection('items').doc(itemId).get();
    final itemData = itemSnapshot.data() ?? {};

    if (itemData.isNotEmpty) {
      final restaurantSnapshot = await FirebaseFirestore.instance
          .collection('restaurant')
          .doc(itemData['restaurant_id'])
          .get();
      final restaurantData = restaurantSnapshot.data() ?? {};

      return {
        'name': itemData['name'] ?? 'Unknown Item',
        'image': itemData['image'] ?? '',
        'restaurant_name': restaurantData['name'] ?? 'Unknown Restaurant',
        'price': itemData['price'] ?? 0.0,
      };
    } else {
      return {};
    }
  }

  Future<void> _addToCart(Map<String, dynamic> itemData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(itemId);

      final cartSnapshot = await cartRef.get();

      if (cartSnapshot.exists) {
        final currentData = cartSnapshot.data()!;
        final currentQuantity = currentData['quantity'] ?? 0;
        final newQuantity = currentQuantity + 1;
        await cartRef.update({
          'quantity': newQuantity,
          'totalPrice': (itemData['price'] as num) * newQuantity,
        });
      } else {
        await cartRef.set({
          'name': itemData['name'],
          'image': itemData['image'],
          'price': itemData['price'],
          'quantity': 1,
          'totalPrice': itemData['price'],
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchItemDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading item details.'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Item not found.'));
        } else {
          final itemData = snapshot.data!;
          return Stack(
            children: [
              // Semi-transparent background
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
              // Centered pop-up
              Center(
                child: GestureDetector(
                  onTap: () {}, // Prevent clicks from dismissing pop-up when inside
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    margin: const EdgeInsets.symmetric(horizontal: 20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          itemData['name'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        itemData['image'].isNotEmpty
                            ? Image.network(
                                itemData['image'],
                                height: 150,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image, size: 150),
                        const SizedBox(height: 10),
                        Text(
                          'Restaurant: ${itemData['restaurant_name']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Price: ₹${itemData['price']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            await _addToCart(itemData);
                            Navigator.of(context).pop();
                          },
                          child: const Text("Add to Cart"),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text("Close"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }
}

// Usage
void showStoryPopUp(BuildContext context, String itemId) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return StoryPopUp(itemId: itemId);
    },
  );
}
