import 'dart:io';
import 'package:ar/widgets/countdownWidget.dart';
import 'package:flutter/material.dart';
import 'package:hidden_drawer_menu/hidden_drawer_menu.dart';
import '../helpers/auth_view_model.dart';
import '../helpers/timer.dart';
import '../model/user_model.dart';
import '../view/fossili/challenge.dart';
import '../view/fossili/home.dart';
import '../view/fossili/ammonite_list.dart';
import '../view/fossili/ammonite_backpack.dart';
import '../widgets/costanti.dart';

class HiddenDrawer extends StatefulWidget {
  const HiddenDrawer({Key? key}) : super(key: key);

  @override
  State<HiddenDrawer> createState() => _HiddenDrawerState();
}

class _HiddenDrawerState extends State<HiddenDrawer> {
  List<ScreenHiddenDrawer> _screens = [];
  final viewModel = AuthViewModel();
  UserModel user = UserModel(userId: "", nome: "", email: "", password: "", lista_fossili: [], lista_challenge: {});

  _getuser() async {
    var prefId = await viewModel.getIdSession();
    var user = await viewModel.getUserFormId(prefId);
    if (user != null) {
      setState(() {
        this.user = user;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getuser();
    _screens = [
      ScreenHiddenDrawer(
        ItemHiddenMenu(
          name: 'HOME',
          baseStyle: defaultTextStyle,
          selectedStyle: defaultTextStyle,
          colorLineSelected: Colors.black54,
        ),
        const Home(),
      ),
      ScreenHiddenDrawer(
        ItemHiddenMenu(
          name: 'CHALLENGE',
          baseStyle: defaultTextStyle,
          selectedStyle: defaultTextStyle,
          colorLineSelected: Colors.black54,
        ),
        const Challenge(),
      ),
      ScreenHiddenDrawer(
        ItemHiddenMenu(
          name: 'FOSSILI',
          baseStyle: defaultTextStyle,
          selectedStyle: defaultTextStyle,
          colorLineSelected: Colors.black54,
        ),
        const AmmoniteList(),
      ),
      ScreenHiddenDrawer(
        ItemHiddenMenu(
          name: 'ZAINO',
          baseStyle: defaultTextStyle,
          selectedStyle: defaultTextStyle,
          colorLineSelected: Colors.black54,
        ),
        const AmmoniteBackpack(),
      ),
      ScreenHiddenDrawer(
        ItemHiddenMenu(
          name: 'ESCI',
          onTap: () async {
            await viewModel.removeSession();
            TimerController.to.stopTimer();
            exit(0);
          },
          baseStyle: defaultTextStyle,
          selectedStyle: defaultTextStyle,
          colorLineSelected: Colors.black54,
        ),
        const Home(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    print('HiddenDrawer: Building Stack with TimerWidget');
    return Stack(
      children: [
        HiddenDrawerMenu(
          backgroundColorMenu: const Color.fromRGBO(222, 184, 135, 1),
          backgroundColorAppBar: marrone,
          screens: _screens,
          isTitleCentered: true,
          initPositionSelected: 0,
          slidePercent: 60,
          styleAutoTittleName: defaultTextStyle,
        ),
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: TimerWidget(),
          ),
        ),
      ],
    );
  }
}