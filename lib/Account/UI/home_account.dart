import 'package:deliq_delivery/Account/UI/account_page.dart';
import 'package:deliq_delivery/Chat/UI/animated_bottom_bar.dart';
import 'package:deliq_delivery/Chat/UI/chat_page.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:flutter/material.dart';

class HomeAccount extends StatefulWidget {
  const HomeAccount({super.key});

  @override
  HomeAccountState createState() => HomeAccountState();
}

class HomeAccountState extends State<HomeAccount> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void onTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  static String bottomIconHome = 'images/footermenu/ic_home.png';

  static String bottomIconOrder = 'images/footermenu/ic_orders.png';
  static String bottomIconChat = 'images/footermenu/chat.png';

  static String bottomIconAccount = 'images/footermenu/ic_profile.png';

  @override
  Widget build(BuildContext context) {
    var appLocalization = AppLocalizations.of(context)!;
    final List<BarItem> barItems = [
      BarItem(
        text: appLocalization.homeText,
        image: bottomIconHome,
      ),
      BarItem(
        text: appLocalization.orderText,
        image: bottomIconOrder,
      ),
      BarItem(
        text: 'Chat',
        image: bottomIconChat,
      ),
      // BarItem(
      //   text: appLocalization.accoun,
      //   image: bottomIconAccount,
      // ),
    ];

    final List<Widget> children = [
      const AccountPageBody(),
      // const ChatPage(),
      const AccountPageBody(),
    ];
    return Scaffold(
      body: children[_currentIndex],
      bottomNavigationBar: AnimatedBottomBar(
          barItems: barItems,
          onBarTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          }),
    );
  }
}
