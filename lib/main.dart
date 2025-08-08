import 'package:ar/helpers/auth_view_model.dart';
import 'package:ar/helpers/ammonite_view_model.dart';
import 'package:ar/helpers/challenge_view_model.dart';
import 'package:ar/helpers/timer.dart';
import 'package:ar/model/ammonite.dart';
import 'package:ar/model/challenge_model.dart';
import 'package:ar/model/user_model.dart';
import 'package:ar/repository/auth_repository.dart';
import 'package:ar/view/connectivity/dependency_injection.dart';
import 'package:ar/view/splash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/binding.dart';

late SharedPreferences sharedPreferences;
late List<Ammonite> ammoniti;
late List<ChallengeModel> challenge;
late List<UserModel> utenti;
final viewmodelAmmonite = AmmoniteViewModel();
final viewmodelChallenge = ChallengeViewModel();
final viewmodelUser = AuthViewModel();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  sharedPreferences = await SharedPreferences.getInstance();
  await dotenv.load(fileName: "assets/config/.env");
  ammoniti = viewmodelAmmonite.ammonite;
  challenge = viewmodelChallenge.challenge;
  utenti = await viewmodelUser.getUserList();
  DependencyInjection.init();

  // Inizializza il TimerController
  Get.put(AuthViewModel());
  Get.put(TimerController());
  TimerController.to.loadTimerState();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('MyApp: Building GetMaterialApp');
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialBinding: Binding(),
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      themeMode: ThemeMode.dark,
      home: const Splash(),
    );
  }
}