import 'dart:convert';

import 'package:deliq_delivery/Core/result.dart';
import 'package:deliq_delivery/models/deposit_model.dart';
import 'package:deliq_delivery/services/auth_service.dart';
import 'package:deliq_delivery/services/error_services.dart';
import 'package:deliq_delivery/shared/shared_values.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart';

class SharedServices {
  Future<List> getTransactions(driver_id) async {
    final token = await AuthService().getToken();
    final res = await get(
        Uri.parse('$baseUrl/drivers/transaction?driver_id=${driver_id}'),
        headers: {
          'Authorization': token,
        });
    if (res.statusCode == 200) {
      print('resy');
      return jsonDecode(res.body)['data'];
    } else {
      return [];
    }
  }

  Future<void> updateSaldoDriver(driver_id, balance) async {
    final token = await AuthService().getToken();
    final res = await post(Uri.parse('$baseUrl/drivers/update'),
        headers: {'Authorization': token},
        body: {'id': driver_id, 'balance': balance});

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }
  }

  Future<void> addTransaction(
      driver_id, price, mode, type, payment_method) async {
    final token = await AuthService().getToken();

    final res = await post(Uri.parse('$baseUrl/drivers/transaction'), headers: {
      'Authorization': token
    }, body: {
      'driver_id': driver_id,
      'price': price,
      'mode': mode,
      'type': type,
      'payment_method': payment_method
    });

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }
  }

  Future<void> addTransactionMerchant(
      merchant_id, price, mode, type, payment_method) async {
    final token = await AuthService().getToken();

    final res =
        await post(Uri.parse('$baseUrl/merchant/transaction'), headers: {
      'Authorization': token
    }, body: {
      'merchant_id': merchant_id,
      'price': price,
      'mode': mode,
      'type': type,
      'payment_method': payment_method
    });

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }
  }

  Future<Map<String, dynamic>> showMerchant(merchant_id) async {
    final token = await AuthService().getToken();
    final res = await get(Uri.parse('$baseUrl/merchant/${merchant_id}'),
        headers: {'Authorization': token});

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }

    return {};
  }

  Future<void> updateSaldoMerchant(merchant_id, balance) async {
    final token = await AuthService().getToken();

    final res = await post(Uri.parse('$baseUrl/merchant/update'),
        headers: {'Authorization': token},
        body: {'id': merchant_id, 'balance': balance});

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }
  }

  Future<List<DepositModel>> getDeposits(customer_id) async {
    final token = await AuthService().getToken();
    try {
      final res = await get(Uri.parse('$baseUrl/v2/drivers/deposit'), headers: {
        'Authorization': token,
      });
      if (res.statusCode == 200) {
        List<dynamic> data = json.decode(res.body)['data'];
        return data.map((item) => DepositModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load deposits');
      }
    } catch (e) {
      print(e);
      throw Exception('Failed to load deposits');
    }
  }

  Future<Result> getSettings() async {
    try {
      final token = await AuthService().getToken();
      final res = await get(Uri.parse('$baseUrlGo/settings'), headers: {
        'Authorization': token,
      });
      if (res.statusCode == 200) {
        return Result.success(jsonDecode(res.body)['data']);
      } else {
        return Result.error('Terjadi Kesalahan / Sedang mengalami gangguan');
      }
    } catch (e) {
      return Result.error('Terjadi Kesalahan / Sedang mengalami gangguan');
    }
  }

  Future<Map<String, dynamic>> finishTransactionProduct(
      String payment_method,
      String price_trip,
      String driver_id,
      List merchants,
      List products) async {
    final token = await AuthService().getToken();
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add a custom header to the request
          options.headers['Authorization'] = token;
          return handler.next(options);
        },
      ),
    );

    final res =
        await dio.post('$baseUrl/drivers/finish-transaction-product', data: {
      "payment_method": payment_method,
      "price_trip": price_trip,
      "driver_id": driver_id,
      "merchants": merchants,
      "products": products
    });

    if (res.statusCode == 200) {
      return res.data['data'];
    }

    return {};
  }

  Future<List?> getBanks() async {
    final token = await AuthService().getToken();

    final res = await get(Uri.parse('$baseUrl/banks'),
        headers: {'Authorization': token});

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }

    return [];
  }

  Future<Map<String, dynamic>> inquiry(String code, String idpel) async {
    final token = await AuthService().getToken();

    final res = await post(Uri.parse('$baseUrl/berkah/inquiry'),
        headers: {'Authorization': token},
        body: {"code": code, "idpel": idpel});

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return {};
  }

  Future<Map<String, dynamic>> paymentDriver(String customer_id, String code,
      String idpel, String payment_method, String price, List info) async {
    final token = await AuthService().getToken();

    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add a custom header to the request
          options.headers['Authorization'] = token;
          return handler.next(options);
        },
      ),
    );
    final res = await dio.post('$baseUrl/berkah/payment/driver', data: {
      "driver_id": customer_id,
      "code": code,
      "idpel": idpel,
      "payment_method": payment_method,
      "price": price,
      "info": info
    });

    if (res.statusCode == 200) {
      return res.data['data'];
    }
    return {};
  }

  Future<Map<String, dynamic>> driverTakeOrderRide(
      String order_id, String driver_id, String status) async {
    final token = await AuthService().getToken();

    final res = await post(Uri.parse('$baseUrl/drivers/driver-take-order'),
        headers: {"Authorization": token},
        body: {"order_id": order_id, "driver_id": driver_id, "status": status});

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }

    return {};
  }

  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    final token = await AuthService().getToken();

    final res = await get(Uri.parse('$baseUrl/customers/orders/$orderId'),
        headers: {"Authorization": token});

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }

    return {};
  }

  Future<Map<String, dynamic>> updateStatusOrder(
      String order_id, String status) async {
    final token = await AuthService().getToken();

    final res = await post(Uri.parse('$baseUrl/drivers/update-status-order'),
        headers: {"Authorization": token},
        body: {"order_id": order_id, "status": status});

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }

    return {};
  }

  Future<Map<String, dynamic>> finishOrderRide(String order_id) async {
    final token = await AuthService().getToken();

    final res = await post(
        Uri.parse('$baseUrl/drivers/orders/finish-order-ride'),
        headers: {"Authorization": token},
        body: {"order_id": order_id});

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }

    return {};
  }

  Future<Map<String, dynamic>> finishOrderProduct(String order_id) async {
    final token = await AuthService().getToken();

    final res = await post(
        Uri.parse('$baseUrl/orders/orders/finish-order-product'),
        headers: {"Authorization": token},
        body: {"order_id": order_id});

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }

    return {};
  }

  Future<List?> getOrderByDriverId(String driver_id) async {
    final token = await AuthService().getToken();

    final res = await get(
        Uri.parse(
            '$baseUrl/drivers/orders/get-order-by-driver-id?driver_id=${driver_id}'),
        headers: {"Authorization": token});

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }

    return [];
  }

  Future<List> getReviewByOrderId(
      String driver_id, String order_id, String customer_id) async {
    final token = await AuthService().getToken();

    final res = await post(
        Uri.parse('$baseUrl/customers/orders/get-review-by-order-id'),
        headers: {
          "Authorization": token
        },
        body: {
          "driver_id": driver_id,
          "order_id": order_id,
          "customer_id": customer_id
        });

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }

    return [];
  }

  Future<Map<String, dynamic>> driverTakeOrderMober(
      String order_customer_id,
      String driver_id,
      String price_trip,
      String type_order,
      String grand_total,
      String status) async {
    final token = await AuthService().getToken();

    final res = await post(
        Uri.parse('$baseUrl/drivers/driver-take-order-mober'),
        headers: {
          "Authorization": token,
        },
        body: {
          "order_customer_id": order_customer_id,
          "driver_id": driver_id,
          "price_trip": price_trip,
          "type_order": type_order,
          "grand_total": grand_total,
          "status": status
        });

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }

    return {};
  }

  Future<Map<String, dynamic>> addCustomerMober(
      String order_customer_id, String order_id) async {
    final token = await AuthService().getToken();

    final res = await post(Uri.parse('$baseUrl/drivers/add-customer-mober'),
        headers: {"Authorization": token},
        body: {"order_customer_id": order_customer_id, "order_id": order_id});

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }

    return {};
  }

  Future<Map<String, dynamic>> updateStatusAngkutMober(
      String order_customer_id) async {
    final token = await AuthService().getToken();

    final res = await post(
        Uri.parse('$baseUrl/drivers/update-status-angkut-mober'),
        headers: {"Authorization": token},
        body: {"order_customer_id": order_customer_id});

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }

    return {};
  }

  Future<Map<String, dynamic>> finishOrderCustomerMober(
      String order_customer_id) async {
    final token = await AuthService().getToken();

    final res = await post(
        Uri.parse('$baseUrl/drivers/orders/finish-order-customer-mober'),
        headers: {"Authorization": token},
        body: {"order_customer_id": order_customer_id});

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }

    return {};
  }

  Future<Map<String, dynamic>> earningDriver(String driver_id) async {
    final token = await AuthService().getToken();
    print(token);
    final res = await get(
        Uri.parse('$baseUrl/drivers/earning-driver?driver_id=${driver_id}'),
        headers: {"Authorization": token});

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }

    return {};
  }

  Future<Map<String, dynamic>> finishOrderMober(String order_id) async {
    final token = await AuthService().getToken();

    final res = await post(
        Uri.parse('$baseUrl/drivers/orders/finish-order-mober'),
        headers: {'Authorization': token},
        body: {'order_id': order_id});

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }

    return {};
  }

  Future<Result> getProductsByNote(String note) async {
    try {
      final token = await AuthService().getToken();

      final res = await get(Uri.parse('$baseUrl/berkah/products?note=${note}'),
          headers: {"Authorization": token});

      if (res.statusCode == 200) {
        return Result.success(jsonDecode(res.body)['data']);
      } else {
        return Result.error('Terjadi kesalahan / Sistem mengalami gangguan');
      }
    } catch (e) {
      return Result.error('Terjadi kesalahan / Sistem mengalami gangguan');
    }
  }

  Future<Result> inquiryBerkah(String driver_id, String code_product,
      String dest, String qty, String note, String description) async {
    final token = await AuthService().getToken();

    final res =
        await post(Uri.parse('$baseUrl/drivers/berkah/inquiry'), headers: {
      'Authorization': token
    }, body: {
      "driver_id": driver_id,
      'code_product': code_product,
      'dest': dest,
      'qty': qty,
      'note': note,
      'description': description
    });

    if (res.statusCode == 200) {
      return Result.success(jsonDecode(res.body)['data']);
    } else if (res.statusCode == 400) {
      return Result.error(
          ErrorService.getErrorMessage(jsonDecode(res.body)['code_error']));
    } else {
      return Result.error('Terjadi Kesalahan / Sistem mengalami gangguan');
    }
  }

  Future<Result> payment(String driver_id, String code_product, String dest,
      String qty, List info, String description) async {
    try {
      final token = await AuthService().getToken();

      final Map<String, dynamic> data2 = {
        "driver_id": driver_id,
        "code_product": code_product,
        "dest": dest,
        "qty": qty,
        "info": info,
        "description": description
      };

      final res = await post(Uri.parse('$baseUrl/drivers/berkah/payment'),
          headers: {'Content-Type': 'application/json', 'Authorization': token},
          body: jsonEncode(data2));

      if (res.statusCode == 200) {
        return Result.success(jsonDecode(res.body)['data']);
      } else if (res.statusCode == 400) {
        return Result.error(
            ErrorService.getErrorMessage(jsonDecode(res.body)['code_error']));
      } else {
        return Result.error('Terjadi Kesalahan / Sistem dalam gangguan');
      }
    } catch (e) {
      return Result.error('Terjadi Kesalahan / Cek koneksi internet anda');
    }
  }

  Future<List> getTransactionPurchasesByDriverId(String driver_id) async {
    final token = await AuthService().getToken();

    final res = await get(
        Uri.parse(
            '$baseUrl/drivers/get-transaction-purchases-by-driver-id?driver_id=${driver_id}'),
        headers: {'Authorization': token});

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'];
    }

    return [];
  }

  Future<Result> getListVehicletype() async {
    final res = await get(Uri.parse('$baseUrlGo/driver/vehicletype'));

    if (res.statusCode == 200) {
      return Result.success(jsonDecode(res.body)['data']);
    } else {
      return Result.error('gagal');
    }
  }

  Future<Result> getListVehicleCategory() async {
    final res = await get(Uri.parse('$baseUrl/driver/vehicle-categories'));

    if (res.statusCode == 200) {
      return Result.success(jsonDecode(res.body)['data']);
    } else {
      return Result.error('gagal');
    }
  }

  Future<Result> inquiryCekUser(String typeUser, String nohp) async {
    try {
      final token = await AuthService().getToken();

      final res = await post(
          Uri.parse('$baseUrl/berkah/customer/inquiry-cek-user'),
          headers: {'Authorization': token},
          body: {'type_user': typeUser, 'nohp': nohp});

      if (res.statusCode == 200) {
        return Result.success(jsonDecode(res.body)['data']);
      } else if (res.statusCode == 400) {
        return Result.error(jsonDecode(res.body)['message']);
      } else {
        return Result.error('Terjadi Kesalahan / Sistem dalam gangguan');
      }
    } catch (e) {
      return Result.error('Terjadi Kesalahan / Periksa Koneksi internet anda');
    }
  }

  Future<Result> sendSaldo(
      String driverId, String nominal, String typeUser, String nohp) async {
    try {
      final token = await AuthService().getToken();

      final res = await post(Uri.parse('$baseUrl/berkah/driver/send-saldo-v2'),
          headers: {
            'Authorization': token
          },
          body: {
            'driver_id': driverId,
            'nominal': nominal,
            'type_user': typeUser,
            'nohp': nohp
          });

      if (res.statusCode == 200) {
        return Result.success(jsonDecode(res.body)['data']);
      } else if (res.statusCode == 400) {
        return Result.error(jsonDecode(res.body)['message']);
      } else {
        return Result.error('Terjadi Kesalahan / Sistem dalam gangguan');
      }
    } catch (e) {
      return Result.error('Terjadi Kesalahan / Periksa koneksi internet anda');
    }
  }
}
