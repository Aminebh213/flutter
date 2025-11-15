// lib/models/contact.dart

class Contact {
  int? id;
  String prenom;
  String nom;
  String telephone;
  String email;

  Contact({
    this.id,
    required this.prenom,
    required this.nom,
    required this.telephone,
    required this.email,
  });

  String get fullName => '$prenom $nom';

  factory Contact.fromMap(Map<String, dynamic> map) => Contact(
        id: map['id'] as int?,
        prenom: map['prenom'] as String? ?? '',
        nom: map['nom'] as String? ?? '',
        telephone: map['telephone'] as String? ?? '',
        email: map['email'] as String? ?? '',
      );

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'prenom': prenom,
      'nom': nom,
      'telephone': telephone,
      'email': email,
    };
    if (id != null) map['id'] = id;
    return map;
  }
}
