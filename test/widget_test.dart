// Basic smoke test for Nigehbaan AI app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ciro_app/main.dart';

void main() {
  testWidgets('NigehbaanApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: NigehbaanApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
