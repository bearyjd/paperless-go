import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/auth/auth_provider.dart';
import 'chat_service.dart';

part 'chat_notifier.g.dart';

@riverpod
ChatService chatService(Ref ref) {
  final aiUrl = ref.watch(aiChatUrlProvider);
  if (aiUrl == null || aiUrl.isEmpty) {
    throw StateError('Paperless-AI URL not configured');
  }
  final normalizedUrl = aiUrl.endsWith('/') ? aiUrl : '$aiUrl/';
  final dio = Dio(BaseOptions(
    baseUrl: normalizedUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60),
    followRedirects: true,
    maxRedirects: 5,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    // Allow redirect status codes so manual redirect handling works
    validateStatus: (status) => status != null && status < 500,
  ));
  return ChatService(dio);
}

enum ChatMode { rag, document }

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final ChatMode mode;
  final int? documentId;
  final String? documentTitle;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.mode = ChatMode.rag,
    this.documentId,
    this.documentTitle,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    ChatMode? mode,
    int? documentId,
    String? documentTitle,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      mode: mode ?? this.mode,
      documentId: documentId ?? this.documentId,
      documentTitle: documentTitle ?? this.documentTitle,
    );
  }
}

@riverpod
class ChatNotifier extends _$ChatNotifier {
  @override
  ChatState build() => const ChatState();

  Future<void> initDocumentMode(int documentId, String title) async {
    state = ChatState(
      mode: ChatMode.document,
      documentId: documentId,
      documentTitle: title,
    );

    try {
      final service = ref.read(chatServiceProvider);
      await service.initDocumentChat(documentId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> sendMessage(String text) async {
    if (state.mode == ChatMode.document) {
      await _sendDocumentMessage(text);
    } else {
      await _sendRagMessage(text);
    }
  }

  Future<void> _sendRagMessage(String text) async {
    final userMessage = ChatMessage(role: 'user', content: text);
    final previousMessages = List<ChatMessage>.from(state.messages);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      final service = ref.read(chatServiceProvider);
      final response = await service.sendMessage(text, previousMessages);
      state = state.copyWith(
        messages: [...state.messages, response],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _sendDocumentMessage(String text) async {
    final documentId = state.documentId;
    if (documentId == null) return;

    final userMessage = ChatMessage(role: 'user', content: text);
    final placeholder = ChatMessage(role: 'assistant', content: '');

    state = state.copyWith(
      messages: [...state.messages, userMessage, placeholder],
      isLoading: true,
      error: null,
    );

    try {
      final service = ref.read(chatServiceProvider);
      final stream = service.sendDocumentMessage(documentId, text);

      await for (final accumulated in stream) {
        final messages = List<ChatMessage>.from(state.messages);
        messages[messages.length - 1] = messages.last.copyWith(content: accumulated);
        state = state.copyWith(messages: messages);
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      // Remove empty placeholder if streaming failed before any content arrived
      final messages = List<ChatMessage>.from(state.messages);
      if (messages.isNotEmpty && messages.last.role == 'assistant' && messages.last.content.isEmpty) {
        messages.removeLast();
      }
      state = state.copyWith(
        messages: messages,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearHistory() {
    if (state.mode == ChatMode.document) {
      state = ChatState(
        mode: ChatMode.document,
        documentId: state.documentId,
        documentTitle: state.documentTitle,
      );
    } else {
      state = const ChatState();
    }
  }

  void dismissError() {
    state = state.copyWith(error: null);
  }
}
