import 'dart:async';
import 'dart:convert';
import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:deliq_delivery/Account/UI/account_page.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/services/auth_service.dart';
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

class OnWayToDestinationPage extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onStatusChanged;

  const OnWayToDestinationPage({
    super.key,
    required this.order,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderMapBloc>(
      create: (context) => OrderMapBloc()..loadMap(),
      child: OnWayToDestinationBody(
        order: order,
        onStatusChanged: onStatusChanged,
      ),
    );
  }
}

class OnWayToDestinationBody extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onStatusChanged;

  const OnWayToDestinationBody({
    super.key,
    required this.order,
    this.onStatusChanged,
  });

  @override
  OnWayBodyToDestinationState createState() => OnWayBodyToDestinationState();
}

class OnWayBodyToDestinationState extends State<OnWayToDestinationBody> {
  final locationController = Location();

  GoogleMapController? mapStyleController;
  bool isLoading = false;
  bool isLoadingButton = false;

  UserModel? driver;
  LatLng? currentPosition;

  Map<PolylineId, Polyline> _polylines = <PolylineId, Polyline>{};
  double? heading;
  LocationSettings? locationSettings;
  Map<String, dynamic> getSettings = {};

  final Completer<GoogleMapController> _googleMapController = Completer();

  double? distanceToDestination;
  bool isNearDestination = false;
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

  double calculateDistanceToDestination() {
    if (currentPosition == null) {
      return double.infinity;
    }

    return Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      widget.order['destination_lat'],
      widget.order['destination_lng'],
    );
  }

  bool checkIfNearDestination() {
    double distance = calculateDistanceToDestination();
    return distance >= MINIMUM_DISTANCE_METERS;
  }

  Future<Map<PolylineId, Polyline>> buildwidget() async {
    List<LatLng> polylineCoordinates = [];
    Map<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{};
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      GOOGLE_API_KEY,
      PointLatLng(currentPosition!.latitude, currentPosition!.longitude),
      PointLatLng(
        widget.order['destination_lat'],
        widget.order['destination_lng'],
      ),
    );
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        );
      }
    }

    final Polyline polyline = Polyline(
      polylineId: const PolylineId('polyline-target'),
      consumeTapEvents: true,
      points: polylineCoordinates,
      color: kMainColor,
      width: 4,
      onTap: () {},
    );
    polyLines[const PolylineId('polyline-target')] = polyline;

    if (mounted) {
      setState(() {
        _polylines = polyLines;
      });
    }

    return polyLines;
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

    if (mounted && position != null) {
      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
        heading = position.heading;

        distanceToDestination = calculateDistanceToDestination();
        isNearDestination = checkIfNearDestination();
      });
    }

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position? position) async {
      if (mounted && position != null) {
        moveToPosition(LatLng(position.latitude, position.longitude));
        setState(() {
          currentPosition = LatLng(position.latitude, position.longitude);
          heading = position.heading;
          distanceToDestination = calculateDistanceToDestination();
          isNearDestination = checkIfNearDestination();
        });
      }
    });
  }

  Future<void> update() async {
    try {
      final token = await AuthService().getToken();

      final response = await http.post(
        Uri.parse('https://api.digojek.com/api/driver/update-order-status'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "order_id": widget.order['order_id'],
          "status": "completed",
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
            content: Text(data['message'] ?? 'Gagal menyelesaikan order'),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan')),
      );
    }

    if (mounted) {
      setState(() {
        isLoadingButton = false;
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
      drawer: const AccountPageBody(),
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
                : BlocBuilder<OrderMapBloc, OrderMapState>(
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
                            rotation: heading ?? 0.0,
                            icon: driver?.vehicletype == 'Motor' ||
                                    driver?.vehicletype == 'motor'
                                ? markerss.first
                                : markerss[1],
                          ),
                          Marker(
                            markerId: const MarkerId('mark2'),
                            position: LatLng(
                              widget.order['destination_lat'],
                              widget.order['destination_lng'],
                            ),
                            icon: markerss.last,
                          ),
                        },
                        onMapCreated: (GoogleMapController controller) {
                          if (!_googleMapController.isCompleted) {
                            _googleMapController.complete(controller);
                          }
                        },
                      );
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

                        // Distance Banner & Navigation Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Expanded(child: buildDestinationDistanceInfo()),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => navigateMaps(widget.order),
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
                              _buildVehicleIcon(widget.order['type_order']),
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

                        const SizedBox(height: 16),

                        // Visual Alamat Jemput & Tujuan
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
                          child: buildSelesaiButton(),
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

  Widget _buildVehicleIcon(String? typeOrder) {
    String assetPath = 'images/image1.png';

    if (typeOrder == 'motor') {
      assetPath = 'images/bike1.png';
    } else if (typeOrder == 'Bajaj') {
      assetPath = 'images/bajaj.png';
    } else if (typeOrder == 'Bentor') {
      assetPath = 'images/becak.png';
    }

    return Image.asset(
      assetPath,
      height: 38,
      width: 38,
      fit: BoxFit.contain,
    );
  }

  Widget buildDestinationDistanceInfo() {
    if (distanceToDestination == null) return const SizedBox.shrink();

    String distanceText;
    Color distanceColor;
    IconData distanceIcon;

    if (distanceToDestination! < 1000) {
      distanceText =
          '${distanceToDestination!.toStringAsFixed(0)}m dari tujuan';
      distanceColor = distanceToDestination! <= MINIMUM_DISTANCE_METERS
          ? Colors.green.shade700
          : Colors.orange.shade800;
      distanceIcon = distanceToDestination! <= MINIMUM_DISTANCE_METERS
          ? Icons.check_circle_rounded
          : Icons.location_on_rounded;
    } else {
      distanceText =
          '${(distanceToDestination! / 1000).toStringAsFixed(1)}km dari tujuan';
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
          if (!isNearDestination)
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

  Widget buildSelesaiButton() {
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
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }

    if (!isNearDestination) {
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
                'Anda harus berada dalam jarak ${MINIMUM_DISTANCE_METERS.toInt()}m dari lokasi tujuan',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        },
        icon: const Icon(Icons.location_off, color: Colors.white, size: 20),
        label: const Text(
          'Terlalu Jauh - Selesai',
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
        await update();
      },
      child: const Text(
        'Selesai',
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
        // Realtime update logic if needed
      }
    });
  }

  moveToPosition(LatLng latLng) async {
    GoogleMapController mapController = await _googleMapController.future;
    mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, zoom: 16)));
  }

  Future<void> navigateMaps(data) async {
    await launchUrl(
      Uri.parse(
        'google.navigation:q=${widget.order['destination_lat']},${widget.order['destination_lng']}&key=$GOOGLE_API_KEY',
      ),
    );
  }
}
