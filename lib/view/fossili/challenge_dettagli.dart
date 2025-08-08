// file: lib/view/fossili/dettagli_challenge.dart
import 'package:ar/helpers/challenge_view_model.dart';
import 'package:ar/helpers/timer.dart';
import 'package:ar/main.dart';
import 'package:ar/model/challenge_model.dart';
import 'package:ar/repository/challenge_repository.dart';
import 'package:ar/view/fossili/ammonite_list.dart';
import 'package:ar/widgets/countdownWidget.dart';
import 'package:firebase_image/firebase_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../model/ammonite.dart';
import '../../model/user_model.dart';
import '../../widgets/costanti.dart';
import 'challenge_raccolta.dart';

const MAPBOX_ACCESS_TOKEN =
    'pk.eyJ1IjoiZmFjYzAwIiwiYSI6ImNsam9kc3kzbDFtcHMzZXBqdWQ2YjNzeDcifQ.koA0RgNUY0hLmiOT6W1yqg';

class DettagliChallenge extends StatefulWidget {
  ChallengeModel model;
  bool utenteIscritto;
  DettagliChallenge({super.key, required this.model, required this.utenteIscritto});

  @override
  State<DettagliChallenge> createState() => _DettagliChallengeState();
}

class _DettagliChallengeState extends State<DettagliChallenge> {
  int _selectedIndex = 0;
  List<Ammonite> ammoniti_lista = [];
  Map<String, int> ammonitiPunti = {};
  List<UserModel> classifica_utenti = [];
  Map<String, int> utentiPunti = {};
  List<LatLng> polygonPoints = [];
  LatLng? centerPoint;
  final viewChallenge = ChallengeViewModel();
  late ChallengeModel challenge;
  late bool isUtenteIscritto;

  @override
  void initState() {
    super.initState();
    challenge = widget.model;
    isUtenteIscritto = widget.utenteIscritto;
    _getInfo();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Image.asset('assets/image/parco.jfif'),
            buttonArrow(context),
            Column(
              children: [
                Expanded(child: scroll()),
                // Usiamo marrone con opacità per mimetizzare il background
                Container(
                  color: marrone, // Usa marrone con opacità
                  child: const TimerWidget(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _getInfo() async {
    List<Ammonite> listaAmm = [];
    List<UserModel> listUser = [];
    List<LatLng> points = await viewChallenge.getPolygonPoints(challenge.id);
    if (points.isNotEmpty) {
      setState(() {
        polygonPoints = points;
        centerPoint = calculatePolygonCenter(points);
      });
    }
    if (challenge.ammoniti!.isNotEmpty) {
      for (var entry in challenge.ammoniti!.entries) {
        String id = entry.key;
        int punti = entry.value;
        for (Ammonite amm in ammoniti) {
          if (amm.id == id) {
            listaAmm.add(amm);
            ammonitiPunti[id] = punti;
          }
        }
      }
      setState(() {
        ammoniti_lista = listaAmm;
      });
    }
    if (challenge.classifica!.isNotEmpty) {
      for (var entry in challenge.classifica!.entries) {
        String id = entry.key;
        int punti = entry.value;
        for (UserModel user in utenti) {
          if (user.userId == id) {
            listUser.add(user);
            utentiPunti[id] = punti;
          }
        }
      }

      listUser.sort((a, b) {
        final pa = utentiPunti[a.userId] ?? 0;
        final pb = utentiPunti[b.userId] ?? 0;
        return pb.compareTo(pa);
      });

      setState(() {
        classifica_utenti = listUser;
      });
    }
  }

  Widget flutterMap() {
    if (centerPoint == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return FlutterMap(
      options: MapOptions(
        center: centerPoint!,
        zoom: 15,
        minZoom: 10,
        maxZoom: 30,
      ),
      children: [
        TileLayer(
          urlTemplate:
          'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
          additionalOptions: const {
            'accessToken': MAPBOX_ACCESS_TOKEN,
            'id': 'mapbox/streets-v12',
          },
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(43.35458650173374, 13.448999948808833),
              builder: (context) {
                return Image.asset('assets/icon/icon_fossil.png', scale: 0.4);
              },
            ),
          ],
        ),
        PolygonLayer(
          polygons: [
            Polygon(
              points: polygonPoints,
              color: Colors.blue,
              borderStrokeWidth: 3,
              borderColor: Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget scroll() {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 1.0,
      minChildSize: 0.75,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: marrone,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 25),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 5,
                            width: 35,
                            color: Colors.black12,
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStatePropertyAll<Color>(
                                  Color.fromRGBO(210, 180, 140, 100)),
                              shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.0),
                                  side: BorderSide(color: Colors.white),
                                ),
                              ),
                            ),
                            onPressed: () => setState(() => _selectedIndex = 0),
                            child: Text("Informazioni"),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStatePropertyAll<Color>(
                                  Color.fromRGBO(210, 180, 140, 100)),
                              shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.0),
                                  side: BorderSide(color: Colors.white),
                                ),
                              ),
                            ),
                            onPressed: () => setState(() => _selectedIndex = 1),
                            child: Text("Classifica"),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStatePropertyAll<Color>(
                                  Color.fromRGBO(210, 180, 140, 100)),
                              shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.0),
                                  side: BorderSide(color: Colors.white),
                                ),
                              ),
                            ),
                            onPressed: () => setState(() => _selectedIndex = 2),
                            child: Text("Punti"),
                          ),
                        ],
                      ),
                      IndexedStack(
                        index: _selectedIndex,
                        children: [
                          informazioni(),
                          classifica(),
                          puntiAmmoniti(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget informazioni() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        Text(
          widget.model.nome.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.bold,
            color: white,
          ),
        ),
        const SizedBox(height: 5),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 4, color: white),
        ),
        Text(
          "Tipo:",
          style: TextStyle(
            color: black54,
            fontSize: 16,
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.model.tipo.toString(),
          style: const TextStyle(
            color: white,
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.normal,
            letterSpacing: 0.5,
            wordSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 5),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 4, color: white),
        ),
        Text(
          "Descrizione:",
          style: TextStyle(
            color: black54,
            fontSize: 16,
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.model.descrizione.toString(),
          style: TextStyle(
            color: white,
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.normal,
            letterSpacing: 0.5,
            wordSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 5),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 4, color: white),
        ),
        Text(
          "Durata Challenge:",
          style: TextStyle(
            color: black54,
            fontSize: 16,
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "Dal ${widget.model.dataInizio} al ${widget.model.dataFine}",
          style: const TextStyle(
            color: white,
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.normal,
            letterSpacing: 0.5,
            wordSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 5),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 4, color: white),
        ),
        Text(
          "Punteggio ottenibile: ",
          style: TextStyle(
            color: black54,
            fontSize: 16,
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.model.punteggioOttenibile.toString(),
          style: TextStyle(
            color: white,
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.normal,
            letterSpacing: 0.5,
            wordSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 5),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 4, color: white),
        ),
        Text(
          "Posizione:",
          style: TextStyle(
            color: black54,
            fontSize: 16,
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          ' ${widget.model.perimetroZona.toString()}',
          style: const TextStyle(
            color: white,
            fontWeight: FontWeight.normal,
            letterSpacing: 0.5,
            wordSpacing: 1.5,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 5),
          child: Divider(height: 4),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          child: flutterMap(),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 5),
          child: Divider(height: 4),
        ),
        FutureBuilder<bool>(
          future: TimerController.to.isChallengePlayable(challenge.id!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              print('Error checking challenge playability: ${snapshot.error}');
              return const SizedBox.shrink();
            }
            final isPlayable = snapshot.data ?? false;
            print('FutureBuilder: isChallengePlayable for ${challenge.id}: $isPlayable');
            if (isUtenteIscritto && isChallengeOpen(widget.model) && isPlayable) {
              return Center(
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll<Color>(
                        Color.fromRGBO(210, 180, 140, 100)),
                    shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        side: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  onPressed: () async {
                    print('Challenge type: ${widget.model.tipo}');
                    if (widget.model.tipo == "Velocità" &&
                        !TimerController.to.isTimerRunningForChallenge(challenge.id!)) {
                      print('Starting timer for challenge ${challenge.id}');
                      TimerController.to.startTimer(challenge.id!, challenge.durata!);
                    }

                    await Get.to(() => ChallengeRaccolta(
                      lista: ammoniti_lista,
                      challengeId: challenge.id!,
                    ));

                    final updatedChallenge =
                    await ChallengeService().getChallengeById(challenge.id!);
                    if (mounted) {
                      setState(() {
                        challenge = updatedChallenge!;
                        _getInfo();
                      });
                    }
                  },
                  child: Text("GIOCA"),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 32), // Spazio per evitare sovrapposizione con TimerWidget
      ],
    );
  }

  Widget classifica() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        Text(
          'Classifica',
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 5),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: classifica_utenti.length,
          itemBuilder: (context, index) {
            final partecipant = classifica_utenti[index];
            final punti = utentiPunti[partecipant.userId];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (index + 1).toString(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      partecipant.nome.toString(),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Text(
                    punti.toString(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget puntiAmmoniti() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          'Ammoniti',
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: ammoniti_lista.length,
          itemBuilder: (context, index) {
            final ammonito = ammoniti_lista[index];
            final int punti = ammonitiPunti[ammonito.id]!;
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: white,
                    ),
                    height: 60,
                    width: 60,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image(
                        image: FirebaseImage(
                          'gs://serene-circlet-394113.appspot.com/${ammonito.foto}',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ammonito.nome.toString(),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  Text(
                    punti.toString(),
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  bool isChallengeOpen(ChallengeModel challenge) {
    DateTime now = DateTime.now();
    DateTime? startDate = DateTime.tryParse(challenge.dataInizio ?? ' ');
    DateTime? endDate = DateTime.tryParse(challenge.scadenzaIscr ?? ' ');

    if (startDate == null || endDate == null) return false;
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  LatLng calculatePolygonCenter(List<LatLng> points) {
    double latSum = 0.0;
    double lngSum = 0.0;
    for (var point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }
    return LatLng(latSum / points.length, lngSum / points.length);
  }
}