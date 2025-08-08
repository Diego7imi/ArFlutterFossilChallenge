

class ChallengeModel {
  String? id, nome, descrizione, tipo, scadenzaIscr, dataInizio, dataFine, perimetroZona, punteggioOttenibile, premio;
  Map<String, dynamic>?classifica, ammoniti, posizione;
  int? durata;

  ChallengeModel({required this.id, required this.nome, required this.descrizione, required this.tipo, required this.scadenzaIscr, required this.dataInizio,
                  required this.dataFine, required this.perimetroZona, required this.punteggioOttenibile, required this.premio, required this.classifica,
                  required this.ammoniti, required this.posizione, this.durata});

  ChallengeModel.fromJson(Map<dynamic, dynamic> map){
    if (map == null) {
      return;
    }
    id = map['challengeId'];
    nome = map['nome'];
    descrizione = map['descrizione'];
    tipo = map['tipo'];
    scadenzaIscr = map['scadenzaIscr'];
    dataInizio = map['dataInizio'];
    dataFine = map['dataFine'];
    perimetroZona = map['perimetroZona'];
    punteggioOttenibile = map['punteggioOttenibile'];
    premio = map['premio'];
    classifica = map['classifica'];
    ammoniti = map['ammoniti'];
    posizione = map['posizione'];
    durata = map['durata'];
  }

  toJson() {
    return {
      'challengeId': id,
      'nome': nome,
      'descrizione': descrizione,
      'tipo': tipo,
      'scadenzaIscr':scadenzaIscr,
      'dataInizio': dataInizio,
      'dataFine': dataFine,
      'perimetroZona': perimetroZona,
      'punteggioOttenibile': punteggioOttenibile,
      'premio': premio,
      'classifica': classifica,
      'ammoniti': ammoniti,
      'posizione': posizione,
      'durata' : durata,
    };
  }
}