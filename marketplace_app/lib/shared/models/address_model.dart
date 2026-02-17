import 'package:equatable/equatable.dart';

/// Modèle représentant une adresse utilisateur
class AddressModel extends Equatable {
  final String id;
  final String label;
  final String street;
  final String city;
  final String postal;
  final String country;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.label,
    required this.street,
    required this.city,
    required this.postal,
    required this.country,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> j) => AddressModel(
    id: j['id'] as String,
    label: j['label'] as String,
    street: j['street'] as String,
    city: j['city'] as String,
    postal: j['postal'] as String,
    country: j['country'] as String,
    isDefault: j['isDefault'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'label': label,
    'street': street,
    'city': city,
    'postal': postal,
    'country': country,
  };

  @override
  List<Object?> get props => [
    id,
    label,
    street,
    city,
    postal,
    country,
    isDefault,
  ];
}
