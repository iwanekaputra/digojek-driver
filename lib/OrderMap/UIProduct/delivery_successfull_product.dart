import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliq_delivery/Account/UI/account_page.dart';
import 'package:deliq_delivery/Components/bottom_bar.dart';
import 'package:deliq_delivery/Locale/locales.dart';
// import 'package:deliq_delivery/Routes/routes.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeliveriySuccessfullProduct extends StatefulWidget {
  Map<String, dynamic> order;
  DeliveriySuccessfullProduct({super.key, required this.order});

  @override
  State<DeliveriySuccessfullProduct> createState() =>
      _DeliveriySuccessfullProductState();
}

class _DeliveriySuccessfullProductState
    extends State<DeliveriySuccessfullProduct> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadedSlideAnimation(
        beginOffset: const Offset(0, 0.3),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: Column(
          children: <Widget>[
            const Spacer(
              flex: 1,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60.0),
              child: FadedScaleAnimation(
                fadeDuration: const Duration(milliseconds: 400),
                scaleDuration: const Duration(milliseconds: 400),
                child: Image.asset(
                  'images/logos/delivery.png',
                  // height: 236.7,
                  fit: BoxFit.fitWidth,
                  width: double.infinity,
                ),
              ),
            ),
            Text(
              AppLocalizations.of(context)!.delivered!,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontSize: 20,
                  color: Theme.of(context).secondaryHeaderColor,
                  letterSpacing: 0.1),
            ),
            Text(
              AppLocalizations.of(context)!.thankYou!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).secondaryHeaderColor,
                  fontWeight: FontWeight.normal),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(left: 31.0, right: 31.0),
              child: Row(
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        AppLocalizations.of(context)!.youDrived!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(color: const Color(0xff818181)),
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      Text(
                        '(${widget.order['order_customers'][0]['distance']})',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(
                                fontSize: 17, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      Text(
                        AppLocalizations.of(context)!.viewOrderInfo!,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(
                                color: kMainColor,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.08),
                      ),
                    ],
                  ),
                  const Spacer(
                    flex: 1,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        AppLocalizations.of(context)!.yourEarnings!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(color: const Color(0xff818181)),
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      Text(
                        formatCurrency(
                            widget.order['order_customers'][0]['price_trip']),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(
                                fontSize: 17, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      Text(
                        AppLocalizations.of(context)!.viewEarnings!,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(
                                color: kMainColor,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.08),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(
              flex: 1,
            ),
            BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthSuccess) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountPageBody(),
                    ),
                  );
                }
              },
              builder: (context, state) {
                return BottomBar(
                  text: AppLocalizations.of(context)!.backToHome,
                  onTap: () {
                    context.read<AuthBloc>().add(AuthGetCurrentUser());
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => const AccountPageState(),
                    //   ),
                    // );
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
