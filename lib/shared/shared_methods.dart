import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

void showCustomSnackbar(BuildContext context, String message) {
  Flushbar(
    message: message,
    flushbarPosition: FlushbarPosition.TOP,
    backgroundColor: const Color(0xffFF2566),
    duration: const Duration(seconds: 2),
  ).show(context);
}

void showCustomSnackbarSuccess(BuildContext context, String message) {
  Flushbar(
    message: message,
    flushbarPosition: FlushbarPosition.TOP,
    backgroundColor: Colors.green,
    duration: const Duration(seconds: 2),
  ).show(context);
}

String formatCurrency(int? number, {String symbol = 'Rp '}) {
  return NumberFormat.currency(
    locale: 'id',
    symbol: symbol,
    decimalDigits: 0,
  ).format(number);
}

Future<XFile?> selectImage() async {
  XFile? selectedImage =
      await ImagePicker().pickImage(source: ImageSource.gallery);

  return selectedImage;
}

String formatPhoneNumber(String phoneNumber) {
  // Menghilangkan spasi dan tanda selain angka
  phoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

  // Memeriksa apakah nomor dimulai dengan '0' dan menggantinya dengan '+62'
  if (phoneNumber.startsWith('0')) {
    return '+62' + phoneNumber.substring(1);
  } else {
    // Jika sudah dalam format internasional
    return phoneNumber;
  }
}
