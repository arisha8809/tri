import 'package:flutter/material.dart';
import 'package:tri/home_page.dart' as home_page; // Import HomePage
import 'package:tri/profile_page.dart'; // Import ProfilePage
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For currentUser
import 'share_popup.dart';

class FavouritesPage extends StatelessWidget {
  const FavouritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Override the back button behavior to navigate to the HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const home_page.HomePage()),
        );
        // Return false to prevent the default pop behavior
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favourites'),
        ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('items').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No items available.'));
            }

            final items = snapshot.data!.docs;
            final currentUserId = FirebaseAuth.instance.currentUser!.uid;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index].data() as Map<String, dynamic>;
                final bool isLiked = (item['likedByUsers'] ?? []).contains(currentUserId);

                if (!isLiked) {
                  return const SizedBox.shrink(); // Don't show items that aren't liked
                }

                return FavouriteItem(
                  imageUrl: item['image'],
                  title: item['name'],
                  price: '₹${item['price']}',
                  isVeg: item['isVeg'] ?? false,
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
      ),
    );
  }
}

class FavouriteItem extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price;
  final bool isVeg;

  const FavouriteItem({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.isVeg,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Food Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              imageUrl,
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
                        ? loadingProgress.cumulativeBytesLoaded /
                            (loadingProgress.expectedTotalBytes ?? 1)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          // Food Details (Name, Price, Veg/Non-Veg Icon)
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
              ],
            ),
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
}
