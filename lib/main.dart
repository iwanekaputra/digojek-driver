import 'dart:convert';

import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/Routes/routes.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/home.dart';
import 'package:deliq_delivery/language_cubit.dart';
import 'package:deliq_delivery/map_utils.dart';
import 'package:deliq_delivery/notification_service.dart';
import 'package:deliq_delivery/splash_page.dart';
import 'package:deliq_delivery/theme_cubit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

final navigatorKey = GlobalKey<NavigatorState>();

// SEMENTARA UNTUK WEB SAJA (Karena mobile di-handle penuh oleh Awesome Notifications)
void showNotificationWeb({required String title, required String body}) {
  if (navigatorKey.currentContext != null) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Ok"))
        ],
      ),
    );
  }
}

void main() async {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  WidgetsFlutterBinding.ensureInitialized();
  MapUtils.getMarkerPic();

  // 1. Inisialisasi Firebase Default
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Jalankan Inisialisasi Service Awesome Notifications
  // (Fungsi ini di dalamnya sudah otomatis mengaktifkan onBackgroundMessage bawaan service)
  await NotificationService.instance.initialize();

  runApp(const AppEntryPoint());
}

class AppEntryPoint extends StatelessWidget {
  const AppEntryPoint({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LanguageCubit>(
          create: (context) => LanguageCubit()..getCurrentLanguage(),
        ),
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit()..getCurrentTheme(),
        ),
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(),
          lazy: true,
        ),
      ],
      child: const Deliq(),
    );
  }
}

class Deliq extends StatelessWidget {
  const Deliq({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LanguageCubit>(
          create: (context) => LanguageCubit()..getCurrentLanguage(),
        ),
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit()..getCurrentTheme(),
        ),
        BlocProvider(
          create: (context) => AuthBloc()..add(AuthGetCurrentUser()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeData>(
        builder: (_, theme) {
          return BlocBuilder<LanguageCubit, Locale>(
            builder: (_, locale) {
              return MaterialApp(
                navigatorKey: navigatorKey,
                localizationsDelegates: const [
                  AppLocalizationsDelegate(),
                  ...GlobalMaterialLocalizations.delegates,
                  GlobalWidgetsLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en'),
                  Locale('ar'),
                  Locale('fr'),
                  Locale('id'),
                  Locale('pt'),
                  Locale('es'),
                  Locale('tr'),
                  Locale('it'),
                  Locale('sw'),
                  Locale('de'),
                  Locale('ro'),
                ],
                locale: locale,
                theme: theme,
                home: const SplashPage(),
                debugShowCheckedModeBanner: false,
                routes: PageRoutes().routes(),
              );
            },
          );
        },
      ),
    );
  }
}
