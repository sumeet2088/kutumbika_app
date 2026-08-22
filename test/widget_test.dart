import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paarisetu_app/main.dart';
import 'package:paarisetu_app/widgets/app_logo.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const PaarisetuApp());

    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
