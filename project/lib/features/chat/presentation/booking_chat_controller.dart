import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_identity.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_idempotency.dart';
import 'package:home_cleaning_marketplace/features/chat/data/chat_api.dart';
import 'package:home_cleaning_marketplace/features/chat/data/chat_models.dart';

class BookingChatState {
  const BookingChatState({
    required this.loading,
    this.messages = const <ChatMessage>[],
    this.loadingOlder = false,
    this.sending = false,
    this.polling = false,
    this.inFlightPoll = false,
    this.errorMessage,
    this.readOnly = false,
    this.conversation,
    this.composer = '',
    this.sendIdempotencyKey,
  });

  const BookingChatState.idle()
    : loading = false,
      messages = const <ChatMessage>[],
      loadingOlder = false,
      sending = false,
      polling = false,
      inFlightPoll = false,
      errorMessage = null,
      readOnly = false,
      conversation = null,
      composer = '',
      sendIdempotencyKey = null;

  final bool loading;
  final List<ChatMessage> messages;
  final bool loadingOlder;
  final bool sending;
  final bool polling;
  final bool inFlightPoll;
  final String? errorMessage;
  final bool readOnly;
  final ConversationDetail? conversation;
  final String composer;
  final String? sendIdempotencyKey;

  BookingChatState copyWith({
    bool? loading,
    List<ChatMessage>? messages,
    bool? loadingOlder,
    bool? sending,
    bool? polling,
    bool? inFlightPoll,
    String? errorMessage,
    bool? readOnly,
    ConversationDetail? conversation,
    String? composer,
    String? sendIdempotencyKey,
    bool clearError = false,
    bool clearConversation = false,
    bool clearSendKey = false,
  }) {
    return BookingChatState(
      loading: loading ?? this.loading,
      messages: messages ?? this.messages,
      loadingOlder: loadingOlder ?? this.loadingOlder,
      sending: sending ?? this.sending,
      polling: polling ?? this.polling,
      inFlightPoll: inFlightPoll ?? this.inFlightPoll,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      readOnly: readOnly ?? this.readOnly,
      conversation: clearConversation
          ? null
          : (conversation ?? this.conversation),
      composer: composer ?? this.composer,
      sendIdempotencyKey: clearSendKey
          ? null
          : (sendIdempotencyKey ?? this.sendIdempotencyKey),
    );
  }
}

class BookingChatController extends Notifier<BookingChatState> {
  Timer? _pollTimer;

  @override
  BookingChatState build() {
    watchAuthIdentityKey(ref);
    ref.onDispose(stopPolling);
    if (!watchHasAuthSession(ref)) {
      return const BookingChatState.idle();
    }
    return const BookingChatState.idle();
  }

  ChatApi get _api => ref.read(chatApiProvider);

  void setComposer(String value) {
    state = state.copyWith(composer: value);
  }

  Future<void> load(String bookingId) async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      loading: true,
      clearError: true,
      clearConversation: true,
      messages: const <ChatMessage>[],
    );
    try {
      final conversation = await _api.createOrGetConversation(bookingId);
      final messages = await _api.getMessages(conversation.id);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        conversation: conversation,
        messages: messages,
        readOnly: conversation.readOnly,
      );
      await markRead();
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(loading: false, errorMessage: error.message);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> loadOlder() async {
    if (!ref.mounted) {
      return;
    }
    final conversation = state.conversation;
    if (conversation == null ||
        state.messages.isEmpty ||
        state.loading ||
        state.loadingOlder) {
      return;
    }
    state = state.copyWith(loadingOlder: true, clearError: true);
    try {
      final older = await _api.getMessages(
        conversation.id,
        before: state.messages.first.id,
      );
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loadingOlder: false,
        messages: _mergeChronological(older, state.messages),
      );
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(loadingOlder: false, errorMessage: error.message);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loadingOlder: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> send({String Function()? keyFactory}) async {
    if (!ref.mounted || state.sending || state.readOnly) {
      return;
    }
    final conversation = state.conversation;
    final body = state.composer.trim();
    if (conversation == null || body.isEmpty) {
      return;
    }
    final key =
        state.sendIdempotencyKey ??
        (keyFactory ?? generateBookingIdempotencyKey)();
    state = state.copyWith(
      sending: true,
      sendIdempotencyKey: key,
      clearError: true,
    );
    try {
      final message = await _api.sendMessage(
        conversationId: conversation.id,
        idempotencyKey: key,
        body: body,
      );
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        sending: false,
        messages: _mergeChronological(state.messages, [message]),
        composer: '',
        clearSendKey: true,
      );
      await markRead();
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(sending: false, errorMessage: error.message);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        sending: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> markRead() async {
    final conversation = state.conversation;
    if (!ref.mounted || conversation == null) {
      return;
    }
    try {
      await _api.markRead(
        conversation.id,
        messageId: state.messages.isEmpty ? null : state.messages.last.id,
      );
    } catch (_) {
      // Read receipts are best-effort and must not spam the composer.
    }
  }

  void startPolling({Duration interval = const Duration(seconds: 5)}) {
    stopPolling();
    state = state.copyWith(polling: true);
    _pollTimer = Timer.periodic(interval, (_) {
      unawaited(pollOnce());
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (ref.mounted) {
      state = state.copyWith(polling: false, inFlightPoll: false);
    }
  }

  Future<void> pollOnce() async {
    if (!ref.mounted || state.inFlightPoll) {
      return;
    }
    final conversation = state.conversation;
    if (conversation == null) {
      return;
    }
    state = state.copyWith(inFlightPoll: true);
    try {
      final incoming = state.messages.isEmpty
          ? await _api.getMessages(conversation.id)
          : await _api.getMessages(
              conversation.id,
              after: state.messages.last.id,
            );
      if (!ref.mounted) {
        return;
      }
      if (incoming.isEmpty) {
        state = state.copyWith(inFlightPoll: false);
        return;
      }
      final merged = state.messages.isEmpty
          ? incoming
          : _mergeChronological(state.messages, incoming);
      final added = merged.length > state.messages.length;
      state = state.copyWith(inFlightPoll: false, messages: merged);
      if (added) {
        await markRead();
      }
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(inFlightPoll: false);
    }
  }

  List<ChatMessage> _mergeChronological(
    List<ChatMessage> first,
    List<ChatMessage> second,
  ) {
    final byId = <String, ChatMessage>{
      for (final message in first) message.id: message,
      for (final message in second) message.id: message,
    };
    final merged = byId.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return merged;
  }
}

final bookingChatControllerProvider =
    NotifierProvider<BookingChatController, BookingChatState>(
      BookingChatController.new,
    );
