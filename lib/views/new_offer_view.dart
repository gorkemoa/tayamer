import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class NewOfferView extends StatefulWidget {
  const NewOfferView({super.key});

  @override
  State<NewOfferView> createState() => _NewOfferViewState();
}

class _NewOfferViewState extends State<NewOfferView> {
  @override
  void initState() {
    super.initState();
    // Widget tamamen initialize olduktan sonra bottom sheet'i göster
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPolicyTypeBottomSheet(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Teklif Merkezi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined, 
              size: 100, 
              color: Colors.grey[400]
            ),
            const SizedBox(height: 20),
            Text(
              'Henüz teklifiniz bulunmuyor',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Yeni teklif oluşturmak için aşağıdaki butona tıklayın',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ElevatedButton(
            onPressed: () => _showPolicyTypeBottomSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C3879),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Yeni Teklif Oluştur',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _showPolicyTypeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              AppBar(
                centerTitle: true,
                backgroundColor: const Color(0xFF1C3879),
                foregroundColor: Colors.white,
                elevation: 0,
                title: const Text('Poliçe Tipi Seç'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: GridView.count(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildPolicyTypeItem(
                      context,
                      title: 'Trafik Sigortası',
                      icon: 'assets/icons/traffic_light.png',
                      onTap: () => _onPolicySelected(context, 'Trafik Sigortası'),
                    ),
                    _buildPolicyTypeItem(
                      context,
                      title: 'Kasko',
                      icon: 'assets/icons/car_insurance.png',
                      onTap: () => _onPolicySelected(context, 'Kasko'),
                    ),
                    _buildPolicyTypeItem(
                      context,
                      title: 'Tamamlayıcı Sağlık',
                      icon: 'assets/icons/health_care.png',
                      onTap: () => _onPolicySelected(context, 'Tamamlayıcı Sağlık'),
                    ),
                    _buildPolicyTypeItem(
                      context,
                      title: 'Özel Sağlık',
                      icon: 'assets/icons/hospital.png',
                      onTap: () => _onPolicySelected(context, 'Özel Sağlık'),
                    ),
                    _buildPolicyTypeItem(
                      context,
                      title: 'DASK',
                      icon: 'assets/icons/home.png',
                      onTap: () => _onPolicySelected(context, 'DASK'),
                    ),
                    _buildPolicyTypeItem(
                      context,
                      title: 'Konut Sigortası',
                      icon: 'assets/icons/home_insurance.png',
                      onTap: () => _onPolicySelected(context, 'Konut Sigortası'),
                    ),
                    _buildPolicyTypeItem(
                      context,
                      title: 'Seyahat Sağlık',
                      icon: 'assets/icons/travel.png',
                      onTap: () => _onPolicySelected(context, 'Seyahat Sağlık'),
                    ),
                    _buildPolicyTypeItem(
                      context,
                      title: 'Hayat Sigortası',
                      icon: 'assets/icons/hospital.png',
                      onTap: () => _onPolicySelected(context, 'Hayat Sigortası'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPolicyTypeItem(
    BuildContext context, {
    required String title,
    required String icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // İkon gösterimi - QR işlemi için
            Image.asset(
              icon,
              width: 64,
              height: 64,
              errorBuilder: (context, error, stackTrace) {
                // Eğer asset bulunamazsa varsayılan ikonları göster
                IconData iconData = Icons.help_outline;
                if (title.contains('Trafik')) iconData = Icons.traffic;
                if (title.contains('Kasko')) iconData = Icons.car_crash;
                if (title.contains('Sağlık')) iconData = Icons.health_and_safety;
                if (title.contains('DASK') || title.contains('Konut')) iconData = Icons.home;
                if (title.contains('Seyahat')) iconData = Icons.flight;
                if (title.contains('Hayat')) iconData = Icons.favorite;
                
                return Icon(iconData, size: 56, color: Colors.blue.shade700);
              },
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPolicySelected(BuildContext context, String policyType) {
    // Önce bottom sheet'i kapat
    Navigator.pop(context);
    
    // QR tarama işlemini başlat
    _startQRScan(context, policyType);
  }
  
  void _startQRScan(BuildContext context, String policyType) async {
    try {
      String qrResult = await FlutterBarcodeScanner.scanBarcode(
        '#3D8BEF', // tarayıcı çizgisi rengi
        'Vazgeç', // iptal butonu metni
        true, // flaş ışığı aktif
        ScanMode.QR, // sadece QR kod tara
      );
      
      if (qrResult != '-1') { // -1 taramadan vazgeçildiğinde dönüyor
        // QR kod başarıyla tarandı, sonucu işle
        _processQRResult(context, policyType, qrResult);
      } else {
        // Kullanıcı taramadan vazgeçti
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR tarama iptal edildi')),
        );
      }
    } catch (e) {
      // Hata durumunda
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR tarama sırasında hata oluştu: $e')),
      );
    }
  }
  
  void _processQRResult(BuildContext context, String policyType, String qrResult) {
    // QR sonucunu işlemek için burada gerekli kodları ekle
    // Örneğin, API'ye istek gönderme, veritabanına kaydetme vb.
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$policyType için QR sonucu: $qrResult')),
    );
    
    // Bu kısımda QR kod sonucuna göre yapılacak işlemleri ekle
    // Örneğin, başka bir sayfaya yönlendirme, verileri görüntüleme vb.
  }
} 