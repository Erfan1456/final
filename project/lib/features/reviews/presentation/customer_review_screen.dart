import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_controller.dart';
import 'package:home_cleaning_marketplace/features/reviews/presentation/customer_review_controller.dart';

class CustomerReviewScreen extends ConsumerStatefulWidget {
  const CustomerReviewScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<CustomerReviewScreen> createState() =>
      _CustomerReviewScreenState();
}

class _CustomerReviewScreenState extends ConsumerState<CustomerReviewScreen> {
  late final TextEditingController _comment;
  int _rating = 0;

  @override
  void initState() {
    super.initState();
    _comment = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(customerReviewControllerProvider.notifier)
          .load(widget.bookingId);
      ref
          .read(customerBookingControllerProvider.notifier)
          .loadDetail(widget.bookingId);
      final review = ref.read(customerReviewControllerProvider).review;
      if (review != null) {
        setState(() {
          _rating = review.rating;
          _comment.text = review.comment ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerReviewControllerProvider);
    final booking = ref.watch(customerBookingControllerProvider).detail;
    ref.listen(customerReviewControllerProvider, (previous, next) {
      final review = next.review;
      if (review != null && previous?.review != review) {
        _rating = review.rating;
        if (_comment.text != (review.comment ?? '')) {
          _comment.text = review.comment ?? '';
        }
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: state.loading && state.review == null && booking == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    if (booking != null) ...[
                      Text(booking.serviceSnapshot.name),
                      Text(booking.cleanerFullName),
                      const SizedBox(height: 16),
                    ],
                    const Text('Rating'),
                    Row(
                      children: [
                        for (var star = 1; star <= 5; star++)
                          IconButton(
                            onPressed: () => setState(() => _rating = star),
                            icon: Icon(
                              star <= _rating ? Icons.star : Icons.star_border,
                            ),
                          ),
                      ],
                    ),
                    TextField(
                      controller: _comment,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Comment (optional)',
                      ),
                    ),
                    if (state.review?.isHidden == true) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'This review is hidden. Editing it will keep it hidden.',
                      ),
                    ],
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(state.errorMessage!),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: state.saving || _rating < 1
                          ? null
                          : () async {
                              await ref
                                  .read(
                                    customerReviewControllerProvider.notifier,
                                  )
                                  .save(
                                    bookingId: widget.bookingId,
                                    rating: _rating,
                                    comment: _comment.text.trim().isEmpty
                                        ? null
                                        : _comment.text.trim(),
                                  );
                            },
                      child: Text(state.saving ? 'Saving...' : 'Save Review'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
