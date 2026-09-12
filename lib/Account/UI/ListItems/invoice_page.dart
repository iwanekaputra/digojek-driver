import 'dart:convert';
import 'dart:io';

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/models/deposit_model.dart';
import 'package:deliq_delivery/services/auth_service.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:deliq_delivery/shared/shared_values.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class InvoicePage extends StatefulWidget {
  final String depositId;

  const InvoicePage({super.key, required this.depositId});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  DepositModel? deposit;

  bool isLoading = true;
  bool isUploading = false;

  XFile? selectedImage;

  // =========================
  // STATUS CHECK
  // =========================
  bool get isLunas {
    return deposit?.status.toLowerCase() == 'lunas';
  }

  bool get isProses {
    return deposit?.status.toLowerCase() == 'proses';
  }

  @override
  void initState() {
    super.initState();
    fetchDepositDetail();
  }

  // =========================
  // API
  // =========================
  Future<void> fetchDepositDetail() async {
    try {
      final token = await AuthService().getToken();

      final res = await http.get(
        Uri.parse('$baseUrl/v2/drivers/deposit/${widget.depositId}'),
        headers: {'Authorization': token},
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);

        setState(() {
          deposit = DepositModel.fromJson(json['data']);
          isLoading = false;
        });
      } else {
        throw Exception('Gagal mengambil detail deposit');
      }
    } catch (e) {
      isLoading = false;
      showCustomSnackbar(context, e.toString());
    }
  }

  // =========================
  // COPY
  // =========================
  void copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showCustomSnackbarSuccess(context, 'Berhasil disalin');
  }

  // =========================
  // UPLOAD
  // =========================
  Future<void> uploadImage() async {
    if (selectedImage == null) {
      showCustomSnackbar(context, 'Pilih gambar terlebih dahulu');
      return;
    }

    setState(() => isUploading = true);

    try {
      final token = await AuthService().getToken();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/drivers/deposit/upload-image'),
      );

      request.headers['Authorization'] = token;

      request.fields['deposit_id'] = deposit!.id.toString();

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          selectedImage!.path,
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        showCustomSnackbarSuccess(context, 'Upload berhasil');

        await fetchDepositDetail();

        setState(() {
          selectedImage = null;
        });
      } else {
        throw Exception('Upload gagal');
      }
    } catch (e) {
      showCustomSnackbar(context, e.toString());
    } finally {
      setState(() => isUploading = false);
    }
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        centerTitle: true,
        title: Text(
          isLunas ? 'Riwayat Deposit' : 'Detail Pembayaran',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: FadedSlideAnimation(
        beginOffset: const Offset(0, 0.3),
        endOffset: Offset.zero,
        slideCurve: Curves.easeOut,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : deposit == null
                ? const Center(child: Text('Data tidak ditemukan'))
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final hasProof =
        deposit!.imageTransfer != null && deposit!.imageTransfer!.isNotEmpty;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            _statusBadge(),
            if (!isLunas) _warningCard(),
            _paymentDetailCard(),
            _proofCard(hasProof),
          ],
        ),

        // Tombol upload hanya kalau PROSES
        if (!hasProof && !isLunas) _uploadButton(),
      ],
    );
  }

  // =========================
  // STATUS BADGE
  // =========================
  Widget _statusBadge() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLunas ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLunas ? Colors.green : Colors.orange,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLunas ? Icons.check_circle : Icons.hourglass_top,
            color: isLunas ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(
            isLunas ? 'Status: LUNAS' : 'Status: PROSES',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isLunas ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // WARNING
  // =========================
  Widget _warningCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade300, Colors.orange.shade500],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Hindari top up pukul 21.00 – 03.00 karena proses validasi bisa lebih lama',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  // =========================
  // PAYMENT DETAIL
  // =========================
  Widget _paymentDetailCard() {
    return Opacity(
      opacity: isLunas ? 0.8 : 1,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text('Total Pembayaran'),
            const SizedBox(height: 12),
            _amountBox(),
            const SizedBox(height: 20),
            _bankInfo(),

            const SizedBox(height: 12),
            _paymentDescription(), // ✅ tambah
          ],
        ),
      ),
    );
  }

  // =========================
// PAYMENT DESCRIPTION
// =========================
  Widget _paymentDescription() {
    // ambil dari deposit dulu, kalau kosong ambil dari payment method
    final desc = deposit!.description.isNotEmpty ? deposit!.description : '';

    if (desc.isEmpty) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountBox() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 24,
      ),
      decoration: BoxDecoration(
        color: kMainColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            formatCurrency(deposit!.grandTotal),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kMainColor,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => copyText(deposit!.grandTotal.toString()),
            child: const Icon(Icons.copy, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _bankInfo() {
    if (deposit!.type == 'va' && deposit!.va != null) {
      return Column(
        children: [
          _infoRow(
            Icons.confirmation_number,
            deposit!.va!.vaNumber,
            'Virtual Account',
          ),
          _infoRow(
            Icons.account_balance,
            deposit!.paymentMethod.name,
            'Bank',
          ),
        ],
      );
    }

    if (deposit!.type == 'manual' && deposit!.paymentBank != null) {
      return Column(
        children: [
          _infoRow(
            Icons.account_balance,
            deposit!.paymentBank!.accountNumber,
            'No Rekening',
          ),
          _infoRow(
            Icons.person,
            deposit!.paymentBank!.accountName,
            'Atas Nama',
          ),
          _infoRow(
            Icons.business,
            deposit!.paymentBank!.bankName,
            'Bank',
          ),
        ],
      );
    }

    return const SizedBox();
  }

  Widget _infoRow(
    IconData icon,
    String value,
    String label,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: kMainColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => copyText(value),
            child: const Icon(Icons.copy, size: 18),
          ),
        ],
      ),
    );
  }

  // =========================
  // PROOF
  // =========================
  Widget _proofCard(bool hasProof) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: hasProof
          ? Image.network(deposit!.imageTransfer!)
          : Column(
              children: [
                InkWell(
                  onTap: isLunas
                      ? null
                      : () async {
                          final img = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                          );

                          if (img != null) {
                            setState(() {
                              selectedImage = img;
                            });
                          }
                        },
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(70),
                    ),
                    child: selectedImage != null
                        ? ClipOval(
                            child: Image.file(
                              File(selectedImage!.path),
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.cloud_upload,
                            size: 40,
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isLunas
                      ? 'Bukti transfer'
                      : 'Tap untuk upload bukti transfer',
                ),
              ],
            ),
    );
  }

  // =========================
  // BUTTON
  // =========================
  Widget _uploadButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kMainColor,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: isUploading ? null : uploadImage,
          child: isUploading
              ? const CircularProgressIndicator(
                  color: Colors.white,
                )
              : const Text('Upload Bukti Transfer'),
        ),
      ),
    );
  }
}
