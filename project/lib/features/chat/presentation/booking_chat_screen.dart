import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';
import 'package:home_cleaning_marketplace/features/chat/data/chat_models.dart';
import 'package:home_cleaning_marketplace/features/chat/presentation/booking_chat_controller.dart';
import 'package:home_cleaning_marketplace/shared/widgets/app_async_states.dart';

class BookingChatScreen extends ConsumerStatefulWidget {
  const BookingChatScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<BookingChatScreen> createState() => _BookingChatScreenState();
}

class _BookingChatScreenState extends ConsumerState<BookingChatScreen> {
  late final TextEditingController _composer;

  @override
  void initState() {
    super.initState();
    _composer = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final notifier = ref.read(bookingChatControllerProvider.notifier);
      notifier.load(widget.bookingId);
      notifier.startPolling();
    });
  }

  @override
  void deactivate() {
    ref.read(bookingChatControllerProvider.notifier).stopPolling();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    ref.read(bookingChatControllerProvider.notifier).startPolling();
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(bookingChatControllerProvider, (previous, next) {
      if (previous?.composer != next.composer &&
          _composer.text != next.composer) {
        _composer.value = TextEditingValue(
          text: next.composer,
          selection: TextSelection.collapsed(offset: next.composer.length),
        );
      }
    });
    final state = ref.watch(bookingChatControllerProvider);
    final sendDisabled = state.sending || state.composer.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(state.conversation?.otherPartyDisplayName ?? 'Chat'),
      ),
      body: SafeArea(
        child: state.loading && state.conversation == null
            ? const AppLoadingState()
            : Column(
                children: [
                  if (state.conversation != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Booking ${state.conversation!.bookingStatus.label}',
                        ),
                      ),
                    ),
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(state.errorMessage!),
                    ),
                  Expanded(
                    child: state.messages.isEmpty
                        ? const AppEmptyState(
                            title: 'No messages yet.',
                            message: 'Send a message about this booking.',
                          )
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: TextButton(
                                  onPressed: state.loadingOlder
                                      ? null
                                      : () => ref
                                            .read(
                                              bookingChatControllerProvider
                                                  .notifier,
                                            )
                                            .loadOlder(),
                                  child: Text(
                                    state.loadingOlder
                                        ? 'Loading...'
                                        : 'Load earlier messages',
                                  ),
                                ),
                              ),
                              for (final message in state.messages)
                                _ChatBubble(message: message),
                            ],
                          ),
                  ),
                  if (state.readOnly)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'This conversation is read-only because the booking is closed.',
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _composer,
                              enabled: !state.sending,
                              decoration: const InputDecoration(
                                labelText: 'Message',
                              ),
                              onChanged: ref
                                  .read(bookingChatControllerProvider.notifier)
                                  .setComposer,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Semantics(
                            button: true,
                            label: 'Send message',
                            child: FilledButton(
                              onPressed: sendDisabled
                                  ? null
                                  : () => ref
                                        .read(
                                          bookingChatControllerProvider
                                              .notifier,
                                        )
                                        .send(),
                              child: Text(
                                state.sending ? 'Sending...' : 'Send',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Card(
          color: message.isMine
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.body),
                const SizedBox(height: 4),
                Text(formatLocalDateTime(message.createdAt)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
