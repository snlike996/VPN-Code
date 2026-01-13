class WGVpnServerModel {
  dynamic id;
  final String name;
  final String address;
  final String config;
  final bool isPremium;
  final String countryCode;
  final String cityName;

  WGVpnServerModel({
    required this.id,
    required this.name,
    required this.address,
    required this.config,
    required this.isPremium,
    required this.countryCode,
    required this.cityName,
  });

  factory WGVpnServerModel.fromJson(Map<String, dynamic> json) {
    return WGVpnServerModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
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
      'address': address,
      'config': config,
      'isPremium': isPremium,
      'country_code': countryCode,
      'city_name': cityName,
    };
  }
}
