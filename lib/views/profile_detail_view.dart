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
        backgroundColor: const Color(0xFF1F3567), // Ana AppBar rengiyle aynı
        title: const Text(
          'Profilim',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: const IconThemeData(color: Colors.white), // Geri butonu rengi
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profil Fotoğrafı Alanı (Boş)
                Container(
                  width: 140, // Biraz daha küçük
                  height: 140, // Kare şeklinde
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8), // Köşeleri yuvarlatılmış
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  // TODO: Profil fotoğrafını göstermek için Image widget'ı eklenebilir
                   child: user.profilePhoto.isNotEmpty
                  ? Image.network(user.profilePhoto, fit: BoxFit.cover)
                  : const Icon(Icons.person, size: 60, color: Colors.grey),
                ),
                const SizedBox(width: 20),
                // Ad Soyad ve Kullanıcı Adı
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoField('Adınız Soyadınız', user.userFullname),
                      const SizedBox(height: 10),
                      _buildInfoField('Kullanıcı Adınız', user.username),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24), // Alanlar arası boşluk
            _buildInfoField('Telefon Numaranız', user.userPhone ?? '-'),
            const SizedBox(height: 16),
            _buildInfoField('E-Posta Adresiniz', user.userEmail),
            const SizedBox(height: 16),
            _buildInfoField('Doğum Tarihiniz', user.userBirthday ?? '-'),
            const SizedBox(height: 16),
            _buildInfoField('Cinsiyet', _formatGender(user.userGender)),
            const SizedBox(height: 16),
            _buildInfoField('Adres', user.userAddress ?? '-', maxLines: 3),
            const SizedBox(height: 32),
            Center(
              child: InkWell(
                onTap: _launchURL,
                child: const Text(
                  'Profil bilgilerinizi güncellemek için lütfen tıklayınız.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.blue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bilgi alanını oluşturan yardımcı metot
  Widget _buildInfoField(String label, String value, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100], // Hafif gri arka plan
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!), // İnce kenarlık
          ),
          width: double.infinity,
          child: Text(
            value.isEmpty ? '-' : value, // Boş değerler için tire göster
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
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