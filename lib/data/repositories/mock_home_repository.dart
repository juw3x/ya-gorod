import '../../core/utils/noyabrsk_time.dart';
import '../models/event_model.dart';
import '../models/home_models.dart';

class MockHomeRepository {
  static List<StoryItem> getStories() => const [
        StoryItem(id: 's1', title: 'Выходные в Ноябрьске'),
        StoryItem(id: 's2', title: 'Новый сезон ДК «Русь»'),
        StoryItem(id: 's3', title: 'Каток в парке', isVideo: true),
        StoryItem(id: 's4', title: 'Выставка фото'),
      ];

  static List<BannerItem> getBanners() => const [
        BannerItem(
          id: 'b1',
          title: 'Фестиваль искусств «Ямал»',
          subtitle: 'Главные концерты этой недели',
          targetUrl: 'https://example.com/festival',
        ),
        BannerItem(
          id: 'b2',
          title: 'Ноябрьск-Парк приглашает',
          subtitle: 'Семейная программа в выходные',
          targetUrl: 'https://example.com/park',
        ),
        BannerItem(
          id: 'b3',
          title: 'Предложите своё событие',
          subtitle: 'Разместим афишу бесплатно',
        ),
      ];

  static List<EventModel> getEvents() {
    final today = NoyabrskTime.dateOnly(NoyabrskTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final in3Days = today.add(const Duration(days: 3));

    final base = <EventModel>[
      EventModel(
        id: 'e_period',
        title: 'Фотовыставка «Северное сияние»',
        category: 'Выставка',
        ageRating: '0+',
        venueName: 'Музейный ресурсный центр',
        venueAddress: 'ул. Советская, 82',
        mapUrl: 'https://yandex.ru/maps/?text=Ноябрьск+Советская+82',
        description: 'Постоянная экспозиция работ ямальских фотографов. Вход свободный в часы работы музея.',
        isFree: true,
        scheduleType: ScheduleType.period,
        periodStart: today.subtract(const Duration(days: 2)),
        periodEnd: today.add(const Duration(days: 10)),
        galleryUrls: const ['photo_1', 'photo_2', 'photo_3'],
      ),
      EventModel(
        id: 'e1',
        title: 'Симфонический вечер при свечах',
        category: 'Концерт',
        ageRating: '12+',
        venueName: 'ГДКиК «Русь»',
        venueAddress: 'ул. Советская, 79',
        mapUrl: 'https://yandex.ru/maps/?text=Ноябрьск+Русь',
        ticketUrl: 'https://example.com/tickets/1',
        description: 'Камерный оркестр исполнит мировые саундтреки и классические произведения.',
        minPrice: 800,
        scheduleType: ScheduleType.single,
        sessions: [EventSession(date: today, startTime: '19:00', endTime: '23:59')],
        galleryUrls: const ['photo_1', 'photo_2'],
      ),
      EventModel(
        id: 'e2',
        title: 'Мастер-класс по керамике',
        category: 'Мастер-класс',
        ageRating: '6+',
        venueName: 'Арт-резиденция «Миксер»',
        venueAddress: 'ул. Советская, 27/1',
        mapUrl: 'https://yandex.ru/maps/?text=Ноябрьск+Миксер',
        description: 'Создадим кружку ручной работы под руководством опытного мастера.',
        minPrice: 500,
        scheduleType: ScheduleType.multiple,
        sessions: [
          EventSession(date: tomorrow, startTime: '14:00', endTime: '16:00'),
          EventSession(date: in3Days, startTime: '15:00', endTime: '17:00'),
        ],
      ),
    ];

    for (var i = 3; i <= 25; i++) {
      final day = today.add(Duration(days: (i % 5) + 1));
      base.add(
        EventModel(
          id: 'e$i',
          title: 'Городское мероприятие №$i',
          category: i.isEven ? 'Спектакль' : 'Спорт',
          ageRating: i.isEven ? '6+' : '0+',
          venueName: i.isEven ? 'ЦД «Нефтяник»' : 'СОК «Зенит»',
          venueAddress: 'г. Ноябрьск, ул. Ленина, ${10 + i}',
          description: 'Подробная программа события №$i для жителей и гостей Ноябрьска.',
          isFree: i % 3 == 0,
          minPrice: i % 3 == 0 ? null : 300 + (i * 50),
          scheduleType: ScheduleType.single,
          sessions: [EventSession(date: day, startTime: '${10 + (i % 9)}:00')],
        ),
      );
    }
    return base;
  }
}
