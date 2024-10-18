import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase package
import 'favourites_page.dart' as favourites_page; // Import FavouritesPage
import 'home_page.dart' as home_page; // Import HomePage
import 'profile_page.dart'; // Import ProfilePage
import 'login_signup_page.dart'; // Import LoginPage
import 'cart_page.dart'; // Import CartPage
import 'hotel_page.dart'; // Import HotelPage
import 'story_pop_up.dart'; // Import StoryPopUp
import 'models/cart_model.dart'; // CartModel for the provider
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); // Initialize Firebase
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartModel(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove debug banner
      initialRoute: '/login', // Set LoginPage as the initial route
      routes: {
        '/home': (context) => home_page.HomePage(), // Use HomePage() as a widget constructor
        '/profile': (context) => ProfilePage(), // Use ProfilePage() as a widget constructor
        '/favourites': (context) => favourites_page.FavouritesPage(), // Use FavouritesPage() as a widget constructor
        '/cart': (context) => CartPage(), // Use CartPage() as a widget constructor
        '/login': (context) => LoginPage(), // Use LoginPage() as a widget constructor
        // HotelPage and StoryPopUp are navigated via Navigator.push(), no need to add here.
      },
    );
  }
}
