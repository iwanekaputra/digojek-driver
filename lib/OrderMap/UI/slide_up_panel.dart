import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:deliq_delivery/shared/shared_values.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderInfoContainer extends StatefulWidget {
  final List itemName;
  final int price_product;
  final String payment_method;
  final List merchants;
  final int price_trip;

  const OrderInfoContainer(this.itemName, this.price_product,
      this.payment_method, this.merchants, this.price_trip,
      {super.key});

  @override
  OrderInfoContainerState createState() => OrderInfoContainerState();
}

class OrderInfoContainerState extends State<OrderInfoContainer> {
  List<String> weight = [
    '1kg x 1',
    '1kg x 1',
    '1kg x 1',
  ];
  List<double> prices = [
    3.00,
    4.50,
    2.50,
  ];

  double sum() {
    double total = 0.00;
    for (int i = 0; i < prices.length; i++) {
      total += prices[i];
    }
    return total;
  }

  Future<void> navigateMaps(latitude, longitude) async {
    await launchUrl(Uri.parse(
        'google.navigation:q=${latitude.toString()}, ${longitude.toString()}&key=${GOOGLE_API_KEY}'));
  }

  @override
  Widget build(BuildContext context) {
    return FadedSlideAnimation(
      beginOffset: const Offset(0, 0.3),
      endOffset: const Offset(0, 0),
      slideCurve: Curves.linearToEaseOut,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        color: Theme.of(context).cardColor,
        height: MediaQuery.of(context).size.width - 40,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemCount: widget.merchants.length,
                itemBuilder: (BuildContext context, int index) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(widget.merchants[index]['merchant']['name']),
                          IconButton(
                            icon: Icon(
                              Icons.phone,
                              color: kMainColor,
                              size: 14.0,
                            ),
                            onPressed: () async {
                              final url =
                                  "whatsapp://send?phone=${formatPhoneNumber(widget.merchants[index]['merchant']['nohp'])}&text=p";
                              await launchUrl(Uri.parse(Uri.encodeFull(url)));
                            },
                          ),
                          GestureDetector(
                            onTap: () {
                              navigateMaps(
                                  widget.merchants[index]['merchant']
                                      ['latitude'],
                                  widget.merchants[index]['merchant']
                                      ['longitude']);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 0.0, left: 0.0, right: 0.0, bottom: 0.0),
                              child: CircleAvatar(
                                  backgroundColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  child: Image.asset(
                                    'images/google-maps.png',
                                    height: 20,
                                  )),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: widget.itemName.map((e) {
                          if (e['merchant_id'] ==
                              widget.merchants[index]['merchant']['id']) {
                            return Container(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              child: ListTile(
                                title: Text(
                                  e['product']['product_name'],
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium!
                                      .copyWith(
                                          fontWeight: FontWeight.w500,
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
                  // return Container(
                  //   color: Theme.of(context).scaffoldBackgroundColor,
                  //   child: ListTile(
                  //     title: Text(
                  //       widget.itemName[index]['name_product']!,
                  //       style: Theme.of(context)
                  //           .textTheme
                  //           .headlineMedium!
                  //           .copyWith(
                  //               fontWeight: FontWeight.w500, fontSize: 15.0),
                  //     ),
                  //     subtitle: Text(
                  //       'x ${widget.itemName[index]['quantity'].toString()}',
                  //       style: Theme.of(context)
                  //           .textTheme
                  //           .bodySmall!
                  //           .copyWith(fontSize: 13.3),
                  //     ),
                  //     trailing: Text(
                  //       '\ ${formatCurrency(widget.itemName[index]['total_price'])}',
                  //       style: Theme.of(context)
                  //           .textTheme
                  //           .bodySmall!
                  //           .copyWith(fontSize: 13.3),
                  //     ),
                  //   ),
                  // );
                },
              ),
            ),
            //SizedBox(height: 6.0),
            // Container(
            //   height: 50.0,
            //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
            //   color: Theme.of(context).cardColor,
            //   child: Row(
            //     children: [
            //       Image.asset(
            //         'images/custom/ic_instruction.png',
            //         scale: 3.5,
            //       ),
            //       const SizedBox(
            //         width: 15.0,
            //       ),
            //       Text(
            //         AppLocalizations.of(context)!.instruction!,
            //         style: Theme.of(context).textTheme.bodySmall,
            //       ),
            //     ],
            //   ),
            // ),

            Container(
              height: 50.0,
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Biaya Perjalanan',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .copyWith(color: kMainTextColor),
                    ),
                    Text(
                      '\ ${formatCurrency(widget.price_trip)}',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: kMainTextColor, fontWeight: FontWeight.bold),
                    ),
                  ]),
            ),

            Container(
              height: 50.0,
              color: kMainColor,
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      widget.payment_method,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .copyWith(color: kWhiteColor),
                    ),
                    Text(
                      '\ ${formatCurrency(widget.price_product)}',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: kWhiteColor, fontWeight: FontWeight.bold),
                    ),
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}
