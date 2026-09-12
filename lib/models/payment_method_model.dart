class PaymentMethodModel {
  final int? id;
  final String name;
  final String? iconUrl;

  PaymentMethodModel({
    required this.id,
    required this.name,
    this.iconUrl,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'],
      name: json['name'] ?? '',
      iconUrl: json['icon_url'],
    );
  }
}
