import 'dart:async';
import 'dart:convert';

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

  ChatMessage copyWith({
    String? role,
    String? content,
    List<DocumentReference>? references,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      references: references ?? this.references,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class DocumentReference {
  final int id;
  final String title;

  const DocumentReference({required this.id, required this.title});
}

class ChatService {
  final Dio _dio;

  ChatService(this._dio);

  /// Send a RAG chat message and get a response.
  /// The Paperless-AI API at /api/chat accepts a message and returns
  /// a response with potential document references.
  Future<ChatMessage> sendMessage(String message, List<ChatMessage> history) async {
    try {
      final payload = {
        'message': message,
        'history': history.map((m) => {
          'role': m.role,
          'content': m.content,
        }).toList(),
      };

      // Dio doesn't follow redirects for POST requests, so we handle
      // 301/302 manually by re-posting to the Location header URL.
      var response = await _dio.post(
        'api/chat/',
        data: payload,
        options: Options(
          validateStatus: (status) => status != null && status < 400,
          followRedirects: false,
        ),
      );

      // Follow redirects manually for POST
      var redirectCount = 0;
      while (response.statusCode == 301 ||
          response.statusCode == 302 ||
          response.statusCode == 307 ||
          response.statusCode == 308) {
        if (++redirectCount > 5) {
          throw Exception('Too many redirects');
        }
        final location = response.headers.value('location');
        if (location == null) {
          throw Exception('Redirect without Location header');
        }
        response = await _dio.post(
          location,
          data: payload,
          options: Options(
            validateStatus: (status) => status != null && status < 400,
            followRedirects: false,
          ),
        );
      }

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

  /// Initialize a document chat session.
  Future<void> initDocumentChat(int documentId) async {
    try {
      await _dio.get(
        'chat/init/$documentId',
        options: Options(
          validateStatus: (status) => status != null && status < 400,
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Document chat endpoint not found. Check your Paperless-AI URL.');
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Cannot connect to Paperless-AI.');
      }
      throw Exception('Init chat error: ${e.message}');
    }
  }

  /// Send a message for document-specific chat and return an SSE stream of content chunks.
  Stream<String> sendDocumentMessage(int documentId, String message) async* {
    try {
      final response = await _dio.post(
        'chat/message',
        data: {
          'documentId': '$documentId',
          'message': message,
        },
        options: Options(
          responseType: ResponseType.stream,
          validateStatus: (status) => status != null && status < 400,
          followRedirects: false,
        ),
      );

      // Follow redirects manually for POST with stream
      var finalResponse = response;
      var redirectCount = 0;
      while (finalResponse.statusCode == 301 ||
          finalResponse.statusCode == 302 ||
          finalResponse.statusCode == 307 ||
          finalResponse.statusCode == 308) {
        if (++redirectCount > 5) {
          throw Exception('Too many redirects');
        }
        final location = finalResponse.headers.value('location');
        if (location == null) {
          throw Exception('Redirect without Location header');
        }
        finalResponse = await _dio.post(
          location,
          data: {
            'documentId': '$documentId',
            'message': message,
          },
          options: Options(
            responseType: ResponseType.stream,
            validateStatus: (status) => status != null && status < 400,
            followRedirects: false,
          ),
        );
      }

      final stream = finalResponse.data.stream as Stream<List<int>>;
      var accumulated = '';
      var buffer = '';

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk);

        // Process complete SSE lines
        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);

          if (line.isEmpty) continue;

          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();

            if (data == '[DONE]') {
              return;
            }

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final content = json['content'] as String? ?? '';
              if (content.isNotEmpty) {
                accumulated += content;
                yield accumulated;
              }
            } catch (_) {
              // Skip malformed JSON chunks
            }
          }
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Document chat endpoint not found. Check your Paperless-AI URL.');
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Cannot connect to Paperless-AI.');
      }
      throw Exception('Chat error: ${e.message}');
    }
  }
}
