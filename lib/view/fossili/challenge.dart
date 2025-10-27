import 'package:ar/helpers/auth_view_model.dart';
import 'package:ar/helpers/challenge_view_model.dart';
import 'package:ar/main.dart';
import 'package:ar/model/challenge_model.dart';
import 'package:ar/view/fossili/ammonite_dettagli.dart';
import 'package:ar/widgets/costanti.dart';
import 'package:firebase_image/firebase_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../widgets/custom_dialog.dart';
import 'challenge_dettagli.dart';

class Challenge extends StatefulWidget{
  const Challenge({Key? key}) : super(key: key);

  @override
  State<Challenge> createState() => _ChallengeState();
}

class _ChallengeState extends State<Challenge>{

  final viewModel = ChallengeViewModel();
  final authModel = AuthViewModel();
  late List<ChallengeModel> lista = [];
  late String userId;
  Map<String, bool> iscrizioneUtente = {};
  bool isLoading = true;

  LatLng? userPosition;
  double? maxDistance;
  String searchTextValue = '';

  @override
  void initState() {
    super.initState();
    lista = challenge;
    initData();
    _getUserPosition();
  }

  /// Inizializza i dati necessari alla schermata.
  ///
  /// Funzionamento:
  /// - Recupera l’`userId` dalla sessione tramite `authModel`.
  /// - Controlla le iscrizioni dell’utente alle challenge con `_checkIscrizioni()`.
  /// - Al termine, imposta `isLoading` su `false` per mostrare la UI.
  ///
  /// Se si verifica un errore durante il recupero, viene stampato nel log.
  Future<void> initData() async {
    try{
      userId = await authModel.getIdSession();
      await _checkIscrizioni();
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Errore durante il recupero delle challenge: $e");
    }
  }

  /// Verifica se l’utente è iscritto a ciascuna challenge presente nella lista.
  ///
  /// Funzionamento:
  /// - Itera su ogni elemento di `lista` (contenente le challenge disponibili).
  /// - Per ogni challenge, chiama `viewModel.isUserEnrolled()` per verificare se
  ///   l’utente corrente è iscritto.
  /// - Aggiorna lo stato locale (`iscrizioneUtente`) per riflettere il risultato.
  Future<void> _checkIscrizioni() async{
    for (var prove in lista) {
      bool isEnrolled = await viewModel.isUserEnrolled(prove.id.toString(), userId);
    setState(() {
      iscrizioneUtente[prove.id.toString()] = isEnrolled;});
    }
  }

  /// Recupera la posizione geografica corrente dell’utente.
  ///
  /// Funzionamento:
  /// - Controlla che i servizi di localizzazione siano abilitati.
  /// - Verifica e richiede i permessi di geolocalizzazione.
  /// - Se tutto è valido, ottiene la posizione GPS corrente con `Geolocator.getCurrentPosition`.
  /// - Aggiorna lo stato con la posizione (`userPosition`) come `LatLng`.
  Future<void> _getUserPosition() async{
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Servizi di localizzazione disabilitati');
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Permessi di localizzazione negati');
        return;
      }
    }
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      userPosition = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Costruisce la UI principale della schermata.
  ///
  /// Funzionamento:
  /// - Se `isLoading` è `true`, mostra un indicatore di caricamento.
  /// - Altrimenti, costruisce la schermata principale con:
  ///   - barra di ricerca (`searchText()`),
  ///   - filtro per distanza (`distanceFilter()`),
  ///   - lista di challenge tramite `_listViewChallenge()`.
  ///
  /// La UI è racchiusa in uno `Scaffold` con `SafeArea` e supporta il
  /// comportamento personalizzato per il tasto “indietro” (`showExitDialog`).
  @override
  Widget build(BuildContext context) {
    if (isLoading){
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: grey300,
      body: SafeArea(
        child: WillPopScope(onWillPop: showExitDialog,
          child: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(flex: 8, child: searchText()),
                    Expanded(flex: 2, child: distanceFilter()),
                  ],
                ),
                const SizedBox(height: 15),
                _listViewChallenge(),
              ],
            ),),
          ),)
      ),
    );
  }

  /// Costruisce la lista delle challenge visualizzate nella schermata.
  ///
  /// Funzionamento:
  /// - Mostra ogni challenge in una `ListView` con immagine, nome, descrizione e pulsante.
  /// - Il pulsante consente di iscriversi o disiscriversi alla challenge.
  /// - Se la challenge è chiusa (`isChallengeOpen == false`), mostra “CHIUSA”.
  ///
  /// Il tap sull’intero container apre la schermata dei dettagli tramite `Get.to()`.
  Widget _listViewChallenge(){
    return SizedBox(
      height: MediaQuery.of(context).size.height*0.75,
      child: ListView.separated(
        itemCount: lista.length,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index){
          bool challengeOpen = isChallengeOpen(lista[index]);
          String cid = lista[index].id.toString();
          bool enrolled = iscrizioneUtente[cid] ?? false;
          return GestureDetector(
            onTap: (){
              Get.to(() => DettagliChallenge(model: lista[index], utenteIscritto: enrolled,));
            },
            child: Container(
              height: MediaQuery.of(context).size.height*0.15,
              margin: const EdgeInsetsDirectional.fromSTEB(0, 0, 10, 10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color:white,
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: AspectRatio(aspectRatio: 1/1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image(
                              image: FirebaseImage('gs://serene-circlet-394113.appspot.com/${lista[index].premio}',)
                            ),
                          ),
                        ),
                      ),
                        const SizedBox(width: 5),
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(lista[index].nome.toString(), style: TextStyle(color: black54,fontFamily: 'PlayfairDisplay',fontSize: 14,fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis,),
                              const SizedBox(height: 2,),
                              Text(lista[index].tipo.toString(), style: TextStyle(color: black54,fontFamily: 'PlayfairDisplay',fontSize: 10,fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 5,),
                              Text(lista[index].descrizione.toString(), style: TextStyle(color: black54,fontFamily: 'PlayfairDisplay',fontSize: 10,fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 2,),
                              const SizedBox(height: 5,),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          flex: 1,
                          child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text("Scadenza: ${formatDate(lista[index].scadenzaIscr!)}", style: TextStyle(color: black54,fontFamily: 'PlayfairDisplay',fontSize: 11,fontWeight: FontWeight.w500),),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                if (challengeOpen)
                                  SizedBox(
                                    //width: double.infinity,
                                    child: ElevatedButton(
                                        style: ButtonStyle(
                                            backgroundColor: MaterialStatePropertyAll<
                                                Color>(
                                                Color.fromRGBO(210, 180, 140, 100)),
                                            shape: MaterialStatePropertyAll<
                                                RoundedRectangleBorder>(
                                                RoundedRectangleBorder(
                                                    borderRadius: BorderRadius
                                                        .circular(18.0),
                                                    side: BorderSide(
                                                        color: Colors.white)
                                                )
                                            ),
                                            minimumSize: const MaterialStatePropertyAll(Size(0, 30)),
                                            padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
                                        ),
                                        onPressed: () async {
                                          String challengeId = lista[index].id.toString();
                                          if (iscrizioneUtente[challengeId] == true) {
                                            bool hasCaughtFossil = await viewModel.userHasCaughtFossil(challengeId, userId);
                                            if (hasCaughtFossil){
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: customSnackBar('Hai già catturato un fossile!', true),
                                                  behavior: SnackBarBehavior.floating,
                                                  elevation: 0,
                                                  backgroundColor: trasparent,
                                                ),
                                              );
                                              return;
                                            }
                                            else{
                                              await viewModel.removeUserFromLeaderboard(challengeId, userId);
                                            }
                                          } else {
                                            await viewModel.addUserToLeaderboard(challengeId, userId);
                                          }

                                          bool isEnrolled = await viewModel.isUserEnrolled(challengeId, userId);
                                          setState(() {
                                            iscrizioneUtente[challengeId] = isEnrolled;
                                          });
                                        },
                                        child: Text(iscrizioneUtente[lista[index].id.toString()] == true ? "DISISCRIVITI" : "ISCRIVITI", style: TextStyle(color: white, fontFamily: 'PlayfairDisplay', fontSize: 11)))
                                  )
                                  else
                                  Text(
                                    "CHIUSA",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        )
                        ),
                    ],
                  ),
                ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 20),
      ),
    );
  }

  /// Crea il filtro per distanza massima.
  ///
  /// Funzionamento:
  /// - Mostra un menu a discesa con distanze predefinite (5, 10, 20, 50, 100 km).
  /// - Quando si seleziona una distanza, aggiorna `maxDistance`
  ///   e richiama `filtraLista()` per applicare il filtro.
  ///
  /// Se nessuna distanza è selezionata, mostra semplicemente “Distanza”.
  Widget distanceFilter() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: white,
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 2.0,
            spreadRadius: 0.0,
            offset: Offset(2.0, 2.0),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        child: Center(
          child: DropdownMenu<double?>(
            width: 130,
            textStyle: const TextStyle(
              color: Colors.black54,
              fontFamily: 'PlayfairDisplay',
              fontSize: 12,
              height: 1,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              isDense: true,
            ),
            dropdownMenuEntries: [
              const DropdownMenuEntry<double?>(
                value: null,
                label: 'Distanza',
              ),
              ...[5.0, 10.0, 20.0, 50.0, 100.0].map((double value) {
                return DropdownMenuEntry<double>(
                  value: value,
                  label: '$value km',
                );
              }).toList(),
            ],
            onSelected: (double? newValue) {
              setState(() {
                maxDistance = newValue;
                filtraLista(searchTextValue);
              });
            },
            hintText: 'Distanza',
          ),
        ),
      ),
    );
  }

  /// Campo di ricerca per filtrare le challenge per nome.
  ///
  /// Ad ogni modifica del testo, richiama `filtraLista()` e aggiorna lo stato.
  Widget searchText(){
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 30,vertical: 5),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color:white, boxShadow: const [
          BoxShadow(color: Colors.grey, blurRadius: 2.0, spreadRadius: 0.0, offset: Offset(2.0, 2.0),
          )],),
        child: TextFormField(onChanged: (value) async {searchTextValue = value; await filtraLista(value); setState(() {}); },
          decoration:  InputDecoration(hintText: 'Ricerca challenge',
            hintStyle: TextStyle(color: black54,fontFamily: 'PlayfairDisplay',fontWeight: FontWeight.w400),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color:black54,),),
          style:  TextStyle(color:black54),),),);
  }


  /// Filtra la lista delle challenge in base al nome e alla distanza.
  ///
  /// Funzionamento:
  /// - Confronta il nome con il testo di ricerca (`startsWith` case-insensitive).
  /// - Se è impostata una distanza massima (`maxDistance`), calcola la distanza
  ///   tra la posizione dell’utente e il centro del poligono della challenge.
  /// - Mantiene solo le challenge che soddisfano entrambi i criteri.
  /// - Aggiorna la lista mostrata (`lista`).
  Future<void> filtraLista(String text) async{
    List<ChallengeModel> listaCompleta = viewModel.challenge;
    List<ChallengeModel> listaFiltrata = [];
    for (int i = 0; i < listaCompleta.length; i++) {
      bool matchesName = listaCompleta[i].nome.toString().toLowerCase().startsWith(text.toLowerCase());
      bool withinDistance = true;
      if (maxDistance != null && userPosition != null && listaCompleta[i].posizione != null) {
        List<LatLng> points = await viewModel.getPolygonPoints(listaCompleta[i].id!);
        LatLng centro = calculatePolygonCenter(points);
        double distance = Geolocator.distanceBetween(
          userPosition!.latitude,
          userPosition!.longitude,
          centro.latitude,
          centro.longitude,
        ) / 1000;
        withinDistance = distance <= maxDistance!;
      }

      if (matchesName && withinDistance) {
        listaFiltrata.add(listaCompleta[i]);
      }
    }
    setState(() {
      lista = listaFiltrata;
    });
  }


  /// Mostra un dialog di conferma quando l’utente tenta di uscire dall’app.
  ///
  /// Restituisce `true` se l’utente conferma l’uscita.
  Future<bool> showExitDialog()async {
    return await showDialog(barrierDismissible: false,context: context, builder: (context)=>
        customAlertDialog(context,"Vuoi uscire dall'applicazione?"),);
  }

  /// Verifica se una challenge è attualmente aperta.
  ///
  /// La challenge è considerata “aperta” se:
  /// - la data corrente è **successiva** alla `dataInizio`
  /// - e **precedente** alla `scadenzaIscr`.
  bool isChallengeOpen(ChallengeModel challenge) {
    DateTime now = DateTime.now();
    DateTime? startDate = DateTime.tryParse(challenge.dataInizio ?? ' ');
    DateTime? endDate = DateTime.tryParse(challenge.scadenzaIscr ?? ' ');

    if (startDate == null || endDate == null) return false;
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Format di una data (yyyy-MM-dd) in formato `dd/MM`.
  String formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return DateFormat('dd/MM').format(parsedDate);
  }

  /// Calcola il punto centrale (centroide) di un poligono.
  ///
  /// Funzionamento:
  /// - Calcola la media aritmetica delle latitudini e longitudini.
  /// - Restituisce un `LatLng` con le coordinate del centro.
  LatLng calculatePolygonCenter(List<LatLng> points){
    double latSum = 0.0;
    double lngSum = 0.0;
    for(var point in points){
      latSum += point.latitude;
      lngSum += point.longitude;
    }
    return LatLng(
      latSum / points.length,
      lngSum / points.length,
    );
  }
}