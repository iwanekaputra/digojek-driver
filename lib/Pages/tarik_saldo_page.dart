import "dart:async";

import "package:animation_wrappers/animations/faded_slide_animation.dart";
import "package:deliq_delivery/Components/bottom_bar.dart";
import "package:deliq_delivery/Components/entry_field.dart";
import "package:deliq_delivery/Locale/locales.dart";
import "package:deliq_delivery/Pages/payment_ppob_page.dart";
import "package:deliq_delivery/Pages/payment_success_tarik_saldo_page.dart";
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
import "package:dropdown_search/dropdown_search.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class TarikSaldoPage extends StatefulWidget {
  const TarikSaldoPage({super.key});

  @override
  State<TarikSaldoPage> createState() => _TarikSaldoPageState();
}

class _TarikSaldoPageState extends State<TarikSaldoPage> {
  final nominalController = TextEditingController(text: '');
  final norekController = TextEditingController(text: '');
  final descriptionController = TextEditingController(text: '');

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

  String? _valBank;

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
        getSetting = res2.value;
      });
    } else {
      showCustomSnackbar(context, res2.error!);
    }
    setState(() {
      isLoading = false;
      customer = user;
    });
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
    if (norekController.text.isEmpty ||
        nominalController.text.isEmpty ||
        _valBank == null) {
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
              ? Center(
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
                            Divider(height: 20),
                            Container(
                                decoration: BoxDecoration(
                                    border: Border.all(color: kGeyColor),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(20))),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: EntryField(
                                  label: 'Nomor Rekening',
                                  controller: norekController,
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
                                // padding: const EdgeInsets.only(
                                //     bottom: 5, left: 30, right: 30),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  DropdownSearch<dynamic>(
                                    // Mode dropdown
                                    items: listBanks,
                                    itemAsString: (item) =>
                                        item['name'] ??
                                        '', // Menampilkan nama item
                                    onChanged: (selectedItem) {
                                      setState(() {
                                        _valBank = selectedItem['code'];
                                      });
                                    },
                                    dropdownDecoratorProps:
                                        DropDownDecoratorProps(
                                      dropdownSearchDecoration: InputDecoration(
                                        labelText: 'Pilih Bank Tujuan',
                                        hintText: 'Mulai mengetik...',
                                        labelStyle: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .copyWith(
                                                color:
                                                    Theme.of(context).hintColor,
                                                fontSize: 14),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 30),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide:
                                              BorderSide(color: kGeyColor),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide:
                                              BorderSide(color: kGeyColor),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: kGeyColor, width: 2),
                                        ),
                                      ),
                                    ),
                                    popupProps: PopupProps.menu(
                                      showSearchBox:
                                          true, // Menampilkan kotak pencarian
                                      searchFieldProps: TextFieldProps(
                                        decoration: InputDecoration(
                                          hintText: 'Cari...',
                                          hintStyle: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.search,
                                            color: Colors.grey,
                                          ),
                                          contentPadding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 16,
                                              vertical:
                                                  12), // Padding di dalam kotak pencarian
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: Colors.blueAccent),
                                          ),
                                        ),
                                      ),
                                      itemBuilder: (context, item, isSelected) {
                                        return ListTile(
                                          title: Text(
                                            item['name'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ])),
                            // const SizedBox(
                            //   height: 10,
                            // ),
                            Container(
                                decoration: BoxDecoration(
                                    border: Border.all(color: kGeyColor),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(20))),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: EntryField(
                                  label: 'Catatan',
                                  controller: descriptionController,
                                )),
                            if (responseInquiry.isEmpty)
                              GestureDetector(
                                onTap: () async {
                                  setState(() {
                                    isInquiry = true;
                                  });

                                  if (validate()) {
                                    final res = await SharedServices()
                                        .inquiryBerkah(
                                            customer!.id.toString(),
                                            _valBank.toString(),
                                            norekController.text,
                                            nominalController.text,
                                            'CEK REKENING',
                                            descriptionController.text);

                                    if (res.isSuccess) {
                                      if (res.value.isNotEmpty) {
                                        if (res.value['data_request']
                                                ['status'] ==
                                            '20') {
                                          setState(() {
                                            responseInquiry = res.value;
                                            listTagihan = res.value['info'];
                                          });
                                        } else {
                                          showCustomSnackbar(context,
                                              'Data Tidak ditemukan / ada kesalahan');
                                        }
                                      } else {
                                        responseInquiry = {};
                                        showCustomSnackbar(
                                            context, 'No rekening salah');
                                      }
                                    } else {
                                      responseInquiry = {};
                                      showCustomSnackbar(
                                          context, 'No rekening salah');
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
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(20))),
                                  padding: const EdgeInsets.all(14),
                                  child: isInquiry
                                      ? Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : Text(
                                          'Cek Rekening Tujuan',
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
                                            'Bank Tujuan',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14),
                                          ),
                                          Text(
                                            responseInquiry['info'][2]['value'],
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
                                            'No. Rekening',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14),
                                          ),
                                          Text(
                                            responseInquiry['info'][1]['value'],
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
                                            'Nama Nasabah',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14),
                                          ),
                                          Text(
                                            responseInquiry['info'][0]['value'],
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
                                                responseInquiry['info'][3]
                                                    ['value'])),
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
                                            'Biaya Admin',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14),
                                          ),
                                          Text(
                                            formatCurrency(
                                                responseInquiry['price_admin']),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(
                                        height: 10,
                                      ),

                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16),
                                          ),
                                          Text(
                                            formatCurrency(
                                                responseInquiry['grand_total']),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16),
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
                                        responseInquiry['grand_total']) {
                                      return showCustomSnackbar(
                                          context, 'Saldo tidak mencukupi');
                                    }

                                    setState(() {
                                      isLoading = true;
                                    });

                                    final res = await SharedServices().payment(
                                        customer!.id.toString(),
                                        _valBank!,
                                        norekController.text,
                                        nominalController.text,
                                        responseInquiry['info'],
                                        descriptionController.text);

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
                                },
                                text: 'Kirim Uang')
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
