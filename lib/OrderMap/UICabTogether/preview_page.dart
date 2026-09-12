import 'dart:async';

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliq_delivery/Account/UI/account_page.dart';
import 'package:deliq_delivery/Components/bottom_bar.dart';
import 'package:deliq_delivery/Locale/locales.dart';
// import 'package:deliq_delivery/OrderMap/UI/slide_up_panel.dart';
import 'package:deliq_delivery/OrderMapBloc/order_map_bloc.dart';
// import 'package:deliq_delivery/OrderMapBloc/order_map_state.dart';
// import 'package:deliq_delivery/Routes/routes.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/Themes/style.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/map_utils.dart';
import 'package:deliq_delivery/models/sign_up_form_model.dart';
import 'package:deliq_delivery/models/user_model.dart';
import 'package:deliq_delivery/services/auth_service.dart';
import 'package:deliq_delivery/services/shared_services.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:deliq_delivery/shared/shared_values.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class PreviewPage extends StatelessWidget {
  final Map<String, dynamic> order;
  Map<PolylineId, Polyline> polylines = <PolylineId, Polyline>{};

  final List order_customers;

  final DocumentSnapshot? config_order;
  final QueryDocumentSnapshot<Map<String, dynamic>> notif;
  PreviewPage(
      {super.key,
      this.config_order,
      required this.order,
      required this.order_customers,
      required this.notif,
      required this.polylines});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderMapBloc>(
      create: (context) => OrderMapBloc()..loadMap(),
      child: PreviewPageBody(
        order: order,
        order_customers: order_customers,
        config_order: config_order,
        notif: notif,
        polylines: polylines,
      ),
    );
  }
}

class PreviewPageBody extends StatefulWidget {
  final Map<String, dynamic> order;
  final List order_customers;
  Map<PolylineId, Polyline> polylines = <PolylineId, Polyline>{};

  final DocumentSnapshot? config_order;
  final QueryDocumentSnapshot<Map<String, dynamic>> notif;
  PreviewPageBody(
      {super.key,
      this.config_order,
      required this.order,
      required this.order_customers,
      required this.notif,
      required this.polylines});

  @override
  PreviewPageBodyState createState() => PreviewPageBodyState();
}

class PreviewPageBodyState extends State<PreviewPageBody> {
  // final Completer<GoogleMapController> _mapController = Completer();
  final locationController = Location();

  GoogleMapController? mapStyleController;
  List<LatLng> polylineCoordinates = [];

  final Set<Marker> _markers = {};
  bool isLoading = false;
  bool isLoadingButton = false;
  LatLng? currentPosition;

  UserModel? driver;

  LocationSettings? locationSettings;

  Map<PolylineId, Polyline> _polylines = <PolylineId, Polyline>{};

  @override
  void initState() {
    rootBundle.loadString('images/map_style.txt').then((string) {
      mapStyle = string;
    });
    super.initState();

    // getPolyPoints();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      setState(() {
        driver = authState.user;
      });
    }

    setState(() {
      _polylines = widget.polylines;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async => await initData());
  }

  List<String> itemName = [
    'Fresh Red Onions',
    'Fresh Cauliflower',
    'Fresh Cauliflower',
  ];

  bool isOpen = false;

  Future<void> initData() async {
    setState(() {
      isLoading = true;
    });

    UserModel user = await AuthService().getCurrentUser();
    getMarkers();

    await _determinePosition();

    await buildwidget();

    setState(() {
      isLoading = false;
    });
  }

  Future<Map<PolylineId, Polyline>> buildwidget() async {
    Map<PolylineId, Polyline> polyLiness = <PolylineId, Polyline>{};

    PolylinePoints polylinePoints = PolylinePoints();

    // for (var i = 0; i < widget.order_customers.length; i++) {
    //   List<LatLng> polylineCoordinates = [];
    //   List<LatLng> polylineCoordinates2 = [];

    //   // line customer
    //   await Future.delayed(const Duration(seconds: 1));
    //   PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
    //       GOOGLE_API_KEY,
    //       PointLatLng(widget.config_order!['latitude_current_driver'],
    //           widget.config_order!['longitude_current_driver']),
    //       PointLatLng(widget.order_customers[i]['latitude_current_customer'],
    //           widget.order_customers[i]['longitude_current_customer']));
    //   if (result.points.isNotEmpty) {
    //     result.points.forEach(
    //       (PointLatLng point) => polylineCoordinates.add(
    //         LatLng(point.latitude, point.longitude),
    //       ),
    //     );
    //   }

    //   final Polyline polyline = Polyline(
    //       polylineId: PolylineId('polyline${i.toString()}'),
    //       consumeTapEvents: true,
    //       points: polylineCoordinates,
    //       color: kMainColor,
    //       width: 4,
    //       onTap: () {});

    //   polyLiness[PolylineId('polyline${i.toString()}')] = polyline;

    //   // line destination
    //   await Future.delayed(Duration(seconds: 1));
    //   PolylineResult result2 = await polylinePoints.getRouteBetweenCoordinates(
    //       GOOGLE_API_KEY,
    //       PointLatLng(widget.config_order!['latitude_current_driver'],
    //           widget.config_order!['longitude_current_driver']),
    //       PointLatLng(widget.order_customers[i]['latitude_destination'],
    //           widget.order_customers[i]['longitude_destination']));
    //   if (result2.points.isNotEmpty) {
    //     result2.points.forEach(
    //       (PointLatLng point) => polylineCoordinates2.add(
    //         LatLng(point.latitude, point.longitude),
    //       ),
    //     );
    //   }

    //   final Polyline polyline2 = Polyline(
    //       polylineId: PolylineId('polyline-oke${i.toString()}'),
    //       consumeTapEvents: true,
    //       points: polylineCoordinates2,
    //       color: kMainColor,
    //       width: 4,
    //       onTap: () {});

    //   polyLiness[PolylineId('polyline-oke${i.toString()}')] = polyline2;
    // }

    // line notif
    List<LatLng> polylineCoordinates3 = [];

    PolylineResult result3 = await polylinePoints.getRouteBetweenCoordinates(
        GOOGLE_API_KEY,
        PointLatLng(widget.notif['latitude_current_customer'],
            widget.notif['longitude_current_customer']),
        PointLatLng(widget.notif['latitude_destination'],
            widget.notif['longitude_destination']));
    if (result3.points.isNotEmpty) {
      result3.points.forEach(
        (PointLatLng point) => polylineCoordinates3.add(
          LatLng(point.latitude, point.longitude),
        ),
      );
    }

    final Polyline polyline3 = Polyline(
        polylineId: PolylineId('polyline-notif'),
        consumeTapEvents: true,
        points: polylineCoordinates3,
        color: kGreenColor,
        width: 4,
        onTap: () {});

    polyLiness[PolylineId('polyline-notif')] = polyline3;

    setState(() {
      _polylines[PolylineId('polyline-notif')] = polyline3;
    });

    return polyLiness;
  }

  Future<bool> addCustomerMober() async {
    final res = await SharedServices().addCustomerMober(
        widget.notif['order_customer_id'].toString(),
        widget.order['id'].toString());

    if (driver!.balance! < widget.notif!['price_trip']) {
      showCustomSnackbar(context, 'Saldo isitas anda tidak mencukupi');
      setState(() {
        isLoadingButton = false;
      });

      return true;
    }

    if (res['is-ordered'] != null) {
      showCustomSnackbar(context, 'Orderan Sudah Diambil oleh driver lain');
      setState(() {
        isLoadingButton = false;
      });
      return false;
    }

    final res2 = await FirebaseFirestore.instance
        .collection('config_order_customers')
        .doc(widget.notif.id)
        .update(
            {"config_order_id": widget.config_order!.id, "status": "diterima"});

    return true;
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
            ),
          ),
        ),
        body: FadedSlideAnimation(
          beginOffset: const Offset(0, 0.3),
          endOffset: const Offset(0, 0),
          slideCurve: Curves.linearToEaseOut,
          child: Stack(
            children: <Widget>[
              buildBodyMober(),
              // Align(
              //   alignment: Alignment.bottomCenter,
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       BottomBar(
              //         color: kGreenColor,
              //         width: 100,
              //         height: 30,
              //         text: 'Terima',
              //         onTap: () async {
              //           await addCustomer();
              //         },
              //       ),
              //       BottomBar(
              //         color: kRedColor,
              //         width: 100,
              //         height: 30,
              //         text: 'Tolak',
              //         onTap: () async {
              //           await rejectedCustomer(context);
              //         },
              //       ),
              //       const SizedBox(
              //         height: 80,
              //       )
              //     ],
              //   ),
              // )

              // StreamBuilder(
              //     stream: FirebaseFirestore.instance
              //         .collection('notif_trips')
              //         .where('driver_id', isEqualTo: driver!.id.toString())
              //         .snapshots(),
              //     builder: ((context, snapshot) {
              //       if (snapshot.connectionState == ConnectionState.waiting) {
              //         return const Center(
              //           child: CircularProgressIndicator(),
              //         );
              //       }
              //       final data = snapshot.data!.docs;
              //       if (snapshot.data!.docs.isEmpty) {
              //         return const SizedBox();
              //       }

              //     }))
              // isOpen ? OrderInfoContainer(itemName) : const SizedBox.shrink(),
            ],
          ),
        ));
  }

  Widget buildBodyMober() {
    return isLoading
        ? Center(
            child: CircularProgressIndicator(),
          )
        : Column(
            children: <Widget>[
              Expanded(
                child: Stack(children: [
                  if (_polylines.isNotEmpty)
                    GoogleMap(
                      zoomControlsEnabled: false,
                      polylines: Set<Polyline>.of(_polylines!.values),
                      mapType: MapType.normal,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                            widget.config_order!['latitude_current_driver'],
                            widget.config_order!['longitude_current_driver']),
                        zoom: 13,
                      ),
                      markers: _markers,
                      onMapCreated: (GoogleMapController controller) async {
                        // _mapController.complete(controller);
                        mapStyleController = controller;
                        // mapStyleController!.setMapStyle(mapStyle);
                        // setState(() {});
                      },
                    ),
                ]),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Container(
                      //   height: 4,
                      //   width: 100,
                      //   margin: const EdgeInsets.only(top: 14),
                      //   decoration: BoxDecoration(
                      //     borderRadius: BorderRadius.circular(4),
                      //     color: Theme.of(context).cardColor,
                      //   ),
                      // ),
                      // const SizedBox(height: 20),
                      Row(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            child: FadedScaleAnimation(
                              scaleDuration: const Duration(milliseconds: 400),
                              fadeDuration: const Duration(milliseconds: 400),
                              child: Image.asset(
                                'images/footermenu/ic_profile.png',
                                scale: 5,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: Text(
                                widget.notif['name_customer'],
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              // subtitle: Text(
                              //   dataNotif['date'],
                              //   style: Theme.of(context)
                              //       .textTheme
                              //       .titleLarge!
                              //       .copyWith(
                              //           fontSize: 11.7,
                              //           color: const Color(0xffc1c1c1)),
                              // ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  // Text(
                                  //   dataNotif['status'],
                                  //   style: orderMapAppBarTextStyle.copyWith(
                                  //       color: kMainColor),
                                  // ),
                                  const SizedBox(height: 7.0),
                                  Text(
                                    '${formatCurrency(widget.notif['price_trip'])} | ${widget.notif['payment_method']}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge!
                                        .copyWith(
                                            fontSize: 11.7,
                                            letterSpacing: 0.06,
                                            color: const Color(0xffc1c1c1)),
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                      Divider(
                        color: Theme.of(context).cardColor,
                        thickness: 1.0,
                      ),
                      Row(
                        children: <Widget>[
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Icon(
                              Icons.location_on,
                              color: kMainColor,
                              size: 13.3,
                            ),
                          ),
                          Text(
                            widget.notif['address_destination'],
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(
                                    fontSize: 10.0,
                                    letterSpacing: 0.05,
                                    fontWeight: FontWeight.bold),
                          ),
                          // Text(
                          //   '(Union Market)',
                          //   style: Theme.of(context)
                          //       .textTheme
                          //       .bodySmall!
                          //       .copyWith(
                          //           fontSize: 10.0,
                          //           letterSpacing: 0.05),
                          // ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Icon(
                              Icons.navigation,
                              color: kMainColor,
                              size: 13.3,
                            ),
                          ),
                          Text(
                            widget.notif['address_current_customer'],
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(
                                    fontSize: 10.0,
                                    letterSpacing: 0.05,
                                    fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      isLoadingButton
                          ? Center(
                              child: CircularProgressIndicator(),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                BottomBar(
                                  color: kGreenColor,
                                  width: 100,
                                  height: 30,
                                  text: 'Terima',
                                  onTap: () {
                                    Navigator.pop(context, 'diterima');
                                  },
                                ),
                                BottomBar(
                                  color: kRedColor,
                                  width: 100,
                                  height: 30,
                                  text: 'Tolak',
                                  onTap: () {
                                    Navigator.pop(context, 'tolak');
                                  },
                                ),
                                const SizedBox(
                                  height: 80,
                                )
                              ],
                            ),
                    ],
                  ),
                ),
              )
            ],
          );
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
        currentPosition =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);

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

  // Future<void> getPolyPoints() async {
  //   PolylinePoints polylinePoints = PolylinePoints();

  //   PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
  //       GOOGLE_API_KEY,
  //       PointLatLng(currentPosition!.latitude, currentPosition!.longitude),
  //       PointLatLng(0.7045817, 101.612035));

  //   if (result.points.isNotEmpty) {
  //     result.points.forEach(
  //       (PointLatLng point) => polylineCoordinates.add(
  //         LatLng(point.latitude, point.longitude),
  //       ),
  //     );

  //     // setState(() {});
  //   }
  // }

  Future<void> update([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {}
    await FirebaseFirestore.instance
        .collection('trips')
        .doc('driver_id_${documentSnapshot!['driver_id']}')
        .collection('trip')
        .doc(documentSnapshot.id)
        .update({
      'status': 'angkut',
    });

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
    //     .update({'status': 'angkut'});
  }

  void getMarkers() {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('mark1'),
        position: LatLng(widget.config_order!['latitude_current_driver'],
            widget.config_order!['longitude_current_driver']),
        icon: markerss[1],
      ),
    );
    for (var i = 0; i < widget.order_customers.length; i++) {
      if (widget.order_customers[i]['status'] == 'diterima') {
        _markers.add(
          Marker(
              markerId: MarkerId('${widget.order_customers[i]['id']}'),
              position: LatLng(
                widget.order_customers[i]['latitude_current_customer'],
                widget.order_customers[i]['longitude_current_customer'],
              ),
              icon: BitmapDescriptor.defaultMarker),
        );
      }

      _markers.add(
        Marker(
          markerId: MarkerId('tujuan${widget.order_customers[i]['id']}'),
          position: LatLng(widget.order_customers[i]['latitude_destination'],
              widget.order_customers[i]['longitude_destination']),
          icon: markerss.last,
        ),
      );
    }

    _markers.add(
      Marker(
        markerId: const MarkerId('mark151'),
        position: LatLng(widget.notif['latitude_destination'],
            widget.notif['longitude_destination']),
        icon: markerss.last,
      ),
    );
    _markers.add(
      Marker(
          markerId: const MarkerId('markoaskd'),
          position: LatLng(widget.notif['latitude_current_customer'],
              widget.notif['longitude_current_customer']),
          icon: BitmapDescriptor.defaultMarker),
    );
  }

  Future<void> addCustomer() async {
    final notifDriver = await FirebaseFirestore.instance
        .collection('notif_trips')
        .where('driver_id', isEqualTo: driver!.id.toString())
        .where('type_order', isEqualTo: 'mober')
        .get();

    final customer = notifDriver.docs[0];

    final res1 = await FirebaseFirestore.instance
        .collection('order_customers')
        .where('order', isEqualTo: customer['order'])
        .where('customer_id', isEqualTo: customer['customer_id'])
        .get();

    // await FirebaseFirestore.instance
    //     .collection('order_customers')
    //     .doc(res1.docs[0].id)
    //     .update({
    //   "status": "diterima",
    //   "order_id": widget.documentSnapshot!.id,\
    //   "order": widget.documentSnapshot!['order']
    // });

    // await updateNotifTrip(customer);
    await deleteNotifTripMober(customer['order']);

    Navigator.pop(context, true);
  }

  // Future<void> updateNotifTrip(DocumentSnapshot notif_trips) async {
  //   await FirebaseFirestore.instance
  //       .collection('notif_trips')
  //       .doc(notif_trips.id)
  //       .update({"trip_id": widget.documentSnapshot!.id, "status": "diterima"});
  // }

  Future<void> rejectedCustomer(BuildContext context) async {
    // hapus notif trips driver
    final deleteNotifDriver = await FirebaseFirestore.instance
        .collection('notif_trips')
        .where('driver_id', isEqualTo: driver!.id.toString())
        .where('type_order', isEqualTo: 'mober')
        .get();

    for (var doc in deleteNotifDriver.docs) {
      await doc.reference.delete();
    }

    Navigator.pop(context, true);
  }

  Future<void> deleteNotifTripMober(orderId) async {
    final deleteNotifDriver = await FirebaseFirestore.instance
        .collection('notif_trips')
        .where('order', isEqualTo: orderId)
        .get();

    for (var doc in deleteNotifDriver.docs) {
      await doc.reference.delete();
    }
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

    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) async {});
  }
}
