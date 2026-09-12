import 'dart:ffi';

class OtpFormModel {
  final String? nohp;
  final String? otp;

  OtpFormModel({this.nohp, this.otp});

  Map<String, dynamic> toJson() {
    return {'nohp': nohp, 'otp': otp};
  }
}
