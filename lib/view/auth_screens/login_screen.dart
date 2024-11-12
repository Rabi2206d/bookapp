import 'package:bookstore/main.dart';
import 'package:bookstore/widgets/widgets_common.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bookstore/const/consts.dart';
import 'package:bookstore/view/Home_Screen/home.dart';
import 'package:bookstore/view/auth_screens/signup_screen.dart';
import 'package:bookstore/widgets/bg_widget.dart';
import 'package:bookstore/widgets/custom_textfield.dart';
import 'package:bookstore/widgets/our_button.dart';
import 'package:bookstore/Admin_Panel/AdminPanel.dart';
import 'package:firebase_core/firebase_core.dart'; // Ensure firebase is initialized

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class Login_Screen extends StatefulWidget {
  const Login_Screen({super.key});

  @override
  _Login_ScreenState createState() => _Login_ScreenState();
}

class _Login_ScreenState extends State<Login_Screen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true; // Variable to toggle password visibility

  // Initialize GoogleSignIn with web client ID (update with your own Client ID)
  final GoogleSignIn googleSignIn = GoogleSignIn(
    clientId: '934197175528-l1ndthd5a6bl32b5dp7263dhlnq32eag.apps.googleusercontent.com',  // Use your actual client ID here
  );

  // Function to handle Google Sign-In via renderButton
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // Check user role in Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).get();

      if (userDoc.exists) {
        String role = userDoc['role'];

        if (role == 'admin') {
          Get.to(() => const AdminPanel());
        } else {
          Get.to(() => const Home());
        }
      } else {
        // If user does not exist, create a new user record
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
          'name': googleUser.displayName,
          'email': googleUser.email,
          'role': 'user', // Default role for new users
        });
        Get.to(() => const Home());
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.message ?? "An error occurred during Google sign-in.");
    } catch (e) {
      Get.snackbar("Error", "An unexpected error occurred: $e");
    }
  }

  // Social Media Icons Widget
  Widget socialMediaIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () async {
            await _signInWithGoogle();
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: lightGrey,
              radius: 25,
              child: Image.asset(
                icGoogleLogo, // Google logo
                width: 30,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: lightGrey,
            radius: 25,
            child: Image.asset(
              icFacebookLogo, // Facebook logo
              width: 30,
            ),
          ),
        ),
        // You can add more icons here as needed
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return bgWidget(
      child: Scaffold(
        resizeToAvoidBottomInset: true, // Ensure that the UI resizes when keyboard appears
        body: SingleChildScrollView( // Wrap the body in a scroll view
          child: Center(
            child: Column(
              children: [
                (context.screenHeight * 0.1).heightBox,
                applogoWidget(),
                10.heightBox,
                "Log in to $appname".text.fontFamily(bold).white.size(18).make(),
                15.heightBox,
                Column(
                  children: [
                    CustomTextField(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      controller: emailController,
                    ),
                    // Password field with toggle view password option
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        CustomTextField(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          controller: passwordController,
                          obscureText: _obscurePassword,
                        ),
                        IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          if (emailController.text.isNotEmpty) {
                            try {
                              await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text);
                              Get.snackbar(
                                "Success",
                                "Password reset email sent. Please check your inbox.",
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                            } on FirebaseAuthException catch (e) {
                              Get.snackbar(
                                "Error",
                                e.message ?? "An error occurred",
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            }
                          } else {
                            Get.snackbar(
                              "Error",
                              "Please enter your email address.",
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        },
                        child: forgot.text.make(),
                      ),
                    ),
                    5.heightBox,
                    ourButton(
                      color: redColor,
                      textcolor: whiteColor,
                      title: login,
                      onPress: () async {
                        try {
                          UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                            email: emailController.text,
                            password: passwordController.text,
                          );

                          DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).get();

                          if (userDoc.exists) {
                            String role = userDoc['role'];

                            if (role == 'admin') {
                              Get.to(() => const AdminPanel());
                            } else {
                              Get.to(() => const Home());
                            }
                          } else {
                            Get.snackbar("Error", "User not found");
                          }
                        } on FirebaseAuthException {
                          Get.snackbar("Error", "Wrong Email Or Password");
                        }
                      },
                    ).box.width(context.screenWidth - 50).make(),
                    5.heightBox,
                    createnewAcc.text.color(fontGrey).make(),
                    5.heightBox,
                    ourButton(
                      color: lightgolden,
                      textcolor: redColor,
                      title: signup,
                      onPress: () {
                        Get.to(() => const Signup_Screen());
                      },
                    ).box.width(context.screenWidth - 50).make(),
                    10.heightBox,
                    loginwith.text.color(fontGrey).make(),
                    5.heightBox,
                    socialMediaIcons(), // Call the socialMediaIcons widget here
                  ],
                ).box.white.rounded.padding(const EdgeInsets.all(16)).width(context.screenWidth - 70).shadowSm.make(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
