import 'package:flutter/material.dart';
import 'package:senkuko/core/app_colors.dart';
import 'package:senkuko/features/auth/pages/user/cart/views/cart_page.dart';
import 'package:senkuko/features/auth/pages/user/history/views/history_page.dart';
import 'package:senkuko/features/auth/pages/user/home/views/home_page.dart';
import 'package:senkuko/features/auth/pages/user/profile/views/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  static get to => null;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static _MainPageState? instance;

  int currentIndex = 0;

  final List<Widget> pages = [
  const HomePage(),
  CartPage(),
  const HistoryPage(),
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
        onTap: changeTab,

        type: BottomNavigationBarType.fixed,

        backgroundColor: Colors.white,

        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,

        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),

        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
        ),

        items: const [

  BottomNavigationBarItem(
    icon: Icon(Icons.home_outlined),
    activeIcon: Icon(Icons.home),
    label: "Beranda",
  ),

  BottomNavigationBarItem(
    icon: Icon(Icons.shopping_cart_outlined),
    activeIcon: Icon(Icons.shopping_cart),
    label: "Keranjang",
  ),

  BottomNavigationBarItem(
    icon: Icon(Icons.receipt_long_outlined),
    activeIcon: Icon(Icons.receipt_long),
    label: "Pesanan",
  ),

  BottomNavigationBarItem(
    icon: Icon(Icons.person_outline),
    activeIcon: Icon(Icons.person),
    label: "Profil",
  ),
],
      ),
    );
  }
}