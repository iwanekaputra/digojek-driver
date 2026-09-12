import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:deliq_delivery/Pages/transaction_purchase_detail.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/models/transaction_purchase_model.dart';
import 'package:deliq_delivery/services/shared_services.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:deliq_delivery/models/user_model.dart';

class TransactionPurchasePage extends StatelessWidget {
  const TransactionPurchasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaksi Pembelian',
            style: Theme.of(context)
                .textTheme
                .headlineMedium!
                .copyWith(fontWeight: FontWeight.w500)),
        titleSpacing: 0.0,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.more_vert),
          //   onPressed: () {/*......*/},
          // ),
        ],
      ),
      body: FadedSlideAnimation(
        beginOffset: const Offset(0, 0.3),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: const TransactionPurchase(),
      ),
    );
  }
}

class TransactionPurchase extends StatefulWidget {
  const TransactionPurchase({super.key});

  @override
  State<TransactionPurchase> createState() => _TransactionPurchaseState();
}

class _TransactionPurchaseState extends State<TransactionPurchase> {
  UserModel? customer;

  List<dynamic> listTransactionPurchases = [];

  bool isLoading = false;

  @override
  void initState() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      customer = authState.user;
    }
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async => await initData());
  }

  Future<void> initData() async {
    setState(() {
      isLoading = true;
    });

    await getTransactionPurchasesByDriverId();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> getTransactionPurchasesByDriverId() async {
    final res = await SharedServices()
        .getTransactionPurchasesByDriverId(customer!.id.toString());

    setState(() {
      listTransactionPurchases = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ListView(
        //   children: <Widget>[
        //     Padding(
        //       padding: const EdgeInsets.symmetric(vertical: 12.0),
        //       child: ListTile(
        //         title: Text(
        //           AppLocalizations.of(context)!.availableBalance!.toUpperCase(),
        //           style: Theme.of(context).textTheme.titleLarge!.copyWith(
        //               letterSpacing: 0.67,
        //               color: kHintColor,
        //               fontWeight: FontWeight.w500),
        //         ),
        //         subtitle: Text(
        //           formatCurrency(customer!.balance),
        //           style: listTitleTextStyle.copyWith(
        //               fontSize: 35.0, color: kMainColor, letterSpacing: 0.18),
        //         ),
        //       ),
        //     ),
        //     Container(
        //       height: 40.0,
        //       padding:
        //           const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        //       color: Theme.of(context).cardColor,
        //       child: Text(
        //         AppLocalizations.of(context)!.recent!,
        //         style: Theme.of(context).textTheme.titleSmall!.copyWith(
        //             color: kTextColor,
        //             fontWeight: FontWeight.w500,
        //             letterSpacing: 0.08),
        //       ),
        //     ),
        //     Divider(
        //       color: Theme.of(context).cardColor,
        //       thickness: 3.0,
        //     ),
        //   ],
        // ),

        // ListView.builder(
        //   // padding: const EdgeInsets.only(top: 150),
        //   itemBuilder: (context, index) {
        //     final deposit = listDeposits[index];

        //     return
        //   },
        //   itemCount: listDeposits.length,
        // ),

        isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : listTransactionPurchases.length == 0
                ? Center(
                    child: Text('Tidak Ada Data'),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children:
                          listTransactionPurchases.map((transactionPurchase) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        TransactionPurchaseDetail(
                                          data:
                                              TransactionPurchaseModel.fromJson(
                                                  transactionPurchase),
                                        )));
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 20.0, right: 20.0, top: 10.0),
                            child: Container(
                              color: Colors.white,
                              width: double.infinity,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(transactionPurchase['name'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall!
                                              .copyWith(
                                                  fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 10.0),
                                      Text(transactionPurchase['created_at'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge!
                                              .copyWith(
                                                  color: kTextColor,
                                                  fontSize: 11.7)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: <Widget>[
                                      Text(
                                        formatCurrency(
                                            transactionPurchase['grand_total']),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: kMainTextColor),
                                      ),
                                      const SizedBox(height: 10.0),
                                      Text(transactionPurchase['message'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge!
                                              .copyWith(
                                                  color: transactionPurchase[
                                                              'message'] ==
                                                          'proses'
                                                      ? kMainColor
                                                      : kGreenColor,
                                                  fontSize: 11.7)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
        // Positioned.directional(
        //   textDirection: Directionality.of(context),
        //   top: 70.0,
        //   end: 20.0,
        //   child: Container(
        //     height: 46.0,
        //     width: 134.0,
        //     color: kMainColor,
        //     child: TextButton(
        //       onPressed: () =>
        //           Navigator.pushNamed(context, PageRoutes.addMoney),
        //       style: TextButton.styleFrom(
        //         backgroundColor: kMainColor,
        //       ),
        //       child: Text(
        //         AppLocalizations.of(context)!.addMoney!,
        //         style: bottomBarTextStyle.copyWith(fontWeight: FontWeight.w500),
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
