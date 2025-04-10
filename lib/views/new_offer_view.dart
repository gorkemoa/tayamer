import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import '../models/policy_type_model.dart';
import '../viewmodels/policy_type_viewmodel.dart';
import '../viewmodels/offer_viewmodel.dart';
import 'home_view.dart';
import 'offer_success_view.dart';
import 'qr_scanner_view.dart';
import 'package:image_picker/image_picker.dart';

class NewOfferView extends StatefulWidget {
  const NewOfferView({super.key});

  @override
  State<NewOfferView> createState() => _NewOfferViewState();
}

class _NewOfferViewState extends State<NewOfferView> {
  bool _isBottomSheetActive = false;
  bool _isPolicySelected = false; // Poliçe seçilip seçilmediğini takip eden bayrak

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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        color: Colors.white,
        child: Container(),
      ),
    );
  }
  
  void _showPolicyTypeBottomSheet(BuildContext context) {
    // Poliçe zaten seçilmişse veya bottom sheet aktifse, tekrar gösterme
    if (_isBottomSheetActive || _isPolicySelected) return;
    
    _isBottomSheetActive = true;
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) {
        _isBottomSheetActive = false;
        return;
      }
      
      showModalBottomSheet(
        context: context,
        isDismissible: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => WillPopScope(
          onWillPop: () async {
            // Bottom sheet kapatılmadan önce _isPolicySelected durumunu kontrol et
            if (!_isPolicySelected) {
              Future.microtask(() => _navigateToHomeIndex(0));
            }
            return true;
          },
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return DraggableScrollableSheet(
                initialChildSize: 0.85,
                maxChildSize: 0.9,
                minChildSize: 0.5,
                expand: true,
                snap: true,
                snapSizes: const [0.5, 0.85, 0.9],
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
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
                              // Bottom sheet'i kapat
                              Navigator.pop(context);
                              
                              // X'e basıldığında ana sayfaya dön
                              if (mounted && !_isPolicySelected) {
                                Future.microtask(() => _navigateToHomeIndex(0));
                              }
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
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
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
                                    onTap: () { 
                                      // Poliçenin seçildiğini setModalState içinde belirt
                                      setModalState(() {
                                        _isPolicySelected = true;
                                      });
                                      
                                      // Ana state'te de güncelle
                                      if (mounted) {
                                        setState(() {
                                          _isPolicySelected = true;
                                        });
                                      }
                                      
                                      // Seçilen poliçe tipini ViewModel'e kaydet
                                      viewModel.selectPolicyType(policyType);
                                      
                                      // Önce bottom sheet'i kapat
                                      Navigator.pop(context);
                                      
                                      // QR özelliği varsa tarama başlat, yoksa doğrudan manuel giriş formuna git
                                      Future.microtask(() {
                                        if (!mounted) return;
                                        
                                        if (policyType.qrCode != null) {
                                          // QR tarama işlemini başlat
                                          _startQRScan(context, policyType);
                                        } else {
                                          // Doğrudan manuel form sayfasına yönlendir
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => ManualEntryView(policyType: policyType)),
                                          );
                                        }
                                      });
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ).then((_) {
        // Kapanış handler'ını çağır
        _handleBottomSheetClosed();
      });
    });
  }

  void _navigateToHomeIndex(int index) {
    if (!mounted) return;
    
    // Ana sayfaya geri dön ve belirli bir indekse git
    try {
      // Future.microtask ile UI thread'inin tamamlanmasını bekleyerek navigasyon yap
      Future.microtask(() {
        if (mounted) {
          // Navigasyon hatasını önlemek için pushReplacement yerine pushAndRemoveUntil kullanıyoruz
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => HomeView(initialIndex: index),
              settings: RouteSettings(arguments: index)
            ),
            (route) => false, // Tüm route'ları temizle
          );
        }
      });
    } catch (e) {
      print('DEBUG: Ana sayfaya dönüş hatası: $e');
      // Navigasyon hatası durumunda son çare olarak yeni navigator oluştur
      try {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeView(initialIndex: 0)),
            (route) => false,
          );
        }
      } catch (e2) {
        print('DEBUG: Kritik navigasyon hatası: $e2');
      }
    }
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

  void _startQRScan(BuildContext context, PolicyType policyType) async {
    // Önce context'in hala geçerli olup olmadığını kontrol et
    if (!mounted) return;
    
    // Global context'i kullanarak SnackBar göstermek için - daha sonra kullanmak üzere sakla
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      print('DEBUG: QR tarama başlatılıyor...');
      // QR tarayıcıyı başlat
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QRScannerView(
            onManualEntry: () {
              // Manuel giriş formuna yönlendir
              Navigator.pop(context); // Önce tarayıcıyı kapat
            },
            onResult: (data) {
              // QR sonucunu al
              print('DEBUG: QR sonucu alındı: $data');
              
              // Form sayfasına geçiş yap - Navigator.pop ile veriyi döndür
              Navigator.pop(context, data);
            },
          ),
        ),
      );
      
      // QR tarayıcıdan geri dönüldü, hala bağlı mı kontrol et
      if (!mounted) return;
      
      print('DEBUG: QR tarayıcıdan geri dönüldü, sonuç: ${result != null ? "Veri alındı" : "Veri yok"}');
      
      // Manuel giriş seçildi veya iptal edildi
      if (result == null) {
        // Context kontrolü 
        if (!mounted) return;
        
        print('DEBUG: Manuel giriş sayfasına yönlendiriliyor');
        // Doğrudan manuel form sayfasına yönlendir
        Future.microtask(() {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ManualEntryView(policyType: policyType)),
            );
          }
        });
      } 
      // QR sonucu ile döndü
      else if (result is Map<String, String>) {
        // Context kontrolü
        if (!mounted) return;
        
        print('DEBUG: QR sonucu ile form sayfasına yönlendiriliyor: $result');
        // Future.microtask kullanarak UI thread'inin tamamlanmasını bekleyerek navigasyon yap
        Future.microtask(() {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManualEntryView(
                  policyType: policyType,
                  initialData: result,
                ),
              ),
            );
          }
        });
      }
    } catch (e) {
      print('QR tarama hatası: $e');
      
      if (!mounted) return;
      
      // Hata mesajını göster
      try {
        // SnackBar göstermeden önce kontrol
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('QR tarama sırasında bir hata oluştu: ${e.toString().substring(0, e.toString().length > 100 ? 100 : e.toString().length)}...'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (snackbarError) {
        print('DEBUG: SnackBar gösterme hatası: $snackbarError');
      }
      
      print('DEBUG: Hata sonrası manuel girişe yönlendiriliyor');
      
      // Hata durumunda manuel girişe yönlendirme - Future.microtask ile güvenli navigasyon
      Future.microtask(() {
        if (mounted) {
          try {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManualEntryView(
                  policyType: policyType,
                ),
              ),
            );
          } catch (navigationError) {
            print('DEBUG: Navigation hatası: $navigationError');
            // Eğer navigasyon hatası varsa, ana sayfaya dön
            if (mounted) {
              _navigateToHomeIndex(0);
            }
          }
        }
      });
    }
  }

  // Bottom sheet kapatıldığında olay
  void _handleBottomSheetClosed() {
    _isBottomSheetActive = false;
    // Bottom sheet kapatıldığında ana sayfaya dön, ancak
    // sadece poliçe seçilmemişse (kullanıcı manuel kapatırsa)
    if (mounted && !_isPolicySelected) {
      // Bir mikrosaniye gecikme ile çağır (Navigator işlemleri için)
      Future.microtask(() {
        if (mounted) {
          _navigateToHomeIndex(0); // Ana sayfa (Dashboard) indeksi
        }
      });
    }
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
    // Form için controller'ları oluştur
    for (var field in widget.policyType.fields) {
      _controllers[field.key] = TextEditingController();
    }
    
    // Açıklama alanı için varsayılan değer
    _descController.text = widget.policyType.desc;
    
    // Eğer initialData varsa, controller'lara verileri yükle
    if (widget.initialData != null) {
      print('Initial data geldi: ${widget.initialData}');
      
      // Galeri modunda mıyız kontrol et 
      isGalleryMode = widget.initialData!.containsKey('galleryMode');
      
      // Galeri modunda odaklanılacak alanları belirle
      focusFields = [];
      
      // Özellikle plaka, tc ve ruhsat bilgilerini kontrol et
      bool hasTCField = false;
      bool hasPlateField = false;
      bool hasRegNoField = false;
      
      // Form alanlarının hangi tür bilgi içerdiğini tespit et
      widget.policyType.fields.forEach((field) {
        // TC alanı bulundu mu?
        if (field.name.toLowerCase().contains('tc') || 
            field.key.toLowerCase().contains('tc') || 
            field.key.toLowerCase().contains('kimlik')) {
          hasTCField = true;
        }
        
        // Plaka alanı bulundu mu?
        if (field.name.toLowerCase().contains('plaka') || 
            field.key.toLowerCase().contains('plaka')) {
          hasPlateField = true;
        }
        
        // Ruhsat alanı bulundu mu?
        if (field.name.toLowerCase().contains('ruhsat') || 
            field.key.toLowerCase().contains('ruhsat')) {
          hasRegNoField = true;
        }
      });
      
      // Form alanlarına QR kod verilerini yerleştir
      widget.policyType.fields.forEach((field) {
        // TC Kimlik için eşleştirme
        if ((field.name.toLowerCase().contains('tc') || 
             field.key.toLowerCase().contains('tc') || 
             field.key.toLowerCase().contains('kimlik')) && 
             widget.initialData!.containsKey('tc')) {
          _controllers[field.key]?.text = widget.initialData!['tc']!;
          print('TC alanı eşleşti: ${widget.initialData!['tc']}');
          // Galeri modunda odaklanılacak alan
          if (isGalleryMode) {
            focusFields.add(field.key);
          }
        }
        // Plaka için eşleştirme
        else if ((field.name.toLowerCase().contains('plaka') || 
                 field.key.toLowerCase().contains('plaka')) && 
                 widget.initialData!.containsKey('plaka') && hasPlateField) {
          _controllers[field.key]?.text = widget.initialData!['plaka']!;
          print('Plaka alanı eşleşti: ${widget.initialData!['plaka']}');
          // Galeri modunda odaklanılacak alan
          if (isGalleryMode) {
            focusFields.add(field.key);
          }
        }
        // Ruhsat için eşleştirme
        else if ((field.name.toLowerCase().contains('ruhsat') || 
                 field.key.toLowerCase().contains('ruhsat')) && 
                 widget.initialData!.containsKey('ruhsatNo') && hasRegNoField) {
          _controllers[field.key]?.text = widget.initialData!['ruhsatNo']!;
          print('Ruhsat alanı eşleşti: ${widget.initialData!['ruhsatNo']}');
          // Galeri modunda odaklanılacak alan
          if (isGalleryMode) {
            focusFields.add(field.key);
          }
        }
      });
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
    return Scaffold(
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Aşağıdaki bilgileri kontrol ederek, poliçenizi oluşturabilirsiniz.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              
              // Galeri modu için özel bilgilendirme
              if (isGalleryMode && focusFields.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 16, bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'QR Kod Bilgilerini Doldurun',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Lütfen öne çıkarılan alanlara (plaka, TC kimlik, ruhsat numarası) doğru bilgileri girerek devam edin.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Form alanlarını oluştur
              ...widget.policyType.fields.map((field) => _buildFormField(field)).toList(),
              
              // Açıklama alanı
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ek Açıklama',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Eklemek istediğiniz bilgiler...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Teklif Oluştur',
                      style: TextStyle(
                        fontSize: 16,
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
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
              '${field.name} ${field.rules.containsKey('required') && field.rules['required']!.value ? '(*)' : ''}',
                    style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                      // Galeri modunda vurgulama - önemli alanlar için renk değiştir
                      color: isHighlightField ? Colors.blue.shade800 : null,
                    ),
                  ),
                ),
                // Galeri modunda vurgulama - önemli alanlar için ikon ekle
                if (isHighlightField)
                  const Icon(Icons.edit, color: Colors.blue, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _controllers[field.key],
              decoration: InputDecoration(
                hintText: 'Örn: "${field.placeholder}"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                // Galeri modunda vurgulama - önemli alanlar için renk değiştir
                enabledBorder: isHighlightField ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                ) : null,
                focusedBorder: isHighlightField ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                ) : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                // Galeri modunda bilgi ikonu ekle
                suffixIcon: isHighlightField ? const Icon(Icons.info_outline, color: Colors.blue) : null,
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
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
            '${field.name} ${field.rules.containsKey('required') && field.rules['required']!.value ? '(*)' : ''}',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w500,
                    // Galeri modunda vurgulama
                    color: isHighlightField ? Colors.blue.shade800 : null,
                  ),
                ),
              ),
              // Galeri modunda vurgulama - önemli alanlar için ikon ekle
              if (isHighlightField)
                const Icon(Icons.edit, color: Colors.blue, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedValue.isNotEmpty ? selectedValue : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              // Galeri modunda vurgulama
              enabledBorder: isHighlightField ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ) : null,
              focusedBorder: isHighlightField ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
              ) : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
            '${field.name} ${field.rules.containsKey('required') && field.rules['required']!.value ? '(*)' : ''}',
                  style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
                    // Galeri modunda vurgulama
                    color: isHighlightField ? Colors.blue.shade800 : null,
                  ),
                ),
              ),
              // Galeri modunda vurgulama - önemli alanlar için ikon ekle
              if (isHighlightField)
                const Icon(Icons.edit, color: Colors.blue, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _controllers[field.key],
            readOnly: true, // Klavye girişini devre dışı bırak
            decoration: InputDecoration(
              hintText: 'Örn: "${field.placeholder}"',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              // Galeri modunda vurgulama
              enabledBorder: isHighlightField ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ) : null,
              focusedBorder: isHighlightField ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
              ) : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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