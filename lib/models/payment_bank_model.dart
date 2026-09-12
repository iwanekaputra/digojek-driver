class PaymentBankModel {
  final String bankName;
  final String accountNumber;
  final String accountName;

  PaymentBankModel({
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
  });

  factory PaymentBankModel.fromJson(Map<String, dynamic> json) {
    return PaymentBankModel(
      bankName: json['bank_name'],
      accountNumber: json['account_number'],
      accountName: json['account_name'],
    );
  }
}
