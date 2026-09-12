import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliq_delivery/Account/UI/account_page.dart';
import 'package:deliq_delivery/Chat/UI/chat_page.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/Routes/routes.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/models/user_model.dart';
import 'package:deliq_delivery/services/shared_services.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:url_launcher/url_launcher.dart';

class TripRideCompletedScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const TripRideCompletedScreen({
    super.key,
    required this.order,
  });

  @override
  State<TripRideCompletedScreen> createState() =>
      _TripRideCompletedScreenState();
}

class _TripRideCompletedScreenState extends State<TripRideCompletedScreen> {
  int? customer_id;

  Map<String, dynamic> review = {};
  UserModel? driver;

  bool isLoading = false;

  List reviews = [];

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;

    if (authState is AuthSuccess) {
      customer_id = authState.user.id;
      driver = authState.user;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async => await initData());
  }

  Future<void> initData() async {
    setState(() {
      isLoading = true;
    });

    await getReview();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> getReview() async {
    List res = await SharedServices().getReviewByOrderId(
      driver!.id.toString(),
      widget.order['order_id'].toString(),
      '0',
    );

    setState(() {
      reviews = res;
    });
  }

  // Helper Widget Informasi Baris Kargo Kapal agar serasi dengan halaman OnWay
  Widget _buildCargoRowItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final shipCargo = widget.order['ship_cargo'];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Ringkasan Transaksi',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // --- KARTU HEADER STATUS UTAMA ---
                          Card(
                            elevation: 0,
                            color: Theme.of(context).cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.order['type_order'] ?? '-',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: kMainColor,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Row(
                                          children: [
                                            Icon(Icons.check_circle,
                                                color: Colors.green, size: 16),
                                            SizedBox(width: 6),
                                            Text(
                                              'Perjalanan Selesai',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (widget.order['services'] != null &&
                                      widget.order['services']['link_image'] !=
                                          null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        widget.order['services']['link_image'],
                                        height: 50,
                                        width: 50,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error,
                                                stackTrace) =>
                                            const Icon(Icons.directions_bike,
                                                size: 35, color: Colors.grey),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // --- KARTU INFORMASI KENDARAAN DRIVER & DETAIL CUSTOMER ---
                          Card(
                            elevation: 0,
                            color: Theme.of(context).cardColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Info Kendaraan
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        driver?.brand ?? '-',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(color: Colors.grey),
                                      ),
                                      Text(
                                        driver?.registrationNumber ?? '-',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 12.0),
                                    child: Divider(height: 1),
                                  ),
                                  // Info Profil Customer & Aksi Kontak Konten
                                  Row(
                                    children: [
                                      if (widget.order['customer'] != null &&
                                          widget.order['customer']
                                                  ['link_image'] !=
                                              null)
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          child: Image.network(
                                            widget.order['customer']
                                                ['link_image'],
                                            height: 45,
                                            width: 45,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error,
                                                    stackTrace) =>
                                                const CircleAvatar(
                                                    radius: 22.5,
                                                    child: Icon(Icons.person)),
                                          ),
                                        ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.order['customer']
                                                      ['name'] ??
                                                  '-',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold),
                                            ),
                                            Text(
                                              widget.order['customer']
                                                      ['phone'] ??
                                                  '-',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Tombol Chat (Logika Dipertahankan)
                                      GestureDetector(
                                        onTap: () {
                                          // Panggil halaman chat jika dibutuhkan di kemudian hari
                                        },
                                        child: Container(
                                          height: 36,
                                          width: 36,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xff009D06)
                                                .withOpacity(0.1),
                                          ),
                                          child: const Icon(Icons.message,
                                              size: 18,
                                              color: Color(0xff009D06)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Tombol Telpon WhatsApp (Logika Dipertahankan)
                                      GestureDetector(
                                        onTap: () async {
                                          final url =
                                              "whatsapp://send?phone=${formatPhoneNumber(widget.order['customer']['phone'])}&text=p";
                                          await launchUrl(
                                              Uri.parse(Uri.encodeFull(url)));
                                        },
                                        child: Container(
                                          height: 36,
                                          width: 36,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xff009D06)
                                                .withOpacity(0.1),
                                          ),
                                          child: const Icon(Icons.call,
                                              size: 18,
                                              color: Color(0xff009D06)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // --- KARTU DETAIL RUTE PERJALANAN ---
                          Card(
                            elevation: 0,
                            color: Theme.of(context).cardColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Detail Alamat Rute',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  // Titik Penjemputan
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 20, color: Color(0xff009D06)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Lokasi Penjemputan',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey)),
                                            const SizedBox(height: 2),
                                            Text(
                                              widget.order['pickup_address'] ??
                                                  '-',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(left: 10.0),
                                    child: SizedBox(
                                        height: 16,
                                        child: VerticalDivider(
                                            width: 1,
                                            thickness: 1,
                                            color: Colors.grey)),
                                  ),
                                  // Titik Drop Off
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.navigation,
                                          size: 20, color: Color(0xffE9C12A)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Lokasi Drop Off',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey)),
                                            const SizedBox(height: 2),
                                            Text(
                                              widget.order[
                                                      'destination_address'] ??
                                                  '-',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // --- INTEGRASI STRUKTUR DETAIL BARANG BAWAAN (SHIP CARGO) ---
                          if (shipCargo != null) ...[
                            Card(
                              elevation: 0,
                              color: Theme.of(context).cardColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(16)),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 16),
                                    child: const Text(
                                      "DETAIL BARANG BAWAAN (SHIP CARGO)",
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                          letterSpacing: 0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildCargoRowItem("Nama Kapal Pelayaran",
                                      "${shipCargo['ship_name']}"),
                                  _buildCargoRowItem(
                                      "Jenis Layanan Porter",
                                      shipCargo['service_type'] ==
                                              'naik_ke_kapal'
                                          ? 'Naik ke Kapal'
                                          : 'Turun dari Kapal'),
                                  _buildCargoRowItem("Estimasi Berat",
                                      "${shipCargo['weight_kg']} Kg"),
                                  _buildCargoRowItem("Dimensi Barang",
                                      "${shipCargo['length_cm']}x${shipCargo['width_cm']}x${shipCargo['height_cm']} cm"),
                                  _buildCargoRowItem("Detail Titik Jemput",
                                      "${shipCargo['origin_location']}"),
                                  _buildCargoRowItem("Detail Lokasi Antar",
                                      "${shipCargo['destination_location']}"),
                                  _buildCargoRowItem("Catatan Fisik Penumpang",
                                      "${shipCargo['notes'] ?? '-'}"),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // --- KARTU RINCIAN PEMBAYARAN & ADMINISTRASI ORDER ---
                          Card(
                            elevation: 0,
                            color: Theme.of(context).cardColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Biaya Perjalanan',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500)),
                                      Text(
                                        formatCurrency(widget.order['price']),
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: kMainColor),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Cara Pembayaran',
                                          style: TextStyle(fontSize: 13)),
                                      Row(
                                        children: [
                                          Image.asset(
                                              'images/account/ic_menu_wallet.png',
                                              height: 18),
                                          const SizedBox(width: 6),
                                          Text(
                                            widget.order['payment_method'] ??
                                                '-',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Id Pemesanan',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                      Text(widget.order['no_order'] ?? '-',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Dipesan Pada',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                      Text(widget.order['created_at'] ?? '-',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- TOMBOL PINAK UTAMA DI SISI BAWAH LAYAR ---
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: kMainColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(context,
                              PageRoutes.accountPage, (route) => false);
                        },
                        child: Text(
                          locale.backToHome ?? 'Kembali Ke Beranda',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
