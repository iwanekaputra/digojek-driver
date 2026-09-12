class VaModel {
  final String companyCode;
  final String vaNumber;

  VaModel({
    required this.companyCode,
    required this.vaNumber,
  });

  factory VaModel.fromJson(Map<String, dynamic> json) {
    return VaModel(
      companyCode: json['company_code'],
      vaNumber: json['va_number'],
    );
  }
}
