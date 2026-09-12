import 'dart:async';

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:deliq_delivery/Components/bottom_bar.dart';
import 'package:deliq_delivery/Components/entry_field.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/Routes/routes.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/models/sign_up_form_model.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Verification page that sends otp to the phone number entered on phone number page
class VerificationRegisterPage extends StatelessWidget {
  final SignUpFormModel data;

  const VerificationRegisterPage(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.verification!,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FadedSlideAnimation(
        beginOffset: const Offset(0, 0.1),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.fastOutSlowIn,
        child: OtpVerify(data),
      ),
    );
  }
}

// Otp verification class
class OtpVerify extends StatefulWidget {
  final SignUpFormModel data;

  const OtpVerify(this.data, {super.key});

  @override
  OtpVerifyState createState() => OtpVerifyState();
}

class OtpVerifyState extends State<OtpVerify> {
  final otpController = TextEditingController(text: '');

  bool isDialogShowing = false;
  int _counter = 20;
  late Timer _timer;

  _startTimer() {
    _counter = 120; // time counter

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _counter > 0 ? _counter-- : _timer.cancel();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    verifyPhoneNumber();
  }

  void verifyPhoneNumber() {
    _startTimer();
  }

  @override
  void dispose() {
    otpController.dispose();
    _timer.cancel();
    super.dispose();
  }

  bool validate() {
    if (otpController.text.isEmpty) {
      showCustomSnackbar(context, 'Harap ini otp');
      return false;
    }

    return true;
  }

  // Helper format waktu mm:ss
  String get _formattedTime {
    final minutes = (_counter ~/ 60).toString().padLeft(2, '0');
    final seconds = (_counter % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailedVerificationOtpRegister) {
          showCustomSnackbar(context, state.e);
        }

        if (state is AuthSuccessVerificationOtpRegister) {
          Navigator.pushNamed(context, PageRoutes.registerSuccess);
        }
      },
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 32),

                      // Visual Icon Container
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kMainColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified_user_rounded,
                          size: 48,
                          color: kMainColor,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title Text
                      Text(
                        AppLocalizations.of(context)!.enterVerification!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.secondaryHeaderColor,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      if (widget.data.nohp != null)
                        Text(
                          'Kode OTP telah dikirimkan ke nomor\n${widget.data.nohp}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      const SizedBox(height: 36),

                      // Input Field
                      EntryField(
                        controller: otpController,
                        readOnly: false,
                        label: AppLocalizations.of(context)!.verificationCode,
                        maxLength: 6,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),

                      // Resend Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 18,
                            color: _counter > 0 ? Colors.grey : kMainColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formattedTime,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _counter < 1
                                ? () {
                                    verifyPhoneNumber();
                                  }
                                : null,
                            child: Text(
                              AppLocalizations.of(context)!.resend!,
                              style: TextStyle(
                                color: _counter < 1 ? kMainColor : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Action Button
              BottomBar(
                text: AppLocalizations.of(context)!.continueText,
                onTap: () {
                  if (validate()) {
                    context.read<AuthBloc>().add(
                          AuthVerificationOtpRegister(
                            widget.data,
                            otpController.text.toString(),
                          ),
                        );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
