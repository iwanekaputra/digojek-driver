class TransactionPurchaseModel {
  final int id;
  final String name;
  final String createdAt;
  final int grandTotal;
  final String message;
  final String code;
  final String msisdn;
  final String requestId;
  final int price;
  final String paymentMethod;
  final int priceAdmin;
  final int cashback;
  final String? description;
  final List<dynamic>? info;
  final String? note;

  TransactionPurchaseModel(
      {required this.id,
      required this.name,
      required this.createdAt,
      required this.grandTotal,
      required this.message,
      required this.code,
      required this.msisdn,
      required this.requestId,
      required this.price,
      required this.paymentMethod,
      required this.priceAdmin,
      required this.cashback,
      this.description,
      this.info,
      this.note});

  factory TransactionPurchaseModel.fromJson(Map<String, dynamic> json) {
    return TransactionPurchaseModel(
        id: json['id'],
        name: json['name'],
        createdAt: json['created_at'],
        grandTotal: json['grand_total'],
        message: json['message'],
        code: json['code'],
        msisdn: json['msisdn'],
        requestId: json['request_id'],
        price: json['price'],
        paymentMethod: json['payment_method'],
        priceAdmin: json['price_admin'],
        cashback: json['cashback'],
        description: json['description'],
        info: json['info'] != null ? List<dynamic>.from(json['info']) : [],
        note: json['note']);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'created_at': createdAt,
      'grand_total': grandTotal,
      'message': message,
      'code': code,
      'msisdn': msisdn,
      'request_id': requestId,
      'price': price,
      'payment_method': paymentMethod,
      'price_admin': priceAdmin,
      'cashback': cashback,
      'description': description ?? '',
      'info': info ?? [],
      'note': note ?? ''
    };
  }
}
