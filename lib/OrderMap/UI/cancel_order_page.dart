import "package:deliq_delivery/Auth/MobileNumber/UI/phone_number.dart";
import "package:deliq_delivery/Routes/routes.dart";
import "package:flutter/material.dart";

class CancelOrderPage extends StatelessWidget {
  const CancelOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 250,
          height: 457,
          child: Column(
            children: [
              Image.asset(
                'images/order.png',
                width: 250,
                height: 210,
              ),
              const SizedBox(
                height: 25,
              ),
              Text(
                'Orderan Di batalkan oleh customer',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, PageRoutes.accountPage, (route) => false);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  child: Text(
                    'Kembali Ke Beranda',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
