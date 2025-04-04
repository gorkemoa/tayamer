class Policy {
  final int policyID;
  final int userID;
  final String policyNumber;
  final String policyType;
  final String policyStatus;
  final String policyStartDate;
  final String policyEndDate;
  final String insuranceCompany;
  final double policyAmount;
  final String currency;
  final String vehiclePlate;
  final String description;
  final bool isActive;
  final String createdAt;

  Policy({
    required this.policyID,
    required this.userID,
    required this.policyNumber,
    required this.policyType,
    required this.policyStatus,
    required this.policyStartDate,
    required this.policyEndDate,
    required this.insuranceCompany,
    required this.policyAmount,
    required this.currency,
    this.vehiclePlate = '',
    this.description = '',
    required this.isActive,
    required this.createdAt,
  });

  factory Policy.fromJson(Map<String, dynamic> json) {
    return Policy(
      policyID: json['policyID'] ?? 0,
      userID: json['userID'] ?? 0,
      policyNumber: json['policyNumber'] ?? '',
      policyType: json['policyType'] ?? '',
      policyStatus: json['policyStatus'] ?? '',
      policyStartDate: json['policyStartDate'] ?? '',
      policyEndDate: json['policyEndDate'] ?? '',
      insuranceCompany: json['insuranceCompany'] ?? '',
      policyAmount: (json['policyAmount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'TL',
      vehiclePlate: json['vehiclePlate'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'policyID': policyID,
      'userID': userID,
      'policyNumber': policyNumber,
      'policyType': policyType,
      'policyStatus': policyStatus,
      'policyStartDate': policyStartDate,
      'policyEndDate': policyEndDate,
      'insuranceCompany': insuranceCompany,
      'policyAmount': policyAmount,
      'currency': currency,
      'vehiclePlate': vehiclePlate,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
} 