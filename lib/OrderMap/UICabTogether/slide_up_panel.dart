import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:flutter/material.dart';

class OrderInfoContainer extends StatefulWidget {
  final List<String?> itemName;

  const OrderInfoContainer(this.itemName, {super.key});

  @override
  OrderInfoContainerState createState() => OrderInfoContainerState();
}

class OrderInfoContainerState extends State<OrderInfoContainer> {
  List<String> weight = [
    '1kg x 1',
    '1kg x 1',
    '1kg x 1',
  ];
  List<double> prices = [
    3.00,
    4.50,
    2.50,
  ];

  double sum() {
    double total = 0.00;
    for (int i = 0; i < prices.length; i++) {
      total += prices[i];
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return FadedSlideAnimation(
      beginOffset: const Offset(0, 0.3),
      endOffset: const Offset(0, 0),
      slideCurve: Curves.linearToEaseOut,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        color: Theme.of(context).cardColor,
        height: MediaQuery.of(context).size.width - 40,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemCount: widget.itemName.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: ListTile(
                      title: Text(
                        widget.itemName[index]!,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(
                                fontWeight: FontWeight.w500, fontSize: 15.0),
                      ),
                      subtitle: Text(
                        weight[index],
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(fontSize: 13.3),
                      ),
                      trailing: Text(
                        '\$ ${prices[index]}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(fontSize: 13.3),
                      ),
                    ),
                  );
                },
              ),
            ),
            //SizedBox(height: 6.0),
            Container(
              height: 50.0,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              color: Theme.of(context).cardColor,
              child: Row(
                children: [
                  Image.asset(
                    'images/custom/ic_instruction.png',
                    scale: 3.5,
                  ),
                  const SizedBox(
                    width: 15.0,
                  ),
                  Text(
                    AppLocalizations.of(context)!.instruction!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              height: 50.0,
              color: kMainColor,
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      AppLocalizations.of(context)!.cod!,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .copyWith(color: kWhiteColor),
                    ),
                    Text(
                      '\$ 11.50',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: kWhiteColor, fontWeight: FontWeight.bold),
                    ),
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}
