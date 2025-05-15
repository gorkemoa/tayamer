import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' show File, Platform;
import 'package:flutter/cupertino.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as mobile_scanner;
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/policy_type_model.dart';
import '../viewmodels/policy_type_viewmodel.dart';
import '../viewmodels/offer_viewmodel.dart';
import 'home_view.dart';
import 'offer_success_view.dart';
import 'package:permission_handler/permission_handler.dart';

class NewOfferView extends StatefulWidget {
  const NewOfferView({super.key});

  @override
  State<NewOfferView> createState() => _NewOfferViewState();
}

class _NewOfferViewState extends State<NewOfferView> {
  bool _isBottomSheetActive = false;
  bool _isPolicySelected = false;

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
      _showPolicyTypeBottomSheet();
    });
  }

  @override
  void dispose() {
    _isPolicySelected = false;
    _isBottomSheetActive = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Yeni Teklif', style: TextStyle(color: Color(0xFF1C3879))),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 80, color: Colors.blue.shade200),
            const SizedBox(height: 24),
            const Text(
              'Poliçe Tipi Seçimi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C3879),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Teklif almak istediğiniz poliçe tipini seçin',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _showPolicyTypeBottomSheet,
              icon: const Icon(Icons.touch_app),
              label: const Text('Poliçe Tipi Seç'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C3879),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        color: Colors.white,
        child: Container(height: 48),
      ),
    );
  }
  
  void _showPolicyTypeBottomSheet() {
    if (_isBottomSheetActive) return;
    
    setState(() {
      _isBottomSheetActive = true;
    });
    
    // Animasyon için kısa gecikme
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) {
        _isBottomSheetActive = false;
        return;
      }
      
      showModalBottomSheet(
        context: context,
        isDismissible: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        elevation: 20,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => _buildPolicyBottomSheet(context),
      ).then((_) => _handleBottomSheetClosed());
    });
  }
  
  Widget _buildPolicyBottomSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      expand: true,
      snap: true,
      snapSizes: const [0.5, 0.85, 0.92],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              )
            ],
          ),
          child: Column(
            children: [
              // Çekme göstergesi
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Başlık
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: AppBar(
                  centerTitle: true,
                  backgroundColor: const Color(0xFF1C3879),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  title: const Column(
                    children: [
                      Text(
                        'Poliçe Tipi Seç',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Teklif almak istediğiniz poliçe tipini seçin',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              // İçerik
              Expanded(
                child: _buildPolicyTypesList(context, scrollController),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildPolicyTypesList(BuildContext context, ScrollController scrollController) {
    return Consumer<PolicyTypeViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.state == PolicyTypeViewState.loading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Poliçe tipleri yükleniyor...'),
              ],
            ),
          );
        } else if (viewModel.state == PolicyTypeViewState.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Hata: ${viewModel.errorMessage}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => viewModel.loadPolicyTypes(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C3879),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (viewModel.activePolicyTypes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, color: Colors.grey, size: 48),
                SizedBox(height: 16),
                Text(
                  'Aktif poliçe tipi bulunamadı',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Aktif poliçe tiplerini göster
        return GridView.builder(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.9,
          ),
          itemCount: viewModel.activePolicyTypes.length,
          itemBuilder: (context, index) {
            final policyType = viewModel.activePolicyTypes[index];
            return _buildPolicyTypeItem(
              context,
              policyType: policyType,
              onTap: () => _selectPolicyType(context, viewModel, policyType),
            );
          },
        );
      },
    );
  }

  void _selectPolicyType(BuildContext context, PolicyTypeViewModel viewModel, PolicyType policyType) {
    if (!mounted) return;
    
    setState(() {
      _isPolicySelected = true;
    });
    
    // Seçilen poliçe tipini ViewModel'e kaydet
    viewModel.selectPolicyType(policyType);
    
    // Önce bottom sheet'i kapat
    Navigator.pop(context);
    
    // QR özelliği varsa tarama başlat, yoksa doğrudan manuel giriş formuna git
    if (policyType.qrCode != null) {
      _startQRScan(context, policyType);
    } else {
      if (mounted) {
        // Yeni sayfaya geçmeden önce güvenli bir şekilde state güncellemesi
        setState(() {
          _isPolicySelected = false;
        });
        
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ManualEntryView(policyType: policyType)),
        );
      }
    }
  }

  Widget _buildPolicyTypeItem(
    BuildContext context, {
    required PolicyType policyType,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.blue.withOpacity(0.1),
        highlightColor: Colors.blue.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: _buildPolicyTypeImage(policyType),
              ),
              const SizedBox(height: 16),
              Text(
                policyType.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (policyType.qrCode != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'QR ile Hızlı Giriş',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
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
  
  Widget _buildPolicyTypeImage(PolicyType policyType) {
    return Image.network(
      policyType.imageUrl,
      width: 60,
      height: 60,
      errorBuilder: (context, error, stackTrace) {
        // Eğer resim yüklenmezse kategori bazlı ikonları göster
        IconData iconData = Icons.help_outline;
        if (policyType.title.contains('Trafik')) iconData = Icons.traffic;
        if (policyType.title.contains('Kasko')) iconData = Icons.car_crash;
        if (policyType.title.contains('Sağlık')) iconData = Icons.health_and_safety;
        if (policyType.title.contains('DASK') || policyType.title.contains('Konut')) iconData = Icons.home;
        if (policyType.title.contains('Seyahat')) iconData = Icons.flight;
        if (policyType.title.contains('Hayat')) iconData = Icons.favorite;
        if (policyType.title.contains('Evcil')) iconData = Icons.pets;
        
        return Icon(iconData, size: 60, color: Colors.blue.shade700);
      },
    );
  }

  void _startQRScan(BuildContext context, PolicyType policyType) async {
    print("DEBUG-OFFER: _startQRScan başladı");
    if (!mounted) {
      print("DEBUG-OFFER: _startQRScan erken çıkış - mounted=false");
      return;
    }
    
    bool wasPolicySelected = _isPolicySelected;
    print("DEBUG-OFFER: Başlangıç _isPolicySelected=$_isPolicySelected");
    
    setState(() {
      _isPolicySelected = true;
    });
    
    try {
      print("DEBUG-OFFER: QR süreci başlatılıyor");
      
      // Önce form sayfasını aç
      final formPage = ManualEntryView(
        policyType: policyType,
        initialData: {'manualEntry': 'true'},
      );
      
      // QR tarama sayfasını aç
      final qrResult = await Navigator.push<Map<String, String>>(
        context,
        MaterialPageRoute(
          builder: (context) => QRScannerView(
            onManualEntry: () {
              Navigator.of(context).pop();
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => formPage),
                );
              }
            },
            onResult: (data) {
              Navigator.of(context).pop();
              if (mounted) {
                // QR sonucunu form sayfasına aktar
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManualEntryView(
                      policyType: policyType,
                      initialData: data,
                    ),
                  ),
                );
              }
            },
            parentState: this,
          ),
        ),
      );
      
      print("DEBUG-OFFER: QR sonucu alındı: ${qrResult?.toString()}");
      
    } catch (e) {
      print("DEBUG-OFFER: QR işlem hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR tarama sırasında bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPolicySelected = wasPolicySelected;
        });
      }
    }
  }

  void _handleBottomSheetClosed() {
    if (!mounted) return;
    
    setState(() {
      _isBottomSheetActive = false;
    });
    
    // Bottom sheet kapandığında herhangi bir yönlendirme yapmıyoruz
    // Böylece kullanıcı en son görüntülediği sayfada kalacak
    
    // Eğer doğrudan yeni teklif sayfasına gelmiş ve geri gidilecek sayfa yoksa
    // (Yani Navigator.of(context).canPop() false ise) ana sayfaya yönlendir
    if (!_isPolicySelected && mounted && !Navigator.of(context).canPop()) {
      _navigateToHomeIndex(1);
    }
  }

  void _navigateToHomeIndex(int index) {
    if (!mounted) return;
    
    setState(() {
      _isPolicySelected = false;
      _isBottomSheetActive = false;
    });
    
    Future.microtask(() {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => HomeView(initialIndex: index),
            settings: RouteSettings(arguments: index)
          ),
          (route) => false,
        );
      }
    });
  }
}

// Manuel giriş formu için yeni sınıf
class ManualEntryView extends StatefulWidget {
  final PolicyType policyType;
  final Map<String, String>? initialData;

  const ManualEntryView({Key? key, required this.policyType, this.initialData}) : super(key: key);

  @override
  State<ManualEntryView> createState() => _ManualEntryViewState();
}

class _ManualEntryViewState extends State<ManualEntryView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _descController = TextEditingController();
  bool isGalleryMode = false;  // Galeri modunda mıyız?
  List<String> focusFields = [];  // Galeri modunda odaklanılacak alanlar

  @override
  void initState() {
    super.initState();
    print("DEBUG-FORM: ManualEntryView initState başladı");
    print("DEBUG-FORM: initialData=${widget.initialData}");
    
    // Form için controller'ları oluştur
    for (var field in widget.policyType.fields) {
      _controllers[field.key] = TextEditingController();
    }
    
    // Açıklama alanı için varsayılan değer
    _descController.text = widget.policyType.desc;
    
    // Eğer initialData varsa, controller'lara verileri yükle
    if (widget.initialData != null) {
      print('DEBUG-FORM: Initial data geldi: ${widget.initialData}');
      
      // Galeri modunda mıyız kontrol et 
      isGalleryMode = widget.initialData!.containsKey('galleryMode');
      print('DEBUG-FORM: isGalleryMode=$isGalleryMode');
      
      // Form alanlarına QR kod verilerini yerleştir
      widget.policyType.fields.forEach((field) {
        String? value;
        
        // Alan tipine göre veri eşleştirme
        if (field.name.toLowerCase().contains('tc') || 
            field.key.toLowerCase().contains('tc') || 
            field.key.toLowerCase().contains('kimlik')) {
          value = widget.initialData!['tc'];
          if (value != null) {
            print('DEBUG-FORM: TC alanı eşleşti: $value -> ${field.key}');
          }
        }
        else if (field.name.toLowerCase().contains('plaka') || 
                 field.key.toLowerCase().contains('plaka')) {
          value = widget.initialData!['plaka'];
          if (value != null) {
            print('DEBUG-FORM: Plaka alanı eşleşti: $value -> ${field.key}');
          }
        }
        else if (field.name.toLowerCase().contains('ruhsat') || 
                 field.key.toLowerCase().contains('ruhsat')) {
          value = widget.initialData!['ruhsatNo'];
          if (value != null) {
            print('DEBUG-FORM: Ruhsat alanı eşleşti: $value -> ${field.key}');
          }
        }
        else if (widget.initialData!.containsKey('raw')) {
          // Eğer raw veri varsa ve alan boşsa, raw veriyi kullan
          value = widget.initialData!['raw'];
          if (value != null) {
            print('DEBUG-FORM: Raw veri eşleşti: $value -> ${field.key}');
          }
        }
        
        // Eğer değer bulunduysa controller'a ata
        if (value != null) {
          _controllers[field.key]?.text = value;
          // Galeri modunda odaklanılacak alanları işaretle
          if (isGalleryMode) {
            focusFields.add(field.key);
          }
        }
      });
      
      print('DEBUG-FORM: Odaklanılacak alanlar: $focusFields');
    }
  }

  @override
  void dispose() {
    // Controller'ları temizle
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Eğer ana sayfaya erişebilirsek (bir ebeveyn NewOfferView sınıfı varsa)
        if (Navigator.of(context).canPop()) {
          // Ebeveyn sayfadaki state'te _isPolicySelected değişkenini sıfırla
          final ancestor = context.findAncestorStateOfType<_NewOfferViewState>();
          if (ancestor != null && ancestor.mounted) {
            ancestor.setState(() {
              ancestor._isPolicySelected = false;
            });
          }
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${widget.policyType.title} Bilgileri'),
              if (isGalleryMode) 
                const Text(
                  'Fotoğraftan QR Okuma', 
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // Eğer ana sayfaya erişebilirsek (bir ebeveyn NewOfferView sınıfı varsa)
              final ancestor = context.findAncestorStateOfType<_NewOfferViewState>();
              if (ancestor != null && ancestor.mounted) {
                ancestor.setState(() {
                  ancestor._isPolicySelected = false;
                });
              }
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Aşağıdaki bilgileri kontrol ederek, poliçenizi oluşturabilirsiniz.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                
                
                
                const SizedBox(height: 16),
                
                // Form alanlarını oluştur
                ...widget.policyType.fields.map((field) => _buildFormField(field)).toList(),
                
                // Açıklama alanı
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ek Açıklama',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Eklemek istediğiniz bilgiler...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Devam butonu
                Consumer<OfferViewModel>(
                  builder: (context, viewModel, child) {
                    if (viewModel.state == OfferViewState.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    return ElevatedButton(
                      onPressed: () => _submitForm(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1C3879),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Teklif Oluştur',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(Field field) {
    // Galeri modunda bu alan odaklanılması gereken bir alan mı?
    bool isHighlightField = isGalleryMode && focusFields.contains(field.key);
    
    if (field.type == 'select') {
      return _buildSelectField(context, field, isHighlightField);
    } else if (field.type == 'date') {
      return _buildDateField(field, isHighlightField);
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${field.name} ${field.rules.containsKey('required') && field.rules['required']!.value ? '(*)' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      // Galeri modunda vurgulama - önemli alanlar için renk değiştir
                      color: isHighlightField ? Colors.blue.shade800 : null,
                    ),
                  ),
                ),
                // Galeri modunda vurgulama - önemli alanlar için ikon ekle
                if (isHighlightField)
                  const Icon(Icons.edit, color: Colors.blue, size: 16),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _controllers[field.key],
              decoration: InputDecoration(
                hintText: 'Örn: "${field.placeholder}"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                // Galeri modunda vurgulama - önemli alanlar için renk değiştir
                enabledBorder: isHighlightField ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.blue.shade400, width: 1.5),
                ) : null,
                focusedBorder: isHighlightField ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.blue.shade700, width: 1.5),
                ) : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                // Galeri modunda bilgi ikonu ekle
                suffixIcon: isHighlightField ? const Icon(Icons.info_outline, color: Colors.blue, size: 18) : null,
              ),
              // Settings özelliklerini uygula
              keyboardType: _getKeyboardType(field),
              textCapitalization: _getTextCapitalization(field),
              autocorrect: _getAutocorrect(field),
              autofocus: _getAutofocus(field) || isHighlightField, // Galeri modunda otomatik odaklan
              // Maksimum uzunluk kuralı
              maxLength: field.rules.containsKey('maxLength') ? 
                (field.rules['maxLength']!.value as int?) : null,
              // Karakter sayacını gizle
              buildCounter: field.rules.containsKey('maxLength') ? 
                (context, {required currentLength, required isFocused, maxLength}) => null : null,
              // Tüm kuralları kontrol eden validator
              validator: (value) {
                // Zorunluluk kontrolü
                if (field.rules.containsKey('required') && 
                    field.rules['required']!.value && 
                    (value == null || value.isEmpty)) {
                  return field.rules['required']!.message ?? 'Bu alan zorunludur';
                }
                
                // Minimum uzunluk kontrolü
                if (field.rules.containsKey('minLength') && 
                    value != null && 
                    value.length < (field.rules['minLength']!.value as int)) {
                  return field.rules['minLength']!.message ?? 
                    'En az ${field.rules['minLength']!.value} karakter girilmelidir';
                }
                
                // Maksimum uzunluk kontrolü (UI zaten maxLength ile sınırlıyor ama doğrulama için)
                if (field.rules.containsKey('maxLength') && 
                    value != null && 
                    value.length > (field.rules['maxLength']!.value as int)) {
                  return field.rules['maxLength']!.message ?? 
                    'En fazla ${field.rules['maxLength']!.value} karakter girilmelidir';
                }
                
                // Regex pattern kontrolü
                if (field.rules.containsKey('pattern') && 
                    value != null && 
                    value.isNotEmpty) {
                  final pattern = RegExp(field.rules['pattern']!.value as String);
                  if (!pattern.hasMatch(value)) {
                    return field.rules['pattern']!.message ?? 'Geçersiz format';
                  }
                }
                
                return null; // Tüm kurallar geçerli
              },
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSelectField(BuildContext context, Field field, bool isHighlightField) {
    final viewModel = Provider.of<PolicyTypeViewModel>(context);
    final options = field.options ?? [];
    final String selectedValue = viewModel.getSelectedOption(field.key) ?? '';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
              '${field.name} ${field.rules.containsKey('required') && field.rules['required']!.value ? '(*)' : ''}',
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.w500,
                    // Galeri modunda vurgulama
                    color: isHighlightField ? Colors.blue.shade800 : null,
                  ),
                ),
              ),
              // Galeri modunda vurgulama - önemli alanlar için ikon ekle
              if (isHighlightField)
                const Icon(Icons.edit, color: Colors.blue, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: selectedValue.isNotEmpty ? selectedValue : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              // Galeri modunda vurgulama
              enabledBorder: isHighlightField ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 1.5),
              ) : null,
              focusedBorder: isHighlightField ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.blue.shade700, width: 1.5),
              ) : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option.value,
                child: Text(option.label),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                viewModel.selectOption(field.key, value);
              }
            },
            validator: (value) {
              // Zorunluluk kuralını kontrol et
              if (field.rules.containsKey('required') && 
                  field.rules['required']!.value && 
                  (value == null || value.isEmpty)) {
                return field.rules['required']!.message ?? 'Bu alan zorunludur';
              }
              return null;
            },
            // Seçenek yoksa veya tek seçenek varsa görüntülemeyi ayarla
            disabledHint: options.isEmpty 
                ? const Text('Seçenek bulunamadı') 
                : null,
            // Placeholder
            hint: Text(field.placeholder.isNotEmpty 
                ? field.placeholder 
                : 'Seçiniz'),
          ),
        ],
      ),
    );
  }

  // Klavye türünü settings'ten alma
  TextInputType _getKeyboardType(Field field) {
    if (field.settings == null || field.settings!['keyboardType'] == null) {
      // Varsayılan klavye türü
      return TextInputType.text;
    }
    
    switch (field.settings!['keyboardType']) {
      case 'numeric':
        return TextInputType.number;
      case 'email':
        return TextInputType.emailAddress;
      case 'phone':
        return TextInputType.phone;
      default:
        return TextInputType.text;
    }
  }

  // Otomatik büyük harf ayarını settings'ten alma
  TextCapitalization _getTextCapitalization(Field field) {
    if (field.settings == null || field.settings!['autoCapitalize'] == null) {
      // Varsayılan değer
      return TextCapitalization.none;
    }
    
    switch (field.settings!['autoCapitalize']) {
      case 'characters':
        return TextCapitalization.characters; // Tüm karakterleri büyük harf yap
      case 'words':
        return TextCapitalization.words; // Her kelimenin ilk harfini büyük yap
      case 'sentences':
        return TextCapitalization.sentences; // Cümlelerin ilk harfini büyük yap
      default:
        return TextCapitalization.none; // Hiçbir şeyi büyük harfe çevirme
    }
  }

  // Otomatik düzeltme ayarını settings'ten alma
  bool _getAutocorrect(Field field) {
    if (field.settings == null || field.settings!['autoCorrect'] == null) {
      // Varsayılan değer
      return true;
    }
    
    return field.settings!['autoCorrect'] as bool;
  }

  // Otomatik odaklanma ayarını settings'ten alma
  bool _getAutofocus(Field field) {
    if (field.settings == null || field.settings!['autoFocus'] == null) {
      // Varsayılan değer
      return false;
    }
    
    return field.settings!['autoFocus'] as bool;
  }

  // Tarih seçim alanı için özel widget
  Widget _buildDateField(Field field, bool isHighlightField) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
            '${field.name} ${field.rules.containsKey('required') && field.rules['required']!.value ? '(*)' : ''}',
                  style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
                    // Galeri modunda vurgulama
                    color: isHighlightField ? Colors.blue.shade800 : null,
                  ),
                ),
              ),
              // Galeri modunda vurgulama - önemli alanlar için ikon ekle
              if (isHighlightField)
                const Icon(Icons.edit, color: Colors.blue, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _controllers[field.key],
            readOnly: true, // Klavye girişini devre dışı bırak
            decoration: InputDecoration(
              hintText: 'Örn: "${field.placeholder}"',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              // Galeri modunda vurgulama
              enabledBorder: isHighlightField ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 1.5),
              ) : null,
              focusedBorder: isHighlightField ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.blue.shade700, width: 1.5),
              ) : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            validator: (value) {
              if (field.rules.containsKey('required') && 
                  field.rules['required']!.value && 
                  (value == null || value.isEmpty)) {
                return field.rules['required']!.message ?? 'Bu alan zorunludur';
              }
              return null;
            },
            onTap: () async {
              // Platform spesifik tarih seçici göster
              DateTime? pickedDate;
              
              if (Platform.isIOS) {
                // iOS için CupertinoDatePicker kullan
                await showCupertinoModalPopup(
                  context: context, 
                  builder: (BuildContext context) {
                    DateTime tempPickedDate = DateTime.now();
                    return Container(
                      height: 300,
                      color: Colors.white,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CupertinoButton(
                                child: const Text('İptal'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              const Text(
                                'Tarih Seçin',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              CupertinoButton(
                                child: const Text('Tamam'),
                                onPressed: () {
                                  pickedDate = tempPickedDate;
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                          Expanded(
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.date,
                              initialDateTime: DateTime.now(),
                              minimumDate: DateTime(1900),
                              maximumDate: DateTime(2100),
                              onDateTimeChanged: (DateTime dateTime) {
                                tempPickedDate = dateTime;
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                );
              } else {
                // Android için Material Design DatePicker kullan
                pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                  // Türkçe tarih formatı için yerelleştirme ayarı
                  locale: const Locale('tr', 'TR'),
                );
              }
              
              if (pickedDate != null && mounted) {
                // API için tarih formatı (YYYY-MM-DD)
                final apiFormattedDate = '${pickedDate!.year}-${pickedDate!.month.toString().padLeft(2, '0')}-${pickedDate!.day.toString().padLeft(2, '0')}';
                
                // Türkçe görüntüleme formatı (GG.AA.YYYY)
                final turkishFormattedDate = '${pickedDate!.day.toString().padLeft(2, '0')}.${pickedDate!.month.toString().padLeft(2, '0')}.${pickedDate!.year}';
                
                // Widget hala ağaçta olduğundan eminiz, çünkü yukarıda kontrol ettik
                setState(() {
                  // API'ye gönderilecek değer olarak controller'a atama yapıyoruz
                  _controllers[field.key]!.text = apiFormattedDate;
                  
                  // Görüntüleme için Türkçe format
                  _controllers[field.key]!.value = TextEditingValue(
                    text: turkishFormattedDate,
                    selection: TextSelection.collapsed(offset: turkishFormattedDate.length),
                  );
                });
              }
            },
          ),
        ],
      ),
    );
  }

  void _submitForm(BuildContext context) async {
    // Tüm kuralları doğrula
    if (_formKey.currentState!.validate()) {
      // Form verilerini topla
      Map<String, dynamic> formData = {
        'policyType': widget.policyType.typeId.toString(),
        'desc': _descController.text,
      };
      
      // Form alanlarını ekle ve özel veri tipleri için formatlama yapma
      _controllers.forEach((key, controller) {
        final field = widget.policyType.fields.firstWhere(
          (f) => f.key == key,
          orElse: () => Field(
            key: key, name: key, placeholder: '', type: 'text', rules: {}
          ),
        );
        
        // Alan türüne göre veri formatını ayarla
        if (field.type == 'date') {
          // Tarih formatı kontrolü - eğer Türkçe formatta ise API formatına çevir
          String value = controller.text;
          if (value.contains('.') && value.split('.').length == 3) {
            // GG.AA.YYYY formatındaysa YYYY-MM-DD formatına çevir
            final parts = value.split('.');
            if (parts.length == 3) {
              value = '${parts[2]}-${parts[1]}-${parts[0]}';
            }
          }
          formData[key] = value.isNotEmpty ? value : null;
        } else if (field.type == 'select') {
          // Seçim değerini al
          final viewModel = Provider.of<PolicyTypeViewModel>(context, listen: false);
          formData[key] = viewModel.getSelectedOption(key) ?? controller.text;
        } else {
          formData[key] = controller.text;
        }
      });
      
      // OfferViewModel üzerinden formu gönder
      final viewModel = Provider.of<OfferViewModel>(context, listen: false);
      final success = await viewModel.createOffer(formData);
      
      if (!mounted) return;
      
      if (success) {
        // Başarı sayfasına yönlendir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OfferSuccessView(
              message: viewModel.offerResponse?['data']['message'] ?? 'Teklifiniz başarıyla oluşturuldu.',
            ),
          ),
        );
      } else {
        // Hata durumunda mesaj göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${viewModel.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Formda hatalar var, kullanıcıyı bilgilendir
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen formdaki hataları düzeltin'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

class QRScannerView extends StatefulWidget {
  final Function(Map<String, String> data)? onResult;
  final VoidCallback? onManualEntry;
  final bool isGalleryMode;
  final _NewOfferViewState? parentState;

  const QRScannerView({
    Key? key,
    this.onResult,
    this.onManualEntry,
    this.isGalleryMode = false,
    this.parentState,
  }) : super(key: key);

  @override
  State<QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends State<QRScannerView> {
  final mobile_scanner.MobileScannerController controller = mobile_scanner.MobileScannerController();
  bool isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _processQRCode(String qrData) {
    try {
      // QR kod verilerini parse et
      Map<String, String> result = {};
      
      // Birleşik format kontrolü (GF362751-34ZG3326-3350421749)
      if (qrData.contains('-')) {
        final parts = qrData.split('-');
        if (parts.length == 3) {
          // Ruhsat, Plaka ve TC formatında
          result['ruhsatNo'] = parts[0];
          result['plaka'] = parts[1];
          result['tc'] = parts[2];
          print('DEBUG-QR: Birleşik format tespit edildi: ${result.toString()}');
        }
      }
      // Tekil format kontrolleri
      else {
        // TC Kimlik kontrolü (11 haneli sayı)
        if (qrData.length == 11 && int.tryParse(qrData) != null) {
          result['tc'] = qrData;
          print('DEBUG-QR: TC format tespit edildi: ${result.toString()}');
        }
        // Plaka kontrolü (örn: 34ABC123)
        else if (RegExp(r'^[0-9]{2}[A-Z]{1,3}[0-9]{2,4}$').hasMatch(qrData)) {
          result['plaka'] = qrData;
          print('DEBUG-QR: Plaka format tespit edildi: ${result.toString()}');
        }
        // Ruhsat numarası kontrolü (en az 8 karakter alfanumerik)
        else if (RegExp(r'^[A-Z0-9]{8,}$').hasMatch(qrData)) {
          result['ruhsatNo'] = qrData;
          print('DEBUG-QR: Ruhsat format tespit edildi: ${result.toString()}');
        }
      }
      
      // Eğer hiçbir formata uymuyorsa, raw veriyi gönder
      if (result.isEmpty) {
        result['raw'] = qrData;
        print('DEBUG-QR: Bilinmeyen format: ${result.toString()}');
      }
      
      // Galeri modunda olduğumuzu belirt
      result['galleryMode'] = 'true';
      
      if (widget.onResult != null) {
        widget.onResult!(result);
      }
    } catch (e) {
      print('DEBUG-QR: İşleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR kod işlenirken bir hata oluştu. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
            if (widget.parentState != null && widget.parentState!.mounted) {
              widget.parentState!._showPolicyTypeBottomSheet();
            }
          },
        ),
        title: const Text('QR Kod Tarama'),
        backgroundColor: const Color(0xFF1C3879),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case mobile_scanner.TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case mobile_scanner.TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case mobile_scanner.CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case mobile_scanner.CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          mobile_scanner.MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (isProcessing) return;
              isProcessing = true;

              final List<mobile_scanner.Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final barcode = barcodes.first;
                if (barcode.rawValue != null) {
                  _processQRCode(barcode.rawValue!);
                }
              }
              isProcessing = false;
            },
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (widget.onManualEntry != null) {
                        widget.onManualEntry!();
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Manuel Giriş'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1C3879),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickAndProcessImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Fotoğraf Yükle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C3879),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndProcessImage() async {
    try {
      // Önce kamerayı durdur
      await controller.stop();
      
      // İzinleri kontrol et
      if (Platform.isAndroid) {
        // Android 13 ve üzeri için photos izni
        if (await Permission.photos.status.isDenied) {
          final result = await Permission.photos.request();
          if (result.isDenied) {
            if (!mounted) return;
            _showPermissionDialog('Galeri');
            return;
          }
        }
        
        // Android 13 altı için storage izni
        if (int.parse(await _getAndroidVersion()) < 33) {
          if (await Permission.storage.status.isDenied) {
            final result = await Permission.storage.request();
            if (result.isDenied) {
              if (!mounted) return;
              _showPermissionDialog('Depolama');
              return;
            }
          }
        }
      } else if (Platform.isIOS) {
        final status = await Permission.photos.status;
        if (status.isDenied || status.isRestricted) {
          final result = await Permission.photos.request();
          if (result.isDenied || result.isRestricted) {
            if (!mounted) return;
            _showPermissionDialog('Galeri');
            return;
          }
        }
      }

      // Görseli seç
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 95,
      ).catchError((error) {
        print('DEBUG-GALLERY: Görsel seçme hatası: $error');
        throw 'Görsel seçilemedi: ${error.toString()}';
      });
      
      if (image == null) {
        print('DEBUG-GALLERY: Görsel seçilmedi');
        // Kamerayı tekrar başlat
        await controller.start();
        return;
      }

      print('DEBUG-GALLERY: Görsel seçildi: ${image.path}');

      // Seçilen görseli işle
      final File imageFile = File(image.path);
      if (!await imageFile.exists()) {
        throw 'Seçilen görsel bulunamadı';
      }

      final InputImage inputImage = InputImage.fromFile(imageFile);
      
      // Google ML Kit ile QR kod tarama
      final barcodeScanner = GoogleMlKit.vision.barcodeScanner();
      
      try {
        final List<Barcode> barcodes = await barcodeScanner.processImage(inputImage);
        print('DEBUG-GALLERY: Bulunan QR kod sayısı: ${barcodes.length}');
        
        if (!mounted) return;

        if (barcodes.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Seçilen görselde QR kod bulunamadı. Manuel giriş yapabilirsiniz.'),
              backgroundColor: Colors.orange,
            ),
          );
          if (widget.onManualEntry != null) {
            widget.onManualEntry!();
          }
          return;
        }

        // İlk QR kodu işle
        final barcode = barcodes.first;
        if (barcode.rawValue != null) {
          print('DEBUG-GALLERY: QR kod içeriği: ${barcode.rawValue}');
          _processQRCode(barcode.rawValue!);
        }
      } finally {
        // Tarayıcıyı temizle
        await barcodeScanner.close();
      }

    } catch (e) {
      print('DEBUG-GALLERY: Hata: $e');
      if (!mounted) return;
      
      String errorMessage = 'Görsel işlenirken bir hata oluştu';
      if (e.toString().contains('permission')) {
        errorMessage = 'Galeri erişim izni alınamadı';
      } else if (e.toString().contains('not found')) {
        errorMessage = 'Seçilen görsel bulunamadı';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Manuel Giriş',
            textColor: Colors.white,
            onPressed: () {
              if (widget.onManualEntry != null) {
                widget.onManualEntry!();
              }
            },
          ),
        ),
      );
    } finally {
      // Kamerayı tekrar başlat (eğer hala widget aktifse)
      if (mounted) {
        try {
          await controller.start();
        } catch (e) {
          print('DEBUG-GALLERY: Kamera başlatma hatası: $e');
        }
      }
    }
  }

  // Android sürüm kontrolü için yardımcı metod
  Future<String> _getAndroidVersion() async {
    if (!Platform.isAndroid) return '0';
    
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final androidInfo = await deviceInfoPlugin.androidInfo;
      return androidInfo.version.sdkInt.toString();
    } catch (e) {
      print('Android sürüm bilgisi alınamadı: $e');
      return '0';
    }
  }

  // İzin dialog'u gösterme
  void _showPermissionDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionType İzni Gerekli'),
        content: Text('QR kod içeren görselleri seçebilmek için $permissionType erişim izni gerekiyor. Lütfen ayarlardan izin verin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Ayarlara Git'),
          ),
        ],
      ),
    );
  }
} 