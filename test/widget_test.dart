import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ya_gorod/core/utils/noyabrsk_time.dart';
import 'package:ya_gorod/data/models/event_model.dart';
import 'package:ya_gorod/features/not_found/not_found_screen.dart';

void main() {
  test('EventModel formats free and paid prices correctly', () {
    const freeEvent = EventModel(
      id: '1',
      title: 'Выставка',
      category: 'Выставка',
      ageRating: '0+',
      venueName: 'Музей',
      venueAddress: 'ул. Советская, 82',
      description: 'Описание',
      isFree: true,
      scheduleType: ScheduleType.single,
    );

    const paidEvent = EventModel(
      id: '2',
      title: 'Концерт',
      category: 'Концерт',
      ageRating: '12+',
      venueName: 'ДК Русь',
      venueAddress: 'ул. Советская, 79',
      description: 'Описание',
      minPrice: 500,
      scheduleType: ScheduleType.single,
    );

    expect(freeEvent.formattedPrice, 'Бесплатно');
    expect(paidEvent.formattedPrice, 'от 500 ₽');
  });

  test('EventSession.isCompleted detects finished sessions', () {
    final session = EventSession(
      date: DateTime(2026, 11, 19),
      startTime: '18:00',
      endTime: '20:00',
    );

    expect(session.isCompleted(DateTime(2026, 11, 19, 19, 30)), isFalse);
    expect(session.isCompleted(DateTime(2026, 11, 19, 20, 1)), isTrue);
  });

  test('NoyabrskTime formats short date', () {
    expect(NoyabrskTime.formatShortDate(DateTime(2026, 11, 5)), '05.11.2026');
  });

  testWidgets('NotFoundScreen renders 404 message and button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotFoundScreen()));

    expect(find.text('404'), findsOneWidget);
    expect(find.text('Страница не найдена'), findsOneWidget);
    expect(find.text('На главную'), findsOneWidget);
  });
}
