import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'views/login_view.dart';
import 'views/home_view.dart';
import 'views/offer_detail_view.dart';
import 'views/policy_detail_view.dart';
import 'views/sms_confirmation_view.dart';
import 'services/auth_service.dart';
import 'services/http_interceptor.dart';
import 'services/api_service.dart';
import 'services/user_service.dart';
import 'viewmodels/policy_type_viewmodel.dart';
import 'viewmodels/offer_viewmodel.dart';
import 'viewmodels/payment_viewmodel.dart';
import 'viewmodels/notification_viewmodel.dart';
import 'viewmodels/policy_viewmodel.dart';
import 'package:flutter/services.dart';
import 'services/local_notification_service.dart';

void main() async {
  // Flutter engine'in hazır olmasını sağla
  WidgetsFlutterBinding.ensureInitialized();
  
  // Navigasyon için global key oluştur
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Bildirim servisini başlat - Singleton instance
  final localNotificationService = LocalNotificationService();
  
  try {
    print('Ana bildirim servisi başlatılıyor...');
    await localNotificationService.initialize();
    print('Ana bildirim servisi başarıyla başlatıldı');
  } catch (e) {
    print('Ana bildirim servisi başlatılırken hata: $e');
  }
  
  // NotificationViewModel'i oluştur ve aynı bildirim servisini kullan
  final notificationViewModel = NotificationViewModel(
    localNotificationService: localNotificationService
  );
  
  // HTTP Interceptor'ı oluştur
  final httpInterceptor = HttpInterceptor(navigatorKey: navigatorKey);
  
  // ApiService'i oluştur
  final apiService = ApiService(httpInterceptor);
  
  // UserService'i başlat
  final userService = UserService();
  userService.initialize(apiService);
  
  print('Servisler başlatılıyor...');
  print('HttpInterceptor başlatıldı');
  print('ApiService başlatıldı');
  print('UserService başlatıldı');
  
  runApp(
    MultiProvider(
      providers: [
        Provider<GlobalKey<NavigatorState>>.value(value: navigatorKey),
        Provider<HttpInterceptor>.value(value: httpInterceptor),
        Provider<ApiService>.value(value: apiService),
        Provider<UserService>.value(value: userService),
        ChangeNotifierProvider(create: (_) => PolicyTypeViewModel()),
        ChangeNotifierProvider(create: (_) => OfferViewModel()),
        ChangeNotifierProvider(create: (_) => PaymentViewModel()),
        ChangeNotifierProvider.value(value: notificationViewModel),
        ChangeNotifierProvider(create: (_) => PolicyViewModel()),
      ],
      child: TayamerApp(
        navigatorKey: navigatorKey,
      ),
    ),
  );
}

class TayamerApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  
  const TayamerApp({
    super.key,
    required this.navigatorKey,
  });

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
      navigatorKey: widget.navigatorKey,
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
      initialRoute: '/',
      routes: {
        '/': (context) => _isLoading 
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : _isLoggedIn ? const HomeView() : LoginView(),
        '/login': (context) => LoginView(),
        '/home': (context) => const HomeView(),
      },
      // Dinamik route tanımlamaları
      onGenerateRoute: (settings) {
        // Route adından parametreleri ayıklama
        if (settings.name != null && settings.name!.startsWith('/policy/detail/')) {
          final policyId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => PolicyDetailView(policyId: policyId),
            settings: settings,
          );
        } else if (settings.name != null && settings.name!.startsWith('/payment/sms-verification/')) {
          final offerId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => SmsConfirmationView(
              offerId: int.tryParse(offerId) ?? 0,
              companyId: 0,
            ),
            settings: settings,
          );
        } else if (settings.name != null && settings.name!.startsWith('/offer/')) {
          final offerId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => OfferDetailView(offerId: offerId),
            settings: settings,
          );
        } else if (settings.name != null && settings.name!.startsWith('/payment/')) {
          // Ödeme sayfası olmadığından HomeView'e yönlendir ve bildirim göster
          return MaterialPageRoute(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ödeme sayfasına yönlendirilemedi'),
                    backgroundColor: Colors.red,
                  ),
                );
              });
              return const HomeView();
            },
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
