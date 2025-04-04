import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../viewmodels/notification_viewmodel.dart';
import 'sms_confirmation_view.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({Key? key}) : super(key: key);

  @override
  _NotificationsViewState createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Sayfa açıldıktan sonra bildirimleri getir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchNotifications();
    });
  }

  // Bildirimleri getir
  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });
    
    final viewModel = Provider.of<NotificationViewModel>(context, listen: false);
    await viewModel.getNotifications();
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          // Gerçek bildirim gönder butonu
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Gerçek bildirim olarak göster',
            onPressed: _showAsRealNotifications,
          ),
          // Bildirimleri yenile butonu
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Bildirimleri yenile',
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: Consumer<NotificationViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading || _isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (viewModel.isError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 50,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hata: ${viewModel.errorMessage}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchNotifications,
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }
          
          final notifications = viewModel.notifications;
          
          if (notifications == null || notifications.isEmpty) {
            return const Center(
              child: Text(
                'Bildirim bulunamadı',
                style: TextStyle(fontSize: 18),
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: _fetchNotifications,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(context, notification);
              },
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildNotificationCard(BuildContext context, PaymentNotification notification) {
    Color cardColor = Colors.white;
    IconData notificationIcon = Icons.notifications;
    
    // Bildirim tipine göre renk ve ikon belirle
    switch (notification.type) {
      case 'policy_payment_sms_code':
        cardColor = Colors.blue[50]!;
        notificationIcon = Icons.sms;
        break;
      case 'offer_creating':
        cardColor = Colors.green[50]!;
        notificationIcon = Icons.receipt;
        break;
      default:
        cardColor = Colors.grey[50]!;
        notificationIcon = Icons.notifications;
    }
    
    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 2,
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // İkon
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  notificationIcon,
                  color: const Color(0xFF1E3A8A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // İçerik
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: const TextStyle(
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tarih: ${notification.createDate}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _handleNotificationTap(PaymentNotification notification) {
    final viewModel = Provider.of<NotificationViewModel>(context, listen: false);
    
    // Bildirimi seç
    viewModel.setSelectedNotification(notification);
    
    // Bildirim tipine göre işlem yap
    if (notification.type == 'policy_payment_sms_code') {
      // SMS onay sayfasına yönlendir
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SmsConfirmationView(
            offerId: int.tryParse(notification.typeId) ?? 0,
            companyId: 0, // Bu bilgiyi almadığımız için varsayılan değer veriyoruz
          ),
        ),
      );
    } else if (notification.url != null && notification.url!.isNotEmpty) {
      // URL varsa, URL'i açmak için gerekli işlemi yapabilirsiniz
      // Örneğin: launch(notification.url!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('URL açılıyor: ${notification.url}'),
        ),
      );
    }
  }
  
  // Bildirimleri gerçek bildirimler olarak göster
  void _showAsRealNotifications() async {
    final viewModel = Provider.of<NotificationViewModel>(context, listen: false);
    
    try {
      // Kullanıcıya bilgi verme
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bildirimler hazırlanıyor...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      print('Gerçek bildirim gösterme işlemi başlatılıyor...');
      
      // Öncelikle test bildirimi gönder - iOS bildirim izinlerini kontrol etmek için
      try {
        print('Önce test bildirimi gönderiliyor...');
        await viewModel.showTestNotification();
        print('Test bildirimi başarılı');
      } catch (testError) {
        print('Test bildirimi hatası: $testError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bildirim izinlerini kontrol edin: ${testError.toString()}'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        // Test bildirimi hatası olsa bile devam et
      }
      
      if (viewModel.notifications == null || viewModel.notifications!.isEmpty) {
        // Önce bildirimleri getir, sonra göster
        print('Bildirimler alınıyor ve gösteriliyor...');
        await viewModel.getNotifications(showAsLocalNotification: true);
      } else {
        // Zaten bildirimler var, doğrudan göster
        print('Mevcut bildirimler gösteriliyor...');
        for (var notification in viewModel.notifications!.take(1)) {
          print('Bildirimi gönderiyor: ${notification.title}');
          await viewModel.showTestNotification();
        }
      }
      
      // Başarılı ise kullanıcıya bildir
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bildirim başarıyla gönderildi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Hata durumunda kullanıcıya bildirme
      print('Bildirim gösterme ana hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bildirim gösterilirken hata: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
} 