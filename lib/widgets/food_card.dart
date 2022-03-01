import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FoodCard extends StatelessWidget {
  final String title;
  final DateTime expiration;

  const FoodCard({Key? key, required this.title, required this.expiration}) : super(key: key);

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
    int expirationDays = expiration.difference(DateTime.now()).inDays;
    TextStyle daysStyle = const TextStyle(color: Colors.grey);
    return ListTile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          Text(
            "Expiration: ${DateFormat('yyyy-MM-dd').format(expiration)}",
            style: daysStyle.copyWith(
              fontSize: 10
            ),
          ),
        ],
      ),
      trailing: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        child: Row(
          children: [
            Text("0d", style: daysStyle),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: LinearProgressIndicator(
                    value: expirationDays / 20,
                    color: calculateProgressIndicatorColor(expirationDays),
                    backgroundColor: Colors.grey,
                  ),
                ),
              ),
            ),
            Text("20d", style: daysStyle,),
          ],
        ),
      ),
    );
  }

}
