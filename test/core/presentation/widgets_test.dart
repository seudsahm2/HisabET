import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisabet/core/presentation/widgets/app_bottom_action_bar.dart';
import 'package:hisabet/core/presentation/widgets/app_highlighted_text.dart';

void main() {
  group('AppBottomActionBar', () {
    Future<Rect> saveButtonRect(WidgetTester tester, {required double keyboard}) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: const Center(child: TextField()),
          bottomNavigationBar: AppBottomActionBar(
            child: ElevatedButton(onPressed: () {}, child: const Text('Save')),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return tester.getRect(find.text('Save'));
    }

    testWidgets('sits at the bottom with no keyboard', (tester) async {
      final rect = await saveButtonRect(tester, keyboard: 0);
      expect(rect.bottom, greaterThan(700));
    });

    testWidgets('moves above the keyboard so Save stays visible', (tester) async {
      const keyboard = 300.0;
      final rect = await saveButtonRect(tester, keyboard: keyboard);
      expect(rect.bottom, lessThanOrEqualTo(800 - keyboard));
    });
  });

  group('AppHighlightedText.segments', () {
    test('marks every case-insensitive match', () {
      expect(AppHighlightedText.segments('Abebe Shoes', 'BE'), [
        ('A', false),
        ('be', true),
        ('be', true),
        (' Shoes', false),
      ]);
    });

    test('returns the whole text when there is no query or no match', () {
      expect(AppHighlightedText.segments('Almaz', ''), [('Almaz', false)]);
      expect(AppHighlightedText.segments('Almaz', 'xyz'), [('Almaz', false)]);
    });
  });
}
