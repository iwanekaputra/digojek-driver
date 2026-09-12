import 'dart:async';

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:deliq_delivery/Account/UI/account_page.dart';
import 'package:deliq_delivery/Components/bottom_bar.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/OrderMap/UI/onway.dart';
import 'package:deliq_delivery/OrderMap/UI/onway_to_destination.dart';
import 'package:deliq_delivery/OrderMapBloc/order_map_bloc.dart';
// import 'package:deliq_delivery/OrderMapBloc/order_map_state.dart';
import 'package:deliq_delivery/Routes/routes.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/models/user_model.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  // final Completer<GoogleMapController> _mapController = Completer();
  GoogleMapController? mapStyleController;
  // final Set<Marker> _markers = {};
  UserModel? driver;
  bool isLoading = false;

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
  }

  @override
  Widget build(BuildContext context) {
    return FadedSlideAnimation(
      beginOffset: const Offset(0, 0.3),
      endOffset: const Offset(0, 0),
      slideCurve: Curves.linearToEaseOut,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const Account(),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70.0),
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: AppBar(
              title: Text(AppLocalizations.of(context)!.newDeliveryTask!,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium!
                      .copyWith(fontWeight: FontWeight.w500)),
            ),
          ),
        ),
        body: Column(
          children: <Widget>[
            isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Expanded(
                    child: StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('notif_trips2')
                            .where('driver_id',
                                isEqualTo: driver!.id.toString())
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text('tidak ada data'),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(10.0),
                            itemBuilder: (context, index) {
                              final DocumentSnapshot documentSnapshot =
                                  snapshot.data!.docs[index];
                              return Column(
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.3),
                                    child: Row(
                                      children: <Widget>[
                                        documentSnapshot['type_order'] ==
                                                'motor'
                                            ? Image.asset(
                                                'images/bike1.png',
                                                height: 42.3,
                                                width: 33.7,
                                              )
                                            : Image.asset(
                                                'images/image1.png',
                                                height: 42.3,
                                                width: 33.7,
                                              ),
                                        Expanded(
                                          child: ListTile(
                                            title: Text(
                                              documentSnapshot['type_order'],
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall!
                                                  .copyWith(
                                                      letterSpacing: 0.07,
                                                      fontWeight:
                                                          FontWeight.bold),
                                            ),
                                            subtitle: Row(
                                              children: <Widget>[
                                                Text(
                                                  documentSnapshot['distance'],
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleLarge!
                                                      .copyWith(
                                                          fontSize: 11.7,
                                                          letterSpacing: 0.06,
                                                          color: kMainColor,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                ),
                                                const SizedBox(
                                                  width: 20,
                                                ),
                                                Text(
                                                  documentSnapshot['date'],
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleLarge!
                                                      .copyWith(
                                                          fontSize: 11.7,
                                                          letterSpacing: 0.06,
                                                          color: const Color(
                                                              0xffc1c1c1)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  Divider(
                                    color: Theme.of(context).cardColor,
                                    thickness: 1.0,
                                  ),
                                  Row(
                                    children: <Widget>[
                                      Padding(
                                          padding: const EdgeInsets.only(
                                              left: 28.0,
                                              bottom: 6.0,
                                              top: 6.0,
                                              right: 10.0),
                                          child: Icon(
                                            Icons.location_on,
                                            size: 14.0,
                                            color: kMainColor,
                                          )),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            documentSnapshot[
                                                'address_destination'],
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall!
                                                .copyWith(
                                                    letterSpacing: 0.05,
                                                    fontWeight:
                                                        FontWeight.bold),
                                          ),
                                          const SizedBox(
                                            height: 5.0,
                                          ),
                                          // Text(
                                          //   '1024, Hemiltone Street, Union Market, USA',
                                          //   style: Theme.of(context)
                                          //       .textTheme
                                          //       .bodySmall!
                                          //       .copyWith(
                                          //           fontSize: 11.0,
                                          //           letterSpacing: 0.05),
                                          // ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 5.0,
                                  ),
                                  Row(
                                    children: <Widget>[
                                      Padding(
                                          padding: const EdgeInsets.only(
                                              left: 28.0,
                                              bottom: 12.0,
                                              top: 12.0,
                                              right: 10.0),
                                          child: Icon(
                                            Icons.navigation,
                                            size: 14.0,
                                            color: kMainColor,
                                          )),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            documentSnapshot[
                                                'address_current_customer'],
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall!
                                                .copyWith(
                                                    letterSpacing: 0.05,
                                                    fontWeight:
                                                        FontWeight.bold),
                                          ),
                                          const SizedBox(
                                            height: 5.0,
                                          ),
                                          // Text(
                                          //   '1024, Hemiltone Street, Union Market, USA',
                                          //   style: Theme.of(context)
                                          //       .textTheme
                                          //       .bodySmall!
                                          //       .copyWith(
                                          //           fontSize: 11.0,
                                          //           letterSpacing: 0.05),
                                          // ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10.0,
                                  ),
                                  if (documentSnapshot['status'] == 'proses')
                                    BottomBar(
                                      text:
                                          AppLocalizations.of(context)!.accept,
                                      onTap: () async {
                                        setState(() {
                                          isLoading = true;
                                        });
                                        final data = await update(
                                            documentSnapshot, context);
                                        Navigator.push(
                                            _scaffoldKey.currentContext!,
                                            MaterialPageRoute(
                                                builder: (context) => OnWayPage(
                                                      documentSnapshot: data,
                                                    )));
                                      },
                                    ),
                                  if (documentSnapshot['status'] == 'diterima')
                                    BottomBar(
                                      text: 'Lanjutkan',
                                      color: kGreenColor,
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    OnWayToDestinationPage(
                                                      documentSnapshot:
                                                          documentSnapshot,
                                                    )));
                                      },
                                    ),
                                  if (documentSnapshot['status'] == 'selesai')
                                    BottomBar(
                                      text: 'Selesai',
                                      color: kDisabledColor,
                                      onTap: () => Navigator.popAndPushNamed(
                                          context, PageRoutes.acceptedPage),
                                    ),
                                ],
                              );
                            },
                            itemCount: snapshot.data?.docs.length,
                          );
                        }),
                  ),
          ],
        ),
      ),
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> update(
      [DocumentSnapshot? documentSnapshot, context]) async {
    // if (documentSnapshot != null) {}

    // update trips customers
    final res2 = await FirebaseFirestore.instance
        .collection('trips2')
        .doc('customer_id_${documentSnapshot!['customer_id']}')
        .collection('trip')
        .where('order_id', isEqualTo: documentSnapshot['order_id'])
        .get();

    final DocumentSnapshot data = res2.docs[0];

    await FirebaseFirestore.instance
        .collection('trips2')
        .doc('customer_id_${documentSnapshot['customer_id']}')
        .collection('trip')
        .doc(data.id)
        .update({
      'status': 'diterima',
      'driver_id': driver!.id.toString(),
      "latitude_current_driver": double.parse(driver!.latitude!),
      "longitude_current_driver": double.parse(driver!.longitude!),
      "name_driver": driver!.name,
      "name_vehicle_driver": driver!.name_vehicle_driver,
      "nohp_driver": driver!.nohp,
      "nopol_vehicle_driver": driver!.registrationNumber,
    }).catchError((error) => showCustomSnackbar(context, error.toString()));

    // add trips driver
    final res1 = await FirebaseFirestore.instance
        .collection('trips2')
        .doc('driver_id_${driver!.id.toString()}')
        .collection('trip')
        .add({
      "order_id": documentSnapshot!['order_id'],
      "driver_id": driver!.id,
      "nohp_driver": driver!.nohp,
      "latitude_current_driver": double.parse(driver!.latitude!),
      "longitude_current_driver": double.parse(driver!.longitude!),
      "name_vehicle_driver": driver!.name_vehicle_driver,
      "nopol_vehicle_driver": driver!.registrationNumber,
      "name_driver": driver!.name,
      "date": documentSnapshot['date'],
      "status": "lanjut",
      "type_order": documentSnapshot['type_order'],
    }).catchError((error) => showCustomSnackbar(context, error.toString()));

    await res1.collection('customers').add({
      "price_trip": documentSnapshot['price_trip'],
      "date": documentSnapshot['date'],
      "name_customer": documentSnapshot['name_customer'],
      "distance": documentSnapshot['distance'],
      "status_payment": documentSnapshot['status_payment'],
      "payment_method": documentSnapshot['payment_method'],
      "order_id": documentSnapshot!['order_id'],
      "nohp_customer": documentSnapshot['nohp_customer'],
      "latitude_current_customer":
          documentSnapshot['latitude_current_customer'],
      "longitude_current_customer":
          documentSnapshot['longitude_current_customer'],
      "address_current_customer": documentSnapshot['address_current_customer'],
      "city_current_customer": documentSnapshot['city_current_customer'],
      "province_current_customer":
          documentSnapshot['province_current_customer'],
      "latitude_destination": documentSnapshot['latitude_destination'],
      "longitude_destination": documentSnapshot['longitude_destination'],
      "address_destination": documentSnapshot['address_destination'],
      "city_destination": documentSnapshot['city_destination'],
      "province_destination": documentSnapshot['province_destination'],
      "status": 'diterima',
      "customer_id": documentSnapshot['customer_id'],
    });

    return res1.get();
    // setState(() {
    //   isLoading = false;
    // });

    // // hapus notif trips driver
    // final deleteNotifDriver = await FirebaseFirestore.instance
    //     .collection('notif_trips2')
    //     .where('order_id', isEqualTo: documentSnapshot['order_id'])
    //     .get();

    // for (var doc in deleteNotifDriver.docs) {
    //   await doc.reference.delete();
    // }
  }
}
