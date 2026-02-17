import 'package:dio/dio.dart';
import 'package:marketplace_app/shared/models/address_model.dart';

/// Service pour gérer les adresses utilisateur via l'API
class AddressesService {
  final Dio _dio;
  AddressesService(this._dio);

  /// Récupère toutes les adresses du compte (utilisateur courant)
  Future<List<AddressModel>> fetchUserAddresses(String userId) async {
    final response = await _dio.get('/users/$userId/addresses');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((j) => AddressModel.fromJson(j)).toList();
    }
    return [];
  }

  /// Crée une nouvelle adresse pour l'utilisateur
  Future<AddressModel> createAddress(
    String userId,
    AddressModel address,
  ) async {
    final response = await _dio.post(
      '/users/$userId/addresses',
      data: address.toJson(),
    );
    if (response.statusCode == 201) {
      return AddressModel.fromJson(response.data);
    }
    throw Exception('Failed to create address');
  }

  /// Met à jour une adresse existante
  Future<AddressModel> updateAddress(
    String userId,
    AddressModel address,
  ) async {
    final response = await _dio.patch(
      '/users/$userId/addresses/${address.id}',
      data: address.toJson(),
    );
    if (response.statusCode == 200) {
      return AddressModel.fromJson(response.data);
    }
    throw Exception('Failed to update address');
  }

  /// Supprime une adresse
  Future<void> deleteAddress(String userId, String addressId) async {
    await _dio.delete('/users/$userId/addresses/$addressId');
  }

  /// Définit l'adresse par défaut pour l'utilisateur
  Future<void> setDefaultAddress(String userId, String addressId) async {
    await _dio.put('/users/$userId/addresses/$addressId/default');
  }
}
