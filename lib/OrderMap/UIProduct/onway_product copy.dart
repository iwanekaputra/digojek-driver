import 'dart:async';

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliq_delivery/Account/UI/account_page.dart';
import 'package:deliq_delivery/Chat/UI/chat_page.dart';
import 'package:deliq_delivery/Components/bottom_bar.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/OrderMap/UI/onway_to_destination.dart';
import 'package:deliq_delivery/OrderMap/UI/slide_up_panel.dart';
import 'package:deliq_delivery/OrderMap/UIProduct/onway_product_to_destination.dart';
// import 'package:deliq_delivery/OrderMap/UI/slide_up_panel.dart';
import 'package:deliq_delivery/OrderMapBloc/order_map_bloc.dart';
// import 'package:deliq_delivery/OrderMapBloc/order_map_state.dart';
// import 'package:deliq_delivery/Routes/routes.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/map_utils.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:deliq_delivery/shared/shared_values.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class OnWayProductPageCopy extends StatelessWidget {
  final DocumentSnapshot? documentSnapshot;
  const OnWayProductPageCopy({super.key, this.documentSnapshot});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderMapBloc>(
      create: (context) => OrderMapBloc()..loadMap(),
      child: OnWayProductBody(
        documentSnapshot: documentSnapshot,
      ),
    );
  }
}

class OnWayProductBody extends StatefulWidget {
  final DocumentSnapshot? documentSnapshot;
  const OnWayProductBody({super.key, this.documentSnapshot});

  @override
  OnWayProductBodyState createState() => OnWayProductBodyState();
}

class OnWayProductBodyState extends State<OnWayProductBody> {
  // final Completer<GoogleMapController> _mapController = Completer();
  final locationController = Location();

  GoogleMapController? mapStyleController;
  List<LatLng> polylineCoordinates = [];

  List listProducts = [];
  List listMerchants = [];

  @override
  void initState() {
    rootBundle.loadString('images/map_style.txt').then((string) {
      mapStyle = string;
    });
    super.initState();
    // WidgetsBinding.instance
    //     .addPostFrameCallback((_) async => await fetchLocationUpdate());
    getProducts();
  }

  Future<void> getProducts() async {
    final res = await FirebaseFirestore.instance
        .collection('order_products')
        .where('order_id', isEqualTo: widget.documentSnapshot!.id)
        .get();
    final res2 = await FirebaseFirestore.instance
        .collection('order_merchants')
        .where('order_id', isEqualTo: widget.documentSnapshot!.id)
        .get();

    setState(() {
      listProducts = res.docs as List;
      listMerchants = res2.docs as List;
    });
  }

  List<String> itemName = [
    'Fresh Red Onions',
    'Fresh Cauliflower',
    'Fresh Cauliflower',
  ];

  bool isOpen = false;
  Future<Map<PolylineId, Polyline>> buildwidget(
      merchant, DocumentSnapshot<Object?> order, customer) async {
    Map<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{};
    PolylinePoints polylinePoints = PolylinePoints();
    List<LatLng> polylineCoordinates2 = [];

    for (var i = 0; i < merchant.length; i++) {
      List<LatLng> polylineCoordinates = [];

      // line customer
      await Future.delayed(Duration(seconds: 1));
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          GOOGLE_API_KEY,
          PointLatLng(order['latitude_current_driver'],
              order['longitude_current_driver']),
          PointLatLng(merchant[i]['latitude_current_merchant'],
              merchant[i]['longitude_current_merchant']));
      if (result.points.isNotEmpty) {
        result.points.forEach(
          (PointLatLng point) => polylineCoordinates.add(
            LatLng(point.latitude, point.longitude),
          ),
        );
      }

      final Polyline polyline = Polyline(
          polylineId: PolylineId('polyline${i.toString()}'),
          consumeTapEvents: true,
          points: polylineCoordinates,
          color: kMainColor,
          width: 4,
          onTap: () {});

      polyLines[PolylineId('polyline${i.toString()}')] = polyline;
    }

    // line destination
    await Future.delayed(Duration(seconds: 1));
    PolylineResult result2 = await polylinePoints.getRouteBetweenCoordinates(
        GOOGLE_API_KEY,
        PointLatLng(order['latitude_current_driver'],
            order['longitude_current_driver']),
        PointLatLng(customer['latitude_current_customer'],
            customer['longitude_current_customer']));
    if (result2.points.isNotEmpty) {
      result2.points.forEach(
        (PointLatLng point) => polylineCoordinates2.add(
          LatLng(point.latitude, point.longitude),
        ),
      );
    }

    final Polyline polyline2 = Polyline(
        polylineId: PolylineId('polyline-oke-4'),
        consumeTapEvents: true,
        points: polylineCoordinates2,
        color: kMainColor,
        width: 4,
        onTap: () {});

    polyLines[PolylineId('polyline-oke-4')] = polyline2;

    return polyLines;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: const AccountPageBody(),
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
              actions: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 20.0),
                  child: TextButton.icon(
                    icon: Icon(
                      isOpen ? Icons.close : Icons.shopping_basket,
                      color: kMainColor,
                      size: 13.0,
                    ),
                    label: Text(
                        isOpen
                            ? AppLocalizations.of(context)!.close!
                            : AppLocalizations.of(context)!.orderInfo!,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              fontSize: 11.7,
                              fontWeight: FontWeight.bold,
                            )),
                    onPressed: () {
                      setState(() {
                        if (isOpen) {
                          isOpen = false;
                        } else {
                          isOpen = true;
                        }
                      });
                    },
                  ),
                )
              ],
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
                      .collection('orders')
                      .doc(widget.documentSnapshot!.id)
                      .snapshots(),
                  builder: (context, snapshot) {
                    // fetchLocationUpdate();
                    if (!snapshot.hasData) {
                      return const Center(
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
                              return StreamBuilder(
                                  stream: FirebaseFirestore.instance
                                      .collection('order_merchants')
                                      .where('order_id',
                                          isEqualTo:
                                              widget.documentSnapshot!.id)
                                      .snapshots(),
                                  builder: (context, snaps) {
                                    final merchants = snaps.data?.docs;
                                    if (merchants != null) {
                                      return StreamBuilder(
                                          stream: FirebaseFirestore.instance
                                              .collection('order_products')
                                              .where('order_id',
                                                  isEqualTo: widget
                                                      .documentSnapshot!.id)
                                              .snapshots(),
                                          builder: (context, snapsho) {
                                            final products = snapsho.data?.docs;
                                            if (products != null) {
                                              LatLng? currentPosition = LatLng(
                                                  doc![
                                                      'latitude_current_driver'],
                                                  doc![
                                                      'longitude_current_driver']);

                                              final Set<Marker> _markers = {};

                                              _markers.add(
                                                Marker(
                                                  markerId:
                                                      const MarkerId('mark1'),
                                                  position: currentPosition!,
                                                  icon: markerss.first,
                                                ),
                                              );

                                              _markers.add(
                                                Marker(
                                                  markerId:
                                                      const MarkerId('mark2'),
                                                  position: LatLng(
                                                      data![
                                                          'latitude_current_customer'],
                                                      data[
                                                          'longitude_current_customer']),
                                                  icon: markerss.last,
                                                ),
                                              );

                                              for (var i = 0;
                                                  i < merchants.length;
                                                  i++) {
                                                _markers.add(
                                                  Marker(
                                                      markerId: MarkerId(
                                                          'mark-merchant-${i.toString()}'),
                                                      position: LatLng(
                                                          merchants[i][
                                                              'latitude_current_merchant'],
                                                          merchants[i][
                                                              'longitude_current_merchant']),
                                                      icon: BitmapDescriptor
                                                          .defaultMarker),
                                                );
                                              }
                                              return FutureBuilder(
                                                  future: buildwidget(
                                                      merchants, doc, data),
                                                  builder: ((context, snap) {
                                                    if (snap.data != null) {
                                                      return Column(
                                                        children: <Widget>[
                                                          Expanded(
                                                            child: GoogleMap(
                                                              zoomControlsEnabled:
                                                                  false,
                                                              polylines: Set<
                                                                      Polyline>.of(
                                                                  snap.data!
                                                                      .values),
                                                              mapType: MapType
                                                                  .normal,
                                                              initialCameraPosition:
                                                                  CameraPosition(
                                                                target:
                                                                    currentPosition!,
                                                                zoom: 16,
                                                              ),
                                                              markers: _markers,
                                                              onMapCreated:
                                                                  (GoogleMapController
                                                                      controller) async {
                                                                // _mapController.complete(controller);
                                                                mapStyleController =
                                                                    controller;
                                                                // mapStyleController!.setMapStyle(mapStyle);
                                                              },
                                                            ),
                                                          ),
                                                          Align(
                                                            alignment: Alignment
                                                                .bottomCenter,
                                                            child: Column(
                                                              children: <Widget>[
                                                                Padding(
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          16.3),
                                                                  child: Row(
                                                                    children: <Widget>[
                                                                      Image
                                                                          .asset(
                                                                        'images/bike1.png',
                                                                        height:
                                                                            42.3,
                                                                        width:
                                                                            33.7,
                                                                      ),

                                                                      Expanded(
                                                                        child:
                                                                            ListTile(
                                                                          title:
                                                                              Text(
                                                                            data['type_order'],
                                                                            style:
                                                                                Theme.of(context).textTheme.bodySmall!.copyWith(letterSpacing: 0.07, fontWeight: FontWeight.bold),
                                                                          ),
                                                                          subtitle:
                                                                              Row(
                                                                            children: <Widget>[
                                                                              Text(
                                                                                data['distance'],
                                                                                style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 11.7, letterSpacing: 0.06, color: kMainColor, fontWeight: FontWeight.bold),
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
                                                                            doc['price_trip']),
                                                                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
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
                                                                  thickness:
                                                                      1.0,
                                                                ),
                                                                Padding(
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          16.3),
                                                                  child: Row(
                                                                    children: <Widget>[
                                                                      Expanded(
                                                                        child:
                                                                            ListTile(
                                                                          title:
                                                                              Text(
                                                                            data['name_customer'],
                                                                            style:
                                                                                Theme.of(context).textTheme.bodySmall!.copyWith(letterSpacing: 0.07, fontWeight: FontWeight.bold),
                                                                          ),
                                                                          subtitle:
                                                                              Row(
                                                                            children: <Widget>[
                                                                              Text(
                                                                                data['nohp_customer'],
                                                                                style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 11.7, letterSpacing: 0.06, color: kMainColor, fontWeight: FontWeight.bold),
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

                                                                      IconButton(
                                                                        icon:
                                                                            Icon(
                                                                          Icons
                                                                              .message,
                                                                          color:
                                                                              kMainColor,
                                                                          size:
                                                                              14.0,
                                                                        ),
                                                                        onPressed:
                                                                            () {
                                                                          // Navigator
                                                                          //     .push(
                                                                          //   context,
                                                                          //   MaterialPageRoute(
                                                                          //       builder: (context) => ChatPage(
                                                                          //             data: data,
                                                                          //           )),
                                                                          // );
                                                                        },
                                                                      ),
                                                                      IconButton(
                                                                        icon:
                                                                            Icon(
                                                                          Icons
                                                                              .phone,
                                                                          color:
                                                                              kMainColor,
                                                                          size:
                                                                              14.0,
                                                                        ),
                                                                        onPressed:
                                                                            () async {
                                                                          await FlutterPhoneDirectCaller.callNumber(
                                                                              data['nohp_customer']);
                                                                        },
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                Divider(
                                                                  color:
                                                                      kCardBackgroundColor,
                                                                  thickness:
                                                                      1.0,
                                                                ),
                                                                const SizedBox(
                                                                  height: 20.0,
                                                                ),
                                                                Column(
                                                                  children:
                                                                      merchants.map(
                                                                          (merchant) {
                                                                    return Row(
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
                                                                          flex:
                                                                              5,
                                                                          child:
                                                                              Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: <Widget>[
                                                                              Text(
                                                                                merchant['address_current_merchant'],
                                                                                style: Theme.of(context).textTheme.bodySmall!.copyWith(letterSpacing: 0.05, fontWeight: FontWeight.bold),
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
                                                                    );
                                                                  }).toList(),
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
                                                                            top:
                                                                                12.0,
                                                                            right:
                                                                                10.0),
                                                                        child:
                                                                            Icon(
                                                                          Icons
                                                                              .navigation,
                                                                          size:
                                                                              14.0,
                                                                          color:
                                                                              kMainColor,
                                                                        )),
                                                                    Expanded(
                                                                      flex: 5,
                                                                      child:
                                                                          Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: <Widget>[
                                                                          Text(
                                                                            data['address_current_customer'],
                                                                            style:
                                                                                Theme.of(context).textTheme.bodySmall!.copyWith(letterSpacing: 0.05, fontWeight: FontWeight.bold),
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
                                                                    text:
                                                                        'Angkut',
                                                                    onTap:
                                                                        () async {
                                                                      await update(
                                                                          data);
                                                                      // Navigator.push(
                                                                      //     context,
                                                                      //     MaterialPageRoute(
                                                                      //         builder: (context) => OnWayProductToDestination(
                                                                      //               documentSnapshot: doc,
                                                                      //             )));
                                                                    }),
                                                              ],
                                                            ),
                                                          )
                                                        ],
                                                      );
                                                    }

                                                    return SizedBox();
                                                  }));
                                            }
                                            return const SizedBox();
                                          });
                                    }
                                    return const SizedBox();
                                  });
                            }

                            return const SizedBox();
                          });
                    }
                    if (doc!['status'] == 'dibatalkan') {
                      return Center(
                        child: Container(
                          width: 250,
                          height: 457,
                          child: Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.cancel),
                                color: kMainColor,
                                onPressed: () {
                                  /*....*/
                                },
                              ),
                              const SizedBox(
                                height: 25,
                              ),
                              Text(
                                'Batal Perjalanan',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontSize: 20),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Text(
                                'Perjalananmu di batalkan oleh pelanggan',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontSize: 16),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const AccountPageBody()));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 8.0),
                                  child: Text(
                                    'Kembali Ke beranda',
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return const SizedBox();
                  }),
              isOpen
                  ? OrderInfoContainer(
                      listProducts,
                      widget.documentSnapshot?['grand_total'],
                      widget.documentSnapshot?['payment_method'],
                      listMerchants,
                      widget.documentSnapshot?['price_trip'])
                  : const SizedBox.shrink(),
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
        print(currentLocation.latitude);
        // final res2 = await FirebaseFirestore.instance
        //     .collection('trips')
        //     .doc('customer_id_${widget.documentSnapshot!['customer_id']}')
        //     .collection('trip')
        //     .where('order_id', isEqualTo: widget.documentSnapshot!['order_id'])
        //     .get();

        // final DocumentSnapshot data = res2.docs[0];

        // await FirebaseFirestore.instance
        //     .collection('trips')
        //     .doc('customer_id_${widget.documentSnapshot!['customer_id']}')
        //     .collection('trip')
        //     .doc(data.id)
        //     .update({
        //   'latitude_current_driver': currentLocation.latitude,
        //   "longitude_current_driver": currentLocation.longitude
        // });

        // getPolyPoints();
      }
    });
  }

  Future<void> update([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {}
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.documentSnapshot!.id)
        .update({
      'status': 'angkut',
    });

    await FirebaseFirestore.instance
        .collection('order_customers')
        .doc(documentSnapshot!.id)
        .update({
      'status': 'angkut',
    });
  }
}
