import 'package:dimensional/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AuthSession.isLoggedIn = false;
  });

  testWidgets('home page renders the NFC landing screen', (tester) async {
    await tester.pumpWidget(const DimensionalApp());

    expect(find.text('去碰一下'), findsOneWidget);
    expect(find.text('遇见你的专属人格'), findsOneWidget);
    expect(find.text('NFC'), findsOneWidget);
    expect(find.text('月海型 · 缪'), findsOneWidget);
    expect(find.byIcon(Icons.touch_app_rounded), findsOneWidget);
  });

  testWidgets('unauthed NFC simulation opens login page', (tester) async {
    await tester.pumpWidget(const DimensionalApp());

    await tester.tap(find.text('NFC'));
    await tester.pumpAndSettle();

    expect(find.text('欢迎回来'), findsOneWidget);
    expect(find.text('登录 / 注册'), findsOneWidget);
  });
}
