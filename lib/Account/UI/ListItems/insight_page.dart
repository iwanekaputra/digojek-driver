import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliq_delivery/Account/UI/account_page.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/Routes/routes.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/models/user_model.dart';
import 'package:deliq_delivery/services/shared_services.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InsightPage extends StatelessWidget {
  const InsightPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AccountPageBody(),
      appBar: AppBar(
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.insight!,
          style: Theme.of(context)
              .textTheme
              .headlineMedium!
              .copyWith(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        titleSpacing: 0.0,
        // actions: <Widget>[
        //   Row(
        //     children: <Widget>[
        //       Text(
        //         AppLocalizations.of(context)!.today!.toUpperCase(),
        //         style: Theme.of(context).textTheme.headlineMedium!.copyWith(
        //             fontSize: 15.0, letterSpacing: 1.5, color: kMainColor),
        //       ),
        //       IconButton(
        //         icon: const Icon(Icons.arrow_drop_down),
        //         color: kMainColor,
        //         onPressed: () {
        //           /*....*/
        //         },
        //       )
        //     ],
        //   )
        // ],
      ),
      body: FadedSlideAnimation(
        beginOffset: const Offset(0, 0.3),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: const Insight(),
      ),
    );
  }
}

class Insight extends StatefulWidget {
  const Insight({super.key});

  @override
  State<Insight> createState() => _InsightState();
}

class _InsightState extends State<Insight> {
  UserModel? driver;

  int earning = 0;
  int totalOrder = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      driver = authState.user;
    }

    getTest();
  }

  Future<void> getTest() async {
    print(driver!.id.toString());
    Map<String, dynamic> res =
        await SharedServices().earningDriver(driver!.id.toString());

    setState(() {
      earning = res['earning'];
      totalOrder = res['count_order'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        // --- RINGKASAN PERFORMA (CARDS) ---
        Row(
          children: <Widget>[
            // Card Total Pesanan
            Expanded(
              child: _buildMetricCard(
                context,
                title: AppLocalizations.of(context)!.orders!,
                value: totalOrder.toString(),
                icon: Icons.shopping_bag_outlined,
                iconColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 12.0),
            // Card Pendapatan
            Expanded(
              child: _buildMetricCard(
                context,
                title: AppLocalizations.of(context)!.earnings!,
                value: formatCurrency(earning),
                icon: Icons.account_balance_wallet_outlined,
                iconColor: kMainColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20.0),

        // --- SECTION PENDAPATAN & DETAIL ACTION ---
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.earnings!.toUpperCase(),
                    style: theme.textTheme.titleMedium!.copyWith(
                      fontSize: 13.0,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Icon(Icons.trending_up_rounded, color: kMainColor, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                formatCurrency(earning),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              // Center(
              //   child: FadedScaleAnimation(
              //     fadeDuration: const Duration(milliseconds: 400),
              //     scaleDuration: const Duration(milliseconds: 400),
              //     child: Image(
              //       image: const AssetImage("images/graph.png"),
              //       color: kMainColor,
              //       colorBlendMode: BlendMode.color,
              //       height: 200.0,
              //     ),
              //   ),
              // ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, PageRoutes.walletPage),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.viewAll!.toUpperCase(),
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: kMainColor,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: kMainColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Padding(
        //   padding: const EdgeInsets.all(20.0),
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       Text(AppLocalizations.of(context)!.orders!.toUpperCase(),
        //           style: Theme.of(context)
        //               .textTheme
        //               .headlineMedium!
        //               .copyWith(fontSize: 15.0, letterSpacing: 1.5)),
        //       Center(
        //         child: FadedScaleAnimation(
        //           fadeDuration: const Duration(milliseconds: 400),
        //           scaleDuration: const Duration(milliseconds: 400),
        //           child: Image(
        //             image: const AssetImage("images/graph1.png"),
        //             color: kMainColor,
        //             colorBlendMode: BlendMode.color,
        //             height: 200.0,
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  // --- HELPER WIDGET METRIK DENGAN CARD ---
  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 14.0),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
