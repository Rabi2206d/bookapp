import 'package:bookstore/view/Home_Screen/home.dart';
import 'package:bookstore/view/more/OrderListScreen.dart';
import 'package:flutter/material.dart';
import 'package:bookstore/common_widget/round_button.dart';

class CheckoutMessageView extends StatelessWidget {
  const CheckoutMessageView({super.key});

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
      width: media.width,
      height: media.height, // Set to full height
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              "assets/img/thank_you.png",
              width: media.width * 0.45,
              height: media.height * 0.25,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 25),
            const Text(
              "Thank You!",
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "for your order",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Your Order is now being processed. We will let you know once the order is picked from the outlet.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 35),
            RoundButton(
              title: "Track My Order",
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const OrderslistScreen()),
                );
              },
            ),
            const SizedBox(height: 35),
            RoundButton(
              title: "Back To Home",
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Home()),
                );
              },
             
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
