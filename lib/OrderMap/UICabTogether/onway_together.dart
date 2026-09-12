import 'dart:async';
import 'dart:convert';

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliq_delivery/Account/UI/account_page.dart';
import 'package:deliq_delivery/Account/UI/home_account.dart';
import 'package:deliq_delivery/Chat/UI/chat_page.dart';
import 'package:deliq_delivery/Components/bottom_bar.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/OrderMap/UI/delivery_successful.dart';
import 'package:deliq_delivery/OrderMap/UI/onway_to_destination.dart';
import 'package:deliq_delivery/OrderMap/UICabTogether/preview_page.dart';
// import 'package:deliq_delivery/OrderMap/UI/slide_up_panel.dart';
import 'package:deliq_delivery/OrderMapBloc/order_map_bloc.dart';
import 'package:deliq_delivery/Routes/routes.dart';
// import 'package:deliq_delivery/OrderMapBloc/order_map_state.dart';
// import 'package:deliq_delivery/Routes/routes.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/Themes/style.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/map_utils.dart';
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
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class OnWayTogetherPage extends StatelessWidget {
  Map<String, dynamic> order;
  OnWayTogetherPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderMapBloc>(
      create: (context) => OrderMapBloc()..loadMap(),
      child: OnWayTogetherBody(
        order: order,
      ),
    );
  }
}

class OnWayTogetherBody extends StatefulWidget {
  Map<String, dynamic> order;
  OnWayTogetherBody({super.key, required this.order});

  @override
  OnWayTogetherBodyState createState() => OnWayTogetherBodyState();
}

class OnWayTogetherBodyState extends State<OnWayTogetherBody> {
  // final Completer<GoogleMapController> _mapController = Completer();
  final locationController = Location();

  bool isLoading = false;

  GoogleMapController? mapStyleController;
  List<LatLng> polylineCoordinates = [];

  final Set<Marker> _markers = {};
  LatLng? currentPosition;
  LocationSettings? locationSettings;

  List order_customers = [];

  List isLoadingButton = [];

  Map<String, dynamic> order = {};

  QueryDocumentSnapshot<Map<String, dynamic>>? config_order;
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? config_order_customers;

  Completer<GoogleMapController> _googleMapController = Completer();
  Map<PolylineId, Polyline> _polylines = <PolylineId, Polyline>{};

  double? heading;

  UserModel? driver;

  bool isLoadingButtonFinish = false;
  bool isLoadingRejected = false;

  int _counter = 1;
  late Timer _timer;

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
    WidgetsBinding.instance.addPostFrameCallback((_) async => await initData());
  }

  Future<void> initData() async {
    setState(() {
      isLoading = true;
    });
    await getConfigOrder();

    await _determinePosition();
    await getOrder();
    await getConfigOrderCustomers();

    await buildwidget();

    getMarkers();
    setState(() {
      isLoading = false;
    });
  }

  _startTimer() {
    //shows timer
    _counter = 1; //time counter

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_counter == 60) {
        print(_counter);
        setState(() {
          _counter = 1;
        });
      } else {
        setState(() {
          _counter > 0 ? _counter++ : _timer.cancel();
        });
      }
    });
  }

  Future<void> reInitData() async {
    await getConfigOrder();

    await getOrder();
    await getConfigOrderCustomers();

    await buildwidget();

    getMarkers();
  }

  Future<void> initDataMore() async {
    await getOrder();
    await getConfigOrderCustomers();

    await buildwidget();

    getMarkers();
  }

  Future<void> getConfigOrder() async {
    final res = await FirebaseFirestore.instance
        .collection('config_orders')
        .where('order_id', isEqualTo: widget.order['id'])
        .get();

    setState(() {
      config_order = res.docs[0];
    });
  }

  Future<void> getOrder() async {
    Map<String, dynamic> getOrder =
        await SharedServices().getOrderById(widget.order['id'].toString());

    for (var i = 0; i < getOrder['order_customers'].length; i++) {
      setState(() {
        isLoadingButton.add({"isLoading": false});
      });
    }

    setState(() {
      order = getOrder;
      order_customers = getOrder['order_customers'];
    });
  }

  Future<void> getConfigOrderCustomers() async {
    final res = await FirebaseFirestore.instance
        .collection('config_order_customers')
        .where('config_order_id', isEqualTo: config_order!.id)
        .get();

    setState(() {
      config_order_customers = res.docs;
    });
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
          .doc(config_order!.id)
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

  Future<void> updateStatusAngkutMober(String order_customer_id) async {
    try {
      final res =
          await SharedServices().updateStatusAngkutMober(order_customer_id);

      if (res.isNotEmpty) {
        initDataMore();
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> finishOrderCustomerMober(String order_customer_id) async {
    try {
      final res =
          await SharedServices().finishOrderCustomerMober(order_customer_id);

      if (res.isNotEmpty) {
        initDataMore();
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  List<String> itemName = [
    'Fresh Red Onions',
    'Fresh Cauliflower',
    'Fresh Cauliflower',
  ];

  bool isOpen = false;

  Future<void> buildwidget() async {
    Map<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{};
    PolylinePoints polylinePoints = PolylinePoints();
    for (var i = 0; i < order_customers.length; i++) {
      List<LatLng> polylineCoordinates = [];
      List<LatLng> polylineCoordinates2 = [];

      // line customer
      if (order_customers[i]['status'] == 'diterima') {
        await Future.delayed(Duration(seconds: 1));
        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
            GOOGLE_API_KEY,
            PointLatLng(currentPosition!.latitude, currentPosition!.longitude),
            PointLatLng(order_customers[i]['latitude_current_customer'],
                order_customers[i]['longitude_current_customer']));

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
      if (order_customers[i]['status'] != 'selesai') {
        await Future.delayed(Duration(seconds: 2));
        PolylineResult result2 =
            await polylinePoints.getRouteBetweenCoordinates(
                GOOGLE_API_KEY,
                PointLatLng(
                    currentPosition!.latitude, currentPosition!.longitude),
                PointLatLng(order_customers[i]['latitude_destination'],
                    order_customers[i]['longitude_destination']));
        if (result2.points.isNotEmpty) {
          result2.points.forEach(
            (PointLatLng point) => polylineCoordinates2.add(
              LatLng(point.latitude, point.longitude),
            ),
          );
        }

        final Polyline polyline2 = Polyline(
            polylineId: PolylineId('polyline-oke${i.toString()}'),
            consumeTapEvents: true,
            points: polylineCoordinates2,
            color: kMainColor,
            width: 4,
            onTap: () {});

        polyLines[PolylineId('polyline-oke${i.toString()}')] = polyline2;
      }
    }

    if (mounted) {
      setState(() {
        _polylines = polyLines;
      });
    }
  }

  Future<void> finishOrderMober() async {
    Map<String, dynamic> res =
        await SharedServices().finishOrderMober(order['id'].toString());
    print(res);
    if (res['is_finish'] != null) {
      showCustomSnackbar(
          context, 'Masih ada penumpang yang belum diselesaikan');

      setState(() {
        isLoadingButtonFinish = false;
      });
    }

    if (res['id'] != null) {
      Navigator.pushNamedAndRemoveUntil(
          context, PageRoutes.accountPage, (route) => false);
    }
  }

  Future<bool> addCustomerMober(
      QueryDocumentSnapshot<Map<String, dynamic>> notif) async {
    final res = await SharedServices().addCustomerMober(
        notif['order_customer_id'].toString(), order['id'].toString());

    if (driver!.balance! < notif!['price_trip']) {
      showCustomSnackbar(context, 'Saldo isitas anda tidak mencukupi');

      return true;
    }

    if (res['is-ordered'] != null) {
      showCustomSnackbar(context, 'Orderan Sudah Diambil oleh driver lain');
      return false;
    }

    final res2 = await FirebaseFirestore.instance
        .collection('config_order_customers')
        .doc(notif.id)
        .update({"config_order_id": config_order!.id, "status": "diterima"});

    // delete Notif
    await FirebaseFirestore.instance
        .collection('notif_trips')
        .doc(notif.id)
        .delete();

    reInitData();

    showCustomSnackbarSuccess(context, 'Penumpang sudah di tambahkan');

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
              actions: [
                Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 2.0, vertical: 12.0),
                    child: FadedScaleAnimation(
                      fadeDuration: const Duration(milliseconds: 400),
                      scaleDuration: const Duration(milliseconds: 400),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: kGreenColor,
                        ),
                        onPressed: () {
                          // updateStatusTrip();
                          setState(() {
                            isLoadingButtonFinish = true;
                          });

                          finishOrderMober();
                        },
                        child: isLoadingButtonFinish
                            ? Center(
                                child: CircularProgressIndicator(),
                              )
                            : Text(
                                'Selesai',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                        color: kWhiteColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.7,
                                        letterSpacing: 0.06),
                              ),
                      ),
                    ))
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
                      order_customers == null ||
                      config_order_customers == null
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : buildBodyMober(),
              isLoading == null ||
                      currentPosition == null ||
                      order_customers == null ||
                      config_order_customers == null ||
                      isLoadingRejected
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('notif_trips')
                          .where('type_order', isEqualTo: 'mober')
                          .where('city_current_customer',
                              isEqualTo: driver!.city)
                          .snapshots(),
                      builder: ((context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final dataNotif = snapshot.data!.docs;
                        if (snapshot.data!.docs.isEmpty) {
                          return const SizedBox();
                        }

                        if (dataNotif.length != 0) {
                          for (var i = 0; i < dataNotif.length; i++) {
                            List listDrivers = dataNotif[i]['drivers'];
                            for (var i = 0; i < listDrivers.length; i++) {
                              if (listDrivers[i]['id'] == driver!.id) {
                                return Center(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: <Widget>[
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12),
                                              child: FadedScaleAnimation(
                                                scaleDuration: const Duration(
                                                    milliseconds: 400),
                                                fadeDuration: const Duration(
                                                    milliseconds: 400),
                                                child: Image.asset(
                                                  'images/footermenu/ic_profile.png',
                                                  scale: 5,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: ListTile(
                                                title: Text(
                                                  dataNotif[i]['name_customer'],
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall!
                                                      .copyWith(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                ),
                                                subtitle: Text(
                                                  '291023',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleLarge!
                                                      .copyWith(
                                                          fontSize: 11.7,
                                                          color: const Color(
                                                              0xffc1c1c1)),
                                                ),
                                                trailing: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: <Widget>[
                                                    Text(
                                                      dataNotif[i]['status'],
                                                      style:
                                                          orderMapAppBarTextStyle
                                                              .copyWith(
                                                                  color:
                                                                      kMainColor),
                                                    ),
                                                    const SizedBox(height: 7.0),
                                                    Text(
                                                      '${formatCurrency(dataNotif[0]['price_trip'])} | ${dataNotif[i]['payment_method']}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleLarge!
                                                          .copyWith(
                                                              fontSize: 11.7,
                                                              letterSpacing:
                                                                  0.06,
                                                              color: const Color(
                                                                  0xffc1c1c1)),
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
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16.0),
                                              child: Icon(
                                                Icons.location_on,
                                                color: kMainColor,
                                                size: 13.3,
                                              ),
                                            ),
                                            Text(
                                              dataNotif[i]
                                                  ['address_destination'],
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall!
                                                  .copyWith(
                                                      fontSize: 10.0,
                                                      letterSpacing: 0.05,
                                                      fontWeight:
                                                          FontWeight.bold),
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
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16.0),
                                              child: Icon(
                                                Icons.navigation,
                                                color: kMainColor,
                                                size: 13.3,
                                              ),
                                            ),
                                            Text(
                                              dataNotif[i]
                                                  ['address_current_customer'],
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall!
                                                  .copyWith(
                                                      fontSize: 10.0,
                                                      letterSpacing: 0.05,
                                                      fontWeight:
                                                          FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        if (dataNotif[i]['status'] == 'proses')
                                          const SizedBox(
                                            height: 10,
                                          ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            BottomBar(
                                              color: kGreenColor,
                                              width: 100,
                                              height: 30,
                                              text: 'Preview',
                                              onTap: () async {
                                                String? res =
                                                    await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              PreviewPage(
                                                            order: order,
                                                            order_customers:
                                                                order_customers,
                                                            notif: dataNotif[i],
                                                            config_order:
                                                                config_order,
                                                            polylines:
                                                                _polylines,
                                                          ),
                                                        ));

                                                if (res == 'diterima') {
                                                  addCustomerMober(
                                                      dataNotif[i]);
                                                } else if (res == 'tolak') {
                                                  rejectedCustomer(
                                                      dataNotif[i]);
                                                } else {}
                                              },
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            BottomBar(
                                              color: kRedColor,
                                              width: 100,
                                              height: 30,
                                              text: 'Tolak',
                                              onTap: () {
                                                rejectedCustomer(dataNotif[i]);
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        }

                        return const SizedBox();
                      })),
            ],
          ),
        ));
  }

  Widget buildBodyMober() {
    return Column(
      children: <Widget>[
        if (order_customers.isNotEmpty)
          Expanded(
            child: Stack(children: [
              GoogleMap(
                zoomControlsEnabled: false,
                polylines: Set<Polyline>.of(_polylines.values),
                mapType: MapType.normal,
                initialCameraPosition: CameraPosition(
                  target: currentPosition!,
                  zoom: 13,
                ),
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  if (!_googleMapController.isCompleted) {
                    _googleMapController.complete(controller);
                  }
                },
              ),
              if (order_customers.isNotEmpty)
                DraggableScrollableSheet(
                  maxChildSize: 0.7,
                  minChildSize: 0.5,
                  snap: true,
                  builder: (context, controller) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 120.0,
                              left: 18.0,
                              right: 18.0,
                              bottom: 18.0),
                          child: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                            child: BackButton(
                              color: Theme.of(context).secondaryHeaderColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: ListView(
                              controller: controller,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        height: 4,
                                        width: 100,
                                        margin: const EdgeInsets.only(top: 14),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          color: Theme.of(context).cardColor,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'Daftar Pelanggan',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                      const SizedBox(height: 20),
                                      ListView.separated(
                                        padding: const EdgeInsets.only(
                                          left: 16,
                                          right: 16,
                                          bottom: 30,
                                        ),
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemBuilder: ((context, index) {
                                          Map<String, dynamic> order_customer =
                                              order_customers[index];

                                          if (order_customer['status'] !=
                                              'proses') {
                                            return Column(
                                              children: [
                                                Row(
                                                  children: <Widget>[
                                                    Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12),
                                                      child:
                                                          FadedScaleAnimation(
                                                        scaleDuration:
                                                            const Duration(
                                                                milliseconds:
                                                                    400),
                                                        fadeDuration:
                                                            const Duration(
                                                                milliseconds:
                                                                    400),
                                                        child: Image.asset(
                                                          'images/footermenu/ic_profile.png',
                                                          scale: 5,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: ListTile(
                                                        title: Text(
                                                          order_customer[
                                                                  'customer']
                                                              ['name'],
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .bodySmall!
                                                              .copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                        ),
                                                        subtitle: Text(
                                                          order_customer[
                                                              'created_at'],
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .titleLarge!
                                                              .copyWith(
                                                                  fontSize:
                                                                      11.7,
                                                                  color: const Color(
                                                                      0xffc1c1c1)),
                                                        ),
                                                        trailing: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          children: <Widget>[
                                                            Text(
                                                              order_customer[
                                                                  'status'],
                                                              style: orderMapAppBarTextStyle
                                                                  .copyWith(
                                                                      color:
                                                                          kMainColor),
                                                            ),
                                                            const SizedBox(
                                                                height: 7.0),
                                                            Text(
                                                              "${formatCurrency(order_customer['price_trip'])} | ${order_customer['payment_method']}",
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .titleLarge!
                                                                  .copyWith(
                                                                      fontSize:
                                                                          11.7,
                                                                      letterSpacing:
                                                                          0.06,
                                                                      color: const Color(
                                                                          0xffc1c1c1)),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                                Divider(
                                                  color: Theme.of(context)
                                                      .cardColor,
                                                  thickness: 1.0,
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
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
                                                              builder:
                                                                  (context) =>
                                                                      ChatPage(
                                                                        order:
                                                                            order,
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
                                                            "whatsapp://send?phone=${formatPhoneNumber(order_customer['customer']['nohp'])}&text=p";
                                                        await launchUrl(
                                                            Uri.parse(
                                                                Uri.encodeFull(
                                                                    url)));
                                                      },
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        if (order_customer[
                                                                'status'] ==
                                                            'diterima') {
                                                          navigateMaps(
                                                              order_customer[
                                                                  'latitude_current_customer'],
                                                              order_customer[
                                                                  'longitude_current_customer']);
                                                        }

                                                        if (order_customer[
                                                                'status'] ==
                                                            'angkut') {
                                                          navigateMaps(
                                                              order_customer[
                                                                  'latitude_destination'],
                                                              order_customer[
                                                                  'longitude_destination']);
                                                        }
                                                      },
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                top: 0.0,
                                                                left: 0.0,
                                                                right: 0.0,
                                                                bottom: 0.0),
                                                        child: CircleAvatar(
                                                            backgroundColor: Theme
                                                                    .of(context)
                                                                .scaffoldBackgroundColor,
                                                            child: Image.asset(
                                                              'images/google-maps.png',
                                                              height: 20,
                                                            )),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: <Widget>[
                                                    Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 8.0,
                                                          horizontal: 16.0),
                                                      child: Icon(
                                                        Icons.location_on,
                                                        color: kMainColor,
                                                        size: 13.3,
                                                      ),
                                                    ),
                                                    Text(
                                                      order_customer[
                                                          'address_destination'],
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall!
                                                          .copyWith(
                                                              fontSize: 10.0,
                                                              letterSpacing:
                                                                  0.05,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
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
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 8.0,
                                                          horizontal: 16.0),
                                                      child: Icon(
                                                        Icons.navigation,
                                                        color: kMainColor,
                                                        size: 13.3,
                                                      ),
                                                    ),
                                                    Text(
                                                      order_customer[
                                                          'address_current_customer'],
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall!
                                                          .copyWith(
                                                              fontSize: 10.0,
                                                              letterSpacing:
                                                                  0.05,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                    ),
                                                  ],
                                                ),
                                                if (order_customer['status'] ==
                                                    'angkut')
                                                  isLoadingButton[index]
                                                          ['isLoading']
                                                      ? Container(
                                                          color: kMainColor,
                                                          height: 60.0,
                                                          width:
                                                              double.maxFinite,
                                                          child: Center(
                                                              child:
                                                                  CircularProgressIndicator()),
                                                        )
                                                      : BottomBar(
                                                          text: 'Selesai',
                                                          onTap: () async {
                                                            setState(() {
                                                              isLoadingButton[
                                                                          index]
                                                                      [
                                                                      'isLoading'] =
                                                                  true;
                                                            });

                                                            finishOrderCustomerMober(
                                                                order_customer[
                                                                        'id']
                                                                    .toString());

                                                            setState(() {
                                                              isLoadingButton[
                                                                          index]
                                                                      [
                                                                      'isLoading'] =
                                                                  false;
                                                            });
                                                            // updateStatusCustomer(
                                                            //     customers, 'angkut');
                                                          },
                                                        ),
                                                if (order_customer['status'] ==
                                                    'diterima')
                                                  isLoadingButton[index]
                                                          ['isLoading']
                                                      ? Container(
                                                          color: kMainColor,
                                                          height: 60.0,
                                                          width:
                                                              double.maxFinite,
                                                          child: Center(
                                                              child:
                                                                  CircularProgressIndicator()),
                                                        )
                                                      : BottomBar(
                                                          text: 'Angkut',
                                                          onTap: () async {
                                                            setState(() {
                                                              isLoadingButton[
                                                                          index]
                                                                      [
                                                                      'isLoading'] =
                                                                  true;
                                                            });

                                                            updateStatusAngkutMober(
                                                                order_customer[
                                                                        'id']
                                                                    .toString());

                                                            await Future
                                                                .delayed(
                                                                    Duration(
                                                                        seconds:
                                                                            3));

                                                            setState(() {
                                                              isLoadingButton[
                                                                          index]
                                                                      [
                                                                      'isLoading'] =
                                                                  false;
                                                            });
                                                            // updateStatusCustomer(
                                                            //     customers, 'angkut');
                                                          },
                                                        ),
                                              ],
                                            );
                                          }
                                        }),
                                        separatorBuilder: ((context, index) {
                                          return const SizedBox(height: 20);
                                        }),
                                        itemCount: order_customers.length,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ]),
          ),
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
      await Future.delayed(Duration(seconds: 10));

      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        print('teasd');
        // final res = await FirebaseFirestore.instance
        //     .collection('trips')
        //     .doc('driver_id_${widget.documentSnapshot!['driver_id']}')
        //     .collection('trip')
        //     .doc('${widget.documentSnapshot!.id}')
        //     .update({
        //   "latitude_current_driver": currentLocation.latitude,
        //   "longitude_current_driver": currentLocation.longitude
        // });

        currentPosition =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
      }
    });
  }

  void getMarkers() {
    _markers.clear();
    _markers.add(
      Marker(
          markerId: const MarkerId('driverasd'),
          position: currentPosition!,
          icon: markerss[1],
          rotation: heading!),
    );

    for (var i = 0; i < order_customers.length; i++) {
      if (order_customers[i]['status'] != 'proses') {
        if (order_customers[i]['status'] == 'diterima') {
          _markers.add(
            Marker(
                markerId: MarkerId('${order_customers[i]}'),
                position: LatLng(
                    order_customers[i]['latitude_current_customer'],
                    order_customers[i]['longitude_current_customer']),
                icon: BitmapDescriptor.defaultMarker),
          );
        }
      }

      if (order_customers[i]['status'] != 'selesai') {
        _markers.add(
          Marker(
            markerId: MarkerId('tujuan${order_customers[i]}'),
            position: LatLng(order_customers[i]['latitude_destination'],
                order_customers[i]['longitude_destination']),
            icon: markerss.last,
          ),
        );
      }
    }
  }

  // Future<void> updateStatusCustomer(
  //     DocumentSnapshot data, String status) async {
  //   if (status == 'selesai') {
  //     await FirebaseFirestore.instance
  //         .collection('orders')
  //         .doc('${widget.documentSnapshot!.id}')
  //         .update({
  //       "price_trip":
  //           widget.documentSnapshot!['price_trip'] + data['price_trip']
  //     });
  //     await FirebaseFirestore.instance
  //         .collection('order_customers')
  //         .doc(data.id)
  //         .update({"status": "selesai"});
  //   }

  //   if (status == 'angkut') {
  //     await FirebaseFirestore.instance
  //         .collection('order_customers')
  //         .doc('${data.id}')
  //         .update({"status": "angkut"});
  //   }
  // }

  Future<void> updateSaldo(DocumentSnapshot documentSnapshot) async {
    final token = await AuthService().getToken();
    if (documentSnapshot['payment_method'] == 'cash' ||
        documentSnapshot['payment_method'] == 'Tunai') {
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
          'mober',
          documentSnapshot['payment_method']);
    }
  }

  Future<void> rejectedCustomer(
      QueryDocumentSnapshot<Map<String, dynamic>> customer) async {
    // print(customer);

    List<dynamic> drivers = customer['drivers'];

    setState(() {
      isLoadingRejected = true;
    });

    Map<String, dynamic> foundDriver =
        drivers.firstWhere((element) => element['id'] == driver!.id);

    drivers.remove(foundDriver);

    // update notif by driver
    await FirebaseFirestore.instance
        .collection('notif_trips')
        .doc(customer.id)
        .update({"drivers": drivers});

    showCustomSnackbarSuccess(context, 'Berhasil Tolak Penumpang');

    setState(() {
      isLoadingRejected = false;
    });
  }

  Future<void> navigateMaps(double latitude, double longitude) async {
    await launchUrl(Uri.parse(
        'google.navigation:q=${latitude.toString()}, ${longitude.toString()}&key=${GOOGLE_API_KEY}'));
  }

  // Future<void> updateStatusTrip() async {
  //   await FirebaseFirestore.instance
  //       .collection('orders')
  //       .doc('${widget.documentSnapshot!.id}')
  //       .update({"status": "selesai"});
  // }
}
