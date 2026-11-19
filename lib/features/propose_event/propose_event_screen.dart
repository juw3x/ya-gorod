import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/utils/noyabrsk_time.dart';
import '../../core/utils/scroll_bus.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/api_repository.dart';

class _ScheduleRow {
  DateTime? date;
  TimeOfDay? start;
  TimeOfDay? end;
}

class ProposeEventScreen extends StatefulWidget {
  const ProposeEventScreen({super.key});

  @override
  State<ProposeEventScreen> createState() => _ProposeEventScreenState();
}

class _ProposeEventScreenState extends State<ProposeEventScreen> {
  static const int _maxFiles = 5;
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10 МБ

  final _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _organizerCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _venueUrlCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ticketUrlCtrl = TextEditingController();

  static const _categories = [
    'Концерт', 'Спектакль', 'Кинопоказ', 'Выставка', 'Экскурсия',
    'Мастер-класс', 'Обучение', 'Фестиваль', 'Ярмарка', 'Спорт', 'Другое',
  ];
  static const _ages = ['0+', '6+', '12+', '16+', '18+'];

  String? _category;
  String? _age;
  bool _isFree = false;
  bool _isSubmitting = false;
  ScheduleType _scheduleType = ScheduleType.single;

  final List<_ScheduleRow> _rows = [_ScheduleRow()];
  DateTime? _periodStart;
  DateTime? _periodEnd;
  String? _scheduleError;
  String? _fileError;
  final List<PlatformFile> _files = [];

  @override
  void initState() {
    super.initState();
    ScrollBus.proposeTop.addListener(_onScrollToTop);
  }

  void _onScrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<DateTime?> _pickDate(DateTime? initial) {
    final today = NoyabrskTime.dateOnly(NoyabrskTime.now());
    return showDatePicker(
      context: context,
      initialDate: initial ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
    );
  }

  Future<void> _pickFiles() async {
    setState(() => _fileError = null);
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc', 'xlsx', 'xls', 'jpeg', 'jpg', 'png', 'zip', 'rar', '7z'],
    );
    if (picked.isEmpty) return;

    final errors = <String>[];
    for (final f in picked) {
      if (_files.length >= _maxFiles) {
        errors.add('Максимум $_maxFiles файлов в одной заявке.');
        break;
      }
      final bytes = (!kIsWeb && f.path != null) ? File(f.path!).lengthSync() : 0;
      if (bytes > _maxFileSizeBytes) {
        errors.add('Файл "${f.name}" превышает лимит 10 МБ.');
        continue;
      }
      _files.add(f);
    }
    setState(() => _fileError = errors.isEmpty ? null : errors.join('\n'));
  }

  bool _validateSchedule() {
    if (_scheduleType == ScheduleType.period) {
      if (_periodStart == null || _periodEnd == null) {
        setState(() => _scheduleError = 'Укажите дату начала и окончания периода');
        return false;
      }
      if (_periodEnd!.isBefore(_periodStart!)) {
        setState(() => _scheduleError = 'Дата окончания не может быть раньше даты начала');
        return false;
      }
    } else {
      final list = _scheduleType == ScheduleType.single ? [_rows.first] : _rows;
      for (var i = 0; i < list.length; i++) {
        final r = list[i];
        if (r.date == null) {
          setState(() => _scheduleError = 'Укажите дату для сеанса №${i + 1}');
          return false;
        }
        if (r.end != null && r.start == null) {
          setState(() => _scheduleError = 'Если указано время окончания, укажите и время начала');
          return false;
        }
        if (r.start != null && r.end != null && _toMinutes(r.end!) <= _toMinutes(r.start!)) {
          setState(() => _scheduleError = 'Время окончания должно быть позже времени начала');
          return false;
        }
      }
    }
    setState(() => _scheduleError = null);
    return true;
  }

  String? _requiredValidator(String? v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null;

  String? _optionalUrlValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final uri = Uri.tryParse(v.trim());
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return 'Укажите ссылку с http:// или https://';
    }
    return null;
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    final scheduleOk = _validateSchedule();
    if (!formOk || !scheduleOk || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await ApiRepository.submitProposal(
        payload: {
          'title': _titleCtrl.text.trim(),
          'organizer': _organizerCtrl.text.trim(),
          'category': _category,
          'ageRating': _age,
          'description': _descCtrl.text.trim(),
          'scheduleType': _scheduleType.name,
          'address': _addressCtrl.text.trim(),
          'venueUrl': _venueUrlCtrl.text.trim(),
          'isFree': _isFree,
          'price': _isFree ? 0 : int.tryParse(_priceCtrl.text.trim()),
          'contactName': _contactNameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'ticketUrl': _ticketUrlCtrl.text.trim(),
        },
        files: _files,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка отправки на сервер. Проверьте подключение.')),
      );
      return;
    }
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Заявка успешно отправлена на модерацию!')),
    );
    _formKey.currentState!.reset();
    for (final c in [_titleCtrl, _organizerCtrl, _descCtrl, _addressCtrl, _venueUrlCtrl, _priceCtrl, _contactNameCtrl, _phoneCtrl, _ticketUrlCtrl]) {
      c.clear();
    }
    setState(() {
      _isSubmitting = false;
      _category = null;
      _age = null;
      _isFree = false;
      _scheduleType = ScheduleType.single;
      _rows
        ..clear()
        ..add(_ScheduleRow());
      _periodStart = null;
      _periodEnd = null;
      _scheduleError = null;
      _fileError = null;
      _files.clear();
    });
  }

  @override
  void dispose() {
    ScrollBus.proposeTop.removeListener(_onScrollToTop);
    _scrollController.dispose();
    for (final c in [_titleCtrl, _organizerCtrl, _descCtrl, _addressCtrl, _venueUrlCtrl, _priceCtrl, _contactNameCtrl, _phoneCtrl, _ticketUrlCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Предложить мероприятие', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Расскажите о событии в Ноябрьске.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Название *', filled: true, fillColor: Colors.white), validator: _requiredValidator),
          const SizedBox(height: 12),
          TextFormField(controller: _organizerCtrl, decoration: const InputDecoration(labelText: 'Организатор *', filled: true, fillColor: Colors.white), validator: _requiredValidator),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Категория *', filled: true, fillColor: Colors.white),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v),
            validator: (v) => v == null ? 'Выберите категорию' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _age,
            decoration: const InputDecoration(labelText: 'Возрастное ограничение *', filled: true, fillColor: Colors.white),
            items: _ages.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
            onChanged: (v) => setState(() => _age = v),
            validator: (v) => v == null ? 'Выберите возраст' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Описание *', filled: true, fillColor: Colors.white), validator: _requiredValidator),
          const SizedBox(height: 16),
          const Text('Расписание (время Ноябрьска, UTC+5)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<ScheduleType>(
            segments: const [
              ButtonSegment(value: ScheduleType.single, label: Text('Одна дата')),
              ButtonSegment(value: ScheduleType.multiple, label: Text('Несколько')),
              ButtonSegment(value: ScheduleType.period, label: Text('Период')),
            ],
            selected: {_scheduleType},
            onSelectionChanged: (s) => setState(() {
              _scheduleType = s.first;
              _scheduleError = null;
            }),
          ),
          const SizedBox(height: 10),
          ..._buildScheduleInputs(),
          if (_scheduleError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_scheduleError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          const SizedBox(height: 12),
          TextFormField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Адрес проведения *', filled: true, fillColor: Colors.white), validator: _requiredValidator),
          const SizedBox(height: 12),
          TextFormField(controller: _venueUrlCtrl, decoration: const InputDecoration(labelText: 'Ссылка на площадку', filled: true, fillColor: Colors.white), validator: _optionalUrlValidator),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Бесплатно'),
            value: _isFree,
            onChanged: (v) => setState(() {
              _isFree = v;
              if (v) _priceCtrl.clear();
            }),
          ),
          TextFormField(
            controller: _priceCtrl,
            enabled: !_isFree,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Стоимость, ₽ *', filled: true, fillColor: Colors.white),
            validator: (v) {
              if (_isFree) return null;
              final numVal = int.tryParse(v ?? '');
              if (numVal == null || numVal <= 0) return 'Укажите стоимость больше 0';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _contactNameCtrl, decoration: const InputDecoration(labelText: 'ФИО контактного лица *', filled: true, fillColor: Colors.white), validator: _requiredValidator),
          const SizedBox(height: 12),
          TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Номер телефона *', filled: true, fillColor: Colors.white), validator: _requiredValidator),
          const SizedBox(height: 12),
          TextFormField(controller: _ticketUrlCtrl, decoration: const InputDecoration(labelText: 'Ссылка на покупку билета или регистрацию', filled: true, fillColor: Colors.white), validator: _optionalUrlValidator),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.attach_file),
            label: Text('Прикрепить файлы (${_files.length}/$_maxFiles, до 10 МБ)'),
          ),
          if (_fileError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_fileError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          ..._files.asMap().entries.map((entry) {
            final file = entry.value;
            final bytes = (!kIsWeb && file.path != null) ? File(file.path!).lengthSync() : 0;
            final kb = (bytes / 1024).toStringAsFixed(1);
            return ListTile(
              dense: true,
              title: Text(file.name, overflow: TextOverflow.ellipsis),
              subtitle: Text('$kb КБ'),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _files.removeAt(entry.key)),
              ),
            );
          }),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B3A67),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Отправить заявку'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildScheduleInputs() {
    if (_scheduleType == ScheduleType.period) {
      return [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final d = await _pickDate(_periodStart);
                  if (d != null) setState(() => _periodStart = d);
                },
                child: Text(_periodStart == null ? 'Начало *' : NoyabrskTime.formatShortDate(_periodStart!)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final d = await _pickDate(_periodEnd ?? _periodStart);
                  if (d != null) setState(() => _periodEnd = d);
                },
                child: Text(_periodEnd == null ? 'Окончание *' : NoyabrskTime.formatShortDate(_periodEnd!)),
              ),
            ),
          ],
        ),
      ];
    }

    final list = _scheduleType == ScheduleType.single ? [_rows.first] : _rows;
    return [
      ...list.asMap().entries.map((entry) {
        final idx = entry.key;
        final row = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(row.date == null ? 'Дата *' : NoyabrskTime.formatShortDate(row.date!)),
                      onPressed: () async {
                        final d = await _pickDate(row.date);
                        if (d != null) setState(() => row.date = d);
                      },
                    ),
                  ),
                  if (_scheduleType == ScheduleType.multiple && _rows.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => setState(() => _rows.removeAt(idx)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final t = await showTimePicker(context: context, initialTime: row.start ?? const TimeOfDay(hour: 18, minute: 0));
                        if (t != null) setState(() => row.start = t);
                      },
                      child: Text(row.start == null ? 'Начало (ЧЧ:ММ)' : _fmtTime(row.start!)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final t = await showTimePicker(context: context, initialTime: row.end ?? const TimeOfDay(hour: 20, minute: 0));
                        if (t != null) setState(() => row.end = t);
                      },
                      child: Text(row.end == null ? 'Конец (ЧЧ:ММ)' : _fmtTime(row.end!)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
      if (_scheduleType == ScheduleType.multiple)
        TextButton.icon(
          onPressed: () => setState(() => _rows.add(_ScheduleRow())),
          icon: const Icon(Icons.add),
          label: const Text('Добавить дату'),
        ),
    ];
  }
}
