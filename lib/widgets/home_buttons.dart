import 'package:bookstore/const/consts.dart';

Widget homebutton({width, height, icon, String? title, onPress, required String text}) {
  return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Image.asset(
      icon,
      width: 26,
    ),
    10.heightBox,
    title!.text.fontFamily(semibold).color(darkFontGrey).make(),
  ]).box.rounded.white.size(width, height).make();
}
