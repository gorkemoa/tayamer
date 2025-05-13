import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Bildirimleri getir
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
        title: const Text('Bildirimler', style: TextStyle(fontSize: 17)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
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
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hata: ${viewModel.errorMessage}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _fetchNotifications,
                    child: const Text('Tekrar Dene', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
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
                style: TextStyle(fontSize: 14),
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: _fetchNotifications,
            child: ListView.builder(
              padding: const EdgeInsets.all(6.0),
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
      margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 2.0),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Icon(
                  notificationIcon,
                  color: const Color(0xFF1E3A8A),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tarih: ${notification.createDate}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 10,
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
    
    // Bildirimi seç ve ViewModel'deki handleNotificationTap fonksiyonunu çağır
    String? targetRoute = viewModel.handleNotificationTap(notification);
    
    if (targetRoute != null) {
      // Hedef rotaya yönlendir
      if (notification.type == 'policy_created') {
        // Poliçe detay sayfasına yönlendir
        Navigator.pushNamed(
          context,
          targetRoute,
          arguments: {'policyId': notification.typeId}
        );
      } else if (notification.type == 'policy_payment_sms_code') {
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
      } else if (notification.type == 'policy_payment_waiting') {
        // Ödeme sayfasına yönlendir
        Navigator.pushNamed(
          context, 
          targetRoute,
          arguments: {'paymentId': notification.typeId}
        );
      } else if (notification.url != null && notification.url!.isNotEmpty) {
        // URL varsa, URL'i açmak için gerekli işlemi yapabilirsiniz
        launchUrl(Uri.parse(notification.url!));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('URL açılıyor: ${notification.url}'),
          ),
        );
      } else {
        // Diğer durumlarda varsayılan rotaya yönlendir
        Navigator.pushNamed(context, targetRoute);
      }
    }
  }
} 