import 'dart:async';
import 'dart:convert';

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliq_delivery/Account/UI/account_page.dart';
import 'package:deliq_delivery/Chat/UI/chat_page.dart';
import 'package:deliq_delivery/Components/bottom_bar.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/OrderMap/UI/onway_to_destination.dart';
import 'package:deliq_delivery/OrderMapBloc/order_map_bloc.dart';
import 'package:deliq_delivery/Themes/colors.dart';
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
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class OnWayPage extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onStatusChanged;
  OnWayPage({super.key, required this.order, this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderMapBloc>(
      create: (context) => OrderMapBloc()..loadMap(),
      child: OnWayBody(
        order: order,
        onStatusChanged: onStatusChanged,
      ),
    );
  }
}

class OnWayBody extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onStatusChanged;
  OnWayBody({super.key, required this.order, this.onStatusChanged});

  @override
  OnWayBodyState createState() => OnWayBodyState();
}

class OnWayBodyState extends State<OnWayBody> {
  final locationController = Location();

  GoogleMapController? mapStyleController;
  List<LatLng> polylineCoordinates = [];
  LocationSettings? locationSettings;

  LatLng? currentPosition;
  bool isLoadingButton = false;
  double? heading;

  Map<PolylineId, Polyline> _polylines = <PolylineId, Polyline>{};
  UserModel? driver;
  Completer<GoogleMapController> _googleMapController = Completer();

  double? distanceToCustomer;
  bool isNearCustomer = false;
  static const double MINIMUM_DISTANCE_METERS = 100.0;

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
    });
    await _determinePosition();
    await buildwidget();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> updateStatusOrder() async {
    try {
      final token = await AuthService().getToken();

      final response = await http.post(
        Uri.parse(
          'https://api.digojek.com/api/driver/update-order-status',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "order_id": widget.order['order_id'],
          "status": "on_trip",
        }),
      );

      final data = jsonDecode(response.body);
      debugPrint(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          widget.onStatusChanged?.call();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? 'Gagal update status',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Terjadi kesalahan',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        isLoadingButton = false;
      });
    }
  }

  double calculateDistanceToCustomer() {
    if (currentPosition == null) {
      return double.infinity;
    }

    return Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      widget.order['pickup_lat'],
      widget.order['pickup_lng'],
    );
  }

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
        PointLatLng(widget.order['pickup_lat'], widget.order['pickup_lng']));
    if (result.points.isNotEmpty) {
      result.points.forEach(
        (PointLatLng point) => polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        ),
      );
    }

    final Polyline polyline = Polyline(
        polylineId: const PolylineId('polyline-target'),
        consumeTapEvents: true,
        points: polylineCoordinates,
        color: kMainColor,
        width: 4,
        onTap: () {});
    polyLines[const PolylineId('polyline-target')] = polyline;

    if (mounted) {
      setState(() {
        _polylines = polyLines;
      });
    }
  }

  Widget _buildCargoRowItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shipCargo = widget.order['ship_cargo'];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          AppLocalizations.of(context)!.newDeliveryTask!,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
        ),
      ),
      body: FadedSlideAnimation(
        beginOffset: const Offset(0, 0.1),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: Stack(
          children: <Widget>[
            isLoading || currentPosition == null
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : GoogleMap(
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
                        rotation: heading ?? 0.0,
                      ),
                      Marker(
                        markerId: const MarkerId('mark2'),
                        position: LatLng(
                          widget.order['pickup_lat'],
                          widget.order['pickup_lng'],
                        ),
                        icon: markerss[4],
                      ),
                    },
                    onMapCreated: (GoogleMapController controller) {
                      if (!_googleMapController.isCompleted) {
                        _googleMapController.complete(controller);
                      }
                    },
                  ),
            if (!isLoading && currentPosition != null)
              DraggableScrollableSheet(
                initialChildSize: 0.46,
                minChildSize: 0.28,
                maxChildSize: 0.85,
                snap: true,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          spreadRadius: 2,
                          offset: const Offset(0, -4),
                        )
                      ],
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 20),
                      children: <Widget>[
                        // Handle bar
                        Center(
                          child: Container(
                            height: 4,
                            width: 38,
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),

                        // Distance Banner & Navigation Map Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Expanded(child: buildDistanceInfo()),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: navigateMaps,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.grey.shade200),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 6,
                                      )
                                    ],
                                  ),
                                  child: Image.asset(
                                    'images/google-maps.png',
                                    height: 22,
                                    width: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Card Ringkasan Layanan & Harga
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: <Widget>[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.order['services']['link_image'],
                                  height: 40,
                                  width: 40,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                    Icons.directions_bike,
                                    size: 30,
                                    color: kMainColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.order['type_order'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Jarak: ${widget.order['distance'] ?? '0'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatCurrency(widget.order['price']),
                                style: TextStyle(
                                  color: kMainColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Card Informasi Customer
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: <Widget>[
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: kMainColor.withOpacity(0.1),
                                child: Icon(Icons.person,
                                    color: kMainColor, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.order['customer']['name'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.order['customer']['phone'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                icon: Icon(Icons.chat_bubble_outline,
                                    color: kMainColor, size: 20),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ChatPage(order: widget.order),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                icon: Icon(Icons.phone_outlined,
                                    color: kMainColor, size: 20),
                                onPressed: () async {
                                  final url =
                                      "whatsapp://send?phone=${formatPhoneNumber(widget.order['customer']['phone'])}&text=p";
                                  await launchUrl(
                                      Uri.parse(Uri.encodeFull(url)));
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Visual Alamat Jemput & Antar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Icon(Icons.circle,
                                      size: 12, color: kMainColor),
                                  Container(
                                    width: 2,
                                    height: 32,
                                    color: Colors.grey.shade300,
                                  ),
                                  const Icon(Icons.location_on,
                                      size: 14, color: Colors.redAccent),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'LOKASI JEMPUT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.order['pickup_address'] ?? '-',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'LOKASI TUJUAN',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.order['destination_address'] ??
                                          '-',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),

                        // Ship Cargo Section
                        if (shipCargo != null) ...[
                          const SizedBox(height: 16),
                          Divider(color: Colors.grey.shade200, thickness: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 20,
                            ),
                            child: const Text(
                              "DETAIL BARANG BAWAAN (SHIP CARGO)",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          _buildCargoRowItem("Nama Kapal Pelayaran",
                              "${shipCargo['ship_name']}"),
                          _buildCargoRowItem(
                              "Jenis Layanan Porter",
                              shipCargo['service_type'] == 'naik_ke_kapal'
                                  ? 'Naik ke Kapal'
                                  : 'Turun dari Kapal'),
                          _buildCargoRowItem(
                              "Estimasi Berat", "${shipCargo['weight_kg']} Kg"),
                          _buildCargoRowItem("Dimensi Barang",
                              "${shipCargo['length_cm']}x${shipCargo['width_cm']}x${shipCargo['height_cm']} cm"),
                          _buildCargoRowItem("Detail Titik Jemput",
                              "${shipCargo['origin_location']}"),
                          _buildCargoRowItem("Detail Lokasi Antar",
                              "${shipCargo['destination_location']}"),
                          _buildCargoRowItem("Catatan Fisik Penumpang",
                              "${shipCargo['notes'] ?? '-'}"),
                        ],

                        const SizedBox(height: 20.0),

                        // Action Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: buildAngkutButton(),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget buildDistanceInfo() {
    if (distanceToCustomer == null) return const SizedBox.shrink();

    String distanceText;
    Color distanceColor;
    IconData distanceIcon;

    if (distanceToCustomer! < 1000) {
      distanceText =
          '${distanceToCustomer!.toStringAsFixed(0)}m dari lokasi customer';
      distanceColor = distanceToCustomer! <= MINIMUM_DISTANCE_METERS
          ? Colors.green.shade700
          : Colors.orange.shade800;
      distanceIcon = distanceToCustomer! <= MINIMUM_DISTANCE_METERS
          ? Icons.check_circle_rounded
          : Icons.location_on_rounded;
    } else {
      distanceText =
          '${(distanceToCustomer! / 1000).toStringAsFixed(1)}km dari lokasi customer';
      distanceColor = Colors.red.shade700;
      distanceIcon = Icons.location_on_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: distanceColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: distanceColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(distanceIcon, color: distanceColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              distanceText,
              style: TextStyle(
                color: distanceColor,
                fontWeight: FontWeight.w600,
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
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget buildAngkutButton() {
    if (isLoadingButton) {
      return Container(
        height: 50.0,
        decoration: BoxDecoration(
          color: kMainColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (!isNearCustomer) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade400,
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Anda harus berada dalam jarak ${MINIMUM_DISTANCE_METERS.toInt()}m dari lokasi customer',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        },
        icon: const Icon(Icons.location_off, color: Colors.white, size: 20),
        label: const Text(
          'Terlalu Jauh - Angkut',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: kMainColor,
        elevation: 0,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () async {
        setState(() {
          isLoadingButton = true;
        });
        await updateStatusOrder();
      },
      child: const Text(
        'Angkut',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
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
      }
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await locationController.requestService();
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position? position = await Geolocator.getLastKnownPosition();

    if (mounted) {
      setState(() {
        currentPosition = LatLng(position!.latitude, position.longitude);
        heading = position.heading;

        distanceToCustomer = calculateDistanceToCustomer();
        isNearCustomer = checkIfNearCustomer();
      });
    }

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position? position) async {
      if (mounted && position != null) {
        moveToPosition(LatLng(position.latitude, position.longitude));
        setState(() {
          currentPosition = LatLng(position.latitude, position.longitude);
          heading = position.heading;

          distanceToCustomer = calculateDistanceToCustomer();
          isNearCustomer = checkIfNearCustomer();
        });
      }
    });
  }

  moveToPosition(LatLng latLng) async {
    GoogleMapController mapController = await _googleMapController.future;
    mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, zoom: 16)));
  }

  Future<void> navigateMaps() async {
    await launchUrl(Uri.parse(
        'google.navigation:q=${widget.order['pickup_lat']}, ${widget.order['pickup_lng']}&key=${GOOGLE_API_KEY}'));
  }
}
