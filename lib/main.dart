import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'package:flutter/services.dart';
import 'services/local_notification_service.dart';
import 'dart:async';

// Arka planda bildirim işleme - Uygulama tamamen kapalıyken
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Arka planda bildirim alındı: ${message.notification?.title}");
  
  // Arka planda gelen bildirimleri kaydetmek veya işlemek için gerekli kodlar
  // LocalNotificationService.showNotification(...) gibi işlemler yapılabilir
}

void main() async {
  // Flutter engine'in hazır olmasını sağla
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase'i başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Arka plan bildirim işleyicisini ayarla
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Bildirim izinlerini iste
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  // Navigasyon için global key oluştur
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Bildirim servislerini başlat
  final localNotificationService = LocalNotificationService();
  final notificationService = NotificationService();
  
  try {
    print('Bildirim servisleri başlatılıyor...');
    await localNotificationService.initialize();
    await notificationService.initialize();
    
    // FCM token'ı al ve kaydet/göster
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $fcmToken');
    
    // Firebase bildirim dinleyicilerini ayarla
    // Ön planda iken
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Ön planda bildirim alındı: ${message.notification?.title}');
      localNotificationService.showNotification(
        id: 0, // Benzersiz ID değeri
        title: message.notification?.title ?? 'Yeni Bildirim',
        body: message.notification?.body ?? '',
        payload: message.data.toString(),
      );
    });
    
    // Arka planda iken ama uygulama açıkken
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Arka planda açık uygulamada bildirime tıklandı: ${message.notification?.title}');
      // Bildirime tıklandığında yapılacak işlemler (navigasyon vb.)
    });
    
    print('Bildirim servisleri başarıyla başlatıldı');
  } catch (e) {
    print('Bildirim servisleri başlatılırken hata: $e');
  }
  
  // NotificationViewModel'i oluştur
  final notificationViewModel = NotificationViewModel(
    localNotificationService: localNotificationService
  );
  
  // Periodik bildirim kontrolünü başlat
  _setupPeriodicNotificationCheck(notificationViewModel);
  
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
        Provider<NotificationService>.value(value: notificationService),
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

// Periyodik bildirim kontrolü ayarla
void _setupPeriodicNotificationCheck(NotificationViewModel viewModel) {
  // Her 15 dakikada bir bildirimleri kontrol et
  Future.delayed(Duration.zero, () async {
    // İlk kontrolü hemen yap
    await viewModel.getNotifications(showAsLocalNotification: true);
    
    // Periyodik kontroller için zamanlayıcı kur
    Timer.periodic(const Duration(minutes: 15), (_) async {
      print('Periyodik bildirim kontrolü yapılıyor...');
      await viewModel.getNotifications(showAsLocalNotification: true);
    });
  });
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
