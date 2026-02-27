import 'package:dio/dio.dart';
import 'package:marketplace_app/shared/models/order_model.dart';

/// Service pour gérer les appels API liés aux commandes
class OrdersService {
  final Dio _dio;

  OrdersService(this._dio);

  /// Créer une nouvelle commande
  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      final response = await _dio.post(
        '/orders',
        data: order.toJson(),
      );
      if (response.statusCode == 201) {
        return OrderModel.fromJson(response.data);
      }
      throw Exception('Failed to create order');
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer les commandes en tant qu'acheteur
  Future<List<OrderModel>> getBuyerOrders() async {
    try {
      final response = await _dio.get('/orders/buyer');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => OrderModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer les commandes en tant que vendeur
  Future<List<OrderModel>> getSellerOrders() async {
    try {
      final response = await _dio.get('/orders/seller');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => OrderModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer une commande par son ID
  Future<OrderModel> getOrder(String id) async {
    try {
      final response = await _dio.get('/orders/$id');
      if (response.statusCode == 200) {
        return OrderModel.fromJson(response.data);
      }
      throw Exception('Failed to load order');
    } catch (e) {
      rethrow;
    }
  }

  Future<OrderModel> updateOrderStatus(
    String id,
    OrderStatus status, {
    String? pickupAddress,
    String? rejectionReason,
    String? returnReason,
    String? cancellationReason,
  }) async {
    try {
      final response = await _dio.patch(
        '/orders/$id',
        data: {
          'status': status.name
              .replaceAllMapped(
                RegExp(r'([A-Z])'),
                (match) => '_${match.group(1)}',
              )
              .toUpperCase(),
          if (pickupAddress != null) 'pickupAddress': pickupAddress,
          if (rejectionReason != null) 'rejectionReason': rejectionReason,
          if (returnReason != null) 'returnReason': returnReason,
          if (cancellationReason != null) 'cancellationReason': cancellationReason,
        },
      );
      if (response.statusCode == 200) {
        return OrderModel.fromJson(response.data);
      }
      throw Exception('Failed to update order status');
    } catch (e) {
      rethrow;
    }
  }
}
