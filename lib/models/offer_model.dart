class Offer {
  final dynamic id; // String veya int olabilir
  final String code;
  final String ruhsatNo;
  final String tcNo;
  final String dogumTarihi;
  final String plaka;
  final String chatUrl;
  final String pdfUrl;
  final String shortDesc;
  final dynamic policyTypeId; // String veya int olabilir
  final String policyType;
  final String status;
  final String statusText;
  final String statusColor;
  final String createDate;
  final List<OfferPrice>? offers; // Detay sayfasında gelen teklifler

  Offer({
    required this.id,
    required this.code,
    required this.ruhsatNo,
    required this.tcNo,
    required this.dogumTarihi,
    required this.plaka,
    required this.chatUrl,
    required this.pdfUrl,
    required this.shortDesc,
    required this.policyTypeId,
    required this.policyType,
    required this.status,
    required this.statusText,
    required this.statusColor,
    required this.createDate,
    this.offers,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    // offers alanı varsa parse et, yoksa null bırak
    List<OfferPrice>? offerPrices;
    if (json['offers'] != null) {
      offerPrices = List<OfferPrice>.from(
        (json['offers'] as List).map((price) => OfferPrice.fromJson(price)),
      );
    }

    return Offer(
      id: json['id'],
      code: json['code'] ?? '',
      ruhsatNo: json['ruhsatNo'] ?? '',
      tcNo: json['tcNo'] ?? '',
      dogumTarihi: json['dogumTarihi'] ?? '',
      plaka: json['plaka'] ?? '',
      chatUrl: json['chatUrl'] ?? '',
      pdfUrl: json['pdfUrl'] ?? '',
      shortDesc: json['shortDesc'] ?? '',
      policyTypeId: json['policyTypeId'] ?? '',
      policyType: json['policyType'] ?? '',
      status: json['status'] ?? '',
      statusText: json['statusText'] ?? '',
      statusColor: json['statusColor'] ?? '#ffffff',
      createDate: json['createDate'] ?? '',
      offers: offerPrices,
    );
  }
}

class OfferPrice {
  final String companyID;
  final String title;
  final String shortDesc;
  final String? wsPriceID;
  final String image;
  final String? pdfUrl;
  final String detailUrl;
  final String installment;
  final String price;

  OfferPrice({
    required this.companyID,
    required this.title,
    required this.shortDesc,
    this.wsPriceID,
    required this.image,
    this.pdfUrl,
    required this.detailUrl,
    required this.installment,
    required this.price,
  });

  factory OfferPrice.fromJson(Map<String, dynamic> json) {
    return OfferPrice(
      companyID: json['companyID'] ?? '',
      title: json['title'] ?? '',
      shortDesc: json['shortDesc'] ?? '',
      wsPriceID: json['wsPriceID'],
      image: json['image'] ?? '',
      pdfUrl: json['pdfUrl'],
      detailUrl: json['detailUrl'] ?? '',
      installment: json['installment'] ?? '1',
      price: json['price'] ?? '0',
    );
  }
} 