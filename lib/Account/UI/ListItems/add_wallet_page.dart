import 'dart:convert';

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:deliq_delivery/Account/UI/ListItems/invoice_page.dart';
import 'package:deliq_delivery/Components/bottom_bar.dart';
import 'package:deliq_delivery/Components/entry_field.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/models/user_model.dart';
import 'package:deliq_delivery/services/auth_service.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:deliq_delivery/shared/shared_values.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

class AddMoney extends StatelessWidget {
  const AddMoney({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Uang',
            style: Theme.of(context)
                .textTheme
                .headlineMedium!
                .copyWith(fontWeight: FontWeight.w500)),
        titleSpacing: 0.0,
      ),
      body: FadedSlideAnimation(
        beginOffset: const Offset(0, 0.3),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: const Add(),
      ),
    );
  }
}

class Add extends StatefulWidget {
  const Add({super.key});

  @override
  State<Add> createState() => _AddState();
}

class _AddState extends State<Add> {
  UserModel? driver;
  bool isLoading = false;
  List<dynamic> listBank = [];
  Map<String, dynamic> settingDeposit = {};

  int? selectedBank;
  String? paymentMethod;
  String? nameOwner;
  String? accountNumber;
  String? bankId;

  final amountController = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      driver = authState.user;
    }

    getListBank();
    getSettingDeposit();
  }

  Future<void> getListBank() async {
    final res = await http.get(Uri.parse('$baseUrl/moota/get-list-bank'));

    if (res.statusCode == 200) {
      if (mounted) {
        setState(() {
          listBank = jsonDecode(res.body)['data'];
        });
      }
    }
  }

  Future<void> getSettingDeposit() async {
    final token = await AuthService().getToken();
    final res = await http.get(Uri.parse('$baseUrl/driver/setting-deposit'),
        headers: {'Authorization': token});
    if (res.statusCode == 200) {
      setState(() {
        settingDeposit = jsonDecode(res.body)['data'];
      });
    }
  }

  Future<Map<dynamic, dynamic>> addDeposit() async {
    final token = await AuthService().getToken();

    final res =
        await http.post(Uri.parse('$baseUrl/drivers/deposit'), headers: {
      "Authorization": token
    }, body: {
      "driver_id": driver!.id.toString(),
      "name_owner_bank": nameOwner,
      "account_number": accountNumber,
      "bank_type": paymentMethod,
      "total_price": amountController.text,
      "bank_id": bankId
    });

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }

    return {};
  }

  bool validate() {
    if (amountController.text.isEmpty) {
      showCustomSnackbar(context, 'Masukkan nominal Top up');
      return false;
    }
    if (int.parse(amountController.text) < settingDeposit['minimal_deposit']) {
      showCustomSnackbar(context,
          'Minimal Top Up ${formatCurrency(settingDeposit['minimal_deposit'])}');
      return false;
    }
    if (selectedBank == null) {
      showCustomSnackbar(context, 'Pilih Bank');
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        isLoading || listBank == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: <Widget>[
                  // --- HEADER & INPUT FIELD ---
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'TOPUP',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.0,
                            color: kHintColor),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: EntryField(
                      textCapitalization: TextCapitalization.words,
                      label: 'Masukkan Jumlah Top up',
                      controller: amountController,
                      keyboardType: TextInputType.number,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- NOMINAL QUICK SELECT (GRID LAYOUT) ---
                  Text(
                    'Pilihan Nominal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.2,
                    children: [
                      buildBoxTopUp(20000),
                      buildBoxTopUp(50000),
                      buildBoxTopUp(100000),
                      buildBoxTopUp(150000),
                      buildBoxTopUp(200000),
                      buildBoxTopUp(250000),
                      buildBoxTopUp(300000),
                      buildBoxTopUp(350000),
                      buildBoxTopUp(400000),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- LIST PILIHAN BANK ---
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Pilih Bank',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                          color: Colors.black87),
                    ),
                  ),
                  ListView.separated(
                      padding: const EdgeInsets.only(bottom: 30),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: ((context, index) {
                        bool isSelected = index == selectedBank;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedBank = index;
                              nameOwner = listBank[index]['atas_nama'];
                              accountNumber = listBank[index]['account_number'];
                              paymentMethod = listBank[index]['bank_type'];
                              bankId = listBank[index]['bank_id'];
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? kMainColor
                                    : Colors.grey.shade200,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              color: isSelected
                                  ? kMainColor.withOpacity(0.05)
                                  : Colors.white,
                              boxShadow: [
                                if (!isSelected)
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Image.network(
                                    listBank[index]['icon'],
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.account_balance,
                                                size: 20, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: listBank[index]
                                                  ['atas_nama'],
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: Colors.black87,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          // dataRoute.isEmpty
                                          //     ? const Text(
                                          //         'no pdated')
                                          //     : Text(
                                          //         _rideOption[
                                          //                 index]
                                          //             .time,
                                          //         style: Theme.of(
                                          //                 context)
                                          //             .textTheme
                                          //             .titleSmall
                                          //             ?.copyWith(
                                          //                 fontSize:
                                          //                     12),
                                          //       ),
                                          // const SizedBox(
                                          //     width: 6),
                                          // CircleAvatar(
                                          //   radius: 2,
                                          //   backgroundColor:
                                          //       kIconColor,
                                          // ),
                                          // const SizedBox(
                                          //     width: 6),
                                          // Icon(
                                          //   Icons.person,
                                          //   color: kIconColor,
                                          //   size: 14,
                                          // ),
                                          // const SizedBox(
                                          //     width: 6),
                                          // Text(
                                          //   _rideOption[index]
                                          //       .passenger
                                          //       .toString(),
                                          //   style: Theme.of(
                                          //           context)
                                          //       .textTheme
                                          //       .titleSmall
                                          //       ?.copyWith(
                                          //           fontSize:
                                          //               12),
                                          // ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      listBank[index]['bank_type']
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: isSelected
                                            ? kMainColor
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      listBank[index]['account_number'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      }),
                      separatorBuilder: ((context, index) {
                        return const SizedBox(height: 10);
                      }),
                      itemCount: listBank.length),
                  const SizedBox(height: 120),
                ],
              ),
        Align(
          alignment: Alignment.bottomCenter,
          child: BottomBar(
              text: 'Tambah Uang',
              onTap: () async {
                // validate();

                if (validate()) {
                  setState(() {
                    isLoading = true;
                  });

                  final res = await addDeposit();

                  setState(() {
                    isLoading = false;
                  });

                  // Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //         builder: (context) => InvoicePage(
                  //               data: res,
                  //             )));
                } else {}
              }),
        )
      ],
    );
  }

  Widget buildBoxTopUp(amount) {
    bool isSelected = amountController.text == amount.toString();

    return GestureDetector(
      onTap: () {
        setState(() {
          amountController.text = amount.toString();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? kMainColor : Colors.white,
          border: Border.all(
            color: isSelected ? kMainColor : Colors.grey.shade300,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
          ],
        ),
        child: Center(
          child: Text(
            formatCurrency(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
