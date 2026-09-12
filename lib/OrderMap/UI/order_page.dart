import 'dart:convert';

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/OrderMap/UI/onway.dart';
import 'package:deliq_delivery/OrderMap/UI/onway_to_destination.dart';
import 'package:deliq_delivery/OrderMap/UI/track_ride_screen.dart';
import 'package:deliq_delivery/OrderMap/UI/trip_ride_completed_screen.dart';
import 'package:deliq_delivery/OrderMap/UICabTogether/onway_together.dart';
import 'package:deliq_delivery/OrderMap/UIGrocier/track_grocier_screen.dart';
import 'package:deliq_delivery/OrderMap/UIPackage/onway_package.dart';
import 'package:deliq_delivery/OrderMap/UIPackage/onway_package_to_destination.dart';
import 'package:deliq_delivery/OrderMap/UIProduct/onway_product.dart';
import 'package:deliq_delivery/OrderMap/UIProduct/onway_product_to_destination.dart';
import 'package:deliq_delivery/OrderMap/UIProduct/track_product_screen.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/Themes/style.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/models/user_model.dart';
import 'package:deliq_delivery/services/auth_service.dart';
import 'package:deliq_delivery/services/shared_services.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  OrderPageState createState() => OrderPageState();
}

class OrderPageState extends State<OrderPage> {
  UserModel? driver;

  List listOrders = [];

  bool isLoading = false;

  @override
  void initState() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      driver = authState.user;
    }
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async => await initData());
  }

  @override
  void dispose() {
    super.dispose();
    // _anchoredBanner?.dispose();
  }

  Future<void> initData() async {
    setState(() {
      isLoading = true;
    });

    await getOrder();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> getOrder() async {
    try {
      final token = await AuthService().getToken();

      final response = await http.get(
        Uri.parse(
          'https://api.digojek.com/api/driver/order-history',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      debugPrint(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          listOrders = data['data'];
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  String formatStatus(String status) {
    switch (status) {
      case 'accepted':
        return 'Diterima';

      case 'completed':
        return 'Selesai';

      case 'cancelled':
        return 'Dibatalkan';

      case 'on_going':
        return 'Dalam Perjalanan';

      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(AppLocalizations.of(context)!.orderText!,
                  style: Theme.of(context).textTheme.bodyLarge),
              centerTitle: true,
            ),
            body: Stack(
              children: [
                if (listOrders.length == 0)
                  Center(
                    child: Image.asset('images/order.png'),
                  ),
                ListView.builder(
                  itemBuilder: (context, index) {
                    Map<String, dynamic> documentSnapshot = listOrders[index];

                    return GestureDetector(
                      onTap: () {
                        if (documentSnapshot['flow_type'] == 'ride') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrackRideScreen(
                                order_id:
                                    documentSnapshot['order_id'].toString(),
                              ),
                            ),
                          );
                        }

                        if (documentSnapshot['flow_type'] == 'delivery') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrackGrocierScreen(
                                order_id:
                                    documentSnapshot['order_id'].toString(),
                              ),
                            ),
                          );
                        }

                        if (documentSnapshot['flow_type'] == 'food') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrackProductScreen(
                                order_id:
                                    documentSnapshot['order_id'].toString(),
                              ),
                            ),
                          );
                        }

                        if (documentSnapshot['flow_type'] == 'together') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    OnWayTogetherPage(order: documentSnapshot)),
                          );
                        }

                        if (documentSnapshot['flow_type'] == 'delivery') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrackRideScreen(
                                order_id:
                                    documentSnapshot['order_id'].toString(),
                              ),
                            ),
                          );
                        }
                      },
                      child: Column(
                        children: [
                          Row(
                            children: <Widget>[
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: FadedScaleAnimation(
                                  scaleDuration:
                                      const Duration(milliseconds: 400),
                                  fadeDuration:
                                      const Duration(milliseconds: 400),
                                  // Ganti di sini
                                  child: Image.network(
                                    documentSnapshot['services']
                                        ['link_image'], // URL dari API
                                    height: 40,
                                    fit: BoxFit.contain,
                                    // Opsional: Handle jika gambar gagal loading
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.broken_image,
                                          size: 40);
                                    },
                                    // Opsional: Tampilkan loading selama gambar di-download
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const SizedBox(
                                        height: 40,
                                        width: 40,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              if (listOrders.isNotEmpty)
                                Expanded(
                                  child: ListTile(
                                    title: Text(
                                      documentSnapshot['type_order'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      documentSnapshot['created_at'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge!
                                          .copyWith(
                                              fontSize: 11.7,
                                              color: const Color(0xffc1c1c1)),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: <Widget>[
                                        Text(
                                          formatStatus(
                                              documentSnapshot['status']),
                                          style: orderMapAppBarTextStyle
                                              .copyWith(color: kMainColor),
                                        ),
                                        const SizedBox(height: 7.0),
                                        // Text(
                                        //   '${formatCurrency(documentSnapshot['price_trip'])} | ${documentSnapshot['payment_method']}',
                                        //   style: Theme.of(context)
                                        //       .textTheme
                                        //       .titleLarge!
                                        //       .copyWith(
                                        //           fontSize: 11.7,
                                        //           letterSpacing: 0.06,
                                        //           color: const Color(
                                        //               0xffc1c1c1)),
                                        // )
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
                          // Row(
                          //   children: <Widget>[
                          //     Padding(
                          //       padding: const EdgeInsets.symmetric(
                          //           vertical: 8.0, horizontal: 16.0),
                          //       child: Icon(
                          //         Icons.location_on,
                          //         color: kMainColor,
                          //         size: 13.3,
                          //       ),
                          //     ),
                          //     // Text(
                          //     //   documentSnapshot['address_destination'],
                          //     //   style: Theme.of(context)
                          //     //       .textTheme
                          //     //       .bodySmall!
                          //     //       .copyWith(
                          //     //           fontSize: 10.0,
                          //     //           letterSpacing: 0.05,
                          //     //           fontWeight: FontWeight.bold),
                          //     // ),
                          //     Text(
                          //       '(Union Market)',
                          //       style: Theme.of(context)
                          //           .textTheme
                          //           .bodySmall!
                          //           .copyWith(
                          //               fontSize: 10.0,
                          //               letterSpacing: 0.05),
                          //     ),
                          //   ],
                          // ),
                          // Row(
                          //   children: <Widget>[
                          //     Padding(
                          //       padding: const EdgeInsets.symmetric(
                          //           vertical: 8.0, horizontal: 16.0),
                          //       child: Icon(
                          //         Icons.navigation,
                          //         color: kMainColor,
                          //         size: 13.3,
                          //       ),
                          //     ),
                          //     // Text(
                          //     //   documentSnapshot[
                          //     //       'address_current_customer'],
                          //     //   style: Theme.of(context)
                          //     //       .textTheme
                          //     //       .bodySmall!
                          //     //       .copyWith(
                          //     //           fontSize: 10.0,
                          //     //           letterSpacing: 0.05,
                          //     //           fontWeight: FontWeight.bold),
                          //     // ),
                          //     Text(
                          //       '\t(Central Residency)',
                          //       style: Theme.of(context)
                          //           .textTheme
                          //           .bodySmall!
                          //           .copyWith(
                          //               fontSize: 10.0,
                          //               letterSpacing: 0.05),
                          //     ),
                          //   ],
                          // ),
                        ],
                      ),
                    );
                  },
                  itemCount: listOrders.length,
                )
              ],
            ));
      },
    );
  }

  Widget buildOrderMober(DocumentSnapshot documentSnapshot) {
    return GestureDetector(
      onTap: () {
        if (documentSnapshot['status'] == 'lanjut') {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => OnWayTogetherPage(
          //       documentSnapshot: documentSnapshot,
          //     ),
          //   ),
          // );
        }
      },
      child: Column(
        children: [
          Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: FadedScaleAnimation(
                  scaleDuration: const Duration(milliseconds: 400),
                  fadeDuration: const Duration(milliseconds: 400),
                  child: Image.asset(
                    'images/image1.png',
                    height: 19,
                  ),
                ),
              ),
              Expanded(
                child: ListTile(
                  title: Text(
                    documentSnapshot['type_order'],
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    documentSnapshot['date'],
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontSize: 11.7, color: const Color(0xffc1c1c1)),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        formatStatus(documentSnapshot['status']),
                        style:
                            orderMapAppBarTextStyle.copyWith(color: kMainColor),
                      ),
                      const SizedBox(height: 7.0),
                      Text(
                        'Rp ${documentSnapshot['price']}',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              fontSize: 11.7,
                              color: const Color(0xffc1c1c1),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        documentSnapshot['payment_method'],
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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
        ],
      ),
    );
  }
}
