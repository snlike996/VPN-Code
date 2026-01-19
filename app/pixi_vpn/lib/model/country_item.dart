class CountryItem {
  final String code;
  final String name;

  CountryItem({
    required this.code,
    required this.name,
  });

  factory CountryItem.fromJson(Map<String, dynamic> json) {
    return CountryItem(
      code: (json['country_code'] ?? '').toString().toLowerCase(),
      name: (json['country_name'] ?? '').toString(),
    );
  }
}
