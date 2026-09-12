import 'dart:async';
import 'dart:convert';
import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliq_delivery/Account/UI/account_page.dart';
import 'package:deliq_delivery/Components/bottom_bar.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/OrderMap/UI/delivery_successful.dart';
import 'package:deliq_delivery/services/auth_service.dart';
import 'package:deliq_delivery/services/shared_services.dart';
import 'package:http/http.dart' as http;

import 'package:deliq_delivery/OrderMapBloc/order_map_bloc.dart';
import 'package:deliq_delivery/OrderMapBloc/order_map_state.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/map_utils.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:deliq_delivery/shared/shared_values.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:deliq_delivery/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';

class OnWayToDestinationPageCopy extends StatelessWidget {
  final DocumentSnapshot? documentSnapshot;
  const OnWayToDestinationPageCopy({super.key, this.documentSnapshot});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderMapBloc>(
      create: (context) => OrderMapBloc()..loadMap(),
      child: OnWayToDestinationBody(
        documentSnapshot: documentSnapshot,
      ),
    );
  }
}

class OnWayToDestinationBody extends StatefulWidget {
  final DocumentSnapshot? documentSnapshot;
  const OnWayToDestinationBody({super.key, this.documentSnapshot});

  @override
  OnWayBodyToDestinationState createState() => OnWayBodyToDestinationState();
}

class OnWayBodyToDestinationState extends State<OnWayToDestinationBody> {
  // final Completer<GoogleMapController> _mapController = Completer();
  final locationController = Location();

  GoogleMapController? mapStyleController;
  bool isLoading = false;

  UserModel? driver;

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
    // WidgetsBinding.instance
    //     .addPostFrameCallback((_) async => await fetchLocationUpdate());
  }

  List<String> itemName = [
    'Fresh Red Onions',
    'Fresh Cauliflower',
    'Fresh Cauliflower',
  ];

  bool isOpen = false;

  Completer<GoogleMapController> _googleMapController = Completer();

  Future<Map<PolylineId, Polyline>> buildwidget(
      DocumentSnapshot doc, DocumentSnapshot data) async {
    List<LatLng> polylineCoordinates = [];
    Map<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{};
    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        GOOGLE_API_KEY,
        PointLatLng(
            doc['latitude_current_driver'], doc['longitude_current_driver']),
        PointLatLng(
            data!['latitude_destination'], data!['longitude_destination']));
    if (result.points.isNotEmpty) {
      result.points.forEach(
        (PointLatLng point) => polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        ),
      );
    }

    final Polyline polyline = Polyline(
        polylineId: PolylineId('polyline-destination'),
        consumeTapEvents: true,
        points: polylineCoordinates,
        color: kMainColor,
        width: 4,
        onTap: () {});
    polyLines[PolylineId('polyline-destination')] = polyline;

    return polyLines;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: const Account(),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: AppBar(
              title: Text(AppLocalizations.of(context)!.newDeliveryTask!,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium!
                      .copyWith(fontWeight: FontWeight.w500)),
              // actions: <Widget>[
              //   Padding(
              //     padding: const EdgeInsets.symmetric(
              //         vertical: 8.0, horizontal: 20.0),
              //     child: TextButton.icon(
              //       icon: Icon(
              //         isOpen ? Icons.close : Icons.shopping_basket,
              //         color: kMainColor,
              //         size: 13.0,
              //       ),
              //       label: Text(
              //           isOpen
              //               ? AppLocalizations.of(context)!.close!
              //               : AppLocalizations.of(context)!.orderInfo!,
              //           style: Theme.of(context).textTheme.bodySmall!.copyWith(
              //                 fontSize: 11.7,
              //                 fontWeight: FontWeight.bold,
              //               )),
              //       onPressed: () {
              //         setState(() {
              //           if (isOpen) {
              //             isOpen = false;
              //           } else {
              //             isOpen = true;
              //           }
              //         });
              //       },
              //     ),
              //   )
              // ],
            ),
          ),
        ),
        body: FadedSlideAnimation(
          beginOffset: const Offset(0, 0.3),
          endOffset: const Offset(0, 0),
          slideCurve: Curves.linearToEaseOut,
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Stack(
                  children: <Widget>[
                    StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('orders')
                            .doc(widget.documentSnapshot!.id)
                            .snapshots(),
                        builder: (context, snapshot) {
                          fetchLocationUpdate();
                          if (!snapshot.hasData) {
                            return Center(
                              child: Text('data tidak ditemukan'),
                            );
                          }

                          final doc = snapshot.data;

                          if (doc != null) {
                            return StreamBuilder(
                                stream: FirebaseFirestore.instance
                                    .collection('order_customers')
                                    .where('order_id',
                                        isEqualTo: widget.documentSnapshot!.id)
                                    .snapshots(),
                                builder: (context, snap) {
                                  final data = snap.data?.docs[0];

                                  if (data != null) {
                                    LatLng? currentPosition = LatLng(
                                        doc['latitude_current_driver'],
                                        doc['longitude_current_driver']);

                                    final Set<Marker> _markers = {};

                                    _markers.add(
                                      Marker(
                                        markerId: const MarkerId('mark1'),
                                        position: currentPosition!,
                                        rotation: doc['heading'],
                                        icon: driver!.vehicletype == 'Motor' ||
                                                driver!.vehicletype == 'motor'
                                            ? markerss.first
                                            : markerss[1],
                                      ),
                                    );
                                    _markers.add(
                                      Marker(
                                        markerId: const MarkerId('mark2'),
                                        position: LatLng(
                                            data!['latitude_destination'],
                                            data!['longitude_destination']),
                                        icon: markerss.last,
                                      ),
                                    );

                                    moveToPosition(doc);

                                    CameraPosition cameraPosition =
                                        CameraPosition(
                                      target: LatLng(
                                          doc['latitude_current_driver'],
                                          doc['longitude_current_driver']),
                                      zoom: 16,
                                    );

                                    print('nasib');

                                    return isLoading
                                        ? Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : FutureBuilder(
                                            future: buildwidget(doc, data),
                                            builder: (context, snap) {
                                              if (snap.data != null) {
                                                return Column(
                                                  children: <Widget>[
                                                    Expanded(
                                                      child: BlocBuilder<
                                                              OrderMapBloc,
                                                              OrderMapState>(
                                                          builder:
                                                              (context, state) {
                                                        return GoogleMap(
                                                          zoomControlsEnabled:
                                                              false,
                                                          polylines:
                                                              Set<Polyline>.of(
                                                                  snap.data!
                                                                      .values),
                                                          mapType:
                                                              MapType.normal,
                                                          initialCameraPosition:
                                                              cameraPosition,
                                                          markers: _markers,
                                                          onMapCreated:
                                                              (GoogleMapController
                                                                  controller) {
                                                            if (!_googleMapController
                                                                .isCompleted) {
                                                              _googleMapController
                                                                  .complete(
                                                                      controller);
                                                            }
                                                          },
                                                        );
                                                      }),
                                                    ),
                                                    Align(
                                                      alignment: Alignment
                                                          .bottomCenter,
                                                      child: Column(
                                                        children: <Widget>[
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .end,
                                                            children: [
                                                              GestureDetector(
                                                                onTap: () {
                                                                  navigateMaps(
                                                                      data);
                                                                },
                                                                child: Padding(
                                                                  padding: const EdgeInsets
                                                                      .only(
                                                                      top: 0.0,
                                                                      left: 0.0,
                                                                      right:
                                                                          0.0,
                                                                      bottom:
                                                                          0.0),
                                                                  child: CircleAvatar(
                                                                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                                                      child: Image.asset(
                                                                        'images/google-maps.png',
                                                                        height:
                                                                            20,
                                                                      )),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        16.3),
                                                            child: Row(
                                                              children: <Widget>[
                                                                doc['type_order'] ==
                                                                        'motor'
                                                                    ? Image
                                                                        .asset(
                                                                        'images/bike1.png',
                                                                        height:
                                                                            42.3,
                                                                        width:
                                                                            33.7,
                                                                      )
                                                                    : Image
                                                                        .asset(
                                                                        'images/image1.png',
                                                                        height:
                                                                            42.3,
                                                                        width:
                                                                            33.7,
                                                                      ),
                                                                Expanded(
                                                                  child:
                                                                      ListTile(
                                                                    title: Text(
                                                                      doc['type_order'],
                                                                      style: Theme.of(
                                                                              context)
                                                                          .textTheme
                                                                          .bodySmall!
                                                                          .copyWith(
                                                                              letterSpacing: 0.07,
                                                                              fontWeight: FontWeight.bold),
                                                                    ),
                                                                    subtitle:
                                                                        Row(
                                                                      children: <Widget>[
                                                                        Text(
                                                                          data[
                                                                              'distance'],
                                                                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                                                              fontSize: 11.7,
                                                                              letterSpacing: 0.06,
                                                                              color: kMainColor,
                                                                              fontWeight: FontWeight.bold),
                                                                        ),
                                                                        // Text(
                                                                        //   '(20 min)',
                                                                        //   style: Theme.of(context)
                                                                        //       .textTheme
                                                                        //       .titleLarge!
                                                                        //       .copyWith(
                                                                        //           fontSize: 11.7,
                                                                        //           letterSpacing: 0.06,
                                                                        //           color: const Color(
                                                                        //               0xffc1c1c1)),
                                                                        // ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                                // TextButton(
                                                                //   onPressed: () {/*....*/},
                                                                //   child: Row(
                                                                //     children: <Widget>[
                                                                //       Icon(
                                                                //         Icons.navigation,
                                                                //         color: kMainColor,
                                                                //         size: 14.0,
                                                                //       ),
                                                                //       const SizedBox(
                                                                //         width: 8.0,
                                                                //       ),
                                                                //       Text(
                                                                //         AppLocalizations.of(context)!
                                                                //             .direction!,
                                                                //         style: Theme.of(context)
                                                                //             .textTheme
                                                                //             .bodySmall!
                                                                //             .copyWith(
                                                                //                 color: kMainColor,
                                                                //                 fontWeight: FontWeight.bold,
                                                                //                 fontSize: 11.7,
                                                                //                 letterSpacing: 0.06),
                                                                //       ),
                                                                //     ],
                                                                //   ),
                                                                // ),

                                                                Text(
                                                                  formatCurrency(
                                                                      data[
                                                                          'price_trip']),
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .bodySmall!
                                                                      .copyWith(
                                                                          color:
                                                                              kMainColor,
                                                                          fontWeight: FontWeight
                                                                              .bold,
                                                                          fontSize:
                                                                              11.7,
                                                                          letterSpacing:
                                                                              0.06),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Divider(
                                                            color:
                                                                kCardBackgroundColor,
                                                            thickness: 1.0,
                                                          ),
                                                          Row(
                                                            children: <Widget>[
                                                              Padding(
                                                                  padding: const EdgeInsets
                                                                      .only(
                                                                      left:
                                                                          28.0,
                                                                      bottom:
                                                                          6.0,
                                                                      top: 6.0,
                                                                      right:
                                                                          10.0),
                                                                  child: Icon(
                                                                    Icons
                                                                        .location_on,
                                                                    size: 14.0,
                                                                    color:
                                                                        kMainColor,
                                                                  )),
                                                              Expanded(
                                                                flex: 5,
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: <Widget>[
                                                                    Text(
                                                                      data[
                                                                          'address_destination'],
                                                                      style: Theme.of(
                                                                              context)
                                                                          .textTheme
                                                                          .bodySmall!
                                                                          .copyWith(
                                                                              letterSpacing: 0.05,
                                                                              fontWeight: FontWeight.bold),
                                                                    ),
                                                                    const SizedBox(
                                                                      height:
                                                                          5.0,
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
                                                              ),
                                                              const Spacer(),
                                                              // Padding(
                                                              //   padding: const EdgeInsets.symmetric(
                                                              //       horizontal: 4.0),
                                                              //   child: FittedBox(
                                                              //     fit: BoxFit.fill,
                                                              //     child: Row(
                                                              //       children: <Widget>[
                                                              //         IconButton(
                                                              //           icon: Icon(
                                                              //             Icons.message,
                                                              //             color: kMainColor,
                                                              //             size: 14.0,
                                                              //           ),
                                                              //           onPressed: () {
                                                              //             Navigator.pushNamed(
                                                              //                 context, PageRoutes.chatPage);
                                                              //           },
                                                              //         ),
                                                              //         IconButton(
                                                              //           icon: Icon(
                                                              //             Icons.phone,
                                                              //             color: kMainColor,
                                                              //             size: 14.0,
                                                              //           ),
                                                              //           onPressed: () {
                                                              //             /*..........*/
                                                              //           },
                                                              //         ),
                                                              //       ],
                                                              //     ),
                                                              //   ),
                                                              // ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 20.0,
                                                          ),
                                                          Row(
                                                            children: <Widget>[
                                                              Padding(
                                                                  padding: const EdgeInsets
                                                                      .only(
                                                                      left:
                                                                          28.0,
                                                                      bottom:
                                                                          12.0,
                                                                      top: 12.0,
                                                                      right:
                                                                          10.0),
                                                                  child: Icon(
                                                                    Icons
                                                                        .navigation,
                                                                    size: 14.0,
                                                                    color:
                                                                        kMainColor,
                                                                  )),
                                                              Expanded(
                                                                flex: 5,
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: <Widget>[
                                                                    Text(
                                                                      data[
                                                                          'address_current_customer'],
                                                                      style: Theme.of(
                                                                              context)
                                                                          .textTheme
                                                                          .bodySmall!
                                                                          .copyWith(
                                                                              letterSpacing: 0.05,
                                                                              fontWeight: FontWeight.bold),
                                                                    ),
                                                                    const SizedBox(
                                                                      height:
                                                                          5.0,
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
                                                              ),
                                                              const Spacer(),
                                                              // Padding(
                                                              //   padding: const EdgeInsets.symmetric(
                                                              //       horizontal: 4.0),
                                                              //   child: FittedBox(
                                                              //     fit: BoxFit.fill,
                                                              //     child: Row(
                                                              //       children: <Widget>[
                                                              //         IconButton(
                                                              //           icon: Icon(
                                                              //             Icons.message,
                                                              //             color: kMainColor,
                                                              //             size: 14.0,
                                                              //           ),
                                                              //           onPressed: () {
                                                              //             Navigator.pushNamed(
                                                              //                 context, PageRoutes.chatPage);
                                                              //           },
                                                              //         ),
                                                              //         IconButton(
                                                              //           icon: Icon(
                                                              //             Icons.phone,
                                                              //             color: kMainColor,
                                                              //             size: 14.0,
                                                              //           ),
                                                              //           onPressed: () {
                                                              //             /*...........*/
                                                              //           },
                                                              //         ),
                                                              //       ],
                                                              //     ),
                                                              //   ),
                                                              // ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 10.0,
                                                          ),
                                                          BottomBar(
                                                              text: 'Selesai',
                                                              onTap: () async {
                                                                setState(() {
                                                                  isLoading =
                                                                      true;
                                                                });
                                                                await update(
                                                                    data);
                                                                await updateSaldo(
                                                                    data);
                                                              }),
                                                        ],
                                                      ),
                                                    )
                                                  ],
                                                );
                                              }

                                              return const SizedBox();
                                            });
                                  }

                                  return const SizedBox();
                                });
                          }

                          return const SizedBox();
                        }),
                    // isOpen ? OrderInfoContainer(itemName) : const SizedBox.shrink(),
                  ],
                ),
        ));
  }

  Future<void> fetchLocationUpdate() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    serviceEnabled = await locationController.serviceEnabled();
    if (serviceEnabled) {
      serviceEnabled = await locationController.requestService();
    } else {
      return;
    }

    permissionGranted = await locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    locationController.onLocationChanged.listen((currentLocation) async {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        final res2 = await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.documentSnapshot!.id)
            .update({
          "latitude_current_driver": currentLocation.latitude,
          "longitude_current_driver": currentLocation.longitude,
          "heading": currentLocation.heading
        });

        // getPolyPoints();
      }
    });
  }

  Future<void> update(DocumentSnapshot customer) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.documentSnapshot!.id)
        .update({
      'status': 'selesai',
    });

    await FirebaseFirestore.instance
        .collection('order_customers')
        .doc(customer.id)
        .update({
      'status': 'selesai',
    });
  }

  moveToPosition(doc) async {
    GoogleMapController mapController = await _googleMapController.future;
    print('selesai');
    mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(
            doc['latitude_current_driver'], doc['longitude_current_driver']),
        zoom: 18)));
  }

  Future<void> updateSaldo(DocumentSnapshot documentSnapshot) async {
    final token = await AuthService().getToken();

    if (documentSnapshot['payment_method'] == 'cash' ||
        documentSnapshot['payment_method'] == 'Tunai') {
      num? prices = documentSnapshot['price_trip'] * 11 / 100;
      num? saldo =
          driver!.balance! - (documentSnapshot['price_trip'] * 11 / 100);
      final res = await http.post(Uri.parse('$baseUrl/drivers/update'), body: {
        'id': driver!.id.toString(),
        'balance': saldo.floor().toString(),
      }, headers: {
        'Authorization': token,
      });
      if (res.statusCode == 200) {
        driver!.copyWith(balance: saldo.floor());
        await SharedServices().addTransaction(
            driver!.id.toString(),
            prices.toString(),
            'masuk',
            'motor',
            widget.documentSnapshot!['payment_method']);
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) =>
        //         DeliverySuccessful(documentSnapshot: documentSnapshot),
        //   ),
        // );
        return jsonDecode(res.body)['data'];
      }
    }

    if (documentSnapshot['payment_method'] == 'Saldo') {
      num? prices = (documentSnapshot['price_trip'] -
          (documentSnapshot['price_trip'] * 11 / 100));
      num? saldo = driver!.balance! + prices!;

      await SharedServices()
          .updateSaldoDriver(driver!.id.toString(), saldo.toString());
      await SharedServices().addTransaction(
          driver!.id.toString(),
          prices.toString(),
          'masuk',
          'motor',
          widget.documentSnapshot!['payment_method']);
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => DeliverySuccessful(
      //       documentSnapshot: documentSnapshot,
      //     ),
      //   ),
      // );
    }
  }

  Future<void> navigateMaps(data) async {
    await launchUrl(Uri.parse(
        'google.navigation:q=${data['latitude_destination']}, ${data['longitude_destination']}&key=${GOOGLE_API_KEY}'));
  }
}
