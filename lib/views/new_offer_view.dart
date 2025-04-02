import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:provider/provider.dart';
import '../models/policy_type_model.dart';
import '../viewmodels/policy_type_viewmodel.dart';
import 'dashboard_view.dart';
import 'home_view.dart';

class NewOfferView extends StatefulWidget {
  const NewOfferView({super.key});

  @override
  State<NewOfferView> createState() => _NewOfferViewState();
}

class _NewOfferViewState extends State<NewOfferView> {
  bool _isBottomSheetActive = false;

  @override
  void initState() {
    super.initState();
    // Widget tamamen initialize olduktan sonra ViewModel'deki verileri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // PolicyTypeViewModel'den poliçe tiplerini yükle
      final viewModel = Provider.of<PolicyTypeViewModel>(context, listen: false);
      viewModel.loadPolicyTypes();
      
      // Bottom sheet'i göster
      _showPolicyTypeBottomSheet(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
    if (_isBottomSheetActive) return;
    
    _isBottomSheetActive = true;
    
    showModalBottomSheet(
      context: context,
      isDismissible: true,
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
                  onPressed: () {
                    // Bottom sheet'i kapat ve ana sayfaya dön
                    Navigator.pop(context);
                    _navigateToHomeIndex(0); // Ana sayfa (Dashboard) indeksi
                  },
                ),
              ),
              Expanded(
                child: Consumer<PolicyTypeViewModel>(
                  builder: (context, viewModel, child) {
                    if (viewModel.state == PolicyTypeViewState.loading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (viewModel.state == PolicyTypeViewState.error) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Hata: ${viewModel.errorMessage}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => viewModel.loadPolicyTypes(),
                              child: const Text('Tekrar Dene'),
                            ),
                          ],
                        ),
                      );
                    } else if (viewModel.activePolicyTypes.isEmpty) {
                      return const Center(
                        child: Text('Aktif poliçe tipi bulunamadı'),
                      );
                    }

                    // Aktif poliçe tiplerini göster
                    return GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: viewModel.activePolicyTypes.length,
                      itemBuilder: (context, index) {
                        final policyType = viewModel.activePolicyTypes[index];
                        return _buildPolicyTypeItem(
                          context,
                          policyType: policyType,
                          onTap: () => _onPolicySelected(context, policyType),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      _isBottomSheetActive = false;
      // Bottom sheet kapatıldığında ana sayfaya dön
      // Bu, kullanıcı swipe ile kapatırsa da çalışır
      if (mounted) {
        _navigateToHomeIndex(0); // Ana sayfa (Dashboard) indeksi
      }
    });
  }

  void _navigateToHomeIndex(int index) {
    if (!mounted) return;
    
    // Ana sayfaya geri dön ve belirli bir indekse git
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => HomeView(), 
        settings: RouteSettings(arguments: index)
      ),
      (route) => false, // Tüm route'ları temizle
    );
  }

  Widget _buildPolicyTypeItem(
    BuildContext context, {
    required PolicyType policyType,
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
            // API'den gelen resmi göster
            Image.network(
              policyType.imageUrl,
              width: 64,
              height: 64,
              errorBuilder: (context, error, stackTrace) {
                // Eğer resim yüklenmezse varsayılan ikonları göster
                IconData iconData = Icons.help_outline;
                if (policyType.title.contains('Trafik')) iconData = Icons.traffic;
                if (policyType.title.contains('Kasko')) iconData = Icons.car_crash;
                if (policyType.title.contains('Sağlık')) iconData = Icons.health_and_safety;
                if (policyType.title.contains('DASK') || policyType.title.contains('Konut')) iconData = Icons.home;
                if (policyType.title.contains('Seyahat')) iconData = Icons.flight;
                if (policyType.title.contains('Hayat')) iconData = Icons.favorite;
                if (policyType.title.contains('Evcil')) iconData = Icons.pets;
                
                return Icon(iconData, size: 56, color: Colors.blue.shade700);
              },
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                policyType.title,
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

  void _onPolicySelected(BuildContext context, PolicyType policyType) {
    // Seçilen poliçe tipini ViewModel'e kaydet
    final viewModel = Provider.of<PolicyTypeViewModel>(context, listen: false);
    viewModel.selectPolicyType(policyType);
    
    // Önce bottom sheet'i kapat
    Navigator.pop(context);
    
    // QR tarama işlemini başlat
    _startQRScan(context, policyType);
  }
  
  void _startQRScan(BuildContext context, PolicyType policyType) async {
    // QR kodu tarama öncesi yardım mesajını göster
    if (policyType.qrCode != null) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('QR Kod Tarama'),
          content: Text(policyType.qrCode!.helpText),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    }
    
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR tarama iptal edildi')),
          );
          // QR tarama iptal edildiğinde de ana sayfaya dön
          _navigateToHomeIndex(0); // Ana sayfa (Dashboard) indeksi
        }
      }
    } catch (e) {
      // Hata durumunda
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR tarama sırasında hata oluştu: $e')),
        );
        // Hata durumunda da ana sayfaya dön
        _navigateToHomeIndex(0); // Ana sayfa (Dashboard) indeksi
      }
    }
  }
  
  void _processQRResult(BuildContext context, PolicyType policyType, String qrResult) {
    // ViewModel aracılığıyla QR sonucunu işle
    final viewModel = Provider.of<PolicyTypeViewModel>(context, listen: false);
    viewModel.processQRCode(qrResult);
    
    if (viewModel.state == PolicyTypeViewState.error) {
      // QR kod işlenemedi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${viewModel.errorMessage}')),
      );
    } else if (viewModel.qrCodeData != null) {
      // QR kod başarıyla işlendi
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR kod başarıyla işlendi.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Burada formu gösterebilir veya veriyi kullanabilirsiniz
      // Örnek: QR verilerini göster
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${policyType.title} için QR Kod Verileri'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: viewModel.qrCodeData!.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text('${entry.key}: ${entry.value}'),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToHomeIndex(0);
              },
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    }
  }
} 