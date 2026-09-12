import 'dart:async';

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliq_delivery/Account/UI/account_page.dart';
import 'package:deliq_delivery/Chat/UI/chat_page.dart';
import 'package:deliq_delivery/Components/bottom_bar.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/OrderMap/UI/onway_to_destination.dart';
import 'package:deliq_delivery/OrderMap/UI/slide_up_panel.dart';
import 'package:deliq_delivery/OrderMap/UIPackage/onway_package_to_destination%20copy.dart';
import 'package:deliq_delivery/OrderMap/UIPackage/onway_package_to_destination.dart';
// import 'package:deliq_delivery/OrderMap/UI/slide_up_panel.dart';
import 'package:deliq_delivery/OrderMapBloc/order_map_bloc.dart';
// import 'package:deliq_delivery/OrderMapBloc/order_map_state.dart';
// import 'package:deliq_delivery/Routes/routes.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/map_utils.dart';
import 'package:deliq_delivery/models/user_model.dart';
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

class OnWayPackagePage extends StatelessWidget {
  String order_id;
  final QueryDocumentSnapshot<Map<String, dynamic>>? config_order;
  final Map<String, dynamic> order;
  OnWayPackagePage(
      {super.key,
      required this.order_id,
      required this.config_order,
      required this.order});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderMapBloc>(
      create: (context) => OrderMapBloc()..loadMap(),
      child: OnWayPackageBody(
        order_id: order_id,
        order: order,
        config_order: config_order,
      ),
    );
  }
}

class OnWayPackageBody extends StatefulWidget {
  String order_id;
  final QueryDocumentSnapshot<Map<String, dynamic>>? config_order;
  final Map<String, dynamic> order;
  OnWayPackageBody(
      {super.key,
      required this.order_id,
      required this.config_order,
      required this.order});

  @override
  OnWayPackageBodyState createState() => OnWayPackageBodyState();
}

class OnWayPackageBodyState extends State<OnWayPackageBody> {
  // final Completer<GoogleMapController> _mapController = Completer();
  final locationController = Location();

  GoogleMapController? mapStyleController;
  List<LatLng> polylineCoordinates = [];
  LocationSettings? locationSettings;

  LatLng? currentPosition;

  bool isLoadingButton = false;

  double? heading;
  bool isOpen = false;

  List order_customers = [];

  // DocumentSnapshot? order_customers;

  Map<PolylineId, Polyline> _polylines = <PolylineId, Polyline>{};
  UserModel? driver;
  Completer<GoogleMapController> _googleMapController = Completer();

  // Tambahkan variable untuk distance validation
  double? distanceToCustomer;
  bool isNearCustomer = false;
  static const double MINIMUM_DISTANCE_METERS = 100.0; // 100 meter

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

  bool isLoading = false;

  Future<void> initData() async {
    setState(() {
      isLoading = true;
      order_customers = widget.order['order_customers'];
    });
    await _determinePosition();
    // await getOrder();
    // await getConfigOrder();

    await buildwidget();
    setState(() {
      isLoading = false;
    });
  }

  double calculateDistanceToCustomer() {
    if (currentPosition == null || order_customers.isEmpty) {
      return double.infinity;
    }

    return Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      order_customers[0]['latitude_current_customer'],
      order_customers[0]['longitude_current_customer'],
    );
  }

  // Method untuk check apakah driver sudah dekat dengan customer
  bool checkIfNearCustomer() {
    double distance = calculateDistanceToCustomer();
    return distance <= MINIMUM_DISTANCE_METERS;
  }

  Future<void> buildwidget() async {
    List<LatLng> polylineCoordinates = [];
    Map<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{};
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        GOOGLE_API_KEY,
        PointLatLng(currentPosition!.latitude, currentPosition!.longitude),
        PointLatLng(order_customers[0]['latitude_current_customer'],
            order_customers[0]['longitude_current_customer']));
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

    if (mounted) {
      setState(() {
        _polylines = polyLines;
      });
    }
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
              // if (polyLines != null)
              isLoading == null ||
                      currentPosition == null ||
                      order_customers == null
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Column(
                      children: [
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
                              markers: {
                                Marker(
                                    markerId: const MarkerId('mark1'),
                                    position: currentPosition!,
                                    icon: driver!.vehicletype == 'Motor' ||
                                            driver!.vehicletype == 'motor'
                                        ? markerss.first
                                        : markerss[1],
                                    rotation: heading!),
                                Marker(
                                  markerId: const MarkerId('mark2'),
                                  position: LatLng(
                                      order_customers[0]
                                          ['latitude_current_customer'],
                                      order_customers[0]
                                          ['longitude_current_customer']),
                                  icon: markerss.last,
                                ),
                              },
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
                              child: Column(children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        navigateMaps();
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

                                // Tambahkan info jarak ke customer di sini
                                buildCustomerDistanceInfo(),
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
                                                    fontWeight:
                                                        FontWeight.bold),
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
                                                    fontWeight:
                                                        FontWeight.bold),
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
                                // Ganti dengan tombol yang sudah divalidasi
                                buildAngkutButton(),
                              ])),
                      ],
                    ),
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

  Widget buildCustomerDistanceInfo() {
    if (distanceToCustomer == null) return SizedBox.shrink();

    String distanceText;
    Color distanceColor;
    IconData distanceIcon;

    if (distanceToCustomer! < 1000) {
      distanceText = '${distanceToCustomer!.toStringAsFixed(0)}m dari customer';
      distanceColor = distanceToCustomer! <= MINIMUM_DISTANCE_METERS
          ? Colors.green
          : Colors.orange;
      distanceIcon = distanceToCustomer! <= MINIMUM_DISTANCE_METERS
          ? Icons.check_circle
          : Icons.location_on;
    } else {
      distanceText =
          '${(distanceToCustomer! / 1000).toStringAsFixed(1)}km dari customer';
      distanceColor = Colors.red;
      distanceIcon = Icons.location_on;
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
              if (!isNearCustomer)
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
          if (order_customers.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: 24, top: 4),
              child: Text(
                order_customers[0]['customer']['name'] ?? 'Customer',
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

  // Update tombol Angkut dengan validasi jarak
  Widget buildAngkutButton() {
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

    // Jika belum dekat dengan customer
    if (!isNearCustomer) {
      return GestureDetector(
        onTap: () {
          // Tampilkan snackbar ketika tombol diklik tapi belum dekat
          String customerName = order_customers.isNotEmpty
              ? (order_customers[0]['customer']['name'] ?? 'customer')
              : 'customer';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Anda harus berada dalam jarak ${MINIMUM_DISTANCE_METERS.toInt()}m dari lokasi customer untuk mengangkut paket',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Detail',
                textColor: Colors.white,
                onPressed: () {
                  showPackageInfoDialog();
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
                Icon(Icons.location_off, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Terlalu Jauh - Angkut',
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

    // Jika sudah dekat dengan customer
    return BottomBar(
      text: 'Angkut',
      onTap: () async {
        setState(() {
          isLoadingButton = true;
        });
        await update();
      },
    );
  }

  // Dialog untuk menampilkan info paket dan customer
  void showPackageInfoDialog() {
    if (order_customers.isEmpty) return;

    var customer = order_customers[0]['customer'];
    var packageInfo = widget.order['order_packages'][0];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.local_shipping, color: kMainColor),
              SizedBox(width: 8),
              Text('Info Pickup Paket'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
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
                          Icon(Icons.info_outline,
                              color: Colors.blue, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Syarat Pickup:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Anda harus berada dalam radius ${MINIMUM_DISTANCE_METERS.toInt()}m dari customer untuk mengangkut paket.',
                        style: TextStyle(
                            fontSize: 11, color: Colors.blue.shade600),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Info Customer
                Text(
                  'Detail Customer:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 8),
                _buildInfoRow(
                    Icons.person, 'Nama', customer['name'] ?? 'Tidak ada nama'),
                _buildInfoRow(Icons.phone, 'No. HP',
                    customer['nohp'] ?? 'Tidak ada nomor'),
                _buildInfoRow(
                    Icons.location_on,
                    'Alamat',
                    order_customers[0]['address_current_customer'] ??
                        'Tidak ada alamat'),

                SizedBox(height: 16),

                // Info Package
                Text(
                  'Detail Paket:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 8),
                _buildInfoRow(Icons.person_outline, 'Penerima',
                    packageInfo['name_receiver'] ?? 'Tidak ada nama'),
                _buildInfoRow(Icons.category, 'Jenis Paket',
                    packageInfo['type_package'] ?? 'Tidak disebutkan'),
                _buildInfoRow(
                    Icons.scale, 'Berat', '${packageInfo['weight'] ?? 0} Kg'),
                _buildInfoRow(Icons.phone_outlined, 'HP Penerima',
                    packageInfo['nohp_receiver'] ?? 'Tidak ada nomor'),
                _buildInfoRow(
                    Icons.location_city,
                    'Tujuan',
                    order_customers[0]['address_destination'] ??
                        'Tidak ada alamat'),

                SizedBox(height: 16),

                // Status Jarak
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isNearCustomer ? Colors.green : Colors.red)
                        .withOpacity(0.1),
                    border: Border.all(
                        color: (isNearCustomer ? Colors.green : Colors.red)
                            .withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isNearCustomer ? Icons.check_circle : Icons.error,
                        color: isNearCustomer ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status Pickup:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              isNearCustomer
                                  ? 'Siap pickup paket'
                                  : 'Belum bisa pickup',
                              style: TextStyle(
                                color:
                                    isNearCustomer ? Colors.green : Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Jarak: ${distanceToCustomer! < 1000 ? '${distanceToCustomer!.toStringAsFixed(0)}m' : '${(distanceToCustomer! / 1000).toStringAsFixed(1)}km'}',
                              style: TextStyle(
                                color:
                                    isNearCustomer ? Colors.green : Colors.red,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            if (!isNearCustomer)
              TextButton(
                child: Text('Navigasi'),
                onPressed: () {
                  Navigator.of(context).pop();
                  navigateMaps();
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              label + ':',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
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
        setState(() {
          currentPosition =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });
        // final res2 = await FirebaseFirestore.instance
        //     .collection('orders')
        //     .doc(widget.documentSnapshot!.id)
        //     .update({
        //   "latitude_current_driver": currentLocation.latitude,
        //   "longitude_current_driver": currentLocation.longitude,
        //   "heading": currentLocation.heading
        // });
      }
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

        distanceToCustomer = calculateDistanceToCustomer();
        isNearCustomer = checkIfNearCustomer();
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

          distanceToCustomer = calculateDistanceToCustomer();
          isNearCustomer = checkIfNearCustomer();
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

  Future<void> update([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {}

    Map<String, dynamic> updateStatus = await SharedServices()
        .updateStatusOrder(widget.order_id.toString(), 'angkut');

    await FirebaseFirestore.instance
        .collection('config_orders')
        .doc(widget.config_order!.id)
        .update({'status': 'angkut'});

    // await FirebaseFirestore.instance
    //     .collection('orders')
    //     .doc(widget.documentSnapshot!.id)
    //     .update({
    //   'status': 'angkut',
    // });

    // await FirebaseFirestore.instance
    //     .collection('order_customers')
    //     .doc(documentSnapshot!.id)
    //     .update({
    //   'status': 'angkut',
    // });
  }

  Future<void> navigateMaps() async {
    await launchUrl(Uri.parse(
        'google.navigation:q=${order_customers[0]['latitude_current_customer']}, ${order_customers[0]['longitude_current_customer']}&key=${GOOGLE_API_KEY}'));
  }

  void debugPackageDistanceInfo() {
    print("=== Package Distance Debug Info ===");
    print("Current Position: $currentPosition");
    print(
        "Customer Position: ${order_customers.isNotEmpty ? LatLng(order_customers[0]['latitude_current_customer'], order_customers[0]['longitude_current_customer']) : 'No customer'}");
    print("Distance: ${distanceToCustomer?.toStringAsFixed(2)}m");
    print("Is Near Customer: $isNearCustomer");
    print("Minimum Distance: ${MINIMUM_DISTANCE_METERS}m");
    print("Package Type: ${widget.order['order_packages'][0]['type_package']}");
    print("===================================");
  }
}
