import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p; // path paketine alias verdik
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../viewmodels/policy_viewmodel.dart';
import '../models/policy_model.dart';
import 'pdf_viewer_screen.dart';

class PolicyDetailView extends StatefulWidget {
  final String policyId;

  const PolicyDetailView({super.key, required this.policyId});

  @override
  State<PolicyDetailView> createState() => _PolicyDetailViewState();
}

class _PolicyDetailViewState extends State<PolicyDetailView> {
  late PolicyViewModel _viewModel;
  bool _isSharing = false; // Paylaşım durumu için state değişkeni

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel = Provider.of<PolicyViewModel>(context, listen: false);
      _viewModel.fetchPolicyDetail(widget.policyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PolicyViewModel>(
      builder: (context, viewModel, child) {
        _viewModel = viewModel;
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            backgroundColor: const Color(0xFF1D3A70),
            elevation: 0,
            title: const Text(
              'Poliçe Detayı',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              // Paylaşım butonu veya yüklenme göstergesi
              if (_viewModel.selectedPolicy != null)
                _isSharing
                  ? const Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () {
                        // _viewModel.selectedPolicy null değilse paylaşımı başlat
                         if (_viewModel.selectedPolicy != null) {
                            _sharePolicyFiles(_viewModel.selectedPolicy!);
                         } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Paylaşılacak poliçe bilgisi bulunamadı.')),
                            );
                         }
                      },
                    ),
            ],
          ),
          body: _buildContent(),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_viewModel.detailState == PolicyViewState.loading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_viewModel.detailState == PolicyViewState.error) {
      return _buildErrorView();
    } else if (_viewModel.selectedPolicy != null) {
      return _buildPolicyDetails(_viewModel.selectedPolicy!);
    } else {
      return const Center(child: Text('Poliçe bilgisi bulunamadı'));
    }
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red[300],
          ),
          const SizedBox(height: 20),
          Text(
            _viewModel.errorMessage,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              _viewModel.fetchPolicyDetail(widget.policyId);
            },
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyDetails(Policy policy) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sigorta şirketi logosu
          if (policy.company.isNotEmpty && policy.company[0].logo.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.white,
              child: Center(
                child: Image.network(
                  policy.company[0].logo,
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          const SizedBox(height: 8), // Logo ile ilk öğe arasına boşluk
          
          // Poliçe detayları
          // Container ve içindeki Column kaldırıldı, her öğe kendi padding'ine sahip
          // Şirket ünvanı
          _buildDetailItem('Şirket Ünvanı', policy.company.isNotEmpty ? policy.company[0].unvan : ''),
          // Divider kaldırıldı
          
          // Poliçe tipi
          _buildDetailItem('Poliçe Tipi', policy.policyType),
          // Divider kaldırıldı
          
          // Plaka
          if (policy.plaka.isNotEmpty) ...[
            _buildDetailItem('Poliçe yapılan Plaka', policy.plaka),
            // Divider kaldırıldı
          ],
          
          // Başlangıç tarihi
          _buildDetailItem('Poliçe Başlangıç Tarihi', _formatDate(policy.startDate)),
          // Divider kaldırıldı
          
          // Bitiş tarihi
          _buildDetailItem('Poliçe Bitiş Tarihi', _formatDate(policy.endDate)),
          // Divider kaldırıldı
          
          // Müşteri ismi
          _buildDetailItem('Müşteri İsmi', policy.customer.isNotEmpty ? policy.customer[0].adiSoyadi : ''),
          // Divider kaldırıldı
          
          // Müşteri telefon numarası
          _buildDetailItem('Müşteri Telefon Numarası', policy.customer.isNotEmpty ? policy.customer[0].telefon : ''),
          // Divider kaldırıldı
          
          // Net fiyat
          _buildDetailItem('Net Fiyat', '₺${policy.netAmount}'),
          // Divider kaldırıldı
          
          // Brüt fiyat
          _buildDetailItem('Brüt Fiyat', '₺${policy.grossAmount}'),
            
          const SizedBox(height: 24),
          
          // Butonlar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Makbuzu İncele',
                    const Color(0xFF1D3A70),
                    () => _openPdf(policy.receiptUrl, 'Makbuz'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Poliçeyi İncele',
                    const Color(0xFF1D3A70),
                    () => _openPdf(policy.pdfUrl, 'Poliçe'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildLinkButton(policy.pdfUrl),
          ),
          const SizedBox(height: 16), // En alta ek boşluk
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    // Dış padding ile öğeler arasına boşluk ekle
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık (Label)
          Text(
            label,
            style: TextStyle(
              fontSize: 12, 
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6), // Başlık ile kutu arasına boşluk
          // Değer için Textbox benzeri Container
          Container(
            width: double.infinity, // Tam genişlik
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // İç boşluk
            decoration: BoxDecoration(
              color: Colors.white, // Kutu arka planı
              border: Border.all(color: Colors.grey.shade300), // Kenarlık
              borderRadius: BorderRadius.circular(4), // Köşe yuvarlama
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87, // Metin rengi
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        elevation: 0,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLinkButton(String url) {
    return ElevatedButton(
      onPressed: () {
        _copyToClipboard(url);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D3A70),
        elevation: 0,
        side: BorderSide(color: Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.copy, size: 20),
          SizedBox(width: 8),
          Text(
            'Poliçe Linkini Kopyala',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _openPdf(String url, String title) {
    print('PDF açılıyor: $url');
    if (url.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            url: url,
            title: title,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF dosyası bulunamadı'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link kopyalandı'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  // PDF dosyasını indirip geçici olarak kaydeder ve dosya yolunu döndürür
  Future<String?> _downloadAndSavePdf(String url, String filenamePrefix) async {
    if (url.isEmpty || !(Uri.tryParse(url)?.isAbsolute ?? false)) {
      if (kDebugMode) {
        print('Geçersiz veya boş URL: $url');
      }
      return null;
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        // Dosya adını URL'nin son kısmından veya verilen ön ekten oluştur
        String fileName = p.basename(url);
        if (!fileName.toLowerCase().endsWith('.pdf')) {
          fileName = '$filenamePrefix.pdf';
        }
        // Geçersiz karakterleri temizle (isteğe bağlı ama önerilir)
        fileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_'); 
        final file = File(p.join(dir.path, fileName)); // p.join kullanıldı
        await file.writeAsBytes(bytes, flush: true);
        if (kDebugMode) {
          print('Dosya kaydedildi: ${file.path}');
        }
        return file.path;
      } else {
        if (kDebugMode) {
          print('PDF indirme hatası ($url): ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('PDF indirme sırasında istisna ($url): $e');
      }
      return null;
    }
  }

  // Poliçe ve/veya makbuz PDF'lerini paylaşır
  Future<void> _sharePolicyFiles(Policy policy) async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    // Paylaşılabilir dosyaları belirle
    final bool canSharePolicy = policy.pdfUrl.isNotEmpty && (Uri.tryParse(policy.pdfUrl)?.isAbsolute ?? false);
    final bool canShareReceipt = policy.receiptUrl.isNotEmpty && 
                               (Uri.tryParse(policy.receiptUrl)?.isAbsolute ?? false) && 
                               policy.receiptUrl != policy.pdfUrl; // Aynı URL değilse

    List<String> filesToDownloadUrls = [];
    Map<String, String> urlToFilenamePrefix = {}; // URL'yi dosya adı önekine eşle

    if (canSharePolicy && canShareReceipt) {
      // Hem poliçe hem makbuz varsa kullanıcıya seçtir
      final selectedFiles = await _showShareSelectionDialog(policy);
      if (selectedFiles == null || selectedFiles.isEmpty) {
        // Kullanıcı iptal etti veya bir şey seçmedi
        setState(() { _isSharing = false; });
        return;
      }
      if (selectedFiles.contains('policy')) {
        filesToDownloadUrls.add(policy.pdfUrl);
        urlToFilenamePrefix[policy.pdfUrl] = '${policy.plaka.isNotEmpty ? policy.plaka : 'Police'}_${policy.policyType.replaceAll(' ', '_')}';
      }
      if (selectedFiles.contains('receipt')) {
        filesToDownloadUrls.add(policy.receiptUrl);
        urlToFilenamePrefix[policy.receiptUrl] = '${policy.plaka.isNotEmpty ? policy.plaka : 'Makbuz'}_${policy.policyType.replaceAll(' ', '_')}_makbuz';
      }

    } else if (canSharePolicy) {
      // Sadece poliçe varsa
      filesToDownloadUrls.add(policy.pdfUrl);
       urlToFilenamePrefix[policy.pdfUrl] = '${policy.plaka.isNotEmpty ? policy.plaka : 'Police'}_${policy.policyType.replaceAll(' ', '_')}';
    } else if (canShareReceipt) {
       // Sadece makbuz varsa (poliçe ile aynı URL değilse, yukarıda kontrol edildi)
      filesToDownloadUrls.add(policy.receiptUrl);
      urlToFilenamePrefix[policy.receiptUrl] = '${policy.plaka.isNotEmpty ? policy.plaka : 'Makbuz'}_${policy.policyType.replaceAll(' ', '_')}_makbuz';
    } else {
      // Paylaşılacak geçerli dosya yok
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paylaşılacak geçerli bir PDF dosyası bulunamadı.')),
      );
      setState(() { _isSharing = false; });
      return;
    }

    // Seçilen dosyaları indir
    List<String> downloadedFilePaths = [];
    for (String url in filesToDownloadUrls) {
      print("Dosya İndiriliyor: $url");
      final filePath = await _downloadAndSavePdf(url, urlToFilenamePrefix[url] ?? 'dosya');
      if (filePath != null) {
        downloadedFilePaths.add(filePath);
      } else {
         // İndirme başarısız olursa kullanıcıyı bilgilendir (opsiyonel)
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$url indirilemedi.')),
          );
      }
    }

    // İndirilen dosyaları paylaş
    if (downloadedFilePaths.isNotEmpty) {
      try {
        final box = context.findRenderObject() as RenderBox?;
        final subject = '${policy.policyType} - ${policy.plaka.isNotEmpty ? policy.plaka : policy.customer.isNotEmpty ? policy.customer[0].adiSoyadi : 'Detay'}';
        final xFiles = downloadedFilePaths.map((path) => XFile(path)).toList();

        await Share.shareXFiles(
          xFiles,
          subject: subject,
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size
        );

        // Geçici dosyaları temizle
         for (var path in downloadedFilePaths) {
           try {
             final file = File(path);
             if (await file.exists()) {
               await file.delete();
               if (kDebugMode) print('Geçici dosya silindi: $path');
             }
           } catch (e) {
              if (kDebugMode) print('Geçici dosya silinirken hata ($path): $e');
           }
         }

      } catch (e) {
          if (kDebugMode) print('Paylaşım sırasında hata: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Dosyalar paylaşılırken bir hata oluştu: ${e.toString()}')),
          );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seçilen dosyalar indirilemedi veya paylaşılamadı.')),
      );
    }

    // İşlem bitince yüklenme durumunu kapat
    if(mounted){
       setState(() {
        _isSharing = false;
      });
    }
  }

  // Kullanıcıya hangi dosyaları paylaşmak istediğini soran dialog
  Future<List<String>?> _showShareSelectionDialog(Policy policy) async {
    Map<String, bool> selections = {
      'policy': true, // Başlangıçta seçili olsun
      'receipt': true, // Başlangıçta seçili olsun
    };

    return await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder( // Dialog içindeki state'i yönetmek için
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Paylaşılacak Belgeleri Seçin'),
              content: Column(
                mainAxisSize: MainAxisSize.min, // İçeriğe göre boyutlan
                children: [
                  CheckboxListTile(
                    title: const Text('Poliçe PDF'),
                    value: selections['policy'],
                    onChanged: (bool? value) {
                      setDialogState(() { // Dialog state'ini güncelle
                        selections['policy'] = value!;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('Makbuz PDF'),
                    value: selections['receipt'],
                    onChanged: (bool? value) {
                       setDialogState(() { // Dialog state'ini güncelle
                        selections['receipt'] = value!;
                      });
                    },
                     controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('İptal'),
                  onPressed: () {
                    Navigator.of(context).pop(null); // Seçim yapmadan kapat
                  },
                ),
                TextButton(
                  child: const Text('Paylaş'),
                  onPressed: () {
                    // Seçilen dosyaların listesini döndür
                    final selectedKeys = selections.entries
                        .where((entry) => entry.value)
                        .map((entry) => entry.key)
                        .toList();
                     if (selectedKeys.isEmpty) { // Hiçbir şey seçilmediyse uyar
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Lütfen paylaşmak için en az bir belge seçin.')),
                       );
                     } else {
                        Navigator.of(context).pop(selectedKeys);
                     }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
} 