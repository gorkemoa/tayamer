import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'firebase_options.dart';
import 'views/login_view.dart';
import 'views/home_view.dart';
import 'views/offer_detail_view.dart';
import 'views/policy_detail_view.dart';
import 'views/sms_confirmation_view.dart';
import 'services/auth_service.dart';
import 'services/http_interceptor.dart';
import 'services/api_service.dart';
import 'services/user_service.dart';
import 'services/notification_service.dart';
import 'viewmodels/policy_type_viewmodel.dart';
import 'viewmodels/offer_viewmodel.dart';
import 'viewmodels/payment_viewmodel.dart';
import 'viewmodels/notification_viewmodel.dart';
import 'viewmodels/policy_viewmodel.dart';
import 'dart:async';
import 'dart:convert';

// Arka planda bildirim işleme - Uygulama tamamen kapalıyken
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("📬 Arka planda bildirim alındı: ${message.notification?.title} - ID: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase'i firebase_options ile başlatıyoruz.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Arka plan mesaj işleyicisini ayarla
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Bildirim izinlerini iste
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('Kullanıcı izin durumu: ${settings.authorizationStatus}');
  
  // iOS ön plan bildirim ayarları
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  
  // Navigasyon için global key oluştur
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Bildirim servislerini oluştur
  final notificationService = NotificationService();
  
  try {
    // FCM token'ı al ve sunucuya gönder
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    print('🔑 FCM Token: $fcmToken');
    
    if (fcmToken != null) {
      await notificationService.updateFcmToken();
      
      // Token değişikliklerini dinle
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        print('🔄 FCM token yenilendi: $newToken');
        notificationService.updateFcmToken();
      });
    }
    
    // Basit debounce mantığı için global değişken
    DateTime? lastNotificationTime;
    const debounceSeconds = 5;
    
    // Gelen bildirimleri dinle - ön planda
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final now = DateTime.now();
      if (lastNotificationTime != null &&
          now.difference(lastNotificationTime!).inSeconds < debounceSeconds) {
        // Eğer son bildirimin üzerinden çok kısa süre geçtiyse gösterme
        print('⏱️ Debounce: Bildirim tekrar geldi, gösterilmiyor.');
        return;
      }
      lastNotificationTime = now;
      
      print('📩 Yeni bildirim geldi!');
      print('Başlık: ${message.notification?.title}');
      print('İçerik: ${message.notification?.body}');
      // Firebase'den gelen bildirimleri sistem bildirimlerinde göster
      // Firebase bildirimler doğrudan sistem tarafından gösteriliyor
    });
    
    // Arka planda iken, ama uygulama açıkken bildirime tıklanırsa
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('👆 Bildirime tıklandı: ${message.notification?.title}');
      // Gerekirse bildirime özel yönlendirme yapılabilir.
    });
    
  } catch (e) {
    print('❌ Bildirim servisleri başlatılırken hata: $e');
  }
  
  // NotificationViewModel oluşturuluyor
  final notificationViewModel = NotificationViewModel();
  
  // HTTP Interceptor, ApiService, UserService kurulumu
  final httpInterceptor = HttpInterceptor(navigatorKey: navigatorKey);
  final apiService = ApiService(httpInterceptor);
  final userService = UserService();
  userService.initialize(apiService);
  
  runApp(
    MultiProvider(
      providers: [
        Provider<GlobalKey<NavigatorState>>.value(value: navigatorKey),
        Provider<HttpInterceptor>.value(value: httpInterceptor),
        Provider<ApiService>.value(value: apiService),
        Provider<UserService>.value(value: userService),
        Provider<NotificationService>.value(value: notificationService),
        ChangeNotifierProvider(create: (_) => PolicyTypeViewModel()),
        ChangeNotifierProvider(create: (_) => OfferViewModel()),
        ChangeNotifierProvider(create: (_) => PaymentViewModel()),
        ChangeNotifierProvider.value(value: notificationViewModel),
        ChangeNotifierProvider(create: (_) => PolicyViewModel()),
      ],
      child: TayamerApp(navigatorKey: navigatorKey),
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
          seedColor: const Color(0xFF1E3A73), // Ana renk: koyu mavi
          secondary: const Color(0xFFE0622C),   // İkincil renk: turuncu
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
      initialRoute: '/',
      routes: {
        '/': (context) => _isLoading 
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : _isLoggedIn ? const HomeView() : LoginView(),
        '/login': (context) => LoginView(),
        '/home': (context) => const HomeView(),
      },
      onGenerateRoute: (settings) {
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
