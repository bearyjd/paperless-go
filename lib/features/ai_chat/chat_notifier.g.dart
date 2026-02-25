// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatServiceHash() => r'47f9c1e398558c9d94643d453668b63c763319f2';

/// See also [chatService].
@ProviderFor(chatService)
final chatServiceProvider = Provider<ChatService?>.internal(
  chatService,
  name: r'chatServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChatServiceRef = ProviderRef<ChatService?>;
String _$chatNotifierHash() => r'51b5df9a686c5c7973b48863116852d40e56cbd8';

/// See also [ChatNotifier].
@ProviderFor(ChatNotifier)
final chatNotifierProvider = NotifierProvider<ChatNotifier, ChatState>.internal(
  ChatNotifier.new,
  name: r'chatNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChatNotifier = Notifier<ChatState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
