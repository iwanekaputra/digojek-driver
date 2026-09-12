import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:deliq_delivery/Components/list_tile.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/models/user_model.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PaymentPpobPage extends StatefulWidget {
  PaymentPpobPage({super.key});

  @override
  State<PaymentPpobPage> createState() => _PaymentPpobPageState();
}

class _PaymentPpobPageState extends State<PaymentPpobPage> {
  UserModel? customer;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      customer = authState.user;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Function()? onTap =
    //     ModalRoute.of(context)?.settings.arguments as Function()?;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64.0),
        child: AppBar(
          automaticallyImplyLeading: true,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Pilih Mode Pembayaran',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(
                height: 8.0,
              ),
              Text(
                'Jumlah yang harus dibayar',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(color: kDisabledColor),
              ),
            ],
          ),
        ),
      ),
      body: FadedSlideAnimation(
        beginOffset: const Offset(0, 0.3),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: ListView(
          children: <Widget>[
            Divider(
              color: Theme.of(context).cardColor,
              thickness: 6.7,
            ),
            ListTile(
              onTap: () {
                Navigator.pop(context, 'Saldo');
              },
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
              leading: FadedScaleAnimation(
                scaleDuration: const Duration(milliseconds: 400),
                fadeDuration: const Duration(milliseconds: 400),
                child: Image.asset(
                  'images/payment/payment_cod.png',
                  height: 25.3,
                ),
              ),
              title: Text(
                AppLocalizations.of(context)!.wallet!,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium!
                    .copyWith(fontWeight: FontWeight.w500, letterSpacing: 0.07),
              ),
              trailing: Text(
                formatCurrency(customer!.balance),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: kDisabledColor),
              ),
            ),
            // BuildListTile(
            //   onTap: () {
            //     Navigator.pop(context, 'Tunai');
            //   },
            //   image: 'images/payment/payment_cod.png',
            //   text: AppLocalizations.of(context)!.cod,
            // ),
            // Container(
            //   color: Theme.of(context).cardColor,
            // )
          ],
        ),
      ),
    );
  }
}
