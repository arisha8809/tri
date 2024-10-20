import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth for the current user
import 'package:tri/cart_page.dart';
import 'package:tri/hotel_page.dart'; // Import the HotelPage
import 'package:tri/favourites_page.dart' as fav_page; // Import FavouritesPage
import 'package:tri/profile_page.dart' as profile_page; // Import the ProfilePage class
import 'story_pop_up.dart'; // Import the StoryPopUp

// HomePage class
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

// HomePage state class
class HomePageState extends State<HomePage> {
  int _currentIndex = 1; // Default to Home tab
  String? firstName; // Store the first name of the user

  @override
  void initState() {
    super.initState();
    _fetchUserFirstName();
  }

  Future<void> _fetchUserFirstName() async {
    User? currentUser = FirebaseAuth.instance.currentUser; // Get the current authenticated user
    if (currentUser != null) {
      String? fetchedFirstName = await getFirstName(currentUser.uid); // Call the query from the separate file
      if (fetchedFirstName != null) {
        setState(() {
          firstName = fetchedFirstName; // Update the UI with the fetched first name
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          firstName != null ? 'Hi, $firstName' : 'Hi', // Dynamically display the first name
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.black),
            onPressed: () {
              // Navigate to CartPage when the cart button is pressed
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search, color: Colors.grey),
                    hintText: 'Search',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),

              // Horizontal list of the most liked dishes (Stories) with triangle shape and click behavior for pop-up
              const Text('Most Liked Dishes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16.0),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('items')
                    .orderBy('likes', descending: true)
                    .limit(10) // Fetch top 10 most liked dishes
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var items = snapshot.data!.docs;
                    return SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          var item = items[index];
                          return GestureDetector(
                            onTap: () {
                              // Open a pop-up when the item is clicked
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StoryPopUp(itemId: item.id), // Link to story_pop_up.dart
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0), // Add space between items
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, // Align contents to start
                                children: [
                                  ClipPath(
                                    clipper: TriangleClipper(),
                                    child: Image.network(
                                      item['image'],
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error loading most liked dishes');
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              ),
              const SizedBox(height: 16.0),

              // Restaurant list from Firestore 'restaurant' collection (Convert restaurantId to String)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('restaurant').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var restaurants = snapshot.data!.docs;
                    return Column(
                      children: restaurants.map((restaurant) {
                        return GestureDetector(
                          onTap: () {
                            // Convert restaurantId (int) to String before passing it
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HotelPage(restaurant_id: restaurant['restaurant_id'].toString()), // Pass the correct restaurantId as a String
                              ),
                            );
                          },
                          child: RestaurantCard(
                            image: restaurant['image'],
                            name: restaurant['name'],
                            status: restaurant['status'],
                            time: restaurant['time'],
                          ),
                        );
                      }).toList(),
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error loading restaurants');
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // Set currentIndex to highlight Home
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update currentIndex
          });

          // Navigate based on bottom bar index
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => fav_page.FavouritesPage()),
            );
          } else if (index == 1) {
            // Stay on Home page
          } else if (index == 2) {
            // Navigate to Profile page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => profile_page.ProfilePage()),
            );
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
}

// Triangle Clipper for triangular-shaped images
class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

// Restaurant card widget
class RestaurantCard extends StatelessWidget {
  final String image;
  final String name;
  final String status;
  final String time;

  const RestaurantCard({
    super.key,
    required this.image,
    required this.name,
    required this.status,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 2,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Image.network(
              image,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  fontSize: 16,
                  color: status == 'Open' ? Colors.green : Colors.red,
                ),
              ),
              Text(time, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

// Method to get the first name from Firestore
Future<String?> getFirstName(String userId) async {
  try {
    // Reference the Firestore collection
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      // Fetch the 'name' field
      String fullName = userDoc.get('username');
      // Extract the first name from the full name
      String firstName = fullName.split(' ')[0]; // Split by space and get the first part
      return firstName;
    } else {
      return null; // User not found
    }
  } catch (e) {
    print('Error fetching user data: $e');
    return null;
  }
}
