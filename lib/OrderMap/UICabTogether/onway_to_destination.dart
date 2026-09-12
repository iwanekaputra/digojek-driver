import 'dart:async';
import 'dart:convert';
import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliq_delivery/Account/UI/account_page.dart';
import 'package:deliq_delivery/Components/bottom_bar.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/OrderMap/UI/delivery_successful.dart';
import 'package:deliq_delivery/services/auth_service.dart';
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

class OnWayToDestinationPage extends StatelessWidget {
  final DocumentSnapshot? documentSnapshot;
  const OnWayToDestinationPage({super.key, this.documentSnapshot});

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
  List<LatLng> polylineCoordinates = [];

  final Set<Marker> _markers = {};
  LatLng? currentPosition;
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
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await fetchLocationUpdate());
  }

  List<String> itemName = [
    'Fresh Red Onions',
    'Fresh Cauliflower',
    'Fresh Cauliflower',
  ];

  bool isOpen = false;

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
          child: Stack(
            children: <Widget>[
              StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('trips2')
                      .doc('driver_id_${widget.documentSnapshot!['driver_id']}')
                      .collection('trip')
                      .where('order_id',
                          isEqualTo: widget.documentSnapshot!['order_id'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: Text('data tidak ditemukan'),
                      );
                    }

                    final data = snapshot.data!.docs[0];

                    return currentPosition == null
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : isLoading
                            ? Center(
                                child: CircularProgressIndicator(),
                              )
                            : Column(
                                children: <Widget>[
                                  Expanded(
                                    child: BlocBuilder<OrderMapBloc,
                                            OrderMapState>(
                                        builder: (context, state) {
                                      return GoogleMap(
                                        zoomControlsEnabled: false,
                                        polylines: {
                                          Polyline(
                                              polylineId:
                                                  const PolylineId('route'),
                                              points: polylineCoordinates,
                                              color: kMainColor)
                                        },
                                        mapType: MapType.normal,
                                        initialCameraPosition: CameraPosition(
                                          target: currentPosition!,
                                          zoom: 13,
                                        ),
                                        markers: _markers,
                                        onMapCreated: (GoogleMapController
                                            controller) async {
                                          // _mapController.complete(controller);
                                          mapStyleController = controller;
                                          // mapStyleController!.setMapStyle(mapStyle);
                                          setState(() {
                                            _markers.add(
                                              Marker(
                                                  markerId:
                                                      const MarkerId('mark1'),
                                                  position: currentPosition!,
                                                  icon: driver!.vehicletype ==
                                                              'Motor' ||
                                                          driver!.vehicletype ==
                                                              'motor'
                                                      ? markerss.first
                                                      : markerss[1]),
                                            );
                                            _markers.add(
                                              Marker(
                                                markerId:
                                                    const MarkerId('mark2'),
                                                position: LatLng(
                                                    data[
                                                        'latitude_destination'],
                                                    data[
                                                        'longitude_destination']),
                                                icon: markerss.last,
                                              ),
                                            );
                                            // _markers.add(
                                            //   Marker(
                                            //     markerId: MarkerId('mark3'),
                                            //     position:
                                            //         LatLng(37.42196183580660, -122.089743655967),
                                            //     icon: markerss[0],
                                            //   ),
                                            // );
                                          });
                                        },
                                      );
                                    }),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Column(
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.3),
                                          child: Row(
                                            children: <Widget>[
                                              Image.asset(
                                                'images/bike1.png',
                                                height: 42.3,
                                                width: 33.7,
                                              ),
                                              Expanded(
                                                child: ListTile(
                                                  title: Text(
                                                    'mobil',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall!
                                                        .copyWith(
                                                            letterSpacing: 0.07,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                  ),
                                                  subtitle: Row(
                                                    children: <Widget>[
                                                      Text(
                                                        data['distance'],
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleLarge!
                                                            .copyWith(
                                                                fontSize: 11.7,
                                                                letterSpacing:
                                                                    0.06,
                                                                color:
                                                                    kMainColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
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
                                                    data['price_trip']),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall!
                                                    .copyWith(
                                                        color: kMainColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 11.7,
                                                        letterSpacing: 0.06),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Divider(
                                          color: kCardBackgroundColor,
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
                                            Expanded(
                                              flex: 5,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    data['address_destination'],
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall!
                                                        .copyWith(
                                                            letterSpacing: 0.05,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
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
                                            Expanded(
                                              flex: 5,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    data[
                                                        'address_current_customer'],
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall!
                                                        .copyWith(
                                                            letterSpacing: 0.05,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
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
                                                isLoading = true;
                                              });
                                              await update(data);
                                              await updateSaldo(data);
                                              if (mounted) {
                                                setState(() {
                                                  isLoading = false;
                                                });
                                              }

                                              // Navigator.pushAndRemoveUntil(
                                              //     context,
                                              //     MaterialPageRoute(
                                              //         builder: (context) =>
                                              //             DeliverySuccessful(
                                              //               documentSnapshot:
                                              //                   data,
                                              //             )),
                                              //     (route) => false);
                                              // Navigator.pushAndRemoveUntil(
                                              //     context,
                                              //     MaterialPageRoute(
                                              //         builder: (context) =>
                                              //             DeliverySuccessful(
                                              //               documentSnapshot:
                                              //                   data,
                                              //             )),
                                              //     (route) => false);
                                            }),
                                      ],
                                    ),
                                  )
                                ],
                              );
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
        if (mounted) {
          setState(() {
            currentPosition =
                LatLng(currentLocation.latitude!, currentLocation.longitude!);
          });
        }

        final res2 = await FirebaseFirestore.instance
            .collection('trips2')
            .doc('customer_id_${widget.documentSnapshot!['customer_id']}')
            .collection('trip')
            .where('order_id', isEqualTo: widget.documentSnapshot!['order_id'])
            .get();

        final DocumentSnapshot data = res2.docs[0];

        await FirebaseFirestore.instance
            .collection('trips2')
            .doc('customer_id_${widget.documentSnapshot!['customer_id']}')
            .collection('trip')
            .doc(data.id)
            .update({
          'latitude_current_driver': currentLocation.latitude,
          "longitude_current_driver": currentLocation.longitude
        });

        // getPolyPoints();
      }
    });
  }

  Future<void> update(DocumentSnapshot documentSnapshot) async {
    await FirebaseFirestore.instance
        .collection('trips2')
        .doc('driver_id_${documentSnapshot['driver_id']}')
        .collection('trip')
        .doc(documentSnapshot.id)
        .update({
      'status': 'selesai',
    });

    final res2 = await FirebaseFirestore.instance
        .collection('trips2')
        .doc('customer_id_${widget.documentSnapshot!['customer_id']}')
        .collection('trip')
        .where('order_id', isEqualTo: widget.documentSnapshot!['order_id'])
        .get();

    final DocumentSnapshot data = res2.docs[0];

    await FirebaseFirestore.instance
        .collection('trips2')
        .doc('customer_id_${widget.documentSnapshot!['customer_id']}')
        .collection('trip')
        .doc(data.id)
        .update({"status": 'selesai'});
  }

  Future<void> updateSaldo(DocumentSnapshot documentSnapshot) async {
    final token = await AuthService().getToken();

    if (documentSnapshot['payment_method'] == 'cash' ||
        documentSnapshot['payment_method'] == 'tunai') {
      num? saldo =
          driver!.balance! - (documentSnapshot['price_trip'] * 10 / 100);
      final res = await http.post(Uri.parse('$baseUrl/drivers/update'), body: {
        'id': driver!.id.toString(),
        'balance': saldo.floor().toString(),
      }, headers: {
        'Authorization': token,
      });

      if (res.statusCode == 200) {
        print(saldo.floor());
        print(driver!.balance);
        driver!.copyWith(balance: saldo.floor());
        print(driver!.balance);
        return jsonDecode(res.body)['data'];
      }
    }
  }

  Future<void> getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        GOOGLE_API_KEY,
        PointLatLng(currentPosition!.latitude, currentPosition!.longitude),
        PointLatLng(widget.documentSnapshot!['latitude_destination'],
            widget.documentSnapshot!['longitude_destination']));

    if (result.points.isNotEmpty) {
      result.points.forEach(
        (PointLatLng point) => polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        ),
      );

      setState(() {});
    }
  }
}
