class AppSettingsModel {
  final String businessName;
  final String? businessPhone;
  final String? businessAddress;
  final String currencySymbol;
  final double defaultTaxPercent;
  final String invoiceFooter;
  final String invoicePrefix;
  final String languageCode;

  const AppSettingsModel({
    required this.businessName,
    this.businessPhone,
    this.businessAddress,
    required this.currencySymbol,
    required this.defaultTaxPercent,
    required this.invoiceFooter,
    required this.invoicePrefix,
    required this.languageCode,
  });

  factory AppSettingsModel.defaults() {
    return const AppSettingsModel(
      businessName: 'My Business',
      businessPhone: null,
      businessAddress: null,
      currencySymbol: 'ETB',
      defaultTaxPercent: 0,
      invoiceFooter: 'Thank you for your business.',
      invoicePrefix: 'INV',
      languageCode: 'en',
    );
  }

  AppSettingsModel copyWith({
    String? businessName,
    String? businessPhone,
    String? businessAddress,
    String? currencySymbol,
    double? defaultTaxPercent,
    String? invoiceFooter,
    String? invoicePrefix,
    String? languageCode,
  }) {
    return AppSettingsModel(
      businessName: businessName ?? this.businessName,
      businessPhone: businessPhone ?? this.businessPhone,
      businessAddress: businessAddress ?? this.businessAddress,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      defaultTaxPercent: defaultTaxPercent ?? this.defaultTaxPercent,
      invoiceFooter: invoiceFooter ?? this.invoiceFooter,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'businessPhone': businessPhone,
      'businessAddress': businessAddress,
      'currencySymbol': currencySymbol,
      'defaultTaxPercent': defaultTaxPercent,
      'invoiceFooter': invoiceFooter,
      'invoicePrefix': invoicePrefix,
      'languageCode': languageCode,
    };
  }

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      businessName: (json['businessName'] as String?)?.trim().isNotEmpty == true
          ? (json['businessName'] as String).trim()
          : 'My Business',
      businessPhone:
          (json['businessPhone'] as String?)?.trim().isNotEmpty == true
          ? (json['businessPhone'] as String).trim()
          : null,
      businessAddress:
          (json['businessAddress'] as String?)?.trim().isNotEmpty == true
          ? (json['businessAddress'] as String).trim()
          : null,
      currencySymbol:
          (json['currencySymbol'] as String?)?.trim().isNotEmpty == true
          ? (json['currencySymbol'] as String).trim()
          : 'ETB',
      defaultTaxPercent: (json['defaultTaxPercent'] as num?)?.toDouble() ?? 0,
      invoiceFooter:
          (json['invoiceFooter'] as String?)?.trim().isNotEmpty == true
          ? (json['invoiceFooter'] as String).trim()
          : 'Thank you for your business.',
      invoicePrefix:
          (json['invoicePrefix'] as String?)?.trim().isNotEmpty == true
          ? (json['invoicePrefix'] as String).trim()
          : 'INV',
      languageCode: (json['languageCode'] as String?)?.trim().isNotEmpty == true
          ? (json['languageCode'] as String).trim()
          : 'en',
    );
  }
}
