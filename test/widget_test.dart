// Basic smoke test for CIRO app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ciro_app/main.dart';

void main() {
  testWidgets('CiroApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CiroApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
