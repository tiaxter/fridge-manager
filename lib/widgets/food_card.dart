import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';

import 'food_adder.dart';

class FoodCard extends StatelessWidget {
  final String title;
  final DateTime expiration;
  final double quantity;
  final int id;

  const FoodCard({Key? key, required this.title, required this.expiration, required this.id, required this.quantity}) : super(key: key);

  Color calculateProgressIndicatorColor(int expirationDays) {
    if (expirationDays >= 15) {
      return Colors.greenAccent;
    }

    if (expirationDays < 15 && expirationDays >= 10) {
      return Colors.yellowAccent;
    }

    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    int expirationDays = Jiffy(expiration).endOf(Units.DAY).diff(Jiffy(), Units.DAY, false).toInt();
    return ListTile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  title,
                ),
              ),
              Text(
                " (x${quantity.toInt()})",
                style: const TextStyle(
                  color: Colors.grey,
                ),
              )
            ],
          ),
          Text(
            "Expiration: ${Jiffy(expiration).format('yyyy-MM-dd')}",
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12
            ),
          ),
        ],
      ),
      trailing: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4,
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: LinearProgressIndicator(
                  value: expirationDays / 20,
                  color: calculateProgressIndicatorColor(expirationDays),
                  backgroundColor: Colors.grey,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  "$expirationDays / 20+",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  )
                ),
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return FoodAdderPopup(id: id);
          }
        );
      },
    );
  }

}
