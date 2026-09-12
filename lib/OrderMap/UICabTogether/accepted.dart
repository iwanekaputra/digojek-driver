import 'dart:async';

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:deliq_delivery/Account/UI/account_page.dart';
import 'package:deliq_delivery/Components/bottom_bar.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/OrderMap/UI/slide_up_panel.dart';
import 'package:deliq_delivery/OrderMapBloc/order_map_bloc.dart';
import 'package:deliq_delivery/OrderMapBloc/order_map_state.dart';
import 'package:deliq_delivery/Routes/routes.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../map_utils.dart';

class AcceptedPage extends StatelessWidget {
  const AcceptedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderMapBloc>(
      create: (context) => OrderMapBloc()..loadMap(),
      child: const AcceptedBody(),
    );
  }
}

class AcceptedBody extends StatefulWidget {
  const AcceptedBody({super.key});

  @override
  AcceptedBodyState createState() => AcceptedBodyState();
}

class AcceptedBodyState extends State<AcceptedBody> {
  final Completer<GoogleMapController> _mapController = Completer();
  GoogleMapController? mapStyleController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    rootBundle.loadString('images/map_style.txt').then((string) {
      mapStyle = string;
    });
    super.initState();
  }

  bool isOpen = false;

  @override
  Widget build(BuildContext context) {
    List<String?> itemName = [
      AppLocalizations.of(context)!.onion,
      AppLocalizations.of(context)!.cauliflower,
      AppLocalizations.of(context)!.tomatoes,
    ];
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
            actions: <Widget>[
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
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
            Column(
              children: <Widget>[
                Expanded(
                  child: BlocBuilder<OrderMapBloc, OrderMapState>(
                      builder: (context, state) {
                    return GoogleMap(
                      zoomControlsEnabled: false,
                      polylines: state.polylines,
                      mapType: MapType.normal,
                      initialCameraPosition: kGooglePlex,
                      markers: _markers,
                      onMapCreated: (GoogleMapController controller) async {
                        _mapController.complete(controller);
                        mapStyleController = controller;
                        mapStyleController!.setMapStyle(mapStyle);
                        setState(() {
                          _markers.add(
                            Marker(
                              markerId: const MarkerId('mark1'),
                              position: const LatLng(
                                  37.42796133580664, -122.085749655962),
                              icon: markerss.first,
                            ),
                          );
                          _markers.add(
                            Marker(
                              markerId: const MarkerId('mark2'),
                              position: const LatLng(
                                  37.42496133180663, -122.081743655960),
                              icon: markerss[1],
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
                        padding: const EdgeInsets.symmetric(horizontal: 16.3),
                        child: Row(
                          children: <Widget>[
                            Image.asset(
                              'images/vegetables_fruitsact.png',
                              height: 42.3,
                              width: 33.7,
                            ),
                            Expanded(
                              child: ListTile(
                                title: Text(
                                  AppLocalizations.of(context)!.vegetable!,
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
                                      '16.5 km ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge!
                                          .copyWith(
                                              fontSize: 11.7,
                                              letterSpacing: 0.06,
                                              color: kMainColor,
                                              fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '(20 min)',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge!
                                          .copyWith(
                                              fontSize: 11.7,
                                              letterSpacing: 0.06,
                                              color: const Color(0xffc1c1c1)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {/*...*/},
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.navigation,
                                    color: kMainColor,
                                    size: 14.0,
                                  ),
                                  const SizedBox(
                                    width: 8.0,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.direction!,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  AppLocalizations.of(context)!.store!,
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
                                Text(
                                  '1024, Hemiltone Street, Union Market, USA',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(
                                          fontSize: 11.0, letterSpacing: 0.05),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: FittedBox(
                              fit: BoxFit.fill,
                              child: Row(
                                children: <Widget>[
                                  IconButton(
                                    icon: Icon(
                                      Icons.message,
                                      color: kMainColor,
                                      size: 14.0,
                                    ),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                          context, PageRoutes.chatPage);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.phone,
                                      color: kMainColor,
                                      size: 14.0,
                                    ),
                                    onPressed: () {
                                      /*..........*/
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 5.0,
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Sam Smith',
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
                              Text(
                                '1024, Hemiltone Street, Union Market, USA',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                        fontSize: 11.0, letterSpacing: 0.05),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                      BottomBar(
                          text: AppLocalizations.of(context)!.markPicked,
                          onTap: () => {
                                // Navigator.popAndPushNamed(
                                //   context, PageRoutes.onWayPage)
                              }),
                    ],
                  ),
                )
              ],
            ),
            isOpen ? OrderInfoContainer(itemName) : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
