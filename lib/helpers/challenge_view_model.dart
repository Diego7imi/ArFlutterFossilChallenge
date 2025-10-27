import 'package:ar/repository/challenge_repository.dart';
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

  /// Recupera tutte le challenge dal servizio remoto (ad esempio Firestore)
  /// e aggiorna la lista locale `_challenge`.
  ///
  /// Funzionamento:
  /// - Imposta `_loading` su `true` per indicare l'inizio del caricamento.
  /// - Chiama `ChallengeService().getChallenge()` per ottenere i dati.
  /// - Converte ogni elemento della risposta in un `ChallengeModel`
  ///   tramite `fromJson`, e lo aggiunge alla lista interna.
  /// - Alla fine, aggiorna lo stato (`update()`) per riflettere i nuovi dati.
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

  /// Aggiunge una nuova challenge al database.
  ///
  /// Funzionamento:
  /// - Riceve un oggetto `ChallengeModel` già compilato.
  /// - Passa il modello al metodo `service.addChallenge()`,
  ///   che si occupa della scrittura effettiva nel backend (es. Firestore).
  addChallenge(ChallengeModel challenge) async{
    await service.addChallenge(challenge);
  }

  /// Aggiorna i dati di una challenge esistente.
  ///
  /// Funzionamento:
  /// - Riceve un `ChallengeModel` aggiornato.
  /// - Passa il modello al metodo `service.updateChallenge()`,
  ///   che si occupa di sincronizzare i cambiamenti con il database.
  updateChallenge(ChallengeModel challenge) async{
    await service.updateChallenge(challenge);
  }

  /// Aggiunge un utente alla classifica di una determinata challenge.
  ///
  /// Funzionamento:
  /// - Imposta `_loading` su `true` per mostrare un eventuale caricamento.
  /// - Chiama `service.addToLeaderboard(challengeId, userId)`
  ///   che inserisce l'utente nella mappa `classifica` della challenge.
  /// - Se si verifica un errore, viene stampato in console.
  /// - Alla fine, `_loading` torna `false` e viene chiamato `update()`
  ///   per aggiornare lo stato visivo o i listener.
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

  /// Rimuove un utente dalla classifica di una challenge.
  ///
  /// Funzionamento:
  /// - Attiva il flag `_loading`.
  /// - Chiama `service.removeFromLeaderboard()` per rimuovere
  ///   la voce corrispondente all’utente dalla classifica.
  /// - Gestisce eventuali errori con un messaggio in console.
  /// - Alla fine, disattiva `_loading` e aggiorna lo stato.
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

  /// Restituisce il numero di punti associati a un determinato fossile
  /// in una specifica challenge.
  ///
  /// Funzionamento:
  /// - Trova la challenge con l’`id` corrispondente nella lista `_challenge`.
  /// - Accede alla mappa `ammoniti` (che collega fossili e punti)
  ///   e ritorna il valore associato al `fossilId`.
  ///
  /// Se il fossile non è presente, la funzione può restituire `null`.
  Future<int> getFossilPoints(String fossilId, String challengeId) async {
    var challenge = _challenge.firstWhere((c) => c.id == challengeId);;
    return challenge.ammoniti?[fossilId];
  }

  /// Aggiorna il punteggio di un utente in una challenge e registra
  /// il fossile che ha appena raccolto.
  ///
  /// Funzionamento:
  /// - Recupera la challenge corrispondente dal buffer locale.
  /// - Ottiene il punteggio corrente dell’utente dalla mappa `classifica`.
  /// - Somma i nuovi punti e aggiorna il valore nella mappa.
  /// - Chiama `updateChallenge()` per salvare le modifiche nel database.
  /// - Registra anche il fossile raccolto chiamando
  ///   `service.addFossilToChallengeList(userId, challengeId, fossilName)`.
  Future<void> updateUserScore(String challengeId, String userId, int points, String fossilName) async{
    var data = _challenge.firstWhere((c) => c.id == challengeId);
    var punteggio = data.classifica?[userId];
    int punti = punteggio + points;
    data.classifica?[userId] = punti;
    await updateChallenge(data);
    await service.addFossilToChallengeList(userId, challengeId, fossilName);
  }

  /// Controlla se un utente risulta già iscritto a una determinata challenge.
  ///
  /// Funzionamento:
  /// - Recupera la challenge con l’id fornito dal servizio.
  /// - Se la challenge non esiste o non ha una classifica, restituisce `false`.
  /// - Altrimenti, verifica se l’`userId` è presente come chiave
  ///   nella mappa `classifica`.
  Future<bool> isUserEnrolled(String challengeId, String userId) async{
    ChallengeModel? challenge = await service.getChallengeById(challengeId);
    if (challenge == null || challenge.classifica == null) return false;
    return challenge.classifica!.containsKey(userId);
  }


  /// Controlla se l’utente ha già raccolto almeno un fossile
  /// all’interno di una determinata challenge.
  ///
  /// Funzionamento:
  /// - Recupera dal servizio la lista dei fossili catturati
  ///   da quell’utente in quella challenge.
  /// - Se la lista è vuota → ritorna `false`.
  /// - Se contiene elementi → ritorna `true`.
  Future<bool> userHasCaughtFossil(String challengeId, String userId) async {
    final fossils = await service.getCollectedFossilsForChallenge(userId, challengeId);
    return fossils.isNotEmpty;
  }

  /// Recupera e ricostruisce la lista di punti (coordinate LatLng)
  /// che definiscono il poligono geografico associato a una challenge.
  ///
  /// Funzionamento:
  /// - Ottiene la challenge con l’ID specificato.
  /// - Estrae la mappa `posizione`, dove ogni chiave numerica (come "1", "2", "3")
  ///   rappresenta un punto e il valore è una stringa con latitudine e longitudine.
  /// - Ordina le chiavi numericamente per mantenere l’ordine corretto dei vertici.
  /// - Converte ogni coppia di coordinate da stringa a `double`
  ///   e crea un oggetto `LatLng`.
  /// - Restituisce la lista ordinata di punti.
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