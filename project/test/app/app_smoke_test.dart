import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/app/app.dart';

void main() {
  testWidgets('app boots the foundation screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: HomeCleaningMarketplaceApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home Cleaning Service Marketplace'), findsOneWidget);
    expect(find.text('Foundation ready'), findsOneWidget);
  });
}
