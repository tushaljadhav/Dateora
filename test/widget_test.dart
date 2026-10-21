import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dateora/models/status_evaluation.dart';
import 'package:dateora/widgets/status_pill.dart';

void main() {
  testWidgets('StatusPill renders label correctly', (WidgetTester tester) async {
    const evaluation = StatusEvaluation(
      status: ComputedItemStatus.safe,
      label: 'Safe',
      daysLeft: 10,
      relativeText: 'Expires in 10 days',
      badgeBg: Colors.green,
      textColor: Colors.white,
      borderColor: Colors.green,
      icon: Icons.check,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusPill(evaluation: evaluation),
        ),
      ),
    );

    expect(find.text('Safe'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
