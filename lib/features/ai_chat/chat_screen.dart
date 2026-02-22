import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/auth/auth_provider.dart';
import 'chat_notifier.dart';
import 'chat_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    final aiUrl = ref.watch(aiChatUrlProvider);
    final isConfigured = aiUrl != null && aiUrl.isNotEmpty;

    // Listen for errors
    ref.listen(chatNotifierProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.error!)),
          );
        }
        ref.read(chatNotifierProvider.notifier).dismissError();
      }
      // Scroll to bottom on new messages
      if (next.messages.length > (prev?.messages.length ?? 0)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        actions: [
          if (chatState.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear chat',
              onPressed: () => ref.read(chatNotifierProvider.notifier).clearHistory(),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: !isConfigured
          ? _buildNotConfigured(context)
          : Column(
              children: [
                Expanded(
                  child: chatState.messages.isEmpty
                      ? _buildEmptyChat(context)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: chatState.messages.length +
                              (chatState.isLoading ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i >= chatState.messages.length) {
                              return _buildTypingIndicator(context);
                            }
                            return _MessageBubble(
                              message: chatState.messages[i],
                              onDocumentTap: (docId) =>
                                  context.push('/documents/$docId'),
                            );
                          },
                        ),
                ),
                _buildInputBar(context, chatState.isLoading),
              ],
            ),
    );
  }

  Widget _buildNotConfigured(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_outlined, size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'AI Chat not configured',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Set up your Paperless-AI URL in settings to start chatting about your documents.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChat(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_outlined, size: 64,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Ask about your documents',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Chat with AI to search, summarize, and understand your documents.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _SuggestionChip(
                  label: 'Summarize recent invoices',
                  onTap: (text) => _sendMessage(text),
                ),
                _SuggestionChip(
                  label: 'What tax documents do I have?',
                  onTap: (text) => _sendMessage(text),
                ),
                _SuggestionChip(
                  label: 'Find contracts expiring soon',
                  onTap: (text) => _sendMessage(text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Thinking...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, bool isLoading) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _focusNode,
              enabled: !isLoading,
              decoration: InputDecoration(
                hintText: 'Ask about your documents...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                isDense: true,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: isLoading ? null : (_) => _submit(),
              maxLines: 3,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: isLoading ? null : _submit,
            icon: const Icon(Icons.send, size: 20),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _sendMessage(text);
  }

  void _sendMessage(String text) {
    _inputController.clear();
    ref.read(chatNotifierProvider.notifier).sendMessage(text);
    _focusNode.requestFocus();
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ValueChanged<int> onDocumentTap;

  const _MessageBubble({
    required this.message,
    required this.onDocumentTap,
  });

  bool get isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isUser)
              SelectableText(
                message.content,
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                ),
              )
            else
              MarkdownBody(
                data: message.content,
                selectable: true,
                onTapLink: (text, href, title) {
                  if (href != null) {
                    launchUrl(Uri.parse(href)).catchError((_) => false);
                  }
                },
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: colorScheme.onSurface),
                  code: TextStyle(
                    backgroundColor: colorScheme.surfaceContainerLow,
                    color: colorScheme.onSurface,
                    fontSize: 13,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            // Document references
            if (message.references.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 6),
              Text(
                'Referenced documents:',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              ...message.references.map((ref) => InkWell(
                    onTap: () => onDocumentTap(ref.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.description_outlined,
                              size: 14, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              ref.title,
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
            // Timestamp
            const SizedBox(height: 4),
            Text(
              DateFormat.Hm().format(message.timestamp),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: (isUser
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant)
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final ValueChanged<String> onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      onPressed: () => onTap(label),
    );
  }
}
