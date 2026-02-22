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
  ));
  return ChatService(dio);
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

@riverpod
class ChatNotifier extends _$ChatNotifier {
  @override
  ChatState build() => const ChatState();

  Future<void> sendMessage(String text) async {
    final userMessage = ChatMessage(role: 'user', content: text);
    final previousMessages = List<ChatMessage>.from(state.messages);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      final service = ref.read(chatServiceProvider);
      // Pass only previous messages as history, not the current user message
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

  void clearHistory() {
    state = const ChatState();
  }

  void dismissError() {
    state = state.copyWith(error: null);
  }
}
