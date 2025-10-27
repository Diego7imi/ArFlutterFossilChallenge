import 'package:ar/model/challenge_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeService {
  final CollectionReference _challengeCollectionRef =
  FirebaseFirestore.instance.collection('challenge');

  final _db = FirebaseFirestore.instance;

  /// Recupera la lista completa delle challenge dal database Firestore.
  ///
  /// Funzionamento:
  /// - Accede alla collezione delle challenge (`_challengeCollectionRef`).
  /// - Esegue una chiamata `.get()` per ottenere tutti i documenti.
  /// - Restituisce la lista di `QueryDocumentSnapshot`, contenente i dati grezzi
  ///   di ogni challenge.
  ///
  /// Questo metodo fornisce i dati “non ancora convertiti” in `ChallengeModel`,
  /// utili per iterazioni o trasformazioni successive.
  Future<List<QueryDocumentSnapshot>> getChallenge() async {
    var value = await _challengeCollectionRef.get();
    return value.docs;
  }

  /// Recupera una singola challenge dal database tramite il suo ID.
  ///
  /// Funzionamento:
  /// - Usa `_challengeCollectionRef.doc(challengeId)` per accedere
  ///   direttamente al documento con quell’ID.
  /// - Se il documento non esiste, restituisce `null`.
  /// - Se esiste, converte i dati JSON in un oggetto `ChallengeModel`.
  ///
  /// Utile per ottenere i dettagli aggiornati di una specifica challenge.
  Future<ChallengeModel?> getChallengeById(String challengeId) async {
    DocumentSnapshot doc = await _challengeCollectionRef.doc(challengeId).get();
    if (!doc.exists) return null;

    return ChallengeModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  /// Aggiunge una nuova challenge al database Firestore.
  ///
  /// Funzionamento:
  /// - Utilizza `challenge.id` come chiave del documento nella collezione.
  /// - Converte l’oggetto `ChallengeModel` in JSON (`toJson()`) e lo salva.
  ///
  /// Se il documento con lo stesso ID esiste già, viene sovrascritto.
  /// In genere usato per creare nuove challenge lato amministratore.
  Future<void> addChallenge(ChallengeModel challenge) async {
    await _challengeCollectionRef
        .doc(challenge.id)
        .set(challenge.toJson());
  }

  /// Aggiorna i dati di una challenge esistente su Firestore.
  ///
  /// Funzionamento:
  /// - Trova il documento nella collezione `challenge` usando `challenge.id`.
  /// - Aggiorna i campi del documento con quelli del `ChallengeModel`
  ///   convertito in JSON.
  ///
  /// Solo i campi esistenti nel modello verranno modificati.
  Future<void> updateChallenge(ChallengeModel challenge) async {
    await _db.collection("challenge").doc(challenge.id).update(challenge.toJson());
  }

  /// Aggiunge un utente alla classifica (“leaderboard”) di una challenge.
  ///
  /// Funzionamento:
  /// - Recupera il documento della challenge da Firestore.
  /// - Estrae la mappa `classifica`, che associa userId → punteggio.
  /// - Se l’utente non è ancora presente, viene aggiunto con punteggio iniziale `0`.
  /// - Aggiorna il documento su Firestore.
  ///
  /// Questo metodo viene richiamato quando un utente si iscrive o partecipa
  /// a una challenge per la prima volta.
  Future<void> addToLeaderboard(String challengeId, String userId) async {
    final docRef = _challengeCollectionRef.doc(challengeId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;
    final classifica = Map<String, dynamic>.from(data['classifica'] ?? {});

    if (!classifica.containsKey(userId)) {
      classifica[userId] = 0; // Punteggio iniziale
      await docRef.update({'classifica': classifica});
    }
  }

  /// Rimuove un utente dalla classifica di una challenge.
  ///
  /// Funzionamento:
  /// - Recupera la challenge corrispondente da Firestore.
  /// - Estrae la mappa `classifica` (userId → punteggio).
  /// - Se l’utente è presente, rimuove la chiave relativa al suo `userId`.
  /// - Aggiorna il documento nel database.
  Future<void> removeFromLeaderboard(String challengeId, String userId) async {
    final docRef = _challengeCollectionRef.doc(challengeId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;
    final classifica = Map<String, dynamic>.from(data['classifica'] ?? {});

    if (classifica.containsKey(userId)) {
      classifica.remove(userId);
      await docRef.update({'classifica': classifica});
    }
  }


  /// Aggiunge un fossile alla lista dei fossili raccolti da un utente
  /// in una determinata challenge.
  ///
  /// Funzionamento:
  /// - Accede al documento dell’utente nella collezione `Users`.
  /// - Estrae la mappa `lista_challenge`, dove ogni chiave è l’ID di una challenge
  ///   e il valore è una lista di fossili raccolti.
  /// - Aggiunge il nuovo fossile se non già presente nella lista.
  /// - Aggiorna il documento utente su Firestore.
  Future<void> addFossilToChallengeList(String userId, String challengeId, String fossilName) async {
    final userDocRef = FirebaseFirestore.instance.collection('Users').doc(userId);
    final snapshot = await userDocRef.get();

    Map<String, dynamic> userData = snapshot.data() ?? {};
    Map<String, dynamic> listaChallenge = Map<String, dynamic>.from(userData['lista_challenge'] ?? {});

    List<dynamic> fossilsInChallenge = List.from(listaChallenge[challengeId] ?? []);

    if (!fossilsInChallenge.contains(fossilName)) {
      fossilsInChallenge.add(fossilName);
      listaChallenge[challengeId] = fossilsInChallenge;

      await userDocRef.update({
        'lista_challenge': listaChallenge,
      });
    }
  }

  /// Restituisce la lista dei fossili raccolti da un utente
  /// in una determinata challenge.
  ///
  /// Funzionamento:
  /// - Accede al documento dell’utente nella collezione `Users`.
  /// - Estrae il campo `lista_challenge`, che contiene tutte le challenge
  ///   a cui l’utente ha partecipato.
  /// - Recupera la lista di fossili associata alla `challengeId` richiesta.
  /// - Se non ci sono fossili, restituisce una lista vuota.
  Future<List<String>> getCollectedFossilsForChallenge(String userId, String challengeId) async {
    final snapshot = await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    final listaChallenge = Map<String, dynamic>.from(snapshot.data()?['lista_challenge'] ?? {});
    final fossils = List<String>.from(listaChallenge[challengeId] ?? []);
    return fossils;
  }


}