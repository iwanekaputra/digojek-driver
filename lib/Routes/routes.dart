import 'package:deliq_delivery/Account/UI/ListItems/about_us_page.dart';
import 'package:deliq_delivery/Account/UI/ListItems/add_wallet_page.dart';
import 'package:deliq_delivery/Account/UI/ListItems/addtobank_page.dart';
import 'package:deliq_delivery/Account/UI/ListItems/deposit_page.dart';
import 'package:deliq_delivery/Account/UI/ListItems/insight_page.dart';
import 'package:deliq_delivery/Account/UI/ListItems/send_saldo_page.dart';
import 'package:deliq_delivery/Account/UI/ListItems/settings_page.dart';
import 'package:deliq_delivery/Account/UI/ListItems/support_page.dart';
import 'package:deliq_delivery/Account/UI/ListItems/tnc_page.dart';
import 'package:deliq_delivery/Account/UI/ListItems/wallet_page.dart';
import 'package:deliq_delivery/Account/UI/account_page.dart';
import 'package:deliq_delivery/Auth/login_navigator.dart';
import 'package:deliq_delivery/Chat/UI/chat_page.dart';
import 'package:deliq_delivery/DeliveryPartnerProfile/delivery_profile.dart';
import 'package:deliq_delivery/OrderMap/UI/accepted.dart';
import 'package:deliq_delivery/OrderMap/UI/delivery_successful.dart';
import 'package:deliq_delivery/OrderMap/UI/new_delivery.dart';
import 'package:deliq_delivery/OrderMap/UI/onway.dart';
import 'package:deliq_delivery/OrderMap/UICabTogether/order_page.dart';
import 'package:deliq_delivery/Pages/tarik_saldo_page.dart';
import 'package:deliq_delivery/Pages/transaction_purchase.dart';
import 'package:deliq_delivery/register_success_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PageRoutes {
  static const String accountPage = 'account_page';
  static const String tncPage = 'tnc_page';
  static const String aboutUsPage = 'about_us_page';
  static const String supportPage = 'support_page';
  static const String loginNavigator = 'login_navigator';
  static const String chatPage = 'chat_page';
  static const String deliverySuccessful = 'delivery_successful';
  static const String insightPage = 'insight_page';
  static const String walletPage = 'wallet_page';
  static const String addToBank = 'addtobank_page';
  static const String editProfile = 'store_profile';
  static const String deposit = 'deposit_page';

  static const String newDeliveryPage = 'new_delivery_page';
  static const String acceptedPage = 'accepted_page';
  // static const String onWayPage = 'on_way_page';
  static const String setting = 'settings_page';
  static const String registerSuccess = 'register_success';
  static const String addMoney = 'addMoney_page';
  static const String tarikSaldo = 'tarikSaldo_page';
  static const String transactionPurchase = 'transaction_purchase';
  static const String sendSaldo = 'send_saldo';
  static const String orderPage = 'order_page';

  Map<String, WidgetBuilder> routes() {
    return {
      accountPage: (context) => const AccountPageBody(),
      tncPage: (context) => const TncPage(),
      aboutUsPage: (context) => const AboutUsPage(),
      supportPage: (context) => const SupportPage(),
      loginNavigator: (context) => const LoginNavigator(),
      // chatPage: (context) => const ChatPage(),
      // deliverySuccessful: (context) => const DeliverySuccessful(),
      insightPage: (context) => const InsightPage(),
      walletPage: (context) => const WalletPage(),
      addToBank: (context) => const AddToBank(),
      editProfile: (context) => const ProfilePage(),
      newDeliveryPage: (context) => const NewDeliveryPage(),
      acceptedPage: (context) => const AcceptedPage(),
      // onWayPage: (context) => const OnWayPage(),
      setting: (context) => const Settings(),
      registerSuccess: (context) => const RegisterSuccessPage(),
      addMoney: (context) => const AddMoney(),
      deposit: (context) => const DepositPage(),
      tarikSaldo: (context) => const TarikSaldoPage(),
      transactionPurchase: (context) => const TransactionPurchasePage(),
      sendSaldo: (context) => const SendSaldoPage(),
      orderPage: (context) => const OrderPage(),
    };
  }
}
