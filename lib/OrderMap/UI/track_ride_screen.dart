import 'dart:convert';
import 'dart:math';

import 'package:deliq_delivery/Components/bottom_bar.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/OrderMap/UI/cancel_order_page.dart';
import 'package:deliq_delivery/OrderMap/UI/delivery_successful.dart';
import 'package:deliq_delivery/OrderMap/UI/onway%20copy.dart';
import 'package:deliq_delivery/OrderMap/UI/onway.dart';
import 'package:deliq_delivery/OrderMap/UI/onway_to_destination.dart';
import 'package:deliq_delivery/OrderMap/UI/trip_ride_completed_screen.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/models/sign_up_form_model.dart';
import 'package:deliq_delivery/models/user_model.dart';
import 'package:deliq_delivery/services/auth_service.dart';
import 'package:deliq_delivery/services/shared_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class TrackRideScreen extends StatefulWidget {
  final String order_id;
  TrackRideScreen({super.key, required this.order_id});

  @override
  State<TrackRideScreen> createState() => _TrackRideScreenState();
}

class _TrackRideScreenState extends State<TrackRideScreen> {
  bool isLoading = false;

  Map<String, dynamic> order = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initData();
    });
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
          'https://api.digojek.com/api/driver/order-detail/${widget.order_id}',
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
          order = data['data'];
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> refreshOrder() async {
    await getOrder();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (order.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('Order tidak ditemukan'),
        ),
      );
    }

    final String status = order['status'] ?? '';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refreshOrder,
          child: Stack(
            children: [
              /// DRIVER MENUJU PICKUP
              if (status == 'accepted')
                OnWayPage(
                  order: order,
                  onStatusChanged: () async {
                    await getOrder();
                  },
                ),

              /// DRIVER MENUJU TUJUAN
              if (status == 'on_trip')
                OnWayToDestinationPage(
                  order: order,
                  onStatusChanged: () async {
                    await getOrder();
                  },
                ),

              /// ORDER SELESAI
              if (status == 'completed')
                TripRideCompletedScreen(
                  order: order,
                ),

              /// ORDER DIBATALKAN
              if (status == 'cancelled') CancelOrderPage(),
            ],
          ),
        ),
      ),
    );
  }
}
