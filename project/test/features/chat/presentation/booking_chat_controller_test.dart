import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/chat/data/chat_api.dart';
import 'package:home_cleaning_marketplace/features/chat/data/chat_models.dart';
import 'package:home_cleaning_marketplace/features/chat/presentation/booking_chat_controller.dart';

import '../../../helpers/feature_test_fakes.dart';

class _FakeChatApi extends ChatApi {
  _FakeChatApi() : super(Dio());

  ConversationDetail conversation = testConversationDetail();
  List<ChatMessage> messages = [testChatMessage()];
  List<ChatMessage> older = const <ChatMessage>[];
  List<ChatMessage> incoming = const <ChatMessage>[];
  ApiFailure? nextError;
  ApiFailure? pollError;
  Completer<void>? sendGate;
  Completer<void>? pollGate;
  int createCalls = 0;
  int listCalls = 0;
  int sendCalls = 0;
  int markReadCalls = 0;
  int afterCalls = 0;
  int beforeCalls = 0;
  String? lastIdempotencyKey;
  String? lastBody;
  String? lastAfter;
  String? lastBefore;

  void _throwIfNeeded({bool polling = false}) {
    final error = polling ? pollError : nextError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<ConversationDetail> createOrGetConversation(String bookingId) async {
    createCalls += 1;
    _throwIfNeeded();
    return conversation;
  }

  @override
  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int? limit,
    String? before,
    String? after,
  }) async {
    lastAfter = after;
    lastBefore = before;
    if (after != null) {
      afterCalls += 1;
      final gate = pollGate;
      if (gate != null) {
        await gate.future;
      }
      _throwIfNeeded(polling: true);
      return incoming;
    }
    if (before != null) {
      beforeCalls += 1;
      lastBefore = before;
      _throwIfNeeded();
      return older;
    }
    listCalls += 1;
    _throwIfNeeded();
    return messages;
  }

  @override
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String idempotencyKey,
    required String body,
  }) async {
    sendCalls += 1;
    lastIdempotencyKey = idempotencyKey;
    lastBody = body;
    final gate = sendGate;
    if (gate != null) {
      await gate.future;
    }
    _throwIfNeeded();
    return testChatMessage(id: '507f1f77bcf86cd7994390b9', body: body);
  }

  @override
  Future<void> markRead(String conversationId, {String? messageId}) async {
    markReadCalls += 1;
  }
}

void main() {
  late _FakeChatApi api;
  late ProviderContainer container;

  setUp(() {
    api = _FakeChatApi();
    container = ProviderContainer(
      overrides: [chatApiProvider.overrideWithValue(api)],
    );
  });

  tearDown(() => container.dispose());

  test('load stores conversation and messages then marks read', () async {
    await container
        .read(bookingChatControllerProvider.notifier)
        .load('507f1f77bcf86cd799439091');
    final state = container.read(bookingChatControllerProvider);
    expect(state.conversation?.otherPartyDisplayName, equals('Ada Cleaner'));
    expect(state.messages, hasLength(1));
    expect(api.createCalls, equals(1));
    expect(api.listCalls, equals(1));
    expect(api.markReadCalls, equals(1));
  });

  test('send reuses one key and ignores duplicate presses', () async {
    api.sendGate = Completer<void>();
    final notifier = container.read(bookingChatControllerProvider.notifier);
    await notifier.load('507f1f77bcf86cd799439091');
    notifier.setComposer('Hello there');
    final first = notifier.send(keyFactory: () => 'fixed-chat-key-aaaa');
    await pumpEventQueue();
    final second = notifier.send(keyFactory: () => 'other-chat-key-bbbb');
    api.sendGate!.complete();
    await Future.wait<void>([first, second]);
    expect(api.sendCalls, equals(1));
    expect(api.lastIdempotencyKey, equals('fixed-chat-key-aaaa'));
    expect(container.read(bookingChatControllerProvider).composer, isEmpty);
  });

  test('failed send retains the idempotency key', () async {
    final notifier = container.read(bookingChatControllerProvider.notifier);
    await notifier.load('507f1f77bcf86cd799439091');
    notifier.setComposer('Hello there');
    api.nextError = ApiFailure(
      code: 'invalid_message',
      message: messageForApiCode('invalid_message'),
    );
    await notifier.send(keyFactory: () => 'fixed-chat-key-aaaa');
    expect(
      container.read(bookingChatControllerProvider).sendIdempotencyKey,
      equals('fixed-chat-key-aaaa'),
    );
    expect(
      container.read(bookingChatControllerProvider).errorMessage,
      contains('plain text'),
    );
    api.nextError = null;
    await notifier.send(keyFactory: () => 'should-not-use-this-key');
    expect(api.sendCalls, equals(2));
    expect(api.lastIdempotencyKey, equals('fixed-chat-key-aaaa'));
  });

  test('loadOlder prepends older messages', () async {
    api.older = [
      testChatMessage(id: '507f1f77bcf86cd7994390a0', body: 'Earlier'),
    ];
    final notifier = container.read(bookingChatControllerProvider.notifier);
    await notifier.load('507f1f77bcf86cd799439091');
    await notifier.loadOlder();
    expect(api.beforeCalls, equals(1));
    expect(api.lastBefore, equals('507f1f77bcf86cd7994390b1'));
    expect(
      container.read(bookingChatControllerProvider).messages.first.body,
      equals('Earlier'),
    );
  });

  test('pollOnce appends newer messages and marks read', () async {
    api.incoming = [
      testChatMessage(
        id: '507f1f77bcf86cd7994390b2',
        body: 'Later',
        isMine: false,
      ),
    ];
    final notifier = container.read(bookingChatControllerProvider.notifier);
    await notifier.load('507f1f77bcf86cd799439091');
    await notifier.pollOnce();
    expect(api.afterCalls, equals(1));
    expect(
      container.read(bookingChatControllerProvider).messages.last.body,
      equals('Later'),
    );
    expect(api.markReadCalls, equals(2));
  });

  test('overlapping poll is ignored', () async {
    api.pollGate = Completer<void>();
    api.incoming = [
      testChatMessage(
        id: '507f1f77bcf86cd7994390b2',
        body: 'Later',
        isMine: false,
      ),
    ];
    final notifier = container.read(bookingChatControllerProvider.notifier);
    await notifier.load('507f1f77bcf86cd799439091');
    final first = notifier.pollOnce();
    await pumpEventQueue();
    final second = notifier.pollOnce();
    api.pollGate!.complete();
    await Future.wait<void>([first, second]);
    expect(api.afterCalls, equals(1));
  });

  test('poll errors do not set a visible error', () async {
    final notifier = container.read(bookingChatControllerProvider.notifier);
    await notifier.load('507f1f77bcf86cd799439091');
    api.pollError = const ApiFailure(
      code: 'network',
      message: 'Unable to reach the server. Check your connection.',
    );
    await notifier.pollOnce();
    expect(container.read(bookingChatControllerProvider).errorMessage, isNull);
  });

  test('read-only conversation does not send', () async {
    api.conversation = testConversationDetail(bookingStatus: 'completed');
    final notifier = container.read(bookingChatControllerProvider.notifier);
    await notifier.load('507f1f77bcf86cd799439091');
    expect(container.read(bookingChatControllerProvider).readOnly, isTrue);
    notifier.setComposer('Hello there');
    await notifier.send();
    expect(api.sendCalls, equals(0));
  });

  test('dispose cancels the polling timer', () async {
    final notifier = container.read(bookingChatControllerProvider.notifier);
    await notifier.load('507f1f77bcf86cd799439091');
    notifier.startPolling(interval: const Duration(hours: 1));
    expect(container.read(bookingChatControllerProvider).polling, isTrue);
    container.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(api.afterCalls, equals(0));
    container = ProviderContainer(
      overrides: [chatApiProvider.overrideWithValue(api)],
    );
  });
}
