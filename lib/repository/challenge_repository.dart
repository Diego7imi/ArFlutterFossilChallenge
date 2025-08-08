import 'package:ar/model/challenge_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeService {
  final CollectionReference _challengeCollectionRef =
  FirebaseFirestore.instance.collection('challenge');

  final _db = FirebaseFirestore.instance;

  Future<List<QueryDocumentSnapshot>> getChallenge() async {
    var value = await _challengeCollectionRef.get();
    return value.docs;
  }

  Future<ChallengeModel?> getChallengeById(String challengeId) async {
    DocumentSnapshot doc = await _challengeCollectionRef.doc(challengeId).get();
    if (!doc.exists) return null;

    return ChallengeModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<void> addChallenge(ChallengeModel challenge) async {
    await _challengeCollectionRef
        .doc(challenge.id)
        .set(challenge.toJson());
  }

  Future<void> updateChallenge(ChallengeModel challenge) async {
    await _db.collection("challenge").doc(challenge.id).update(challenge.toJson());
  }

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

  Future<List<String>> getCollectedFossilsForChallenge(String userId, String challengeId) async {
    final snapshot = await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    final listaChallenge = Map<String, dynamic>.from(snapshot.data()?['lista_challenge'] ?? {});
    final fossils = List<String>.from(listaChallenge[challengeId] ?? []);
    return fossils;
  }


}