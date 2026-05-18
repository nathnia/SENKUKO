import 'package:flutter/material.dart';
import 'package:senkuko/features/auth/pages/user/home/views/home_page.dart';
import 'package:senkuko/features/auth/pages/user/cart/views/cart_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static _MainPageState? instance;

  int currentIndex = 0;

  final pages = [
    const HomePage(),
    CartPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    instance = this;
  }

  static _MainPageState get to => instance!;

  void changeTab(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
  currentIndex: currentIndex,
  selectedItemColor: Colors.green,
  backgroundColor: Colors.white,
  elevation: 8,
  type: BottomNavigationBarType.fixed,

  selectedLabelStyle: const TextStyle(
    fontWeight: FontWeight.w600,
  ),

  unselectedLabelStyle: const TextStyle(
    fontWeight: FontWeight.w500,
  ),

  onTap: (index) {
    changeTab(index);
  },

  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: "Beranda",
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.shopping_cart),
      label: "Keranjang",
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: "Profil",
    ),
  ],
),
    );
  }
}

//PROFILE (biarin aja)
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Profil"));
  }
}