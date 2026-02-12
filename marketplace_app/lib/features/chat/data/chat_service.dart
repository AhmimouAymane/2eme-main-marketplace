import 'package:dio/dio.dart';
import 'package:marketplace_app/shared/models/conversation_model.dart';

class ChatService {
  final Dio _dio;

  ChatService(this._dio);

  Future<List<ConversationModel>> getConversations() async {
    final response = await _dio.get('/conversations');
    final List<dynamic> data = response.data;
    return data.map((json) => ConversationModel.fromJson(json)).toList();
  }

  Future<ConversationModel> getConversation(String id) async {
    final response = await _dio.get('/conversations/$id');
    return ConversationModel.fromJson(response.data);
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    final response = await _dio.get('/conversations/$conversationId/messages');
    final List<dynamic> data = response.data;
    return data.map((json) => MessageModel.fromJson(json)).toList();
  }

  Future<MessageModel> sendMessage(
    String conversationId,
    String content,
  ) async {
    final response = await _dio.post(
      '/conversations/$conversationId/messages',
      data: {'content': content},
    );
    return MessageModel.fromJson(response.data);
  }

  Future<void> markAsRead(String conversationId) async {
    await _dio.post('/conversations/$conversationId/read');
  }
}

