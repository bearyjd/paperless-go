import 'package:dio/dio.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final List<DocumentReference> references;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    this.references = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class DocumentReference {
  final int id;
  final String title;

  const DocumentReference({required this.id, required this.title});
}

class ChatService {
  final Dio _dio;

  ChatService(this._dio);

  /// Send a chat message and get a response.
  /// The Paperless-AI API at /api/chat accepts a message and returns
  /// a response with potential document references.
  Future<ChatMessage> sendMessage(String message, List<ChatMessage> history) async {
    try {
      final response = await _dio.post(
        'api/chat',
        data: {
          'message': message,
          'history': history.map((m) => {
            'role': m.role,
            'content': m.content,
          }).toList(),
        },
      );

      final data = response.data;

      if (data is String) {
        return ChatMessage(
          role: 'assistant',
          content: data,
        );
      }

      final responseData = data as Map<String, dynamic>;
      final content = responseData['response'] as String? ??
          responseData['message'] as String? ??
          responseData['content'] as String? ??
          data.toString();

      // Parse document references if present
      final refs = <DocumentReference>[];
      if (responseData.containsKey('documents')) {
        final docs = responseData['documents'] as List<dynamic>?;
        if (docs != null) {
          for (final doc in docs) {
            if (doc is Map<String, dynamic>) {
              refs.add(DocumentReference(
                id: doc['id'] as int? ?? 0,
                title: doc['title'] as String? ?? 'Unknown',
              ));
            }
          }
        }
      }

      return ChatMessage(
        role: 'assistant',
        content: content,
        references: refs,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Chat endpoint not found. Check your Paperless-AI URL.');
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Cannot connect to Paperless-AI. Check the URL and ensure the service is running.');
      }
      throw Exception('Chat error: ${e.message}');
    }
  }
}
