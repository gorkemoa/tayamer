import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../models/notification_model.dart';

class SmsConfirmationView extends StatefulWidget {
  final int offerId;
  final int companyId;
  final String? detailUrl;
  
  const SmsConfirmationView({
    Key? key, 
    required this.offerId, 
    required this.companyId,
    this.detailUrl,
  }) : super(key: key);

  @override
  _SmsConfirmationViewState createState() => _SmsConfirmationViewState();
}

class _SmsConfirmationViewState extends State<SmsConfirmationView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _smsCodeController = TextEditingController();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında bildirimleri getir
    _fetchNotifications();
  }
  
  @override
  void dispose() {
    _smsCodeController.dispose();
    super.dispose();
  }
  
  // Bildirimleri getir
  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });
    
    final viewModel = Provider.of<NotificationViewModel>(context, listen: false);
    await viewModel.getNotifications();
    
    // SMS bildirimi var mı kontrol et
    final smsNotification = viewModel.findSmsNotification();
    
    setState(() {
      _isLoading = false;
    });
    
    if (smsNotification == null) {
      // SMS bildirimi bulunamadı, uyarı göster
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doğrulama kodu bildirimi bulunamadı.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
  
  // SMS kodunu gönder
  Future<void> _submitSmsCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      final viewModel = Provider.of<NotificationViewModel>(context, listen: false);
      final success = await viewModel.sendSmsCode(_smsCodeController.text);
      
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        // Başarılı ise ana sayfaya dön
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ödeme başarıyla onaylandı.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        // Hata mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${viewModel.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Bildirim detaylarını göster
  Widget _buildNotificationDetails(PaymentNotification notification) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(notification.body),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Onayı'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<NotificationViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading || _isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          // SMS bildirimi
          final smsNotification = viewModel.selectedNotification;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Bildirim başlığı
                const Text(
                  'Telefonunuza Gelen Kodu Giriniz',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Bildirim detayları
                if (smsNotification != null)
                  _buildNotificationDetails(smsNotification),
                
                const SizedBox(height: 32),
                
                // SMS kodu girişi
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _smsCodeController,
                        decoration: const InputDecoration(
                          labelText: 'SMS Kodu',
                          border: OutlineInputBorder(),
                          hintText: 'Lütfen telefonunuza gelen kodu giriniz',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen SMS kodunu giriniz';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: viewModel.isLoading ? null : _submitSmsCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Onayla'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Kodu tekrar gönder
                TextButton(
                  onPressed: viewModel.isLoading ? null : _fetchNotifications,
                  child: const Text(
                    'Kodu Tekrar Gönder',
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 