class SystemSettingsModel {
  final String id;
  final double serviceFeePercentage;
  final double shippingFee;

  SystemSettingsModel({
    required this.id,
    required this.serviceFeePercentage,
    required this.shippingFee,
  });

  factory SystemSettingsModel.fromJson(Map<String, dynamic> json) {
    return SystemSettingsModel(
      id: json['id'],
      serviceFeePercentage: (json['serviceFeePercentage'] as num).toDouble(),
      shippingFee: (json['shippingFee'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceFeePercentage': serviceFeePercentage,
      'shippingFee': shippingFee,
    };
  }
}
