import 'dart:math';

import 'package:deliq_delivery/Components/bottom_bar.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/OrderMap/UI/cancel_order_page.dart';
import 'package:deliq_delivery/OrderMap/UI/delivery_successful.dart';
import 'package:deliq_delivery/OrderMap/UI/onway%20copy.dart';
import 'package:deliq_delivery/OrderMap/UI/onway.dart';
import 'package:deliq_delivery/OrderMap/UI/onway_to_destination.dart';
import 'package:deliq_delivery/OrderMap/UIProduct/delivery_successfull_product.dart';
import 'package:deliq_delivery/OrderMap/UIProduct/onway_product%20copy.dart';
import 'package:deliq_delivery/OrderMap/UIProduct/onway_product.dart';
import 'package:deliq_delivery/OrderMap/UIProduct/onway_product_to_destination.dart';
import 'package:deliq_delivery/OrderMap/UIProduct/trip_product_completed_screen.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/models/sign_up_form_model.dart';
import 'package:deliq_delivery/models/user_model.dart';
import 'package:deliq_delivery/services/auth_service.dart';
import 'package:deliq_delivery/services/shared_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrackProductScreen extends StatefulWidget {
  final String order_id;
  TrackProductScreen({super.key, required this.order_id});

  @override
  State<TrackProductScreen> createState() => _TrackProductScreenState();
}

class _TrackProductScreenState extends State<TrackProductScreen> {
  bool isLoading = false;
  UserModel? driver;

  String? status_order;
  Map<String, dynamic> order = {};

  QueryDocumentSnapshot<Map<String, dynamic>>? config_order;

  @override
  void initState() {
    super.initState();

    final authState = context.read<AuthBloc>().state;

    if (authState is AuthSuccess) {
      driver = authState.user;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async => await initData());
  }

  Future<void> initData() async {
    setState(() {
      isLoading = true;
    });

    await getOrder();
    await getConfigOrder();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> getOrder() async {
    Map<String, dynamic> getOrder =
        await SharedServices().getOrderById(widget.order_id.toString());

    setState(() {
      order = getOrder;
    });
  }

  Future<void> getConfigOrder() async {
    final res = await FirebaseFirestore.instance
        .collection('config_orders')
        .where('order_id', isEqualTo: int.parse(widget.order_id))
        .get();

    setState(() {
      config_order = res.docs[0];
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Stack(
                children: [
                  // if (order.isNotEmpty)
                  StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('config_orders')
                          .where('order_id',
                              isEqualTo: int.parse(widget.order_id))
                          .snapshots(),
                      builder: (context, snapshot) {
                        DocumentSnapshot? doc = snapshot.data?.docs[0];
                        if (doc != null) {
                          if (doc!['status'] == 'diterima') {
                            return OnWayProductPage(
                              order_id: widget.order_id.toString(),
                              config_order: config_order,
                              order: order,
                            );
                          }

                          if (doc!['status'] == 'angkut') {
                            return OnWayProductToDestination(
                              order_id: widget.order_id.toString(),
                              config_order: config_order,
                              order: order,
                            );
                          }
                          if (doc!['status'] == 'selesai') {
                            print(widget.order_id);
                            return TripProductCompletedScreen(
                              order_id: widget.order_id.toString(),
                            );
                          }
                          if (doc['status'] == 'dibatalkan') {
                            return CancelOrderPage();
                          }
                        }

                        return const SizedBox();
                      }),
                ],
              ),
      ),
    );
  }
}
