import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'dashboard_view.dart';
import 'offers_view.dart';
import 'new_offer_view.dart';
import 'policies_view.dart';
import 'profile_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;
  final UserService _userService = UserService();
  User? _user;
  bool _isLoading = true;
  
  // Alt navigasyon sayfaları
  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    // Sayfaları başlangıçta null kullanıcı ile başlat, daha sonra güncelle
    _pages = [
      const DashboardView(),
      const OffersView(),
      const NewOfferView(),
      const PoliciesView(),
      const ProfileView(),
    ];
  }
  
  Future<void> _fetchUserInfo() async {
    try {
      final user = await _userService.getUserInfo();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      print('Kullanıcı bilgileri alınırken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      body: _pages[_selectedIndex],
      
      // Alt navigasyon çubuğu
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            label: 'Teklifler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code),
            label: 'Yeni Teklif',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_copy_outlined),
            label: 'Poliçeler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hesabım',
          ),
        ],
      ),
    );
  }
} 