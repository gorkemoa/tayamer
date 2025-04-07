class User {
  final int userID;
  final String userCode;
  final String username;
  final String userFullname;
  final List<String> userShortname;
  final String userEmail;
  final String? userBirthday;
  final String? userAddress;
  final dynamic userPermissions;
  final String? userPhone;
  final String? userRank;
  final bool isSmsUser;
  final String userStatus;
  final String userGender;
  final String userToken;
  final String userDuration;
  final String commissionViewRate;
  final String accountAuthority;
  final String platform;
  final String userVersion;
  final String iOSVersion;
  final String androidVersion;
  final String profilePhoto;
  final UserStatistics statistics;
  final String? version;

  User({
    required this.userID,
    required this.userCode,
    required this.username,
    required this.userFullname,
    required this.userShortname,
    required this.userEmail,
    this.userBirthday,
    this.userAddress,
    this.userPermissions,
    this.userPhone,
    this.userRank,
    required this.isSmsUser,
    required this.userStatus,
    required this.userGender,
    required this.userToken,
    required this.userDuration,
    required this.commissionViewRate,
    required this.accountAuthority,
    required this.platform,
    required this.userVersion,
    required this.iOSVersion,
    required this.androidVersion,
    required this.profilePhoto,
    required this.statistics,
    this.version,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userID: json['userID'] ?? 0,
      userCode: json['userCode'] ?? '',
      username: json['username'] ?? '',
      userFullname: json['userFullname'] ?? '',
      userShortname: List<String>.from(json['userShortname'] ?? []),
      userEmail: json['userEmail'] ?? '',
      userBirthday: json['userBirthday'],
      userAddress: json['userAddress'],
      userPermissions: json['userPermissions'],
      userPhone: json['userPhone'],
      userRank: json['userRank'],
      isSmsUser: json['isSmsUser'] ?? false,
      userStatus: json['userStatus'] ?? '',
      userGender: json['userGender'] ?? '',
      userToken: json['userToken'] ?? '',
      userDuration: json['userDuration'] ?? '',
      commissionViewRate: json['commissionViewRate'] ?? '',
      accountAuthority: json['accountAuthority'] ?? '',
      platform: json['platform'] ?? '',
      userVersion: json['userVersion'] ?? '',
      iOSVersion: json['iOSVersion'] ?? '',
      androidVersion: json['androidVersion'] ?? '',
      profilePhoto: json['profilePhoto'] ?? '',
      statistics: UserStatistics.fromJson(json['statistics'] ?? {}),
      version: json['version'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'userCode': userCode,
      'username': username,
      'userFullname': userFullname,
      'userShortname': userShortname,
      'userEmail': userEmail,
      'userBirthday': userBirthday,
      'userAddress': userAddress,
      'userPermissions': userPermissions,
      'userPhone': userPhone,
      'userRank': userRank,
      'isSmsUser': isSmsUser,
      'userStatus': userStatus,
      'userGender': userGender,
      'userToken': userToken,
      'userDuration': userDuration,
      'commissionViewRate': commissionViewRate,
      'accountAuthority': accountAuthority,
      'platform': platform,
      'userVersion': userVersion,
      'iOSVersion': iOSVersion,
      'androidVersion': androidVersion,
      'profilePhoto': profilePhoto,
      'statistics': statistics.toJson(),
      'version': version,
    };
  }
}

class UserStatistics {
  final int totalPolicy;
  final int totalOffer;
  final String totalAmount;
  final String monthlyAmount;

  UserStatistics({
    required this.totalPolicy,
    required this.totalOffer,
    required this.totalAmount,
    required this.monthlyAmount,
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      totalPolicy: json['totalPolicy'] ?? 0,
      totalOffer: json['totalOffer'] ?? 0,
      totalAmount: json['totalAmount'] ?? '0,00',
      monthlyAmount: json['monthlyAmount'] ?? '0,00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPolicy': totalPolicy,
      'totalOffer': totalOffer,
      'totalAmount': totalAmount,
      'monthlyAmount': monthlyAmount,
    };
  }
} 