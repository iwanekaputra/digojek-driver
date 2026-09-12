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
import 'package:geolocator/geolocator.dart';
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

class OnWayPackageToDestinationPage extends StatelessWidget {
  String order_id;
  final QueryDocumentSnapshot<Map<String, dynamic>>? config_order;
  final Map<String, dynamic> order;
  OnWayPackageToDestinationPage(
      {super.key,
      required this.order_id,
      required this.config_order,
      required this.order});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderMapBloc>(
      create: (context) => OrderMapBloc()..loadMap(),
      child: OnWayPackageToDestinationBody(
        order_id: order_id,
        config_order: config_order,
        order: order,
      ),
    );
  }
}

class OnWayPackageToDestinationBody extends StatefulWidget {
  String order_id;
  final QueryDocumentSnapshot<Map<String, dynamic>>? config_order;
  final Map<String, dynamic> order;
  OnWayPackageToDestinationBody(
      {super.key,
      required this.order_id,
      required this.config_order,
      required this.order});

  @override
  OnWayBodyToDestinationState createState() => OnWayBodyToDestinationState();
}

class OnWayBodyToDestinationState extends State<OnWayPackageToDestinationBody> {
  // final Completer<GoogleMapController> _mapController = Completer();
  final locationController = Location();

  GoogleMapController? mapStyleController;
  bool isLoading = false;
  bool isLoadingButton = false;

  UserModel? driver;

  LatLng? currentPosition;

  Map<PolylineId, Polyline> _polylines = <PolylineId, Polyline>{};

  double? heading;

  LocationSettings? locationSettings;

  // DocumentSnapshot? order_customers;

  List order_customers = [];
  Map<String, dynamic> getSettings = {};

  Completer<GoogleMapController> _googleMapController = Completer();

  bool isOpen = false;

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

  Future<void> initData() async {
    setState(() {
      isLoading = true;
      order_customers = widget.order['order_customers'];
    });
    // await getOrder();
    // await getConfigOrder();
    await _determinePosition();
    // Map<String, dynamic> res = await SharedServices().getSettings();

    await buildwidget();
    setState(() {
      isLoading = false;
      // getSettings = res;
    });
  }

  Future<Map<PolylineId, Polyline>> buildwidget() async {
    List<LatLng> polylineCoordinates = [];
    Map<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{};
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        GOOGLE_API_KEY,
        PointLatLng(currentPosition!.latitude, currentPosition!.longitude),
        PointLatLng(order_customers[0]['latitude_destination'],
            order_customers[0]['longitude_destination']));
    if (result.points.isNotEmpty) {
      result.points.forEach(
        (PointLatLng point) => polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        ),
      );
    }

    final Polyline polyline = Polyline(
        polylineId: PolylineId('polyline-target'),
        consumeTapEvents: true,
        points: polylineCoordinates,
        color: kMainColor,
        width: 4,
        onTap: () {});
    polyLines[PolylineId('polyline-target')] = polyline;

    setState(() {
      _polylines = polyLines;
    });

    return polyLines;
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
        });
      }
      // await buildwidget();
      final res2 = await FirebaseFirestore.instance
          .collection('config_orders')
          .doc(widget.config_order!.id)
          .update({
        "latitude_current_driver": position!.latitude,
        "longitude_current_driver": position!.longitude,
        "heading": position!.heading
      });
    });
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
              isLoading == null ||
                      currentPosition == null ||
                      order_customers == null
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Column(children: <Widget>[
                      if (order_customers.isNotEmpty)
                        Expanded(
                          child: BlocBuilder<OrderMapBloc, OrderMapState>(
                              builder: (context, state) {
                            return GoogleMap(
                              zoomControlsEnabled: false,
                              polylines: Set<Polyline>.of(_polylines.values),
                              mapType: MapType.normal,
                              initialCameraPosition: CameraPosition(
                                target: currentPosition!,
                                zoom: 16,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('mark1'),
                                  position: currentPosition!,
                                  rotation: heading!,
                                  icon: driver!.vehicletype == 'Motor' ||
                                          driver!.vehicletype == 'motor'
                                      ? markerss.first
                                      : markerss[1],
                                ),
                                Marker(
                                  markerId: const MarkerId('mark2'),
                                  position: LatLng(
                                      order_customers[0]
                                          ['latitude_destination'],
                                      order_customers[0]
                                          ['longitude_destination']),
                                  icon: markerss.last,
                                ),
                              },
                              onMapCreated: (GoogleMapController controller) {
                                if (!_googleMapController.isCompleted) {
                                  _googleMapController.complete(controller);
                                }
                              },
                            );
                          }),
                        ),
                      if (order_customers.isNotEmpty)
                        Align(
                            alignment: Alignment.bottomCenter,
                            child: Column(children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      navigateMaps(order_customers);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 0.0,
                                          left: 0.0,
                                          right: 0.0,
                                          bottom: 0.0),
                                      child: CircleAvatar(
                                          backgroundColor: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                          child: Image.asset(
                                            'images/google-maps.png',
                                            height: 20,
                                          )),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.3),
                                child: Row(
                                  children: <Widget>[
                                    if (driver!.vehicletype == 'motor')
                                      Image.asset(
                                        'images/bike1.png',
                                        height: 42.3,
                                        width: 33.7,
                                      ),
                                    if (driver!.vehicletype == 'Bajaj')
                                      Image.asset(
                                        'images/bajaj.png',
                                        height: 42.3,
                                        width: 33.7,
                                      ),

                                    if (driver!.vehicletype == 'Bentor')
                                      Image.asset(
                                        'images/becak.png',
                                        height: 42.3,
                                        width: 33.7,
                                      ),

                                    if (driver!.vehicletype == 'mobil' ||
                                        driver!.vehicletype == 'Sedan' ||
                                        driver!.vehicletype == 'SUV' ||
                                        driver!.vehicletype == 'MVP' ||
                                        driver!.vehicletype == 'MPV' ||
                                        driver!.vehicletype == 'Truck' ||
                                        driver!.vehicletype == 'Bus' ||
                                        driver!.vehicletype == 'Pick UP')
                                      Image.asset(
                                        'images/image1.png',
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
                                          order_customers[0]
                                              ['address_destination'],
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
                              isLoadingButton
                                  ? GestureDetector(
                                      onTap: () {},
                                      child: Container(
                                        color: kMainColor,
                                        height: 60.0,
                                        width: double.maxFinite,
                                        child: Center(
                                            child: CircularProgressIndicator()),
                                      ),
                                    )
                                  : BottomBar(
                                      text: 'Selesai',
                                      onTap: () async {
                                        setState(() {
                                          isLoadingButton = true;
                                        });
                                        await update();

                                        // await updateSaldo(order_customers!);
                                      }),
                            ]))
                    ]),
              isOpen
                  ? FadedSlideAnimation(
                      beginOffset: const Offset(0, 0.3),
                      endOffset: const Offset(0, 0),
                      slideCurve: Curves.linearToEaseOut,
                      child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          color: Theme.of(context).cardColor,
                          height: MediaQuery.of(context).size.width - 40,
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                  child: Column(
                                children: [
                                  Container(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    child: ListTile(
                                      title: Text(
                                        'Nama Penerima',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium!
                                            .copyWith(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15.0),
                                      ),
                                      trailing: Text(
                                        widget.order['order_packages'][0]
                                            ['name_receiver'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .copyWith(fontSize: 13.3),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    child: ListTile(
                                      title: Text(
                                        'Jenis Paket',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium!
                                            .copyWith(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15.0),
                                      ),
                                      trailing: Text(
                                        widget.order['order_packages'][0]
                                            ['type_package'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .copyWith(fontSize: 13.3),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    child: ListTile(
                                      title: Text(
                                        'Berat Paket',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium!
                                            .copyWith(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15.0),
                                      ),
                                      trailing: Text(
                                        "${widget.order['order_packages'][0]['weight'].toString()} Kg",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .copyWith(fontSize: 13.3),
                                      ),
                                    ),
                                  ),
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 15),
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      child: Row(
                                        children: [
                                          Text(
                                            'Nohp Penerima',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium!
                                                .copyWith(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 15.0),
                                          ),
                                          Spacer(),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  Icons.phone,
                                                  color: kMainColor,
                                                  size: 14.0,
                                                ),
                                                onPressed: () async {
                                                  final url =
                                                      "whatsapp://send?phone=${formatPhoneNumber(widget.order['order_packages'][0]['nohp_receiver'])}&text=p";
                                                  await launchUrl(Uri.parse(
                                                      Uri.encodeFull(url)));
                                                },
                                              ),
                                              Text(
                                                widget.order['order_packages']
                                                    [0]['nohp_receiver'],
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall!
                                                    .copyWith(fontSize: 13.3),
                                              ),
                                            ],
                                          )
                                        ],
                                      )),
                                ],
                              )),
                            ],
                          )))
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
        // final res2 = await FirebaseFirestore.instance
        //     .collection('orders')
        //     .doc(widget.documentSnapshot!.id)
        //     .update({
        //   "latitude_current_driver": currentLocation.latitude,
        //   "longitude_current_driver": currentLocation.longitude,
        //   "heading": currentLocation.heading
        // });

        // getPolyPoints();
      }
    });
  }

  Future<void> update() async {
    Map<String, dynamic> finishOrder =
        await SharedServices().finishOrderRide(widget.order_id.toString());

    await FirebaseFirestore.instance
        .collection('config_orders')
        .doc(widget.config_order!.id)
        .update({'status': "selesai"});
  }

  moveToPosition(LatLng latLng) async {
    GoogleMapController mapController = await _googleMapController.future;
    mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, zoom: 16)));
  }

  Future<void> updateSaldo(DocumentSnapshot documentSnapshot) async {
    final token = await AuthService().getToken();

    if (documentSnapshot['payment_method'] == 'cash' ||
        documentSnapshot['payment_method'] == 'Tunai') {
      num? prices = documentSnapshot['price_trip'] *
          getSettings['potongan_admin_driver'] /
          100;
      num? saldo = driver!.balance! -
          (documentSnapshot['price_trip'] *
              getSettings['potongan_admin_driver'] /
              100);
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
            'keluar',
            'motor',
            documentSnapshot!['payment_method']);
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
          (documentSnapshot['price_trip'] *
              getSettings['potongan_admin_driver'] /
              100));
      num? saldo = driver!.balance! + prices!;

      await SharedServices()
          .updateSaldoDriver(driver!.id.toString(), saldo.toString());
      await SharedServices().addTransaction(
          driver!.id.toString(),
          prices.toString(),
          'masuk',
          'motor',
          documentSnapshot['payment_method']);
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
        'google.navigation:q=${data[0]['latitude_destination']}, ${data[0]['longitude_destination']}&key=${GOOGLE_API_KEY}'));
  }
}
