import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kutumbika_app/main.dart';
import 'package:kutumbika_app/widgets/app_logo.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const KutumbikaApp());

    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
