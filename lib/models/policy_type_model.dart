// Sigorta poliçe tipleri için model sınıfları
// https://tayamer-mobile.b-cdn.net/tayamer-policy-types.json

class PolicyType {
  final String title;
  final String colorCode;
  final String imageUrl;
  final int typeId;
  final bool isActive;
  final QRCode? qrCode;
  final List<Field> fields;

  PolicyType({
    required this.title,
    required this.colorCode,
    required this.imageUrl,
    required this.typeId,
    required this.isActive,
    this.qrCode,
    required this.fields,
  });

  factory PolicyType.fromJson(Map<String, dynamic> json) {
    return PolicyType(
      title: json['title'] ?? '',
      colorCode: json['colorCode'] ?? '#FFFFFF',
      imageUrl: json['imageUrl'] ?? '',
      typeId: json['typeId'] ?? 0,
      isActive: json['isActive'] ?? false,
      qrCode: json['qrCode'] != null ? QRCode.fromJson(json['qrCode']) : null,
      fields: json['fields'] != null
          ? List<Field>.from(json['fields'].map((x) => Field.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'colorCode': colorCode,
      'imageUrl': imageUrl,
      'typeId': typeId,
      'isActive': isActive,
      'qrCode': qrCode?.toJson(),
      'fields': fields.map((e) => e.toJson()).toList(),
    };
  }
}

class QRCode {
  final String helpText;
  final String pattern;
  final Map<String, String> groups;

  QRCode({
    required this.helpText,
    required this.pattern,
    required this.groups,
  });

  factory QRCode.fromJson(Map<String, dynamic> json) {
    return QRCode(
      helpText: json['helpText'] ?? '',
      pattern: json['pattern'] ?? '',
      groups: json['groups'] != null
          ? Map<String, String>.from(json['groups'])
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'helpText': helpText,
      'pattern': pattern,
      'groups': groups,
    };
  }
}

class Field {
  final String key;
  final String name;
  final String placeholder;
  final String type;
  final Map<String, Rule> rules;
  final Map<String, dynamic>? settings;
  final List<Option>? options;

  Field({
    required this.key,
    required this.name,
    required this.placeholder,
    required this.type,
    required this.rules,
    this.settings,
    this.options,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    Map<String, Rule> rulesMap = {};
    if (json['rules'] != null) {
      json['rules'].forEach((key, value) {
        rulesMap[key] = Rule.fromJson(value);
      });
    }

    return Field(
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      placeholder: json['placeholder'] ?? '',
      type: json['type'] ?? '',
      rules: rulesMap,
      settings: json['settings'],
      options: json['options'] != null
          ? List<Option>.from(json['options'].map((x) => Option.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> rulesMap = {};
    rules.forEach((key, value) {
      rulesMap[key] = value.toJson();
    });

    return {
      'key': key,
      'name': name,
      'placeholder': placeholder,
      'type': type,
      'rules': rulesMap,
      'settings': settings,
      'options': options?.map((e) => e.toJson()).toList(),
    };
  }
}

class Rule {
  final dynamic value;
  final String? message;

  Rule({
    required this.value,
    this.message,
  });

  factory Rule.fromJson(Map<String, dynamic> json) {
    return Rule(
      value: json['value'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'message': message,
    };
  }
}

class Option {
  final String label;
  final String value;

  Option({
    required this.label,
    required this.value,
  });

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      label: json['label'] ?? '',
      value: json['value'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
    };
  }
} 