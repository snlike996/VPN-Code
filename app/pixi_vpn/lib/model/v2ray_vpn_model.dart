class V2rayVpnModel {
  dynamic id;
  final String name;
  final String config;
  final bool isPremium;
  final String countryCode;
  final String cityName;

  V2rayVpnModel({
    required this.id,
    required this.name,
    required this.config,
    required this.isPremium,
    required this.countryCode,
    required this.cityName,
  });

  factory V2rayVpnModel.fromJson(Map<String, dynamic> json) {
    return V2rayVpnModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      config: json['link'] ?? '',
      isPremium: (json['type'] ?? 0) == 1,
      countryCode: json['country_code'] ?? '',
      cityName: json['city_name'] ?? '',
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
    };
  }
}
