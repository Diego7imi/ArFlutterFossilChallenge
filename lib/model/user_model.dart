
class UserModel {
  String? userId, nome, email, password;
  List<dynamic>? lista_fossili;
  Map<String, List<String>>? lista_challenge;

  UserModel({required this.userId, required this.nome, required this.email, required this.password,required this.lista_fossili, required this.lista_challenge});

  UserModel.fromJson(Map<dynamic, dynamic> map) {
    if (map == null) {
      return;
    }
    userId = map['userId'];
    nome = map['nome'];
    email = map['email'];
    password=map['password'];
    lista_fossili=map['lista_fossili'];
    //lista_challenge=map['lista_challenge'];

    if (map['lista_challenge'] != null) {
      lista_challenge = {};
      (map['lista_challenge'] as Map).forEach((key, value) {
        lista_challenge![key] = List<String>.from(value);
      });
    } else {
      lista_challenge = {};
    }
  }

  toJson() {
    return {
      'userId': userId,
      'nome': nome,
      'email': email,
      'password': password,
      'lista_fossili':lista_fossili,
      'lista_challenge':lista_challenge,
    };
  }
}
