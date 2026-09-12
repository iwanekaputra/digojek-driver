import 'dart:async';
import 'dart:convert';

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:deliq_delivery/Account/UI/account_page.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/OrderMap/UI/onway.dart';
import 'package:deliq_delivery/OrderMap/UI/onway_to_destination.dart';
import 'package:deliq_delivery/OrderMap/UI/track_ride_screen.dart';
import 'package:deliq_delivery/OrderMap/UICabTogether/onway_together.dart';
import 'package:deliq_delivery/OrderMap/UIGrocier/track_grocier_screen.dart';
import 'package:deliq_delivery/OrderMap/UIPackage/onway_package.dart';
import 'package:deliq_delivery/OrderMap/UIPackage/track_package_screen.dart';
import 'package:deliq_delivery/OrderMap/UIProduct/onway_product.dart';
import 'package:deliq_delivery/OrderMap/UIProduct/track_product_screen.dart';
import 'package:deliq_delivery/OrderMapBloc/order_map_bloc.dart';
import 'package:deliq_delivery/Routes/routes.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/models/sign_up_form_model.dart';
import 'package:deliq_delivery/models/user_model.dart';
import 'package:deliq_delivery/services/auth_service.dart';
import 'package:deliq_delivery/services/shared_services.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../../map_utils.dart';

class NewDeliveryPage extends StatelessWidget {
  const NewDeliveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderMapBloc>(
      create: (context) => OrderMapBloc()..loadMap(),
      child: const NewDeliveryBody(),
    );
  }
}

class NewDeliveryBody extends StatefulWidget {
  const NewDeliveryBody({super.key});

  @override
  NewDeliveryBodyState createState() => NewDeliveryBodyState();
}

class NewDeliveryBodyState extends State<NewDeliveryBody> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController? mapStyleController;
  UserModel? driver;
  bool isLoading = false;
  bool isLoadingButton = false;

  List<dynamic> incomingOrders = [];

  @override
  void initState() {
    rootBundle.loadString('images/map_style.txt').then((string) {
      mapStyle = string;
    });
    super.initState();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      setState(() {
        driver = authState.user;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async => await initData());
  }

  Future<void> getIncomingOrders() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await AuthService().getToken();

      final response = await http.get(
        Uri.parse('https://api.digojek.com/api/driver/orders/incoming'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        setState(() {
          incomingOrders = data['data'];
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> initData() async {
    setState(() {
      isLoading = true;
    });

    UserModel user = await AuthService().getCurrentUser();

    setState(() {
      driver = user;
    });

    await getIncomingOrders();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> acceptOrder(Map<String, dynamic> order) async {
    try {
      setState(() {
        isLoadingButton = true;
      });

      final token = await AuthService().getToken();

      final response = await http.post(
        Uri.parse(
          'https://api.digojek.com/api/driver/accept-order',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "order_id": order['order_id'],
        }),
      );

      final data = jsonDecode(response.body);

      debugPrint(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        showCustomSnackbar(
          context,
          data['message'],
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrackRideScreen(
              order_id: data['order_id'].toString(),
            ),
          ),
        );
      } else {
        showCustomSnackbar(
          context,
          data['message'] ?? 'Gagal mengambil order',
        );
      }
    } catch (e) {
      debugPrint(e.toString());

      showCustomSnackbar(
        context,
        'Terjadi kesalahan',
      );
    }

    setState(() {
      isLoadingButton = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadedSlideAnimation(
      beginOffset: const Offset(0, 0.1),
      endOffset: const Offset(0, 0),
      slideCurve: Curves.linearToEaseOut,
      child: Scaffold(
        key: _scaffoldKey,
        // drawer: const AccountPageBody(),
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Text(
            AppLocalizations.of(context)!.newDeliveryTask!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () async => await getIncomingOrders(),
            )
          ],
        ),
        body: RefreshIndicator(
          onRefresh: getIncomingOrders,
          color: kMainColor,
          child: Column(
            children: <Widget>[
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : incomingOrders.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            itemCount: incomingOrders.length,
                            itemBuilder: (context, index) {
                              final order = incomingOrders[index];
                              return _buildOrderCard(order);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Tampilan Kosong (Modern & Simple)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Tidak ada pesanan masuk',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Card Pesanan Modern
  Widget _buildOrderCard(Map<String, dynamic> order) {
    String typeOrder = (order['type_order'] ?? '').toString();
    String vehicleAsset = 'images/bike1.png';

    if (typeOrder == 'SHIP_PORTER') {
      vehicleAsset = 'images/porter.png';
    } else if (typeOrder == 'mobil' ||
        typeOrder == 'Sedan' ||
        typeOrder == 'SUV' ||
        typeOrder == 'MPV') {
      vehicleAsset = 'images/image1.png';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card: Ikon Kendaraan, Tipe Order, No Order
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kMainColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  vehicleAsset,
                  height: 32,
                  width: 32,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.directions_bike, color: kMainColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['type_order'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order['no_order'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rp ${order['price'] ?? 0}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: kMainColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: kMainColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order['distance'] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kMainColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1),
          ),

          // Alamat Penjemputan & Pengantaran (Visual Timeline)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Icon(Icons.circle, size: 12, color: kMainColor),
                  Container(
                    width: 2,
                    height: 28,
                    color: Colors.grey[300],
                  ),
                  const Icon(Icons.location_on, size: 14, color: Colors.red),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Penjemputan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order['pickup_address'] ?? '-',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pengantaran',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order['destination_address'] ?? '-',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tombol Terima Pesanan
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: isLoadingButton
                  ? null
                  : () async {
                      await acceptOrder(order);
                    },
              child: isLoadingButton
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Terima Pesanan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Method Pendukung Tetap Dipertahankan Sesuai Kebutuhan
  Widget buildNotifMober(DocumentSnapshot documentSnapshot) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.3),
          child: Row(
            children: <Widget>[
              if (documentSnapshot['type_order'] == 'motor')
                Image.asset('images/bike1.png', height: 42.3, width: 33.7),
              if (documentSnapshot['type_order'] == 'SHIP_PORTER')
                Image.asset('images/bike1.png', height: 42.3, width: 33.7),
              if (documentSnapshot['type_order'] == 'Bajaj')
                Image.asset('images/bajaj.png', height: 42.3, width: 33.7),
              if (documentSnapshot['type_order'] == 'Bentor')
                Image.asset('images/becak.png', height: 42.3, width: 33.7),
              if (documentSnapshot['type_order'] == 'mobil' ||
                  documentSnapshot['type_order'] == 'Sedan' ||
                  documentSnapshot['type_order'] == 'SUV' ||
                  documentSnapshot['type_order'] == 'MPV' ||
                  documentSnapshot['type_order'] == 'MVP' ||
                  documentSnapshot['type_order'] == 'Truck' ||
                  documentSnapshot['type_order'] == 'Bus' ||
                  documentSnapshot['type_order'] == 'Pick UP')
                Image.asset('images/image1.png', height: 42.3, width: 33.7),
              Expanded(
                child: ListTile(
                  title: Text(
                    documentSnapshot['type_order'],
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        letterSpacing: 0.07, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Row(
                    children: <Widget>[
                      Text(
                        documentSnapshot['distance'],
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontSize: 11.7,
                            letterSpacing: 0.06,
                            color: kMainColor,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        documentSnapshot['date'],
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontSize: 11.7,
                            letterSpacing: 0.06,
                            color: const Color(0xffc1c1c1)),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        Divider(color: Theme.of(context).cardColor, thickness: 1.0),
        Row(
          children: <Widget>[
            Padding(
                padding: EdgeInsets.only(
                    left: 28.0, bottom: 6.0, top: 6.0, right: 10.0),
                child: Icon(Icons.location_on, size: 14.0, color: kMainColor)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  documentSnapshot['address_destination'],
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      letterSpacing: 0.05, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5.0),
              ],
            ),
          ],
        ),
        const SizedBox(height: 5.0),
        Row(
          children: <Widget>[
            Padding(
                padding: EdgeInsets.only(
                    left: 28.0, bottom: 12.0, top: 12.0, right: 10.0),
                child: Icon(Icons.navigation, size: 14.0, color: kMainColor)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  documentSnapshot['address_current_customer'],
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      letterSpacing: 0.05, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5.0),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10.0),
      ],
    );
  }

  Future<bool> validate(DocumentSnapshot documentSnapshot) async {
    final res2 = await FirebaseFirestore.instance
        .collection('orders')
        .where('order', isEqualTo: documentSnapshot['order'])
        .get();

    final DocumentSnapshot data = res2.docs[0];

    if (data['driver_id'].isNotEmpty) {
      showCustomSnackbar(context, 'Driver lain sudah mengambil pesanan ini');
      return false;
    }

    return true;
  }

  Future<bool> updateMober([DocumentSnapshot? documentSnapshot]) async {
    Map<String, dynamic> driverTakeOrderMober = await SharedServices()
        .driverTakeOrderMober(
            documentSnapshot!['order_customer_id'].toString(),
            driver!.id.toString(),
            documentSnapshot['price_trip'].toString(),
            'mober',
            documentSnapshot['price_trip'].toString(),
            'lanjut');

    if (driverTakeOrderMober['is-ordered'] != null) {
      showCustomSnackbar(context, 'Orderan Sudah Diambil oleh driver lain');
      setState(() {
        isLoading = false;
      });
      return false;
    }

    final res =
        await FirebaseFirestore.instance.collection('config_orders').add({
      "heading": 0.1,
      "latitude_current_driver": double.parse(driver!.latitude!),
      "longitude_current_driver": double.parse(driver!.longitude!),
      "order_id": driverTakeOrderMober['id'],
      "status": "lanjut"
    });

    await FirebaseFirestore.instance
        .collection('config_order_customers')
        .doc(documentSnapshot['config_order_customer_id'])
        .update({"config_order_id": res.id, "status": "diterima"});

    Navigator.push(
        _scaffoldKey.currentContext!,
        MaterialPageRoute(
            builder: (context) => OnWayTogetherPage(
                  order: driverTakeOrderMober,
                )));

    return true;
  }

  Future<void> updateNotifTrip(
      DocumentSnapshot notif_trips, DocumentSnapshot trips) async {
    await FirebaseFirestore.instance
        .collection('notif_trips')
        .doc(notif_trips.id)
        .update({"trip_id": trips.id, "status": "diterima"});
  }

  Future<bool> update([DocumentSnapshot? documentSnapshot]) async {
    num? prices = documentSnapshot!['price_trip'] * 11 / 100;

    if (driver!.vehicletype == 'motor' &&
        (driver!.balance! < 10000 ||
            (driver!.balance! - prices! < 0 && driver!.balance! > 10000))) {
      showCustomSnackbar(context, 'Saldo isitas anda tidak mencukupi');
      setState(() {
        isLoading = false;
      });
      return false;
    }

    if (driver!.vehicletype == 'Bajaj' &&
        (driver!.balance! < 10000 ||
            (driver!.balance! - prices! < 0 && driver!.balance! > 10000))) {
      showCustomSnackbar(context, 'Saldo isitas anda tidak mencukupi');
      setState(() {
        isLoading = false;
      });
      return false;
    }

    if (driver!.vehicletype == 'Bentor' &&
        (driver!.balance! < 10000 ||
            (driver!.balance! - prices! < 0 && driver!.balance! > 10000))) {
      showCustomSnackbar(context, 'Saldo isitas anda tidak mencukupi');
      setState(() {
        isLoading = false;
      });
      return false;
    }

    if (driver!.vehicletype == 'mobil' &&
        (driver!.balance! < 50000 ||
            (driver!.balance! - prices! < 0 && driver!.balance! > 50000))) {
      showCustomSnackbar(context, 'Saldo isitas anda tidak mencukupi');
      setState(() {
        isLoading = false;
      });
      return false;
    }

    if (driver!.vehicletype == 'SUV' &&
        (driver!.balance! < 50000 ||
            (driver!.balance! - prices! < 0 && driver!.balance! > 50000))) {
      showCustomSnackbar(context, 'Saldo isitas anda tidak mencukupi');
      setState(() {
        isLoading = false;
      });
      return false;
    }

    if (driver!.vehicletype == 'MVP' &&
        (driver!.balance! < 50000 ||
            (driver!.balance! - prices! < 0 && driver!.balance! > 50000))) {
      showCustomSnackbar(context, 'Saldo isitas anda tidak mencukupi');
      setState(() {
        isLoading = false;
      });
      return false;
    }

    if (driver!.vehicletype == 'MPV' &&
        (driver!.balance! < 50000 ||
            (driver!.balance! - prices! < 0 && driver!.balance! > 50000))) {
      showCustomSnackbar(context, 'Saldo isitas anda tidak mencukupi');
      setState(() {
        isLoading = false;
      });
      return false;
    }

    if (driver!.vehicletype == 'Sedan' &&
        (driver!.balance! < 50000 ||
            (driver!.balance! - prices! < 0 && driver!.balance! > 50000))) {
      showCustomSnackbar(context, 'Saldo isitas anda tidak mencukupi');
      setState(() {
        isLoading = false;
      });
      return false;
    }

    if (driver!.vehicletype == 'Truck' &&
        (driver!.balance! < 50000 ||
            (driver!.balance! - prices! < 0 && driver!.balance! > 50000))) {
      showCustomSnackbar(context, 'Saldo isitas anda tidak mencukupi');
      setState(() {
        isLoading = false;
      });
      return false;
    }

    if (driver!.vehicletype == 'Bus' &&
        (driver!.balance! < 50000 ||
            (driver!.balance! - prices! < 0 && driver!.balance! > 50000))) {
      showCustomSnackbar(context, 'Saldo isitas anda tidak mencukupi');
      setState(() {
        isLoading = false;
      });
      return false;
    }

    if (driver!.vehicletype == 'Pick UP' &&
        (driver!.balance! < 50000 ||
            (driver!.balance! - prices! < 0 && driver!.balance! > 50000))) {
      showCustomSnackbar(context, 'Saldo isitas anda tidak mencukupi');
      setState(() {
        isLoading = false;
      });
      return false;
    }

    Map<String, dynamic> driverTakeOrder = await SharedServices()
        .driverTakeOrderRide(documentSnapshot!['order_id'].toString(),
            driver!.id.toString(), 'diterima');

    if (driverTakeOrder['is-ordered'] != null) {
      showCustomSnackbar(context, 'Orderan Sudah Diambil oleh driver lain');
      setState(() {
        isLoading = false;
      });
      return false;
    }

    await FirebaseFirestore.instance
        .collection('config_orders')
        .doc(documentSnapshot['config_order_id'].toString())
        .update({
      'status': "diterima",
      "latitude_current_driver": double.parse(driver!.latitude!),
      "longitude_current_driver": double.parse(driver!.longitude!)
    });

    await FirebaseFirestore.instance
        .collection('notif_trips')
        .doc(documentSnapshot.id)
        .delete();

    if (documentSnapshot['type_order'] == 'produk') {
      Navigator.push(
          _scaffoldKey.currentContext!,
          MaterialPageRoute(
              builder: (context) => TrackProductScreen(
                    order_id: documentSnapshot['order_id'].toString(),
                  )));
    }

    if (documentSnapshot['type_order'] == 'grosir') {
      Navigator.push(
          _scaffoldKey.currentContext!,
          MaterialPageRoute(
              builder: (context) => TrackGrocierScreen(
                    order_id: documentSnapshot['order_id'].toString(),
                  )));
    }

    if (documentSnapshot['type_order'] == 'motor' ||
        documentSnapshot['type_order'] == 'mobil' ||
        documentSnapshot['type_order'] == 'Sedan' ||
        documentSnapshot['type_order'] == 'SUV' ||
        documentSnapshot['type_order'] == 'MPV' ||
        documentSnapshot['type_order'] == 'Pick UP' ||
        documentSnapshot['type_order'] == 'MVP' ||
        documentSnapshot['type_order'] == 'Truck' ||
        documentSnapshot['type_order'] == 'Bus' ||
        documentSnapshot['type_order'] == 'Bentor' ||
        documentSnapshot['type_order'] == 'Bajaj') {
      Navigator.push(
          _scaffoldKey.currentContext!,
          MaterialPageRoute(
            builder: (context) => TrackRideScreen(
                order_id: documentSnapshot['order_id'].toString()),
          ));
    }

    if (documentSnapshot['type_order'] == 'paket') {
      Navigator.push(
          _scaffoldKey.currentContext!,
          MaterialPageRoute(
            builder: (context) => TrackPackageScreen(
                order_id: documentSnapshot['order_id'].toString()),
          ));
    }

    return true;
  }

  Future<void> deleteNotifTripMober(DocumentSnapshot documentSnapshot) async {
    final deleteNotifDriver = await FirebaseFirestore.instance
        .collection('notif_trips')
        .where('order', isEqualTo: documentSnapshot['order'])
        .get();

    for (var doc in deleteNotifDriver.docs) {
      await doc.reference.delete();
    }
  }
}
