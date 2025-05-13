import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';

class ProfileDetailView extends StatelessWidget {
  final User user;

  const ProfileDetailView({super.key, required this.user});

  // URL'yi açan metot (Sınıf içine taşındı)
  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://crm.tayamer.com/portal/?code=FB-profile-${user.userCode}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // TODO: Hata durumunu kullanıcıya bildir (Snackbar vb.)
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor, 
        title: const Text(
          'Profilim',
          style: TextStyle(color: Colors.white, fontSize: 16), // Font boyutu küçültüldü
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20), // Boyut küçültüldü
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 20), // Boyut küçültüldü
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10.0), // Padding azaltıldı
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100, // Genişlik azaltıldı
                  height: 100, // Yükseklik azaltıldı
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4), // Kenar yuvarlaklığı azaltıldı
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                   child: user.profilePhoto.isNotEmpty
                  ? ClipRRect( // Köşeleri yuvarlatmak için eklendi
                      borderRadius: BorderRadius.circular(4), // Kenar yuvarlaklığı azaltıldı
                      child: Image.network(user.profilePhoto, fit: BoxFit.cover)
                    )
                  : Icon(Icons.person, size: 40, color: Colors.grey[400]), // Boyut küçültüldü
                ),
                const SizedBox(width: 12), // Boşluk azaltıldı
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoField('Adınız Soyadınız', user.userFullname, labelSize: 12, valueSize: 12), // Font boyutları azaltıldı
                      const SizedBox(height: 6), // Boşluk azaltıldı
                      _buildInfoField('Kullanıcı Adınız', user.username, labelSize: 12, valueSize: 12), // Font boyutları azaltıldı
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // Boşluk azaltıldı
            _buildInfoField('Telefon Numaranız', user.userPhone ?? '-', labelSize: 12, valueSize: 12),
            const SizedBox(height: 10), // Boşluk azaltıldı
            _buildInfoField('E-Posta Adresiniz', user.userEmail, labelSize: 12, valueSize: 12),
            const SizedBox(height: 10), // Boşluk azaltıldı
            _buildInfoField('Doğum Tarihiniz', user.userBirthday ?? '-', labelSize: 12, valueSize: 12),
            const SizedBox(height: 10), // Boşluk azaltıldı
            _buildInfoField('Cinsiyet', _formatGender(user.userGender), labelSize: 12, valueSize: 12),
            const SizedBox(height: 10), // Boşluk azaltıldı
            _buildInfoField('Adres', user.userAddress ?? '-', maxLines: 3, labelSize: 12, valueSize: 12),
            const SizedBox(height: 20), // Boşluk azaltıldı
            Center(
              child: InkWell(
                onTap: _launchURL,
                child: const Text(
                  'Profil bilgilerinizi güncellemek için lütfen tıklayınız.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 11, // Font boyutu azaltıldı
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12), // Boşluk azaltıldı
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value, {int maxLines = 1, double labelSize = 14, double valueSize = 13}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: labelSize, // Parametre kullanıldı
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4), // Boşluk azaltıldı
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), // Padding azaltıldı
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4), // Kenar yuvarlaklığı azaltıldı
            border: Border.all(color: Colors.grey[300]!), 
          ),
          width: double.infinity,
          child: Text(
            value.isEmpty ? '-' : value, 
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: valueSize, color: Colors.black87), // Parametre kullanıldı
          ),
        ),
      ],
    );
  }

  // Cinsiyet bilgisini formatlayan metot
  String _formatGender(String genderCode) {
    switch (genderCode.toLowerCase()) {
      case 'm':
      case 'male':
      case 'erkek':
        return 'Erkek';
      case 'f':
      case 'female':
      case 'kadin':
        return 'Kadın';
      default:
        return 'Belirtilmemiş';
    }
  }
} 