import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliq_delivery/Account/UI/account_page.dart';
import 'package:deliq_delivery/Chat/UI/chat_page.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/models/user_model.dart';
import 'package:deliq_delivery/services/shared_services.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:url_launcher/url_launcher.dart';

class TripProductCompletedScreen extends StatefulWidget {
  String order_id;
  TripProductCompletedScreen({super.key, required this.order_id});

  @override
  State<TripProductCompletedScreen> createState() =>
      _TripProductCompletedScreenState();
}

class _TripProductCompletedScreenState
    extends State<TripProductCompletedScreen> {
  int? customer_id;

  Map<String, dynamic> review = {};
  UserModel? driver;

  bool isLoading = false;

  List reviews = [];

  Map<String, dynamic> order = {};
  Map<String, dynamic> customer = {};
  Map<String, dynamic> vehicle = {};
  List order_products = [];
  List order_merchants = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final authState = context.read<AuthBloc>().state;

    if (authState is AuthSuccess) {
      customer_id = authState.user.id;
      driver = authState.user;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async => await initData());
  }

  Future<void> initData() async {
    setState(() {
      isLoading = true;
    });

    await getOrder();
    await getReview();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> getOrder() async {
    Map<String, dynamic> getOrder =
        await SharedServices().getOrderById(widget.order_id.toString());

    setState(() {
      order = getOrder;
      customer = getOrder['order_customers'][0]['customer'];
      order_products = getOrder['order_products'];
      order_merchants = getOrder['order_merchants'];

      vehicle = getOrder['driver']['vehicle'];
    });
  }

  Future<void> getReview() async {
    List res = await SharedServices().getReviewByOrderId(driver!.id.toString(),
        order['id'].toString(), customer['id'].toString());

    setState(() {
      reviews = res;
    });
  }

  // Future<void> updateRatingTrip(rating) async {
  //   final res = await FirebaseFirestore.instance
  //       .collection('reviews')
  //       .where('order_id', isEqualTo: widget.data!.id)
  //       .get();

  //   await FirebaseFirestore.instance
  //       .collection('reviews')
  //       .doc(res.docs[0].id)
  //       .update({
  //     'rating': rating,
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: vehicle.isEmpty
                  ? const SizedBox()
                  : SingleChildScrollView(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        // decoration: BoxDecoration(
                        //   boxShadow: [
                        //     BoxShadow(
                        //       blurRadius: 40,
                        //       color: Theme.of(context).hintColor,
                        //     ),
                        //   ],
                        //   color: Theme.of(context).scaffoldBackgroundColor,
                        //   borderRadius: const BorderRadius.vertical(
                        //     top: Radius.circular(20),
                        //   ),
                        // ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Stack(
                              alignment: AlignmentDirectional.topEnd,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const SizedBox(height: 8),
                                      // Align(
                                      //   child: Container(
                                      //     height: 4,
                                      //     width: 100,
                                      //     decoration: BoxDecoration(
                                      //       color: Theme.of(context)
                                      //           .hintColor
                                      //           .withOpacity(0.5),
                                      //       borderRadius:
                                      //           BorderRadius.circular(10),
                                      //     ),
                                      //   ),
                                      // ),
                                      const SizedBox(height: 28),
                                      Text(
                                        order['type_order'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Perjalanan selesai',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w400,
                                            ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                                Image.asset(
                                  'images/bike1.png',
                                  height: 60,
                                )
                              ],
                            ),
                            const SizedBox(height: 14),

                            const SizedBox(height: 14),
                            // Center(
                            //   child: RatingBar.builder(
                            //     initialRating: review['rating'] != null
                            //         ? review['rating']
                            //         : 0,
                            //     unratedColor: kDisabledColor,
                            //     glowColor: kMainColor,
                            //     itemBuilder: ((context, index) {
                            //       return const Icon(
                            //         Icons.star,
                            //         color: Color(0xffFFBA32),
                            //       );
                            //     }),
                            //     onRatingUpdate: (val) {
                            //       review['rating'] != null
                            //           ? updateRatingTrip(val)
                            //           : addRatingTrip(val);
                            //     },
                            //   ),
                            // ),
                            const SizedBox(height: 14),
                            Divider(
                              height: 6,
                              thickness: 6,
                              color: Theme.of(context).cardColor,
                            ),
                            const SizedBox(height: 14),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          vehicle['brand'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          vehicle['registration_number'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 16),
                                        // DashedLine(
                                        //   color: Theme.of(context)
                                        //       .dividerColor,
                                        // ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Text(
                                              customer['name'],
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(width: 12),
                                            Spacer(),
                                            GestureDetector(
                                              onTap: () {
                                                // Navigator.push(
                                                //   context,
                                                //   MaterialPageRoute(
                                                //     builder: (context) =>
                                                //         ChatPage(
                                                //       data: data,
                                                //     ),
                                                //   ),
                                                // );
                                              },
                                              child: Container(
                                                height: 30,
                                                width: 30,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border:
                                                      Border.all(width: 0.1),
                                                  color: Theme.of(context)
                                                      .scaffoldBackgroundColor,
                                                ),
                                                child: const Icon(
                                                  Icons.message,
                                                  size: 16,
                                                  color: Color(0xff009D06),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 20,
                                            ),
                                            GestureDetector(
                                              onTap: () async {
                                                final url =
                                                    "whatsapp://send?phone=${formatPhoneNumber(customer!['nohp'])}&text=p";
                                                await launchUrl(Uri.parse(
                                                    Uri.encodeFull(url)));
                                              },
                                              child: Container(
                                                height: 30,
                                                width: 30,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border:
                                                      Border.all(width: 0.1),
                                                  color: Theme.of(context)
                                                      .scaffoldBackgroundColor,
                                                ),
                                                child: const Icon(
                                                  Icons.call,
                                                  size: 16,
                                                  color: Color(0xff009D06),
                                                ),
                                              ),
                                            ),
                                            // Container(
                                            //   decoration: BoxDecoration(
                                            //     borderRadius:
                                            //         BorderRadius.circular(20),
                                            //     color:
                                            //         const Color(0xff7AC81F),
                                            //   ),
                                            //   padding:
                                            //       const EdgeInsets.symmetric(
                                            //           vertical: 2,
                                            //           horizontal: 6),
                                            //   child: Row(
                                            //     children: [
                                            //       Icon(
                                            //         Icons.star,
                                            //         size: 12,
                                            //         color: Theme.of(context)
                                            //             .scaffoldBackgroundColor,
                                            //       ),
                                            //       const SizedBox(width: 4),
                                            //       Text(
                                            //         '4.3',
                                            //         style: Theme.of(context)
                                            //             .textTheme
                                            //             .bodySmall
                                            //             ?.copyWith(
                                            //               color: Theme.of(
                                            //                       context)
                                            //                   .scaffoldBackgroundColor,
                                            //               fontSize: 12,
                                            //             ),
                                            //       ),
                                            //       const SizedBox(width: 2),
                                            //     ],
                                            //   ),
                                            // ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 18.0,
                                    ),
                                    child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          customer['link_image'],
                                          height: 60,
                                        )),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              color: Theme.of(context).cardColor,
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Detail pesanan',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Column(
                              children: order_merchants.map((merchant) {
                                return Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(merchant['merchant']['name']),
                                        IconButton(
                                          icon: Icon(
                                            Icons.phone,
                                            color: kMainColor,
                                            size: 14.0,
                                          ),
                                          onPressed: () async {
                                            final url =
                                                "whatsapp://send?phone=${formatPhoneNumber(merchant['merchant']['nohp'])}&text=p";
                                            await launchUrl(
                                                Uri.parse(Uri.encodeFull(url)));
                                          },
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: order_products.map((e) {
                                        if (e['merchant_id'] ==
                                            merchant['merchant']['id']) {
                                          return Container(
                                            color: Theme.of(context)
                                                .scaffoldBackgroundColor,
                                            child: ListTile(
                                              title: Text(
                                                e['product']['product_name'],
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineMedium!
                                                    .copyWith(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 15.0),
                                              ),
                                              subtitle: Text(
                                                'x ${e['quantity'].toString()}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall!
                                                    .copyWith(fontSize: 13.3),
                                              ),
                                              trailing: Text(
                                                '\ ${formatCurrency(e['total_price'])}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall!
                                                    .copyWith(fontSize: 13.3),
                                              ),
                                            ),
                                          );
                                        }

                                        return const SizedBox();
                                      }).toList(),
                                    )
                                  ],
                                );
                              }).toList(),
                            ),

                            Container(
                              color: Theme.of(context).cardColor,
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Detail perjalanan',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: const Color(0xff009D06),
                                    child: Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lokasi penjemputan',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(fontSize: 12),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      order['order_customers'][0]
                                          ['address_current_customer'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: const Color(0xffE9C12A),
                                    child: Icon(
                                      Icons.navigation,
                                      size: 14,
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lokasi drop off',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(fontSize: 12),
                                    ),
                                    const SizedBox(height: 6),
                                    // Text(
                                    //   order['order_customers'][0]
                                    //       ['address_destination'],
                                    //   style: Theme.of(context)
                                    //       .textTheme
                                    //       .bodySmall
                                    //       ?.copyWith(
                                    //         fontWeight: FontWeight.w600,
                                    //       ),
                                    // ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Divider(
                              height: 6,
                              thickness: 6,
                              color: Theme.of(context).cardColor,
                            ),
                            const SizedBox(height: 14),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Biaya perjalanan',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    formatCurrency(order['price_trip']),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(
                              height: 20,
                              indent: 20,
                              endIndent: 20,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Cara Pembayaran',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                  Image.asset(
                                    'images/account/ic_menu_wallet.png',
                                    height: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    order['order_customers'][0]
                                        ['payment_method'],
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                              height: 40,
                              thickness: 6,
                              color: Theme.of(context).cardColor,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Id pemesanan',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    order['no_order'],
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Dipesan di',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    order['created_at'],
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 8.0),
                                backgroundColor: kMainColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AccountPageBody(),
                                  ),
                                );
                              },
                              child: Text(
                                AppLocalizations.of(context)!.backToHome!,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
    );
  }
}
