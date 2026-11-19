import '../models/event_model.dart';
import '../models/home_models.dart';

class MockHomeRepository {
  List<StoryModel> getStories() => const [
        StoryModel(
          id: '1',
          title: 'Глава города',
          shortCaption: 'Главное из жизни города и новости главы Ноябрьска.',
          fullDescription: 'Еженедельный дайджест ключевых решений, благоустройства городских пространств и ответов на вопросы жителей Ноябрьска.',
          sortOrder: 1,
        ),
        StoryModel(
          id: '2',
          title: 'Приложение',
          shortCaption: 'Все события Ноябрьска в одном приложении «Я-Город».',
          sortOrder: 2,
        ),
        StoryModel(
          id: '3',
          title: 'Помощь',
          shortCaption: 'Куда обратиться в экстренных ситуациях и полезные телефоны.',
          sortOrder: 3,
        ),
        StoryModel(
          id: '4',
          title: 'О городе',
          shortCaption: 'История, достопримечательности и интересные факты о Ноябрьске.',
          sortOrder: 4,
        ),
        StoryModel(
          id: '5',
          title: 'Выходные',
          shortCaption: 'Подборка лучших мероприятий на эти выходные.',
          sortOrder: 5,
        ),
      ];

  List<BannerModel> getSliderBanners() => const [
        BannerModel(
          id: 'b1',
          type: BannerType.info,
          title: 'Ноябрь в Ноябрьске',
          subtitle: 'В городе готовят программу ноябрьских мероприятий',
          sortOrder: 1,
        ),
        BannerModel(
          id: 'b2',
          type: BannerType.ad,
          title: 'Время быть вместе',
          subtitle: '«Лето в Москве» заряжает добром',
          linkUrl: 'https://example.com',
          sortOrder: 2,
        ),
      ];

  List<BannerModel> getAfishaAdBanners() => const [
        BannerModel(
          id: 'ad1',
          type: BannerType.ad,
          title: 'Время быть вместе',
          subtitle: '«Лето в Москве» заряжает добром',
          linkUrl: 'https://example.com',
          sortOrder: 1,
        ),
      ];

  List<EventModel> getEvents() {
    final today = DateTime.now().toUtc().add(const Duration(hours: 5));
    final d1 = DateTime(today.year, today.month, today.day);
    final d2 = DateTime(today.year, today.month, today.day + 1);

    return [
      EventModel(
        id: 'e1',
        title: '«В единстве — сила и судьба»',
        category: 'Концерт',
        ageRating: '6+',
        venueName: 'ДШИ им. П. И. Чайковского',
        venueAddress: 'Ноябрьск, пр. Мира, 80А',
        description: 'Концерт «В единстве — сила и судьба». Условия входа: Платный вход.',
        priceLabel: 'Платный вход',
        scheduleType: ScheduleType.single,
        sessions: [EventSession(date: d1, startTime: '19:00')],
      ),
      EventModel(
        id: 'e2',
        title: 'Музыкальный вечер «Культмикс»',
        category: 'Музыкальный вечер',
        ageRating: '12+',
        venueName: 'ЦКиИ «Нефтяник»',
        venueAddress: 'Ноябрьск, ул. Ленина, 12',
        description: 'Живая музыка и творческая атмосфера.',
        priceLabel: 'Платный вход',
        scheduleType: ScheduleType.single,
        sessions: [EventSession(date: d1)],
      ),
      EventModel(
        id: 'e3',
        title: '«Музыкальная ретроспектива»',
        category: 'Программа',
        ageRating: '18+',
        venueName: 'КЦ «Ямал»',
        venueAddress: 'Ноябрьск, ул. Энтузиастов, 43',
        description: 'Программа «Музыкальная ретроспектива».',
        priceLabel: 'Платный вход',
        scheduleType: ScheduleType.single,
        sessions: [EventSession(date: d2, startTime: '18:00')],
      ),
    ];
  }
}