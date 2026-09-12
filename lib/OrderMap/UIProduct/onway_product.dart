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
import 'package:deliq_delivery/services/shared_services.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:deliq_delivery/shared/shared_values.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';

class OnWayProductPage extends StatelessWidget {
  String order_id;
  final QueryDocumentSnapshot<Map<String, dynamic>>? config_order;
  final Map<String, dynamic> order;
  OnWayProductPage(
      {super.key,
      required this.order_id,
      required this.config_order,
      required this.order});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderMapBloc>(
      create: (context) => OrderMapBloc()..loadMap(),
      child: OnWayProductBody(
        order_id: order_id,
        config_order: config_order,
        order: order,
      ),
    );
  }
}

class OnWayProductBody extends StatefulWidget {
  String order_id;
  final QueryDocumentSnapshot<Map<String, dynamic>>? config_order;
  final Map<String, dynamic> order;
  OnWayProductBody(
      {super.key,
      required this.order_id,
      required this.config_order,
      required this.order});

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

  LocationSettings? locationSettings;

  // Map<String, dynamic> order = {};

  LatLng? currentPosition;

  Map<PolylineId, Polyline> _polylines = <PolylineId, Polyline>{};

  // DocumentSnapshot? order_customers;
  // List<QueryDocumentSnapshot<Map<String, dynamic>>>? order_merchants;

  double? heading;

  List order_customers = [];
  List order_merchants = [];
  List order_products = [];

  // QueryDocumentSnapshot<Map<String, dynamic>>? config_order;

  bool isLoading = false;

  bool isLoadingButton = false;

  final Set<Marker> _markers = {};

  Completer<GoogleMapController> _googleMapController = Completer();

  double? distanceToNearestMerchant;
  Map<String, dynamic>? nearestMerchant;
  bool isNearAnyMerchant = false;
  static const double MINIMUM_DISTANCE_METERS = 100.0; // 100 meter

  @override
  void initState() {
    rootBundle.loadString('images/map_style.txt').then((string) {
      mapStyle = string;
    });
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async => await initData());
  }

  Future<void> initData() async {
    setState(() {
      isLoading = true;
      order_customers = widget.order['order_customers'];
      order_products = widget.order['order_products'];
      order_merchants = widget.order['order_merchants'];
    });
    // await getMerchants();
    await _determinePosition();
    // await getOrder();
    // await getConfigOrder();
    getMerchantMarkers();
    // await getDataCustomers();
    // await getProducts();
    // await getMerchantMarkers();
    await buildwidget();
    setState(() {
      isLoading = false;
    });
  }

  double calculateDistanceToNearestMerchant() {
    if (currentPosition == null || order_merchants.isEmpty) {
      return double.infinity;
    }

    double minDistance = double.infinity;
    Map<String, dynamic>? closestMerchant;

    for (var merchant in order_merchants) {
      double distance = Geolocator.distanceBetween(
        currentPosition!.latitude,
        currentPosition!.longitude,
        merchant['merchant']['latitude'],
        merchant['merchant']['longitude'],
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestMerchant = merchant;
      }
    }

    nearestMerchant = closestMerchant;
    return minDistance;
  }

  // Method untuk check apakah driver sudah dekat dengan merchant mana pun
  bool checkIfNearAnyMerchant() {
    double distance = calculateDistanceToNearestMerchant();
    return distance <= MINIMUM_DISTANCE_METERS;
  }

  void getMerchantMarkers() {
    _markers.add(
      Marker(
        markerId: const MarkerId('mark1'),
        position: currentPosition!,
        icon: markerss.first,
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId('mark2'),
        position: LatLng(order_customers[0]['latitude_current_customer'],
            order_customers[0]['longitude_current_customer']),
        icon: markerss.last,
      ),
    );

    for (var i = 0; i < order_merchants!.length; i++) {
      _markers.add(
        Marker(
            markerId: MarkerId('mark-merchant-${i.toString()}'),
            position: LatLng(order_merchants![i]['merchant']['latitude'],
                order_merchants![i]['merchant']['longitude']),
            icon: BitmapDescriptor.defaultMarker),
      );
    }
  }

  // Future<void> getProducts() async {
  //   final res = await FirebaseFirestore.instance
  //       .collection('order_products')
  //       .where('order_id', isEqualTo: widget.documentSnapshot!.id)
  //       .get();
  //   final res2 = await FirebaseFirestore.instance
  //       .collection('order_merchants')
  //       .where('order_id', isEqualTo: widget.documentSnapshot!.id)
  //       .get();

  //   setState(() {
  //     listProducts = res.docs as List;
  //     listMerchants = res2.docs as List;
  //   });
  // }

  // Future<void> getDataCustomers() async {
  //   final res = await FirebaseFirestore.instance
  //       .collection('order_customers')
  //       .where('order_id', isEqualTo: widget.documentSnapshot!.id)
  //       .get();

  //   setState(() {
  //     order_customers = res.docs[0];
  //   });
  // }

  // Future<void> getMerchants() async {
  //   final res = await FirebaseFirestore.instance
  //       .collection('order_merchants')
  //       .where('order_id', isEqualTo: widget.documentSnapshot!.id)
  //       .get();

  //   setState(() {
  //     order_merchants = res.docs;
  //   });
  // }

  List<String> itemName = [
    'Fresh Red Onions',
    'Fresh Cauliflower',
    'Fresh Cauliflower',
  ];

  bool isOpen = false;
  Future<void> buildwidget() async {
    Map<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{};
    PolylinePoints polylinePoints = PolylinePoints();
    List<LatLng> polylineCoordinates2 = [];

    for (var i = 0; i < order_merchants.length; i++) {
      List<LatLng> polylineCoordinates = [];

      // line customer
      await Future.delayed(Duration(seconds: 1));
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          GOOGLE_API_KEY,
          PointLatLng(currentPosition!.latitude, currentPosition!.longitude),
          PointLatLng(order_merchants[i]['merchant']['latitude'],
              order_merchants[i]['merchant']['longitude']));
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
        PointLatLng(currentPosition!.latitude, currentPosition!.longitude),
        PointLatLng(order_customers[0]['latitude_current_customer'],
            order_customers[0]['longitude_current_customer']));
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

    if (mounted) {
      setState(() {
        _polylines = polyLines;
      });
    }
  }

  Future<void> navigateMaps() async {
    await launchUrl(Uri.parse(
        'google.navigation:q=${order_customers[0]['latitude_current_customer']}, ${order_customers[0]['longitude_current_customer']}&key=${GOOGLE_API_KEY}'));
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
              isLoading || currentPosition == null || order_customers == null
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Column(children: <Widget>[
                      if (order_customers.isNotEmpty)
                        Expanded(
                          child: GoogleMap(
                            zoomControlsEnabled: false,
                            polylines: Set<Polyline>.of(_polylines.values),
                            mapType: MapType.normal,
                            initialCameraPosition: CameraPosition(
                              target: currentPosition!,
                              zoom: 16,
                            ),
                            markers: _markers,
                            onMapCreated: (GoogleMapController controller) {
                              if (!_googleMapController.isCompleted) {
                                _googleMapController.complete(controller);
                              }
                            },
                          ),
                        ),
                      if (order_customers.isNotEmpty)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Column(
                            children: <Widget>[
                              // Row(
                              //   mainAxisAlignment: MainAxisAlignment.end,
                              //   children: [
                              //     GestureDetector(
                              //       onTap: () {
                              //         navigateMaps();
                              //       },
                              //       child: Padding(
                              //         padding: const EdgeInsets.only(
                              //             top: 0.0,
                              //             left: 0.0,
                              //             right: 0.0,
                              //             bottom: 0.0),
                              //         child: CircleAvatar(
                              //             backgroundColor: Theme.of(context)
                              //                 .scaffoldBackgroundColor,
                              //             child: Image.asset(
                              //               'images/google-maps.png',
                              //               height: 20,
                              //             )),
                              //       ),
                              //     ),
                              //   ],
                              // ),

                              buildMerchantDistanceInfo(),
                              buildAllMerchantDistances(),

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
                                          order_customers[0]['type_order'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall!
                                              .copyWith(
                                                  letterSpacing: 0.07,
                                                  fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Row(
                                          children: <Widget>[
                                            Text(
                                              order_customers[0]['distance'],
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
                                          order_customers[0]['price_trip']),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                              color: kMainColor,
                                              fontWeight: FontWeight.bold,
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
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.3),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: ListTile(
                                        title: Text(
                                          order_customers[0]['customer']
                                              ['name'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall!
                                              .copyWith(
                                                  letterSpacing: 0.07,
                                                  fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Row(
                                          children: <Widget>[
                                            Text(
                                              order_customers[0]['customer']
                                                  ['nohp'],
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
                                      icon: Icon(
                                        Icons.message,
                                        color: kMainColor,
                                        size: 14.0,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => ChatPage(
                                                    order: widget.order,
                                                  )),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.phone,
                                        color: kMainColor,
                                        size: 14.0,
                                      ),
                                      onPressed: () async {
                                        final url =
                                            "whatsapp://send?phone=${formatPhoneNumber(order_customers[0]['customer']['nohp'])}&text=p";
                                        await launchUrl(
                                            Uri.parse(Uri.encodeFull(url)));
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                color: kCardBackgroundColor,
                                thickness: 1.0,
                              ),
                              const SizedBox(
                                height: 20.0,
                              ),
                              Column(
                                children: order_merchants!.map((merchant) {
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
                                        flex: 5,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              merchant['merchant']['address'],
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
                                          order_customers[0]
                                              ['address_current_customer'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall!
                                              .copyWith(
                                                  letterSpacing: 0.05,
                                                  fontWeight: FontWeight.bold),
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
                              buildAmbilBarangButton(),
                            ],
                          ),
                        )
                    ]),
              isOpen
                  ? OrderInfoContainer(
                      order_products,
                      widget.order['grand_total'],
                      order_customers[0]['payment_method'],
                      order_merchants,
                      order_customers[0]['price_trip'])
                  : const SizedBox.shrink(),
            ],
          ),
        ));
  }

  Widget buildMerchantDistanceInfo() {
    if (distanceToNearestMerchant == null || nearestMerchant == null) {
      return SizedBox.shrink();
    }

    String distanceText;
    Color distanceColor;
    IconData distanceIcon;

    if (distanceToNearestMerchant! < 1000) {
      distanceText =
          '${distanceToNearestMerchant!.toStringAsFixed(0)}m dari merchant terdekat';
      distanceColor = distanceToNearestMerchant! <= MINIMUM_DISTANCE_METERS
          ? Colors.green
          : Colors.orange;
      distanceIcon = distanceToNearestMerchant! <= MINIMUM_DISTANCE_METERS
          ? Icons.check_circle
          : Icons.store;
    } else {
      distanceText =
          '${(distanceToNearestMerchant! / 1000).toStringAsFixed(1)}km dari merchant terdekat';
      distanceColor = Colors.red;
      distanceIcon = Icons.store;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: distanceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: distanceColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(distanceIcon, color: distanceColor, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  distanceText,
                  style: TextStyle(
                    color: distanceColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              if (!isNearAnyMerchant)
                Text(
                  'Min: ${MINIMUM_DISTANCE_METERS.toInt()}m',
                  style: TextStyle(
                    color: distanceColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
          if (nearestMerchant != null)
            Padding(
              padding: EdgeInsets.only(left: 24, top: 4),
              child: Text(
                nearestMerchant!['merchant']['name'] ?? 'Merchant',
                style: TextStyle(
                  color: distanceColor.withOpacity(0.8),
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildAllMerchantDistances() {
    if (currentPosition == null || order_merchants.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 16),
              SizedBox(width: 8),
              Text(
                'Jarak ke semua merchant:',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          ...order_merchants.asMap().entries.map((entry) {
            int index = entry.key;
            var merchant = entry.value;

            double distance = Geolocator.distanceBetween(
              currentPosition!.latitude,
              currentPosition!.longitude,
              merchant['merchant']['latitude'],
              merchant['merchant']['longitude'],
            );

            bool isNear = distance <= MINIMUM_DISTANCE_METERS;
            Color statusColor = isNear ? Colors.green : Colors.orange;

            return Padding(
              padding: EdgeInsets.only(left: 24, top: 2),
              child: Row(
                children: [
                  Icon(
                    isNear ? Icons.check_circle : Icons.circle_outlined,
                    color: statusColor,
                    size: 12,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${merchant['merchant']['name'] ?? 'Merchant ${index + 1}'}: ${distance < 1000 ? '${distance.toStringAsFixed(0)}m' : '${(distance / 1000).toStringAsFixed(1)}km'}',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget buildAmbilBarangButton() {
    if (isLoadingButton) {
      return GestureDetector(
        onTap: () {},
        child: Container(
          color: kMainColor,
          height: 60.0,
          width: double.maxFinite,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Jika belum dekat dengan merchant mana pun
    if (!isNearAnyMerchant) {
      return GestureDetector(
        onTap: () {
          // Tampilkan snackbar ketika tombol diklik tapi belum dekat
          String merchantName =
              nearestMerchant?['merchant']['name'] ?? 'merchant';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Anda harus berada dalam jarak ${MINIMUM_DISTANCE_METERS.toInt()}m dari salah satu merchant untuk mengambil barang',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Lihat',
                textColor: Colors.white,
                onPressed: () {
                  // Show dialog dengan info semua merchant
                  showMerchantDistanceDialog();
                },
              ),
            ),
          );
        },
        child: Container(
          color: Colors.grey.shade400, // Warna abu-abu untuk disabled
          height: 60.0,
          width: double.maxFinite,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_mall_directory_outlined,
                    color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Terlalu Jauh - Ambil Barang',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Jika sudah dekat dengan minimal satu merchant
    return BottomBar(
      text: 'Ambil Barang',
      onTap: () async {
        setState(() {
          isLoadingButton = true;
        });
        await update();
      },
    );
  }

  void showMerchantDistanceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.store, color: kMainColor),
              SizedBox(width: 8),
              Text('Jarak ke Merchant'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Anda harus berada dalam radius ${MINIMUM_DISTANCE_METERS.toInt()}m dari salah satu merchant:',
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 12),
              ...order_merchants.asMap().entries.map((entry) {
                int index = entry.key;
                var merchant = entry.value;

                double distance = Geolocator.distanceBetween(
                  currentPosition!.latitude,
                  currentPosition!.longitude,
                  merchant['merchant']['latitude'],
                  merchant['merchant']['longitude'],
                );

                bool isNear = distance <= MINIMUM_DISTANCE_METERS;
                Color statusColor = isNear ? Colors.green : Colors.red;

                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isNear ? Icons.check_circle : Icons.error,
                        color: statusColor,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              merchant['merchant']['name'] ??
                                  'Merchant ${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${distance < 1000 ? '${distance.toStringAsFixed(0)}m' : '${(distance / 1000).toStringAsFixed(1)}km'} ${isNear ? '✓' : ''}',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await locationController.requestService();
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position? position = await Geolocator.getLastKnownPosition();

    if (mounted) {
      // moveToPosition(LatLng(position?.latitude ?? 0, position?.longitude ?? 0));
      setState(() {
        // rotation = position!.heading;
        currentPosition = LatLng(position!.latitude, position!.longitude);
        heading = position.heading;

        distanceToNearestMerchant = calculateDistanceToNearestMerchant();
        isNearAnyMerchant = checkIfNearAnyMerchant();
      });
    }
    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) async {
      if (mounted) {
        moveToPosition(
            LatLng(position?.latitude ?? 0, position?.longitude ?? 0));
        setState(() {
          currentPosition = LatLng(position!.latitude!, position!.longitude!);
          heading = position.heading;

          distanceToNearestMerchant = calculateDistanceToNearestMerchant();
          isNearAnyMerchant = checkIfNearAnyMerchant();
        });
      }

      // await buildwidget();
      final res2 = await FirebaseFirestore.instance
          .collection('config_orders')
          .doc(widget.config_order!.id)
          .update({
        "latitude_current_driver": position!.latitude,
        "longitude_current_driver": position.longitude,
        "heading": position.heading
      });
    });
  }

  moveToPosition(LatLng latLng) async {
    GoogleMapController mapController = await _googleMapController.future;
    mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, zoom: 16)));
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
    Map<String, dynamic> updateStatus = await SharedServices()
        .updateStatusOrder(widget.order_id.toString(), 'angkut');

    await FirebaseFirestore.instance
        .collection('config_orders')
        .doc(widget.config_order!.id)
        .update({'status': 'angkut'});
  }

  // Method untuk debugging - bisa dihapus nanti
  void debugMerchantDistanceInfo() {
    print("=== Merchant Distance Debug Info ===");
    print("Current Position: $currentPosition");
    print("Number of Merchants: ${order_merchants.length}");
    print(
        "Distance to Nearest: ${distanceToNearestMerchant?.toStringAsFixed(2)}m");
    print("Nearest Merchant: ${nearestMerchant?['merchant']['name']}");
    print("Is Near Any Merchant: $isNearAnyMerchant");
    print("Minimum Distance: ${MINIMUM_DISTANCE_METERS}m");
    print("===================================");
  }
}
