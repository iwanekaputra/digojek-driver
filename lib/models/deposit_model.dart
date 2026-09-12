import 'payment_method_model.dart';
import 'va_model.dart';
import 'payment_bank_model.dart';

class DepositModel {
  final int id;
  final String type; // va | manual
  final PaymentMethodModel paymentMethod;
  final VaModel? va;
  final PaymentBankModel? paymentBank;
  final int totalPrice;
  final int grandTotal;
  final String status;
  final String description;
  final String? imageTransfer;
  final String? createdAt;

  DepositModel(
      {required this.id,
      required this.type,
      required this.paymentMethod,
      this.va,
      this.paymentBank,
      required this.totalPrice,
      required this.grandTotal,
      required this.status,
      required this.description,
      this.imageTransfer,
      this.createdAt});

  factory DepositModel.fromJson(Map<String, dynamic> json) {
    return DepositModel(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      paymentMethod: PaymentMethodModel.fromJson(json['payment_method'] ?? {}),
      va: json['va'] != null ? VaModel.fromJson(json['va']) : null,
      paymentBank: json['payment_bank'] != null
          ? PaymentBankModel.fromJson(json['payment_bank'])
          : null,
      totalPrice: json['total_price'] ?? 0,
      grandTotal: json['grand_total'] ?? 0,
      status: json['status'] ?? '',
      description: json['description'] ?? '',
      imageTransfer: json['image_transfer'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}
