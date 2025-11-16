/// Modelo que representa la información del usuario que se guardará
/// para enviar en caso de emergencia.
class UserData {
  final String name;
  final String emergencyMessage;
  final List<String> emergencyContacts; // números de teléfono

  const UserData({
    required this.name,
    required this.emergencyMessage,
    required this.emergencyContacts,
  });

  /// Convierte el objeto a JSON (Map) para guardarlo en SharedPreferences.
  Map<String, dynamic> toJson() => {
        'name': name,
        'emergencyMessage': emergencyMessage,
        'emergencyContacts': emergencyContacts,
      };

  /// Crea una instancia a partir de un Map (JSON).
  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
        name: json['name'] as String,
        emergencyMessage: json['emergencyMessage'] as String,
        emergencyContacts:
            (json['emergencyContacts'] as List).cast<String>(),
      );

  /// Útil para depuración.
  @override
  String toString() =>
      'UserData(name: $name, message: $emergencyMessage, contacts: $emergencyContacts)';
}