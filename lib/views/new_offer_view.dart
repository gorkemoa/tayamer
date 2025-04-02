import 'package:flutter/material.dart';

class NewOfferView extends StatelessWidget {
  const NewOfferView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Yeni Teklif Oluştur',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildOfferTypeCard(
                  context,
                  title: 'Trafik Sigortası',
                  icon: Icons.directions_car,
                  color: Colors.blue,
                ),
                _buildOfferTypeCard(
                  context,
                  title: 'Kasko',
                  icon: Icons.car_crash,
                  color: Colors.orange,
                ),
                _buildOfferTypeCard(
                  context,
                  title: 'Konut Sigortası',
                  icon: Icons.home,
                  color: Colors.green,
                ),
                _buildOfferTypeCard(
                  context,
                  title: 'Sağlık Sigortası',
                  icon: Icons.health_and_safety,
                  color: Colors.red,
                ),
                _buildOfferTypeCard(
                  context,
                  title: 'Seyahat Sigortası',
                  icon: Icons.card_travel,
                  color: Colors.purple,
                ),
                _buildOfferTypeCard(
                  context,
                  title: 'Bireysel Emeklilik',
                  icon: Icons.account_balance,
                  color: Colors.indigo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferTypeCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title teklifi yakında eklenecek')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
} 