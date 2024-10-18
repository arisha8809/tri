import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animated Buttons',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const HomePage(),
    );
  }
}

// Home Page with Animated Buttons in Footer
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: const Center(
        child: Text('Food Delivery App Home'),
      ),
      bottomNavigationBar: FooterButtons(),
    );
  }
}

// Footer Buttons for Home, Profile, and Favorites
class FooterButtons extends StatefulWidget {
  @override
  _FooterButtonsState createState() => _FooterButtonsState();
}

class _FooterButtonsState extends State<FooterButtons> with SingleTickerProviderStateMixin {
  late int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to the respective page based on the index
    if (index == 0) {
      print("Navigate to Favorites");
    } else if (index == 1) {
      print("Stay on Home");
    } else if (index == 2) {
      print("Navigate to Profile");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: AnimatedButton(
            iconData: Icons.favorite,
            label: 'Favorites',
          ),
          label: 'Favorites',
        ),
        BottomNavigationBarItem(
          icon: AnimatedButton(
            iconData: Icons.home,
            label: 'Home',
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: AnimatedButton(
            iconData: Icons.person,
            label: 'Profile',
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}

// Custom Animated Button Widget
class AnimatedButton extends StatefulWidget {
  final IconData iconData;
  final String label;

  const AnimatedButton({Key? key, required this.iconData, required this.label}) : super(key: key);

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // Set up animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Define scaling effect
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Define color change animation
    _colorAnimation = ColorTween(begin: Colors.grey[600], end: Colors.green).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  // Handle button press (hover and click effects)
  void _onTapDown(TapDownDetails details) {
    _controller.forward(); // Start the animation when button is pressed
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse(); // Reverse the animation when button is released
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Icon(
              widget.iconData,
              size: 30,
              color: _colorAnimation.value,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
