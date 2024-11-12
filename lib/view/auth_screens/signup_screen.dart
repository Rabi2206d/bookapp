import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookstore/const/consts.dart';
import 'package:bookstore/widgets/bg_widget.dart';
import 'package:bookstore/widgets/custom_textfield.dart';
import 'package:bookstore/widgets/our_button.dart';
import 'package:bookstore/widgets/widgets_common.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class Signup_Screen extends StatefulWidget {
  const Signup_Screen({super.key});

  @override
  State<Signup_Screen> createState() => _Signup_ScreenState();
}

class _Signup_ScreenState extends State<Signup_Screen> {
  bool isCheck = false;
  bool showPassword = false; 
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController retypePasswordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController(); // Address controller
  PhoneNumber? phoneNumber;

  @override
  Widget build(BuildContext context) {
    PhoneNumber initialPhoneNumber = PhoneNumber(isoCode: 'PK');

    return bgWidget(
      child: Scaffold(
        resizeToAvoidBottomInset: true, // Allow resizing
        body: SingleChildScrollView( // Enable scrolling
          padding: const EdgeInsets.only(bottom: 30.0), // Add bottom padding
          child: Center(
            child: Column(
              children: [
                (context.screenHeight * 0.1).heightBox,
                applogoWidget(),
                10.heightBox,
                "Sign up to $appname".text.fontFamily(bold).white.size(18).make(),
                15.heightBox,
                Column(
                  children: [
                    CustomTextField(
                      labelText: 'Full Name',
                      hintText: 'Enter your name',
                      controller: nameController,
                      keyboardType: TextInputType.text,
                    ),
                    CustomTextField(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: InternationalPhoneNumberInput(
                        onInputChanged: (PhoneNumber number) {
                          phoneNumber = number;
                        },
                        selectorConfig: const SelectorConfig(
                          selectorType: PhoneInputSelectorType.DROPDOWN,
                        ),
                        ignoreBlank: false,
                        autoValidateMode: AutovalidateMode.disabled,
                        selectorTextStyle: const TextStyle(color: Colors.black),
                        initialValue: initialPhoneNumber,
                        textFieldController: phoneController,
                        maxLength: 11,
                        formatInput: false,
                        keyboardType: TextInputType.number,
                        inputDecoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter your phone number',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    CustomTextField(
                      labelText: 'Address', // Address field
                      hintText: 'Enter your address',
                      controller: addressController,
                      keyboardType: TextInputType.text,
                    ),
                    CustomTextField(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      controller: passwordController,
                      obscureText: !showPassword,
                      keyboardType: TextInputType.text,
                      suffixIcon: IconButton(
                        icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            showPassword = !showPassword;
                          });
                        },
                      ),
                    ),
                    CustomTextField(
                      labelText: 'Re-type Password',
                      hintText: 'Re-enter your password',
                      controller: retypePasswordController,
                      obscureText: !showPassword,
                      keyboardType: TextInputType.text,
                      suffixIcon: IconButton(
                        icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            showPassword = !showPassword;
                          });
                        },
                      ),
                    ),
                    5.heightBox,
                    Row(
                      children: [
                        Checkbox(
                          activeColor: redColor,
                          checkColor: whiteColor,
                          value: isCheck,
                          onChanged: (newValue) {
                            setState(() {
                              isCheck = newValue!;
                            });
                          },
                        ),
                        10.widthBox,
                        Expanded(
                          child: RichText(
                            text: const TextSpan(children: [
                              TextSpan(text: "I agree to the ", style: TextStyle(fontFamily: regular, color: fontGrey)),
                              TextSpan(text: tremConditions, style: TextStyle(fontFamily: regular, color: redColor)),
                              TextSpan(text: " & ", style: TextStyle(fontFamily: regular, color: fontGrey)),
                              TextSpan(text: privacyPolicy, style: TextStyle(fontFamily: regular, color: redColor)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                    10.heightBox,
                    ourButton(
                      color: isCheck ? redColor : lightGrey,
                      textcolor: whiteColor,
                      title: signup,
                      onPress: () async {
                        if (nameController.text.isEmpty || emailController.text.isEmpty || phoneController.text.isEmpty || addressController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please fill all fields."),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (passwordController.text != retypePasswordController.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Passwords do not match."),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Validate phone number length
                        String phone = phoneController.text.trim();
                        if (phone.length != 11 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Phone number must be exactly 11 digits."),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
                              .collection('users')
                              .where('email', isEqualTo: emailController.text.trim())
                              .get();

                          if (querySnapshot.docs.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Email is already in use."),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          UserCredential userCredential = await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                            email: emailController.text.trim(),
                            password: passwordController.text,
                          );

                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userCredential.user?.uid)
                              .set({
                            'name': nameController.text,
                            'email': emailController.text,
                            'phone': phone, // Save phone number
                            'address': addressController.text, // Save address
                            'role': 'user',
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Account created successfully."),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Get.back();
                        } on FirebaseAuthException catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.message ?? "An error occurred"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("An unexpected error occurred: $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ).box.width(context.screenWidth - 50).make(),
                    10.heightBox,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        alreadyhaveanacc.text.color(fontGrey).make(),
                        login.text.color(redColor).make().onTap(() {
                          Get.back();
                        }),
                      ],
                    ),
                  ],
                )
                    .box
                    .white
                    .rounded
                    .padding(const EdgeInsets.all(16))
                    .width(context.screenWidth - 70)
                    .shadowSm
                    .make(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
