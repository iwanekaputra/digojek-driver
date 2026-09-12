import "package:deliq_delivery/Account/UI/account_page.dart";
import "package:deliq_delivery/Components/bottom_bar.dart";
import "package:deliq_delivery/Routes/routes.dart";
import "package:deliq_delivery/blocs/auth/auth_bloc.dart";
import "package:deliq_delivery/shared/shared_methods.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class PaymentSuccessTarikSaldoPage extends StatefulWidget {
  Map<String, dynamic> data;

  PaymentSuccessTarikSaldoPage({super.key, required this.data});

  @override
  State<PaymentSuccessTarikSaldoPage> createState() =>
      _PaymentSuccessTarikSaldoPageState();
}

class _PaymentSuccessTarikSaldoPageState
    extends State<PaymentSuccessTarikSaldoPage> {
  List info = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    info = widget.data['info'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => AccountPageBody()),
                (route) => false);
          }
        },
        builder: (context, state) {
          return Stack(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'images/excellence.png',
                        width: 250,
                        height: 210,
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      Text(
                        'Pembayaran Berhasil ',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: 20),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kode Produk',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontSize: 16),
                      ),
                      Text(
                        widget.data['code'],
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Metode Pembayaran',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontSize: 16),
                      ),
                      Text(
                        widget.data['payment_method'],
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontSize: 16),
                      ),
                      Text(
                        widget.data['message'],
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Column(
                    children: info.map((e) {
                      if (e['name'] == 'NOMINAL') {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              e['name'],
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontSize: 16),
                            ),
                            Text(
                              formatCurrency(int.parse(e['value'])),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontSize: 16),
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              e['name'],
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontSize: 16),
                            ),
                            Text(
                              e['value'],
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontSize: 16),
                            ),
                          ],
                        );
                      }
                    }).toList(),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    'TERIMA KASIH',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontSize: 20),
                  ),
                  Text(
                    'PT DIGOJEK',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontSize: 20),
                  ),

                  const SizedBox(
                    height: 40,
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('images/download.png'),
                      const SizedBox(
                        width: 20,
                      ),
                      Image.asset('images/print.png')
                    ],
                  ),

                  // ElevatedButton(
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Theme.of(context).primaryColor,
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(30.0),
                  //     ),
                  //   ),
                  //   onPressed: () {
                  //     context.read<AuthBloc>().add(AuthGetCurrentUser());
                  //   },
                  //   child: Padding(
                  //     padding: const EdgeInsets.symmetric(
                  //         horizontal: 12.0, vertical: 8.0),
                  //     child: Text(
                  //       'Kembali Ke Beranda',
                  //       style: Theme.of(context).textTheme.labelLarge,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  BottomBar(
                      onTap: () {
                        context.read<AuthBloc>().add(AuthGetCurrentUser());
                      },
                      text: 'Kembali Ke Beranda')
                ],
              ),
            ),
          ]);
        },
      ),
    );
  }
}
