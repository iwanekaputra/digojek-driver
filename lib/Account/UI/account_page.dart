import 'dart:async';

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:deliq_delivery/Account/UI/ListItems/menu_page.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/OrderMap/UI/order_page.dart';
import 'package:deliq_delivery/Routes/routes.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/map_utils.dart';
import 'package:deliq_delivery/models/user_model.dart';
import 'package:deliq_delivery/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class AccountPageBody extends StatefulWidget {
  const AccountPageBody({super.key});

  @override
  AccountPageBodyState createState() => AccountPageBodyState();
}

class AccountPageBodyState extends State<AccountPageBody> {
  GoogleMapController? mapController;
  final Set<Marker> _markers = {};
  LatLng? currentPosition;
  final locationController = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  UserModel? driver;
  bool isOffline = false;
  bool isMober = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initDriver();
    _startLocationListener();
  }

  void _initDriver() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      driver = authState.user;
      isOffline = driver!.status_driver == 'offline';
      isMober = driver!.is_mober == 1;
    }

    final token = await AuthService().getToken();
    print('Token: $token');
  }

  void _startLocationListener() async {
    if (!await locationController.serviceEnabled()) {
      await locationController.requestService();
    }

    if (await locationController.hasPermission() == PermissionStatus.denied) {
      final status = await locationController.requestPermission();
      if (status != PermissionStatus.granted) return;
    }

    _locationSubscription =
        locationController.onLocationChanged.listen((locationData) async {
      if (!mounted ||
          locationData.latitude == null ||
          locationData.longitude == null) return;

      currentPosition = LatLng(locationData.latitude!, locationData.longitude!);
      _updateMarkers();
      setState(() {});
    });
  }

  void _updateMarkers() {
    _markers.clear();
    if (currentPosition != null && driver != null) {
      String vehicleType = driver!.vehicletype!.toLowerCase();
      var driverIcon = markerss[1];

      if (vehicleType == 'motor') {
        driverIcon = markerss.first;
      } else if (vehicleType == 'ship_porter') {
        driverIcon = markerss[5];
      }

      _markers.add(
        Marker(
          markerId: const MarkerId('driver_marker'),
          position: currentPosition!,
          icon: driverIcon,
        ),
      );
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sembunyikan AppBar jika sedang berada di tab selain Beranda (Peta)
      appBar: _currentIndex == 0
          ? PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: AppBar(
                  title: Text(
                    isOffline
                        ? AppLocalizations.of(context)!.offlineText!
                        : AppLocalizations.of(context)!.onlineText!,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium!
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                  actions: [
                    if (driver != null &&
                        ['Sedan', 'MPV', 'SUV', 'MVP', 'Bus']
                            .contains(driver!.vehicletype))
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 12),
                        child: _buildMoberButton(context),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 12),
                      child: _buildOfflineOnlineButton(context),
                    ),
                  ],
                ),
              ),
            )
          : null,

      // IndexedStack menjaga halaman tetap aktif tanpa mereset status peta
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildMapBody(),
          const OrderPage(),
          const MenuPage(),
        ],
      ),

      floatingActionButton: (_currentIndex == 0 && !isOffline)
          ? FadedScaleAnimation(
              fadeDuration: const Duration(milliseconds: 400),
              scaleDuration: const Duration(milliseconds: 400),
              child: FloatingActionButton(
                backgroundColor: kMainColor,
                child: const Icon(Icons.list),
                onPressed: () =>
                    Navigator.pushNamed(context, PageRoutes.newDeliveryPage),
              ),
            )
          : null,

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: kMainColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_rounded),
              label: 'Order',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_rounded),
              label: 'Menu',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBody() {
    return currentPosition == null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('images/worldwide.gif', height: 180),
                Text("Sedang Mencari Posisimu!",
                    style: Theme.of(context).textTheme.bodyLarge)
              ],
            ),
          )
        : GoogleMap(
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            initialCameraPosition:
                CameraPosition(target: currentPosition!, zoom: 16),
            markers: _markers,
            onMapCreated: (controller) {
              mapController = controller;
            },
          );
  }

  Widget _buildMoberButton(BuildContext context) {
    return FadedScaleAnimation(
      fadeDuration: const Duration(milliseconds: 400),
      scaleDuration: const Duration(milliseconds: 400),
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: isMober ? kGreenColor : kRedColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: isMober ? kGreenColor : kRedColor),
          ),
        ),
        onPressed: () {
          setState(() => isMober = !isMober);
          context.read<AuthBloc>().add(
              AuthUpdateStatusMober(driver!.id.toString(), isMober ? 1 : 0));
        },
        child: Text(
          isMober ? 'Mober' : 'Mobil',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11.7,
              ),
        ),
      ),
    );
  }

  Widget _buildOfflineOnlineButton(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {},
      builder: (context, state) {
        return FadedScaleAnimation(
          fadeDuration: const Duration(milliseconds: 400),
          scaleDuration: const Duration(milliseconds: 400),
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: isOffline ? kRedColor : kGreenColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: isOffline ? kRedColor : kGreenColor),
              ),
            ),
            onPressed: () {
              setState(() => isOffline = !isOffline);
              context.read<AuthBloc>().add(AuthUpdateStatus(
                  isOffline ? 'offline' : 'online',
                  driver!.id.toString(),
                  currentPosition!.latitude.toString(),
                  currentPosition!.longitude.toString()));
            },
            child: Text(
              isOffline ? 'Offline' : 'Online',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.7,
                  ),
            ),
          ),
        );
      },
    );
  }
}
