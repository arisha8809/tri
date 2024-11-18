import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:tri/cart_page.dart';
import 'package:tri/hotel_page.dart';
import 'package:tri/favourites_page.dart' as fav_page;
import 'package:tri/profile_page.dart' as profile_page;
import 'models/cart_model.dart';
import 'story_pop_up.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _currentIndex = 1;
  String? firstName;

  @override
  void initState() {
    super.initState();
    _fetchUserFirstName();
  }

  Future<void> _fetchUserFirstName() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String? fetchedFirstName = await getFirstName(currentUser.uid);
      if (fetchedFirstName != null) {
        setState(() {
          firstName = fetchedFirstName;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItemCount = Provider.of<CartModel>(context).itemCount;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          firstName != null ? 'Hi, $firstName' : 'Hi',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.black),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 20),

              const Text(
                'Most Liked Dishes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('items')
                    .orderBy('likes', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var items = snapshot.data!.docs;
                    return SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          var item = items[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StoryPopUp(itemId: item.id),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: ClipPath(
                                clipper: TriangleClipper(),
                                child: Image.network(
                                  item['image'],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
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
              const SizedBox(height: 16),

              const Text(
                'Restaurants',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('restaurant').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var restaurants = snapshot.data!.docs;
                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: restaurants.length,
                      itemBuilder: (context, index) {
                        var restaurant = restaurants[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HotelPage(restaurant_id: restaurant['restaurant_id'].toString()),
                              ),
                            );
                          },
                          child: RestaurantCard(
                            image: restaurant['image'],
                            name: restaurant['name'],
                            status: restaurant['status'],
                          ),
                        );
                      },
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
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => fav_page.FavouritesPage()),
            );
          } else if (index == 1) {
            // Stay on Home page
          } else if (index == 2) {
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

class RestaurantCard extends StatelessWidget {
  final String image;
  final String name;
  final String status;

  const RestaurantCard({
    super.key,
    required this.image,
    required this.name,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            child: Image.network(
              image,
              width: double.infinity,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
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
                  status,
                  style: TextStyle(
                    fontSize: 14,
                    color: status == 'Open' ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> getFirstName(String userId) async {
  try {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      String fullName = userDoc.get('username');
      String firstName = fullName.split(' ')[0];
      return firstName;
    } else {
      return null;
    }
  } catch (e) {
    print('Error fetching user data: $e');
    return null;
  }
}
