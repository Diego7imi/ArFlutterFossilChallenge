import 'package:ar/repository/challenge_repository.dart';
import 'package:ar/view/fossili/ammonite_list.dart';
import 'package:ar/view/fossili/challenge.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:latlong2/latlong.dart';

import '../model/challenge_model.dart';

class ChallengeViewModel extends GetxController {
  final service = ChallengeService();

  ValueNotifier<bool> get loading => _loading;
  ValueNotifier<bool> _loading = ValueNotifier(false);

  List<ChallengeModel> get challenge => _challenge;
  List<ChallengeModel> _challenge = [];

  ChallengeViewModel() {
    getChallenge();
  }

  getChallenge() async {
     _loading.value = true;
    ChallengeService().getChallenge().then((value) {
      for (int i = 0; i < value.length; i++) {
        _challenge.add(ChallengeModel.fromJson(value[i].data() as Map<dynamic, dynamic>));
        _loading.value = false;
      }
      update();
    });
  }
  addChallenge(ChallengeModel challenge) async{
    await service.addChallenge(challenge);
  }
  updateChallenge(ChallengeModel challenge) async{
    await service.updateChallenge(challenge);
  }

  Future<void> addUserToLeaderboard(String challengeId, String userId) async {
    _loading.value = true;
    try {
      await service.addToLeaderboard(challengeId, userId);
    } catch (e) {
      print('Errore durante l\'aggiunta alla classifica: $e');
    } finally {
      _loading.value = false;
      update();
    }
  }

  Future<void> removeUserFromLeaderboard(String challengeId, String userId) async {
    _loading.value = true;
    try {
      await service.removeFromLeaderboard(challengeId, userId);
    } catch (e) {
      print('Errore durante la rimozione dalla classifica: $e');
    } finally {
      _loading.value = false;
      update();
    }
  }

  Future<int> getFossilPoints(String fossilId, String challengeId) async {
    var challenge = _challenge.firstWhere((c) => c.id == challengeId);;
    return challenge.ammoniti?[fossilId];
  }

  Future<void> updateUserScore(String challengeId, String userId, int points, String fossilName) async{
    var data = _challenge.firstWhere((c) => c.id == challengeId);
    var punteggio = data.classifica?[userId];
    int punti = punteggio + points;
    data.classifica?[userId] = punti;
    await updateChallenge(data);
    await service.addFossilToChallengeList(userId, challengeId, fossilName);
  }

  Future<bool> isUserEnrolled(String challengeId, String userId) async{
    ChallengeModel? challenge = await service.getChallengeById(challengeId);
    if (challenge == null || challenge.classifica == null) return false;
    return challenge.classifica!.containsKey(userId);
    //return challenge.classifica!.contains(userId);
  }

  Future<bool> userHasCaughtFossil(String challengeId, String userId) async {
    final fossils = await service.getCollectedFossilsForChallenge(userId, challengeId);
    return fossils.isNotEmpty;
  }

  Future<List<LatLng>> getPolygonPoints(String? challengeId) async {
    ChallengeModel? challenge = await service.getChallengeById(challengeId!);

    Map<String, dynamic> posizione = challenge?.posizione as Map<String, dynamic>;
    List<String> sortedKeys = posizione.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    List<LatLng> points = [];
    for (String key in sortedKeys) {
      String coordString = posizione[key] as String;
      List<String> coords = coordString.split(', ');
      if (coords.length == 2) {
        points.add(LatLng(
          double.parse(coords[0].trim()),
          double.parse(coords[1].trim()),
        ));
      }
    }
    return points;
  }
}