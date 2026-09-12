import "dart:io";
import "dart:typed_data";

import "package:deliq_delivery/Account/UI/account_page.dart";
import "package:deliq_delivery/Components/bottom_bar.dart";
import "package:deliq_delivery/Themes/colors.dart";
import "package:deliq_delivery/blocs/auth/auth_bloc.dart";
import "package:deliq_delivery/models/transaction_purchase_model.dart";
import "package:deliq_delivery/services/shared_services.dart";
import "package:deliq_delivery/shared/shared_methods.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
// import "package:google_fonts/google_fonts.dart";
// import "package:google_fonts/google_fonts.dart";
import "package:http/http.dart";
import "package:path_provider/path_provider.dart";
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

import "package:url_launcher/url_launcher.dart";

class TransactionPurchaseDetail extends StatefulWidget {
  final TransactionPurchaseModel data;

  const TransactionPurchaseDetail({super.key, required this.data});

  @override
  State<TransactionPurchaseDetail> createState() =>
      _TransactionPurchaseDetailState();
}

class _TransactionPurchaseDetailState extends State<TransactionPurchaseDetail> {
  List info = [];
  bool isDownloadingPdf = false;

  @override
  void initState() {
    super.initState();

    info = widget.data.info ?? [];
  }

  void _downloadFile(File file) async {
    // Menentukan direktori penyimpanan yang dapat diakses di perangkat
    final String dir = (await getExternalStorageDirectory())!.path;
    final String path = '$dir/example2.pdf';

    // Copy file dari direktori temporary ke direktori penyimpanan yang dapat diakses
    File originalFile = File(file.path);
    File newFile = await originalFile.copy(path);

    // Tampilkan pesan sukses jika berhasil menyimpan PDF
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("PDF Created and Saved"),
          content: Text("PDF berhasil dibuat dan disimpan di $path"),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => const AccountPageBody()),
                (route) => false);
          }
        },
        builder: (context, state) {
          return Stack(children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 20, right: 20, top: 40, bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'images/excellence.png',
                            width: 250,
                            height: 210,
                          ),
                          const SizedBox(
                            height: 25,
                          ),
                          Text(
                            'Pembayaran Berhasil ',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontSize: 20),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    Text(widget.data.createdAt,
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black)),

                    Divider(
                        color: Color(0xffC9E2E2),
                        thickness: 4,
                        height: 40), // Divider dengan kustomisasi
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Status',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(widget.data.message,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge!
                                    .copyWith(
                                        color: widget.data.message == 'proses'
                                            ? kMainColor
                                            : widget.data.message == 'Sukses' ||
                                                    widget.data.message ==
                                                        'sukses'
                                                ? kGreenColor
                                                : kRedColor,
                                        fontSize: 14)),
                          ),
                        ],
                      ),
                    ),

                    buildInfoRow('Nama Produk', widget.data.name),
                    buildInfoRow('No. Tujuan', widget.data.msisdn),
                    buildInfoRow(
                        'Metode Pembayaran', widget.data.paymentMethod),

                    if (widget.data.note == 'TRANSFER UANG')
                      buildInfoRow(
                          'Nominal',
                          formatCurrency(widget.data.price is String
                              ? widget.data.price
                              : widget.data.price)),

                    if (widget.data.note == 'TRANSFER UANG')
                      buildInfoRow(
                          'Biaya Admin',
                          formatCurrency(widget.data.priceAdmin is String
                              ? widget.data.priceAdmin
                              : widget.data.priceAdmin)),
                    buildInfoRow(
                        'Total Harga',
                        formatCurrency(widget.data.grandTotal is String
                            ? widget.data.grandTotal
                            : widget.data.grandTotal)),
                    buildInfoRow(
                        'Cashback',
                        formatCurrency(widget.data.cashback is String
                            ? widget.data.cashback
                            : widget.data.cashback)),

                    buildInfoRow(
                        'Catatan',
                        widget.data.description == null ||
                                widget.data.description == ""
                            ? '-'
                            : widget.data.description!),
                    SizedBox(height: 20),
                    Column(
                      children: info.map((e) {
                        if (e['nama'] == 'tag' ||
                            e['nama'] == 'adm' ||
                            e['nama'] == 'ttag') {
                          return buildInfoRow(
                              e['nama'], formatCurrency(int.parse(e['value'])));
                        } else if (e['nama'] == 'NOMINAL') {
                          return buildInfoRow(
                              e['nama'], formatCurrency(int.parse(e['value'])));
                        } else if (e['nama'] == 'Link Materai') {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Link Materai',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: GestureDetector(
                                    onTap: () async {
                                      if (await canLaunchUrl(
                                          Uri.parse(e['value']))) {
                                        await launchUrl(Uri.parse(e[
                                            'value'])); // Konversi String ke Uri
                                      } else {
                                        showCustomSnackbar(
                                          context,
                                          'Tidak dapat membuka url ${e['value']}',
                                        );
                                      }
                                    },
                                    child: Text(
                                      'Klik Disini',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return buildInfoRow(e['nama'], e['value']);
                        }
                      }).toList(),
                    ),
                    const SizedBox(
                      height: 20,
                    ),

                    Divider(
                        color: Color(0xffC9E2E2),
                        thickness: 4,
                        height: 40), // D
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '*TERIMA KASIH*',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontSize: 20),
                          ),
                          Text(
                            'PT DIGOJEK',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontSize: 20),
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                        ],
                      ),
                    ),

                    // ElevatedButton(
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: Theme.of(context).primaryColor,
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(30.0),
                    //     ),
                    //   ),
                    //   onPressed: () {
                    //     context.read<AuthBloc>().add(AuthGetCurrentUser());
                    //   },
                    //   child: Padding(
                    //     padding: const EdgeInsets.symmetric(
                    //         horizontal: 12.0, vertical: 8.0),
                    //     child: Text(
                    //       'Kembali Ke Beranda',
                    //       style: Theme.of(context).textTheme.labelLarge,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  BottomBar(
                      onTap: () {
                        context.read<AuthBloc>().add(AuthGetCurrentUser());
                      },
                      text: 'Kembali Ke Beranda')
                ],
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
