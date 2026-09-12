import 'dart:ffi';

import 'package:bloc/bloc.dart';
import 'package:deliq_delivery/models/otp_form_model.dart';
import 'package:deliq_delivery/models/sign_up_form_model.dart';
import 'package:deliq_delivery/models/user_model.dart';
import 'package:deliq_delivery/services/auth_service.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthEvent>((event, emit) async {
      // TODO: implement event handler

      if (event is AuthRegister) {
        try {
          emit(AuthLoading());

          final isExistNohp = await AuthService().checkNohp(event.data);

          if (isExistNohp) {
            emit(const AuthFailed('Nohp sudah terpakai'));
          } else {
            // final driver = await AuthService().register(event.data);
            // if (driver) {
            //   emit(AuthSuccessRegister());
            // } else {
            //   emit(const AuthFailed('Gagal Registrasi'));
            // }
          }
        } catch (e) {
          emit(AuthFailed(e.toString()));
        }
      }

      if (event is AuthLogin) {
        try {
          emit(AuthLoading());

          final isExistNohp = await AuthService().checkNohp(event.data);
          if (isExistNohp) {
            final sendWa = await AuthService().sendOtpWa(event.data.nohp!);
            if (sendWa) {
              print('send');
              emit(AuthSendOtp(event.data.nohp!));
            } else {
              print('wa');
              emit(AuthFailed('Akunmu masih menunggu persetujuan'));
            }
          } else {
            emit(const AuthFailed('Nohp Belum Terdaftar'));
          }
        } catch (e) {
          emit(AuthFailed(e.toString()));
        }
      }

      if (event is AuthVerificationOtpRegister) {
        emit(AuthLoading());

        try {
          final res = await AuthService().register(event.data, event.otp);

          if (res.isSuccess) {
            emit(AuthSuccessVerificationOtpRegister());
          } else {
            emit(AuthFailedVerificationOtpRegister(
                'Terjadi kesalahan / isi otp dengan benar'));
          }
        } catch (e) {
          emit(AuthFailedVerificationOtpRegister(
              'Terjadi kesalahan / isi otp dengan benar'));
        }
      }

      if (event is AuthVerificationOtp) {
        emit(AuthLoading());
        try {
          // pastikan Firebase sudah di-init di main.dart
          final messaging = FirebaseMessaging.instance;

          // Dapatkan token secara async
          final deviceToken = await messaging.getToken();

          final result = await AuthService().verificationOtp(event.data);

          if (result.isSuccess) {
            print("berhasil");
            // update device token dengan nilai yang sudah tersedia
            if (deviceToken != null) {
              await AuthService()
                  .updateDeviceToken(result.value!.id.toString(), deviceToken);
            }
            emit(AuthSuccess(result.value!));
          } else {
            emit(AuthFailedVerificationOtp(result.error!));
          }
        } catch (e) {
          print(e.toString());
          emit(AuthFailedVerificationOtp('Terjadi kesalahan' + e.toString()));
        }
      }

      if (event is AuthGetCurrentUser) {
        try {
          emit(AuthLoading());
          final _firebaseMessaging = FirebaseMessaging.instance;

          String? deviceToken = await _firebaseMessaging.getToken();

          // late FirebaseMessaging messaging;
          // String? deviceToken;
          // messaging = FirebaseMessaging.instance;
          // messaging.getToken().then((value) {
          //   deviceToken = value;
          // });
          final SignUpFormModel data =
              await AuthService().getCredentialFromLocal();
          final UserModel driver = await AuthService().getCurrentUser();
          final updateDeviceToken = await AuthService()
              .updateDeviceToken(driver.id.toString(), deviceToken!);
          emit(AuthSuccess(driver));
        } catch (e) {
          emit(AuthFailed(e.toString()));
        }
      }

      if (event is AuthLogout) {
        try {
          emit(AuthLoading());

          await AuthService().clearLocalStorage();

          emit(AuthInitial());
        } catch (e) {
          emit(AuthFailed(e.toString()));
        }
      }

      if (event is AuthUpdateStatus) {
        await AuthService().updateStatusDriver(
            event.status, event.id, event.latitude, event.longitude);

        if (state is AuthSuccess) {
          final currentUser = (state as AuthSuccess).user;
          final updateUser = currentUser.copyWith(
              status_driver: event.status,
              latitude: event.latitude,
              longitude: event.longitude);

          emit(AuthSuccess(updateUser));
        }
      }

      if (event is AuthUpdateStatusMober) {
        await AuthService().updateStatusMober(event.id, event.statusMober);
        if (state is AuthSuccess) {
          final currentUser = (state as AuthSuccess).user;
          final updateUser = currentUser.copyWith(is_mober: event.statusMober);

          emit(AuthSuccess(updateUser));
        }
      }

      if (event is AuthUserUpdate) {
        try {
          emit(AuthLoading());
          final res = await AuthService()
              .updateUser(event.user_id, event.name, event.image, event.email);
          final UserModel driver = await AuthService().getCurrentUser();
          emit(AuthSuccess(driver));
        } catch (e) {
          emit(AuthFailed(e.toString()));
        }
      }
    });
  }
}
