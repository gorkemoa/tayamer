import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'views/login_view.dart';
import 'services/auth_service.dart';
import 'viewmodels/policy_type_viewmodel.dart';
import 'viewmodels/offer_viewmodel.dart';
import 'viewmodels/payment_viewmodel.dart';
import 'viewmodels/notification_viewmodel.dart';
import 'package:flutter/services.dart';

void main() async {
  // Flutter engine'in hazır olmasını sağla
  WidgetsFlutterBinding.ensureInitialized();
  
  // NotificationViewModel'i oluştur
  final notificationViewModel = NotificationViewModel();
  
  try {
    // Önce bildirimleri başlatmayı dene
    await notificationViewModel.initializeLocalNotifications();
  } catch (e) {
    // Hata oluşursa console'a yaz
    print('Bildirim servisi başlatılırken hata oluştu: $e');
    // Uygulama çalışmaya devam etsin - bildirimleri kullanmadan
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PolicyTypeViewModel()),
        ChangeNotifierProvider(create: (_) => OfferViewModel()),
        ChangeNotifierProvider(create: (_) => PaymentViewModel()),
        ChangeNotifierProvider.value(value: notificationViewModel),
      ],
      child: const TayamerApp(),
    ),
  );
}

class TayamerApp extends StatefulWidget {
  const TayamerApp({super.key});

  @override
  State<TayamerApp> createState() => _TayamerAppState();
}

class _TayamerAppState extends State<TayamerApp> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    bool loggedIn = await _authService.isLoggedIn();
    print('Oturum durumu kontrol ediliyor: ${loggedIn ? "Giriş yapılmış" : "Giriş yapılmamış"}');
    setState(() {
      _isLoggedIn = loggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tayamer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A73), // Ana renk - koyu mavi
          secondary: const Color(0xFFE0622C), // İkincil renk - turuncu
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1E3A73),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF1E3A73),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1E3A73), width: 2),
          ),
        ),
      ),
      // Ana route tanımlamaları
      home: LoginView(),
    );
  }
}
