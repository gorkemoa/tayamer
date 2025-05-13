import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/api_service.dart';
import 'dashboard_view.dart';
import 'offers_view.dart';
import 'new_offer_view.dart';
import 'policies_view.dart';
import 'profile_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class HomeView extends StatefulWidget {
  final int initialIndex;
  
  const HomeView({super.key, this.initialIndex = 0});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late int _selectedIndex;
  final UserService _userService = UserService();
  User? _user;
  bool _isLoading = true;
  
  // Alt navigasyon sayfaları
  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    // Widget'tan initialIndex değerini al
    _selectedIndex = widget.initialIndex;
    
    _pages = [
      const DashboardView(),
      const OffersView(),
      const NewOfferView(),
      const PoliciesView(),
      const ProfileView(),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // ApiService'i Provider'dan al ve UserService'e enjekte et
    final apiService = Provider.of<ApiService>(context, listen: false);
    _userService.initialize(apiService);
    
    // Kullanıcı bilgilerini getir
    if (_isLoading) {
      _fetchUserInfo();
    }
    
    // Route argümanlarını kontrol et ve gerekirse seçili indeksi güncelle
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is int && args >= 0 && args < _pages.length) {
      setState(() {
        _selectedIndex = args;
      });
    }
  }
  
  Future<void> _fetchUserInfo() async {
    try {
      final user = await _userService.getUserInfo();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Kullanıcı bilgileri alınırken hata: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        selectedLabelStyle: const TextStyle(fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.house, size: 20),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.tags, size: 20),
            label: 'Teklifler',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.qrcode, size: 20),
            label: 'Yeni Teklif',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.fileContract, size: 20),
            label: 'Poliçeler',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.user, size: 20),
            label: 'Hesabım',
          ),
        ],
      ),
    );
  }
} 