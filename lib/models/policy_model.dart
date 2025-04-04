import 'dart:convert';

class Policy {
  final String id;
  final String policyNO;
  final String policyType;
  final String pdfUrl;
  final String receiptUrl;
  final String startDate;
  final String endDate;
  final String status;
  final String paymentType;
  final String plaka;
  final String desc;
  final String netAmount;
  final String grossAmount;
  final List<Customer> customer;
  final List<Company> company;

  Policy({
    required this.id,
    required this.policyNO,
    required this.policyType,
    required this.pdfUrl,
    required this.receiptUrl,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.paymentType,
    required this.plaka,
    required this.desc,
    required this.netAmount,
    required this.grossAmount,
    required this.customer,
    required this.company,
  });

  factory Policy.fromJson(Map<String, dynamic> json) {
    return Policy(
      id: json['id'] ?? '',
      policyNO: json['policyNO'] ?? '',
      policyType: json['policyType'] ?? '',
      pdfUrl: json['pdfUrl'] ?? '',
      receiptUrl: json['receiptUrl'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      status: json['status'] ?? '',
      paymentType: json['paymentType'] ?? '',
      plaka: json['plaka'] ?? '',
      desc: json['shortDesc'] ?? '',
      netAmount: json['netAmount'] ?? '',
      grossAmount: json['grossAmount'] ?? '',
      customer: json['customer'] != null
          ? List<Customer>.from(json['customer'].map((x) => Customer.fromJson(x)))
          : [],
      company: json['company'] != null
          ? List<Company>.from(json['company'].map((x) => Company.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'policyNO': policyNO,
      'policyType': policyType,
      'pdfUrl': pdfUrl,
      'receiptUrl': receiptUrl,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
      'paymentType': paymentType,
      'plaka': plaka,
      'desc': desc,
      'netAmount': netAmount,
      'grossAmount': grossAmount,
      'customer': customer.map((x) => x.toJson()).toList(),
      'company': company.map((x) => x.toJson()).toList(),
    };
  }
}

class Customer {
  final String id;
  final String adiSoyadi;
  final String tcNo;
  final String telefon;
  final String email;
  final String adres;

  Customer({
    required this.id,
    required this.adiSoyadi,
    required this.tcNo,
    required this.telefon,
    required this.email,
    required this.adres,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? '',
      adiSoyadi: json['adi_soyadi'] ?? '',
      tcNo: json['tcNo'] ?? '',
      telefon: json['telefon'] ?? '',
      email: json['email'] ?? '',
      adres: json['adres'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adi_soyadi': adiSoyadi,
      'tcNo': tcNo,
      'telefon': telefon,
      'email': email,
      'adres': adres,
    };
  }
}

class Company {
  final String id;
  final String unvan;
  final String logo;

  Company({
    required this.id,
    required this.unvan,
    required this.logo,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] ?? '',
      unvan: json['unvan'] ?? '',
      logo: json['logo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unvan': unvan,
      'logo': logo,
    };
  }
}

class PolicyResponse {
  final bool error;
  final bool success;
  final PolicyData data;

  PolicyResponse({
    required this.error,
    required this.success,
    required this.data,
  });

  factory PolicyResponse.fromJson(Map<String, dynamic> json) {
    return PolicyResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: PolicyData.fromJson(json['data'] ?? {}),
    );
  }
}

class PolicyData {
  final List<Policy> policys;

  PolicyData({
    required this.policys,
  });

  factory PolicyData.fromJson(Map<String, dynamic> json) {
    return PolicyData(
      policys: json['policys'] != null
          ? List<Policy>.from(json['policys'].map((x) => Policy.fromJson(x)))
          : [],
    );
  }
} 