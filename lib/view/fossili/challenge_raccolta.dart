import 'package:ar/view/ar_flutter/ar_fossil.dart';
import 'package:ar/helpers/ammonite_view_model.dart';
import 'package:ar/widgets/countdownWidget.dart';
import 'package:firebase_image/firebase_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../helpers/shared_prefs.dart';
import '../../main.dart';
import '../../model/ammonite.dart';
import '../../model/user_model.dart';
import '../../widgets/costanti.dart';
import '../../widgets/custom_dialog.dart';
import 'ammonite_dettagli.dart';
import 'ammonite_polyline.dart';
import '../../helpers/auth_view_model.dart';

class ChallengeRaccolta extends StatefulWidget {
  final List<Ammonite> lista;
  final String challengeId;
  
  const ChallengeRaccolta({Key? key, required this.lista, required this.challengeId}) : super(key: key);

  @override
  State<ChallengeRaccolta> createState() => _ChallengeRaccoltaState();
}

class _ChallengeRaccoltaState extends State<ChallengeRaccolta> {

  UserModel? user;
  final viewModel = AmmoniteViewModel();
  final viewModelAuth = AuthViewModel();
  List<LatLng> points = [];

  @override
  void initState(){
    super.initState();
    points.clear();
    _loadUser();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Costruisce la schermata principale della challenge di cattura.
  /// Mostra la lista dei fossili disponibili, un campo di ricerca,
  /// e un timer persistente in basso che indica la durata della sfida attiva.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: marrone,
        centerTitle: true,
        title: Text('CHALLENGE CATTURA', style: defaultTextStyle),
      ),
      backgroundColor: grey300,
      body: SafeArea(
        child: Stack(
          children: [
            WillPopScope(
              onWillPop: showExitDialog,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      searchText(),
                      const SizedBox(height: 15),
                      _listViewFossils(),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 600),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  decoration: BoxDecoration(
                    color: marrone,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TimerWidget(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Costruisce la lista dei fossili presenti nella challenge.
  /// Ogni elemento mostra immagine, nome, zona, e due azioni:
  /// - Mappa: apre la posizione del fossile.
  /// - AR Fossil: permette di catturarlo in realtà aumentata (se non già raccolto).
  Widget _listViewFossils() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: ListView.separated(
        itemCount: widget.lista.length,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index) {
          bool giaRaccolto = user?.lista_challenge?[widget.challengeId]?.contains(widget.lista[index].id) ?? false;
          return GestureDetector(
            onTap: () {
              Get.to(() => DettagliAmmonite(model: widget.lista[index]));
            },
            child: Container(
              height: MediaQuery.of(context).size.height * 0.15,
              margin: const EdgeInsetsDirectional.fromSTEB(0, 0, 10, 20),
              child: AspectRatio(
                aspectRatio: 3 / 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: white,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: <Widget>[
                      AspectRatio(
                        aspectRatio: 1 / 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image(
                            image: FirebaseImage('gs://serene-circlet-394113.appspot.com/${widget.lista[index].foto}'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.lista[index].nome.toString(),
                              style: const TextStyle(
                                color: Colors.black54,
                                fontFamily: 'PlayfairDisplay',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${widget.lista[index].zona}",
                              style: const TextStyle(
                                color: Colors.black54,
                                fontFamily: 'PlayfairDisplay',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    points.clear();
                                    Map geometry = getGeometryFromSharedPrefs(index);
                                    for (int i = 0; i < geometry['coordinates'].length; i++) {
                                      var coordinate = geometry['coordinates'][i];
                                      points.add(LatLng(double.parse(coordinate[1].toString()), double.parse(coordinate[0].toString())));
                                    }
                                    Get.to(() => AmmonitePolyline(model: widget.lista[index], points: points));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: white,
                                    ),
                                    child: Column(
                                      children: [
                                        Image.asset('assets/image/icon_mappa.png', height: 30),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                GestureDetector(
                                  onTap: giaRaccolto ? null : () async {
                                    await Get.to(() => ArFossil(model: widget.lista[index], source: "Challenge", challenge: widget.challengeId));
                                    _loadUser();
                                  },
                                  child: Opacity(
                                    opacity: giaRaccolto ? 0.3 : 1.0,
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: white,
                                      ),
                                      child: Column(
                                        children: [
                                          Image.asset('assets/image/pickage.png', height: 30),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 20),
      ),
    );
  }

  /// Crea un piccolo bottone grafico, usato come elemento UI ausiliario.
  Widget cardButtons(String path) {
    return SizedBox(
      width: 45,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          padding: const EdgeInsets.all(7),
          minimumSize: Size.zero,
          backgroundColor: marrone,
        ),
        child: Image.asset(path,height: 20,color: white,),
      ),

    );
  }


  /// Campo di ricerca che filtra la lista dei fossili in base al testo inserito.
  /// Ogni volta che l’utente digita, viene richiamata `filtraLista()`.
  Widget searchText(){
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 30,vertical: 5),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color:white, boxShadow: const [
          BoxShadow(color: Colors.grey, blurRadius: 2.0, spreadRadius: 0.0, offset: Offset(2.0, 2.0),
          )],),
        child: TextFormField(onChanged: (value) =>{filtraLista(value), setState(() {}), },
          decoration:  InputDecoration(hintText: 'Ricerca fossili', hintStyle: TextStyle(color: black54,fontFamily: 'PlayfairDisplay',fontWeight: FontWeight.w400), border: InputBorder.none, prefixIcon: Icon(Icons.search, color:black54,),), style:  TextStyle(color:black54),),),);
  }


  /// Filtra la lista dei fossili in base al nome digitato.
  /// Il filtro è case-insensitive e verifica l’inizio del nome.
  void filtraLista(String text) {
    List<Ammonite> listaCompleta = viewModel.ammonite;
    List<Ammonite> listaFiltrata = [];
    for (int i = 0; i < listaCompleta.length; i++) {
      if (listaCompleta[i].nome.toString().toLowerCase().startsWith(
          text.toLowerCase())) {
        listaFiltrata.add(listaCompleta[i]);
      }
    }
    setState(() {
    });
  }

  /// Mostra un dialogo di conferma prima di uscire dalla challenge.
  /// Restituisce `true` se l’utente conferma l’uscita.
  Future<bool> showExitDialog()async {
    return await showDialog(barrierDismissible: false,context: context, builder: (context)=>
        customAlertDialog(context,"Vuoi uscire dall'applicazione?"),);
  }


  /// Carica dal database l’utente corrente loggato,
  /// aggiornando lo stato locale (`user`) per riflettere i dati più recenti.
  void _loadUser() async {
    String userId = await viewModelAuth.getIdSession();
    UserModel? currentUser = await viewModelAuth.getUserFormId(userId);
    if (currentUser != null) {
      setState(() {
        user = currentUser;
      });
    }
  }
}




