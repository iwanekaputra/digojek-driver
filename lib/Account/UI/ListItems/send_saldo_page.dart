import "dart:async";

import "package:animation_wrappers/animations/faded_slide_animation.dart";
import "package:deliq_delivery/Components/bottom_bar.dart";
import "package:deliq_delivery/Components/entry_field.dart";
import "package:deliq_delivery/Locale/locales.dart";
import "package:deliq_delivery/Pages/payment_ppob_page.dart";
import "package:deliq_delivery/Pages/transaction_purchase_detail.dart";
import "package:deliq_delivery/Routes/routes.dart";
import "package:deliq_delivery/Themes/colors.dart";
import "package:deliq_delivery/blocs/auth/auth_bloc.dart";
import "package:deliq_delivery/models/sign_up_form_model.dart";
import "package:deliq_delivery/models/transaction_purchase_model.dart";
import "package:deliq_delivery/models/user_model.dart";
import "package:deliq_delivery/services/auth_service.dart";
import "package:deliq_delivery/services/shared_services.dart";
import "package:deliq_delivery/shared/shared_methods.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class SendSaldoPage extends StatefulWidget {
  const SendSaldoPage({super.key});

  @override
  State<SendSaldoPage> createState() => _SendSaldoPageState();
}

class _SendSaldoPageState extends State<SendSaldoPage> {
  final nominalController = TextEditingController(text: '');
  final nohpController = TextEditingController(text: '');

  Timer? _debounce;
  String? selectedPaymentMethod = 'Saldo';

  UserModel? customer;

  bool isInquiry = false;
  bool isLoading = false;

  Map<String, dynamic> responseInquiry = {};

  Map<String, dynamic> data = {};
  Map<String, dynamic> getSetting = {};

  List listTagihan = [];
  List listBanks = [];

  List listAccount = [
    {"name": "Customer", "value": "customer"},
    {"name": "Driver", "value": "driver"},
    {"name": "Merchant", "value": "merchant"},
  ];

  String? _valBank;
  String? _valAccount;

  Map<String, dynamic> item = {};

  @override
  void initState() {
    super.initState();

    final authState = context.read<AuthBloc>().state;

    if (authState is AuthSuccess) {
      customer = authState.user;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async => await initData());
  }

  Future<void> initData() async {
    setState(() {
      isLoading = true;
    });

    UserModel user = await AuthService().getCurrentUser();

    await getProductsByNote();

    final res2 = await SharedServices().getSettings();

    if (res2.isSuccess) {
      setState(() {
        isLoading = false;
        getSetting = res2.value;
        customer = user;
      });
    } else if (res2.isError) {
      showCustomSnackbar(context, res2.error!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> getProductsByNote() async {
    final res = await SharedServices().getProductsByNote('cek rekening');

    if (res.isSuccess) {
      setState(() {
        listBanks = res.value;
      });
    } else {
      showCustomSnackbar(context, res.error!);
    }
  }

  bool validate() {
    if (nohpController.text.isEmpty ||
        nominalController.text.isEmpty ||
        _valAccount == null) {
      showCustomSnackbar(context, 'Semua Field Harus diisi');
      return false;
    }

    if (getSetting['minimal_tarik_saldo_customer'] >
        int.parse(nominalController.text)) {
      showCustomSnackbar(context,
          'Minimal Tarik Saldo ${formatCurrency(getSetting['minimal_tarik_saldo_customer'])}');
      return false;
    }

    if (getSetting['maksimal_tarik_saldo_customer'] <
        int.parse(nominalController.text)) {
      showCustomSnackbar(context,
          'Maksimal Tarik Saldo ${formatCurrency(getSetting['maksimal_tarik_saldo_customer'])}');

      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80.0),
          child: AppBar(
            automaticallyImplyLeading: true,
            title: Text(
              'Kirim Uang',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        body: FadedSlideAnimation(
          beginOffset: const Offset(0, 0.3),
          endOffset: const Offset(0, 0),
          slideCurve: Curves.linearToEaseOut,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Stack(
                  children: [
                    SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.only(
                            right: 20, left: 20, top: 20, bottom: 160),
                        child: Column(
                          children: [
                            Image.asset("images/tarik_saldo.png"),
                            const SizedBox(
                              height: 40,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Saldo DIGOJEK',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: kMainTextColor,
                                          fontSize: 14),
                                ),
                                Text(
                                  formatCurrency(customer!.balance),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: kMainTextColor,
                                          fontSize: 14),
                                )
                              ],
                            ),
                            const Divider(height: 20),
                            Container(
                                decoration: BoxDecoration(
                                    border: Border.all(color: kGeyColor),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(20))),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: EntryField(
                                  label: 'Nomor Akun',
                                  controller: nohpController,
                                  keyboardType: TextInputType.number,
                                )),
                            Container(
                                decoration: BoxDecoration(
                                    border: Border.all(color: kGeyColor),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(20))),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: EntryField(
                                  label: 'Nominal',
                                  controller: nominalController,
                                  keyboardType: TextInputType.number,
                                )),
                            Container(
                                padding: const EdgeInsets.only(
                                    bottom: 5, left: 30, right: 30),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        height: 8,
                                      ),
                                      DropdownButtonFormField(
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.all(5),
                                        ),
                                        isExpanded: true,
                                        hint: const Text("Jenis Akun"),
                                        value: _valAccount,
                                        items: listAccount.map((value) {
                                          return DropdownMenuItem(
                                            value: value['value'],
                                            child: Text(value['name']),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _valAccount = value.toString();
                                          });
                                        },
                                      ),
                                    ])),
                            const SizedBox(
                              height: 20,
                            ),
                            if (responseInquiry.isEmpty)
                              GestureDetector(
                                onTap: () async {
                                  setState(() {
                                    isInquiry = true;
                                  });

                                  if (validate()) {
                                    final res = await SharedServices()
                                        .inquiryCekUser(
                                            _valAccount!, nohpController.text);
                                    print(res.value);
                                    if (res.isSuccess) {
                                      if (res.value.isNotEmpty) {
                                        setState(() {
                                          responseInquiry = res.value;
                                        });
                                      } else {
                                        responseInquiry = {};
                                        showCustomSnackbar(
                                            context, 'No Tujuan salah');
                                      }
                                    } else {
                                      responseInquiry = {};
                                      showCustomSnackbar(context, res.error!);
                                    }
                                  }

                                  setState(() {
                                    isInquiry = false;
                                  });
                                },
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                      color: kMainColor,
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(20))),
                                  padding: const EdgeInsets.all(14),
                                  child: isInquiry
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : Text(
                                          'Cek Akun Tujuan',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: kWhiteColor,
                                                  fontSize: 14),
                                          textAlign: TextAlign.center,
                                        ),
                                ),
                              ),
                            const SizedBox(
                              height: 20,
                            ),
                            if (responseInquiry.isNotEmpty)
                              Container(
                                  decoration: const BoxDecoration(
                                      color: Color(0xff77CACA),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(20))),
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Nomor Akun',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14),
                                          ),
                                          Text(
                                            responseInquiry['nohp'],
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14),
                                          ),
                                        ],
                                      ),

                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Nama Akun',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14),
                                          ),
                                          Text(
                                            responseInquiry['name'],
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14),
                                          ),
                                        ],
                                      ),

                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Jenis Akun',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14),
                                          ),
                                          Text(
                                            responseInquiry['type_user'],
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14),
                                          ),
                                        ],
                                      ),

                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Nominal',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14),
                                          ),
                                          Text(
                                            formatCurrency(int.parse(
                                                nominalController.text)),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14),
                                          ),
                                        ],
                                      ),

                                      // const SizedBox(
                                      //   height: 50,
                                      // ),
                                    ],
                                  )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    // PositionedDirectional(
                    //   bottom: 0,
                    //   start: 0,
                    //   end: 0,
                    //   child: BottomBar(
                    //     text: "Cek Tagihan",
                    //     onTap: () {},
                    //   ),
                    // ),

                    if (responseInquiry.isNotEmpty)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Material(
                              elevation: 15,
                              child: Container(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        String? getSelectedPaymentMethod =
                                            await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      PaymentPpobPage(),
                                                ));

                                        if (getSelectedPaymentMethod != null) {
                                          setState(() {
                                            selectedPaymentMethod =
                                                getSelectedPaymentMethod;
                                          });
                                        }
                                      },
                                      child: Row(
                                        children: [
                                          if (selectedPaymentMethod == 'Tunai')
                                            buildSelectedPaymentMethod(
                                                'images/vec_money.png',
                                                'Tunai',
                                                context),
                                          if (selectedPaymentMethod == 'Saldo')
                                            buildSelectedPaymentMethod(
                                                'images/vec_wallet.png',
                                                'Saldo',
                                                context),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    // Container(
                                    //   padding: const EdgeInsets.symmetric(
                                    //       horizontal: 12, vertical: 6),
                                    //   decoration: BoxDecoration(
                                    //     borderRadius: BorderRadius.circular(8),
                                    //     border: Border.all(
                                    //       width: 0.1,
                                    //     ),
                                    //   ),
                                    //   child: Row(
                                    //     children: [
                                    //       const Icon(
                                    //         Icons.local_offer_sharp,
                                    //         size: 14,
                                    //       ),
                                    //       const SizedBox(width: 8),
                                    //       Text(
                                    //         '',
                                    //         style: Theme.of(context)
                                    //             .textTheme
                                    //             .titleSmall
                                    //             ?.copyWith(fontSize: 10),
                                    //       ),
                                    //     ],
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                            ),
                            BottomBar(
                                onTap: () async {
                                  if (selectedPaymentMethod == 'Saldo') {
                                    if (customer!.balance! <
                                        int.parse(nominalController.text)) {
                                      return showCustomSnackbar(
                                          context, 'Saldo tidak mencukupi');
                                    } else {
                                      setState(() {
                                        isLoading = true;
                                      });
                                      final res =
                                          await SharedServices().sendSaldo(
                                        customer!.id.toString(),
                                        nominalController.text,
                                        _valAccount!,
                                        nohpController.text,
                                      );

                                      if (res.isSuccess) {
                                        if (mounted) {
                                          Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      TransactionPurchaseDetail(
                                                          data:
                                                              TransactionPurchaseModel
                                                                  .fromJson(res
                                                                      .value))),
                                              (route) => false);
                                        }
                                      } else {
                                        showCustomSnackbar(context, res.error!);
                                      }
                                    }
                                  }
                                },
                                text: 'Kirim Saldo')
                          ],
                        ),
                      ),
                  ],
                ),
        ));
  }

  Widget buildSelectedPaymentMethod(
    String image,
    String name,
    BuildContext context,
  ) {
    return Row(
      children: [
        Image.asset(
          image,
          height: 20,
        ),
        const SizedBox(width: 12),
        Text(
          name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.arrow_forward_ios,
          size: 12,
        ),
      ],
    );
  }
}
