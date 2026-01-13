class OpenVpnServerModel {
  dynamic id;
  final String name;
  final String config;
  final bool isPremium;
  final String countryCode;
  final String cityName;
  final String username;
  final String password;

  OpenVpnServerModel({
    required this.id,
    required this.name,
    required this.config,
    required this.isPremium,
    required this.countryCode,
    required this.cityName,
    required this.username,
    required this.password,
  });

  factory OpenVpnServerModel.fromJson(Map<String, dynamic> json) {
    return OpenVpnServerModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      config: json['link'] ?? '',
      isPremium: (json['type'] ?? 0) == 1,
      countryCode: json['country_code'] ?? '',
      cityName: json['city_name'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'config': config,
      'isPremium': isPremium,
      'country_code': countryCode,
      'city_name': cityName,
      'username': username,
      'password': password,
    };
  }
}
