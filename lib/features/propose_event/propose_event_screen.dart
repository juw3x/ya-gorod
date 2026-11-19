import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../data/models/event_model.dart';

class ProposeEventScreen extends StatefulWidget {
  const ProposeEventScreen({super.key});

  @override
  State<ProposeEventScreen> createState() => _ProposeEventScreenState();
}

class _ProposeEventScreenState extends State<ProposeEventScreen> {
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
  ScheduleType _scheduleType = ScheduleType.single;
  final List<PlatformFile> _files = [];

  Future<void> _pickFiles() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc', 'xlsx', 'xls', 'jpeg', 'jpg', 'png', 'zip', 'rar', '7z'],
    );
    if (picked.isNotEmpty) {
      setState(() => _files.addAll(picked));
    }
  }

  String? _requiredValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Обязательное поле';
    return null;
  }

  String? _optionalUrlValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final uri = Uri.tryParse(v.trim());
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return 'Укажите ссылку с http:// или https://';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Заявка успешно отправлена на модерацию!')),
    );
    _formKey.currentState!.reset();
    _titleCtrl.clear();
    _organizerCtrl.clear();
    _descCtrl.clear();
    _addressCtrl.clear();
    _venueUrlCtrl.clear();
    _priceCtrl.clear();
    _contactNameCtrl.clear();
    _phoneCtrl.clear();
    _ticketUrlCtrl.clear();
    setState(() {
      _category = null;
      _age = null;
      _isFree = false;
      _files.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Предложить мероприятие', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Расскажите о событии в Ноябрьске.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Название *', filled: true, fillColor: Colors.white),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _organizerCtrl,
            decoration: const InputDecoration(labelText: 'Организатор *', filled: true, fillColor: Colors.white),
            validator: _requiredValidator,
          ),
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
          TextFormField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Описание *', filled: true, fillColor: Colors.white),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 16),
          SegmentedButton<ScheduleType>(
            segments: const [
              ButtonSegment(value: ScheduleType.single, label: Text('Одна дата')),
              ButtonSegment(value: ScheduleType.multiple, label: Text('Несколько')),
              ButtonSegment(value: ScheduleType.period, label: Text('Период')),
            ],
            selected: {_scheduleType},
            onSelectionChanged: (s) => setState(() => _scheduleType = s.first),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressCtrl,
            decoration: const InputDecoration(labelText: 'Адрес проведения *', filled: true, fillColor: Colors.white),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _venueUrlCtrl,
            decoration: const InputDecoration(labelText: 'Ссылка на площадку', filled: true, fillColor: Colors.white),
            validator: _optionalUrlValidator,
          ),
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
          TextFormField(
            controller: _contactNameCtrl,
            decoration: const InputDecoration(labelText: 'ФИО контактного лица *', filled: true, fillColor: Colors.white),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Номер телефона *', filled: true, fillColor: Colors.white),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _ticketUrlCtrl,
            decoration: const InputDecoration(labelText: 'Ссылка на покупку билета или регистрацию', filled: true, fillColor: Colors.white),
            validator: _optionalUrlValidator,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.attach_file),
            label: const Text('Прикрепить файлы'),
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
            onPressed: _submit,
            child: const Text('Отправить заявку'),
          ),
        ],
      ),
    );
  }
}
