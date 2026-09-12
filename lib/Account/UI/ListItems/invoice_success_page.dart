import "package:deliq_delivery/Components/bottom_bar.dart";
import "package:deliq_delivery/Routes/routes.dart";
import "package:deliq_delivery/blocs/auth/auth_bloc.dart";
import "package:deliq_delivery/models/deposit_model.dart";
import "package:deliq_delivery/shared/shared_methods.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class InvoiceSuccessPage extends StatefulWidget {
  final DepositModel data;

  const InvoiceSuccessPage({super.key, required this.data});

  @override
  State<InvoiceSuccessPage> createState() => _InvoiceSuccessPageState();
}

class _InvoiceSuccessPageState extends State<InvoiceSuccessPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            Navigator.pushNamedAndRemoveUntil(
                context, PageRoutes.accountPage, (route) => false);
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
                        'Detail Deposit ',
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
                        'Kode Unik',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontSize: 16),
                      ),
                      // Text(
                      //   widget.data.code.toString(),
                      //   style: Theme.of(context)
                      //       .textTheme
                      //       .headlineSmall
                      //       ?.copyWith(fontSize: 16),
                      // ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nama Pemilik Bank',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontSize: 16),
                      ),
                      // Text(
                      //   widget.data.nameOwnerBank,
                      //   style: Theme.of(context)
                      //       .textTheme
                      //       .headlineSmall
                      //       ?.copyWith(fontSize: 16),
                      // ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'No Rekening',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontSize: 16),
                      ),
                      // Text(
                      //   widget.data.accountNumber,
                      //   style: Theme.of(context)
                      //       .textTheme
                      //       .headlineSmall
                      //       ?.copyWith(fontSize: 16),
                      // ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tipe Bank',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontSize: 16),
                      ),
                      // Text(
                      //   widget.data.bankType,
                      //   style: Theme.of(context)
                      //       .textTheme
                      //       .headlineSmall
                      //       ?.copyWith(fontSize: 16),
                      // ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nominal',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontSize: 16),
                      ),
                      Text(
                        formatCurrency(widget.data.totalPrice),
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
                        'Seluruh Total',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontSize: 16),
                      ),
                      Text(
                        formatCurrency(widget.data.grandTotal),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontSize: 16),
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
                        'Status',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontSize: 16),
                      ),
                      Text(
                        widget.data.status,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
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
