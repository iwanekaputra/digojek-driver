import 'package:deliq_delivery/Account/UI/account_page.dart';
import 'package:deliq_delivery/Auth/MobileNumber/UI/phone_number.dart';
import 'package:deliq_delivery/Routes/routes.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance
    //     .addPostFrameCallback((_) async => await listenToNotifications());
  }

  // listenToNotifications() {
  //   print("Listening o");
  //   LocalNotifications.onClickNotification.stream.listen((event) {
  //     print(event);
  //     Navigator.pushNamed(context, PageRoutes.addMoney);
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            Navigator.pushNamedAndRemoveUntil(
                context, PageRoutes.accountPage, (route) => false);
          }

          if (state is AuthFailed) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PhoneNumber(),
              ),
            );
          }
        },
        child: Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              image:
                  DecorationImage(image: AssetImage("images/logos/logo.png")),
            ),
          ),
        ),
      ),
    );
    ;
  }
}
