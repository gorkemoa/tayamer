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
          style: TextStyle(color: Colors.white, fontSize: 17), // Küçültüldü
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22), // Boyut eklendi
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 22), // Boyut eklendi
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0), // Küçültüldü
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120, // Küçültüldü
                  height: 120, // Küçültüldü
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6), // Küçültüldü
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                   child: user.profilePhoto.isNotEmpty
                  ? ClipRRect( // Köşeleri yuvarlatmak için eklendi
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(user.profilePhoto, fit: BoxFit.cover)
                    )
                  : Icon(Icons.person, size: 48, color: Colors.grey[400]), // Boyut ve renk ayarlandı
                ),
                const SizedBox(width: 16), // Küçültüldü
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoField('Adınız Soyadınız', user.userFullname, labelSize: 13, valueSize: 13), // Boyutlar eklendi
                      const SizedBox(height: 8), // Küçültüldü
                      _buildInfoField('Kullanıcı Adınız', user.username, labelSize: 13, valueSize: 13), // Boyutlar eklendi
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20), // Küçültüldü
            _buildInfoField('Telefon Numaranız', user.userPhone ?? '-', labelSize: 13, valueSize: 13),
            const SizedBox(height: 12), // Küçültüldü
            _buildInfoField('E-Posta Adresiniz', user.userEmail, labelSize: 13, valueSize: 13),
            const SizedBox(height: 12), // Küçültüldü
            _buildInfoField('Doğum Tarihiniz', user.userBirthday ?? '-', labelSize: 13, valueSize: 13),
            const SizedBox(height: 12), // Küçültüldü
            _buildInfoField('Cinsiyet', _formatGender(user.userGender), labelSize: 13, valueSize: 13),
            const SizedBox(height: 12), // Küçültüldü
            _buildInfoField('Adres', user.userAddress ?? '-', maxLines: 3, labelSize: 13, valueSize: 13),
            const SizedBox(height: 24), // Küçültüldü
            Center(
              child: InkWell(
                onTap: _launchURL,
                child: const Text(
                  'Profil bilgilerinizi güncellemek için lütfen tıklayınız.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12, // Küçültüldü
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16), // Eklendi (Alt boşluk)
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value, {int maxLines = 1, double labelSize = 15, double valueSize = 14}) {
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
        const SizedBox(height: 5), // Küçültüldü
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Padding azaltıldı
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6), // Küçültüldü
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