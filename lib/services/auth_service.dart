import 'dart:convert';
import 'dart:developer';

import 'package:deliq_delivery/Core/result.dart';
import 'package:deliq_delivery/models/otp_form_model.dart';
import 'package:deliq_delivery/models/sign_up_form_model.dart';
import 'package:deliq_delivery/models/user_model.dart';
import 'package:deliq_delivery/shared/shared_values.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  Future<bool> checkNohp(SignUpFormModel data) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/driver/is-nohp-exist'),
          body: {'nohp': data.nohp});

      if (res.statusCode == 200) {
        return jsonDecode(res.body)['is-nohp-exist'];
      } else {
        return jsonDecode(res.body)['nohp'];
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Result> register(SignUpFormModel data, String otp) async {
    final res =
        await http.post(Uri.parse('$baseUrl/driver/register-v2'), body: {
      'otp': otp,
      'name': data.name,
      'birthday': data.birthday,
      'gender': data.gender,
      'email': data.email,
      'city': data.city,
      'province': data.province,
      'address': data.address,
      'agreement': data.agreement,
      'nohp': data.nohp,
      'vehicletype_id': data.vehicletypeId,
      'brand': data.brand,
      'registration_number': data.registrationNumber,
      'manufacture_year': data.manufactureYear,
      'color': data.color,
      'ktp': data.ktp,
      'sim': data.sim,
      'image': data.image,
      'image_vehicle': data.imageVehicle,
      'stnk': data.stnk,
      'referal': data.referal
    });

    if (res.statusCode == 200) {
      return Result.success(jsonDecode(res.body));
    } else if (res.statusCode == 422) {
      return Result.error('Terjadi kesalahan');
    } else {
      return Result.error('Terjadi kesalahan');
    }
  }

  Future<bool> sendOtpWa(String nohp) async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/driver/send-otp-wa'), body: {'nohp': nohp});

      if (res.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Result> sendOtpWaRegister(SignUpFormModel data) async {
    final res = await http.post(
        Uri.parse('$baseUrl/driver/send-otp-wa-register'),
        body: data.toJson());

    if (res.statusCode == 200) {
      return Result.success(jsonDecode(res.body));
    } else if (res.statusCode == 422) {
      return Result.validationErrors(jsonDecode(res.body)['errors']);
    } else {
      return Result.error('Terjadi kesalahan');
    }
  }

  Future<Result<UserModel>> verificationOtp(OtpFormModel data) async {
    try {
      final res = await http.post(
          Uri.parse('$baseUrl/driver/is-otp-correct-v2'),
          body: {'nohp': data.nohp.toString(), 'otp': data.otp});
      print('otp correct ${res.statusCode}');
      if (res.statusCode == 200) {
        final user = UserModel.fromJson(jsonDecode(res.body)['data']);
        await storeCredentialToLocal(user);
        print('user benar');
        return Result.success(user);
      } else {
        return Result.error('Terjadi kesalahan, harap isi otp dengan benar');
      }
    } catch (e) {
      print(e);
      return Result.error('Terjadi kesalahan, harap isi otp dengan benar');
    }
  }

  Future<UserModel> login(SignUpFormModel data) async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/driver/login'), body: {'nohp': data.nohp});

      if (res.statusCode == 200) {
        if (jsonDecode(res.body)['data']['status'] == 'Approved' ||
            jsonDecode(res.body)['data']['status'] == 'active') {
          final user = UserModel.fromJson(jsonDecode(res.body)['data']);
          return user;
        }

        throw jsonDecode(res.body)['message'].toString();
      } else {
        throw jsonDecode(res.body)['message'].toString();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> getCurrentUser() async {
    final token = await AuthService().getToken();

    final res = await http
        .get(Uri.parse('$baseUrl/driver'), headers: {'Authorization': token});

    if (res.statusCode == 200) {
      final user = UserModel.fromJson(jsonDecode(res.body));
      return user;
    } else {
      throw jsonDecode(res.body)['password'].toString();
    }
  }

  Future<void> storeCredentialToLocal(UserModel user) async {
    try {
      const storage = FlutterSecureStorage();
      await storage.write(key: 'nohp', value: user.nohp);
      await storage.write(key: 'token', value: user.token_driver);
    } catch (e) {
      rethrow;
    }
  }

  Future<SignUpFormModel> getCredentialFromLocal() async {
    try {
      const storage = FlutterSecureStorage();
      Map<String, String> values = await storage.readAll();

      if (values['nohp'] == null || values['token'] == null) {
        throw "authenticated";
      } else {
        final SignUpFormModel data = SignUpFormModel(nohp: values['nohp']);

        return data;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getToken() async {
    String token = '';

    const storage = FlutterSecureStorage();
    String? value = await storage.read(key: 'token');

    if (value != null) {
      token = 'Bearer ' + value;
    }

    return token;
  }

  Future<void> clearLocalStorage() async {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
  }

  Future<void> updateStatusDriver(String status, String driver_id,
      String latitude, String longitude) async {
    final token = await AuthService().getToken();

    final Map<String, dynamic> data2 = {
      "driver_id": driver_id,
      "status_driver": status,
      "latitude": latitude,
      "longitude": longitude,
    };

    final res = await http.post(
        Uri.parse('$baseUrl/driver/update-status-driver'),
        body: jsonEncode(data2),
        headers: {'Authorization': token, 'Content-Type': 'application/json'});

    if (res.statusCode == 200) {
      // final user = UserModel.fromJson(jsonDecode(res.body)['data']);

      // final emit = context.read<AuthBloc>().emit(AuthSuccess(user));
      // final authState = context.read<AuthBloc>().state;

      // if (authState is AuthSuccess) {
      //   print(authState.user.status_driver);
      // }
      return jsonDecode(res.body)['data'];
    }
  }

  Future<void> updateLocationDriver(String status, String driver_id,
      String latitude, String longitude) async {
    final token = await AuthService().getToken();

    final Map<String, dynamic> data2 = {
      'driver_id': driver_id,
      'latitude': latitude,
      'longitude': longitude,
    };

    final res = await http.post(
        Uri.parse('$baseUrl/drivers/update-location-driver'),
        body: jsonEncode(data2),
        headers: {'Authorization': token, 'Content-Type': 'application/json'});

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }
  }

  Future<void> updateStatusMober(String? driver_id, int? is_mober) async {
    final token = await AuthService().getToken();
    final res = await http
        .post(Uri.parse('$baseUrl/driver/update-status-mober'), body: {
      'driver_id': driver_id,
      'is_mober': is_mober == 1 ? "1" : "0"
    }, headers: {
      'Authorization': token,
    });
    if (res.statusCode == 200) {
      // final user = UserModel.fromJson(jsonDecode(res.body)['data']);

      // final emit = context.read<AuthBloc>().emit(AuthSuccess(user));
      // final authState = context.read<AuthBloc>().state;

      // if (authState is AuthSuccess) {
      //   print(authState.user.status_driver);
      // }
      return jsonDecode(res.body)['data'];
    }
  }

  Future<Map<String, dynamic>> updateUser(
      String customer_id, String name, String image, String email) async {
    print({customer_id, name, image, email});
    try {
      final token = await getToken();
      final res = await http.post(Uri.parse('$baseUrl/drivers/update'),
          headers: {
            'Authorization': token
          },
          body: {
            'driver_id': customer_id,
            'name': name,
            'image': image,
            'email': email
          });

      if (res.statusCode == 200) {
        return jsonDecode(res.body)['data'];
      }

      return {};
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateDeviceToken(
      String driver_id, String device_token) async {
    try {
      final token = await getToken();

      final Map<String, dynamic> data2 = {
        'driver_id': driver_id,
        'device_token': device_token
      };
      print("device_token $device_token");

      final res = await http.post(
          Uri.parse('$baseUrl/drivers/update-device-token'),
          headers: {'Authorization': token, 'Content-type': 'application/json'},
          body: jsonEncode(data2));

      print("device_token ${res.statusCode}");

      if (res.statusCode == 200) {
        return jsonDecode(res.body)['data'];
      }

      return {};
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendNotifFcm(String title, String body, String to) async {
    try {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // Add a custom header to the request
            options.headers['Authorization'] = 'key=${FCM_KEY}';
            return handler.next(options);
          },
        ),
      );
      final res = await dio.post('$baseUrlFcm/send', data: {
        "notification": {"title": title, "body": body, "click_action": ""},
        "to": to
      });
      if (res.statusCode == 200) {}
    } catch (e) {
      rethrow;
    }
  }
}
