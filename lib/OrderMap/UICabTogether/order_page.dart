import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/OrderMap/UI/onway.dart';
import 'package:deliq_delivery/OrderMap/UI/onway_to_destination.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/Themes/style.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/models/user_model.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  OrderPageState createState() => OrderPageState();
}

class OrderPageState extends State<OrderPage> {
  // static const AdRequest request = AdRequest(
  //   keywords: <String>['foo', 'bar'],
  //   contentUrl: 'http://foo.com/bar.html',
  //   nonPersonalizedAds: true,
  // );

  // BannerAd? _anchoredBanner;
  // bool _loadingAnchoredBanner = false;

  // Future<void> _createAnchoredBanner(BuildContext context) async {
  //   final AnchoredAdaptiveBannerAdSize? size =
  //       await AdSize.getAnchoredAdaptiveBannerAdSize(
  //     Orientation.portrait,
  //     MediaQuery.of(context).size.width.truncate(),
  //   );

  //   if (size == null) {
  //     debugPrint('Unable to get height of anchored banner.');
  //     return;
  //   }

  //   final BannerAd banner = BannerAd(
  //     size: size,
  //     request: request,
  //     adUnitId: Platform.isAndroid
  //         ? 'ca-app-pub-3940256099942544/6300978111'
  //         : 'ca-app-pub-3940256099942544/2934735716',
  //     listener: BannerAdListener(
  //       onAdLoaded: (Ad ad) {
  //         debugPrint('$BannerAd loaded.');
  //         setState(() {
  //           _anchoredBanner = ad as BannerAd?;
  //         });
  //       },
  //       onAdFailedToLoad: (Ad ad, LoadAdError error) {
  //         debugPrint('$BannerAd failedToLoad: $error');
  //         ad.dispose();
  //       },
  //       onAdOpened: (Ad ad) => debugPrint('$BannerAd onAdOpened.'),
  //       onAdClosed: (Ad ad) => debugPrint('$BannerAd onAdClosed.'),
  //     ),
  //   );
  //   return banner.load();
  // }

  UserModel? driver;

  @override
  void initState() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      driver = authState.user;
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    // _anchoredBanner?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        // if (!_loadingAnchoredBanner) {
        //   _loadingAnchoredBanner = true;
        //   _createAnchoredBanner(context);
        // }
        return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(AppLocalizations.of(context)!.orderText!,
                  style: Theme.of(context).textTheme.bodyLarge),
              centerTitle: true,
            ),
            body: Stack(
              children: [
                StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('trips')
                        .doc('driver_id_${driver!.id.toString()}')
                        .collection('trip')
                        .orderBy('date', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Text('Tidak ada data'),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      return ListView.builder(
                        itemBuilder: (context, index) {
                          final DocumentSnapshot documentSnapshot =
                              snapshot.data!.docs[index];

                          return GestureDetector(
                            onTap: () {
                              if (documentSnapshot['status'] == 'diterima') {
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (context) => OnWayPage(
                                //       documentSnapshot: documentSnapshot,
                                //     ),
                                //   ),
                                // );
                              }

                              if (documentSnapshot['status'] == 'angkut') {
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (context) =>
                                //         OnWayToDestinationPage(
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: FadedScaleAnimation(
                                        scaleDuration:
                                            const Duration(milliseconds: 400),
                                        fadeDuration:
                                            const Duration(milliseconds: 400),
                                        child: Image.asset(
                                          'images/bike1.png',
                                          scale: 5,
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
                                              .copyWith(
                                                  fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          documentSnapshot['date'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge!
                                              .copyWith(
                                                  fontSize: 11.7,
                                                  color:
                                                      const Color(0xffc1c1c1)),
                                        ),
                                        trailing: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: <Widget>[
                                            Text(
                                              documentSnapshot['status'],
                                              style: orderMapAppBarTextStyle
                                                  .copyWith(color: kMainColor),
                                            ),
                                            const SizedBox(height: 7.0),
                                            Text(
                                              '${formatCurrency(documentSnapshot['price_trip'])} | ${documentSnapshot['payment_method']}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge!
                                                  .copyWith(
                                                      fontSize: 11.7,
                                                      letterSpacing: 0.06,
                                                      color: const Color(
                                                          0xffc1c1c1)),
                                            )
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
                                Row(
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0, horizontal: 16.0),
                                      child: Icon(
                                        Icons.location_on,
                                        color: kMainColor,
                                        size: 13.3,
                                      ),
                                    ),
                                    Text(
                                      documentSnapshot['address_destination'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                              fontSize: 10.0,
                                              letterSpacing: 0.05,
                                              fontWeight: FontWeight.bold),
                                    ),
                                    // Text(
                                    //   '(Union Market)',
                                    //   style: Theme.of(context)
                                    //       .textTheme
                                    //       .bodySmall!
                                    //       .copyWith(
                                    //           fontSize: 10.0,
                                    //           letterSpacing: 0.05),
                                    // ),
                                  ],
                                ),
                                Row(
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0, horizontal: 16.0),
                                      child: Icon(
                                        Icons.navigation,
                                        color: kMainColor,
                                        size: 13.3,
                                      ),
                                    ),
                                    Text(
                                      documentSnapshot[
                                          'address_current_customer'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                              fontSize: 10.0,
                                              letterSpacing: 0.05,
                                              fontWeight: FontWeight.bold),
                                    ),
                                    // Text(
                                    //   '\t(Central Residency)',
                                    //   style: Theme.of(context)
                                    //       .textTheme
                                    //       .bodySmall!
                                    //       .copyWith(
                                    //           fontSize: 10.0,
                                    //           letterSpacing: 0.05),
                                    // ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                        itemCount: snapshot.data!.docs.length,
                      );
                    })
              ],
            ));
      },
    );
  }
}
