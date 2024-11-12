import 'package:get/get.dart';
import 'package:bookstore/const/consts.dart';
import 'package:bookstore/view/auth_screens/login_screen.dart';
import 'package:bookstore/widgets/widgets_common.dart';
import 'package:bookstore/view/auth_screens/signup_screen.dart'; // Import your Signup_Screen


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  ChangeScreen() {
    Future.delayed(const Duration(seconds: 2), () {
      Get.to(() => const Login_Screen());
    });
  }


  @override
  void initState() {
    ChangeScreen();
    super.initState();
  }
  
void main() {
  runApp(
    const GetMaterialApp(
      home: Signup_Screen(),
      // Other configurations...
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: redColor,
      body: Center(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Image.asset(
                icSplashBg,
                width: 300,
              ),
            ),
            20.heightBox,
            applogoWidget(),
            10.heightBox,
            appname.text.fontFamily(bold).size(22).white.make(),
            5.heightBox,
            appversion.text.white.make(),
            const Spacer(),
            credits.text.white.fontFamily(semibold).make(),
            30.heightBox
          ],
        ),
      ),
    );
  }
}
