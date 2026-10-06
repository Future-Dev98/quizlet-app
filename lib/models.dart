import 'dart:convert';

import 'package:unorm_dart/unorm_dart.dart' as unicode;

String newId() => DateTime.now().microsecondsSinceEpoch.toString();
String normalizeAnswer(String v) =>
    unicode.nfc(v).trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

class Folder {
  Folder(this.id, this.name, this.parentId);
  final String id;
  String name;
  String? parentId;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'parentId': parentId,
  };
}

class StudyCard {
  StudyCard({
    required this.id,
    required this.term,
    required this.definition,
    this.starred = false,
    this.mastered = false,
    this.seen = false,
    this.details,
  });
  final String id;
  String term, definition;
  bool starred, mastered, seen;
  WordDetails? details;
  Map<String, dynamic> toJson() => {
    'id': id,
    'term': term,
    'definition': definition,
    'starred': starred,
    'mastered': mastered,
    'seen': seen,
    if (details != null) 'details': details!.toJson(),
  };
  factory StudyCard.fromJson(Map<String, dynamic> j) {
    if (j['id'] is! String ||
        j['term'] is! String ||
        j['definition'] is! String ||
        (j['term'] as String).trim().isEmpty ||
        (j['definition'] as String).trim().isEmpty) {
      throw const FormatException('Thẻ không hợp lệ.');
    }
    return StudyCard(
      id: j['id'],
      term: j['term'],
      definition: j['definition'],
      starred: j['starred'] == true,
      mastered: j['mastered'] == true,
      seen: j['seen'] == true,
      details: j['details'] == null ? null : WordDetails.fromJson(j['details']),
    );
  }
}

class WordDetails {
  WordDetails({
    required this.language,
    required this.sourceUrl,
    required this.fetchedAt,
    this.usage = const [],
    this.examples = const [],
    this.synonyms = const [],
    this.definitions = const [],
  });
  final String language, sourceUrl, fetchedAt;
  final List<String> usage, examples, synonyms, definitions;
  bool get isEmpty =>
      usage.isEmpty &&
      examples.isEmpty &&
      synonyms.isEmpty &&
      definitions.isEmpty;
  Map<String, dynamic> toJson() => {
    'language': language,
    'sourceUrl': sourceUrl,
    'fetchedAt': fetchedAt,
    'usage': usage,
    'examples': examples,
    'synonyms': synonyms,
    'definitions': definitions,
  };
  factory WordDetails.fromJson(dynamic value) {
    if (value is! Map ||
        value['language'] is! String ||
        value['sourceUrl'] is! String ||
        value['fetchedAt'] is! String) {
      throw const FormatException('Invalid word details.');
    }
    List<String> strings(String key) {
      final list = value[key] ?? [];
      if (list is! List || list.any((e) => e is! String)) {
        throw const FormatException('Invalid word details.');
      }
      return List<String>.from(list);
    }

    return WordDetails(
      language: value['language'],
      sourceUrl: value['sourceUrl'],
      fetchedAt: value['fetchedAt'],
      usage: strings('usage'),
      examples: strings('examples'),
      synonyms: strings('synonyms'),
      definitions: strings('definitions'),
    );
  }
}

class StudySet {
  StudySet({
    required this.id,
    required this.title,
    required this.cards,
    this.subject = 'Tiếng Hàn',
    this.description = '',
    this.folderId,
    this.sortOrder = 0,
    this.lastCardId,
    List<Map<String, dynamic>>? attempts,
  }) : attempts = attempts ?? [];
  final String id;
  String title, subject, description;
  List<StudyCard> cards;
  String? folderId, lastCardId;
  int sortOrder;
  List<Map<String, dynamic>> attempts;
  int get learned => cards.where((c) => c.mastered).length;
  double get progress => cards.isEmpty ? 0 : learned / cards.length;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subject': subject,
    'description': description,
    'cards': cards.map((c) => c.toJson()).toList(),
    'folderId': folderId,
    'sortOrder': sortOrder,
    'lastCardId': lastCardId,
    'attempts': attempts,
  };
  factory StudySet.fromJson(Map<String, dynamic> j) {
    if (j['id'] is! String ||
        j['title'] is! String ||
        (j['title'] as String).trim().isEmpty ||
        j['cards'] is! List) {
      throw const FormatException('Bộ thẻ không hợp lệ.');
    }
    final cards = (j['cards'] as List)
        .map((e) => StudyCard.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    if (cards.map((c) => c.id).toSet().length != cards.length) {
      throw const FormatException('Mã thẻ bị trùng.');
    }
    return StudySet(
      id: j['id'],
      title: j['title'],
      subject: j['subject'] as String? ?? 'Tiếng Hàn',
      description: j['description'] as String? ?? '',
      cards: cards,
      folderId: j['folderId'] as String?,
      sortOrder: j['sortOrder'] as int? ?? 0,
      lastCardId: j['lastCardId'] as String?,
      attempts: (j['attempts'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }
}

class StudyData {
  StudyData({
    required this.sets,
    this.sessions = 0,
    this.correct = 0,
    this.answers = 0,
    this.darkMode = false,
    List<Folder>? folders,
    Map<String, dynamic>? settings,
  }) : folders = folders ?? [],
       settings = settings ?? {};
  List<StudySet> sets;
  int sessions, correct, answers;
  bool darkMode;
  List<Folder> folders;
  Map<String, dynamic> settings;
  String folderPath(String? id) {
    final parts = <String>[];
    while (id != null) {
      final f = folders.firstWhere((f) => f.id == id);
      parts.insert(0, f.name);
      id = f.parentId;
    }
    return parts.join(' / ');
  }

  String encode() => jsonEncode({
    'version': 1,
    'sets': sets.map((s) => s.toJson()).toList(),
    'sessions': sessions,
    'correct': correct,
    'answers': answers,
    'darkMode': darkMode,
    'folders': folders.map((f) => f.toJson()).toList(),
    'settings': settings,
  });
  StudyData copy() => StudyData.decode(encode());
  factory StudyData.decode(String source) {
    final j = jsonDecode(source);
    if (j is! Map || j['version'] != 1 || j['sets'] is! List) {
      throw const FormatException('Sai định dạng bản sao lưu.');
    }
    final sets = (j['sets'] as List)
        .map((e) => StudySet.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    if (sets.map((s) => s.id).toSet().length != sets.length) {
      throw const FormatException('Mã bộ thẻ trùng.');
    }
    int count(String key) {
      final v = j[key] ?? 0;
      if (v is! int || v < 0) {
        throw const FormatException('Tiến độ không hợp lệ.');
      }
      return v;
    }

    if (count('correct') > count('answers')) {
      throw const FormatException('Tiến độ không hợp lệ.');
    }
    final folders = (j['folders'] as List? ?? [])
        .map(
          (e) => Folder(
            e['id'] as String,
            e['name'] as String,
            e['parentId'] as String?,
          ),
        )
        .toList();
    final ids = folders.map((f) => f.id).toSet();
    if (ids.length != folders.length ||
        sets.any((s) => s.folderId != null && !ids.contains(s.folderId))) {
      throw const FormatException('Thư mục không hợp lệ.');
    }
    for (final f in folders) {
      final visited = <String>{};
      Folder? node = f;
      while (node != null) {
        if (!visited.add(node.id)) {
          throw const FormatException('Thư mục tạo vòng lặp.');
        }
        if (node.parentId == null) break;
        if (!ids.contains(node.parentId)) {
          throw const FormatException('Thiếu thư mục cha.');
        }
        node = folders.firstWhere((v) => v.id == node!.parentId);
      }
    }
    final settings = Map<String, dynamic>.from(j['settings'] as Map? ?? {});
    if (settings.containsKey('interfaceLanguage') &&
        !['vi', 'en'].contains(settings['interfaceLanguage'])) {
      throw const FormatException('Invalid interface language.');
    }
    for (final key in ['wordLanguage', 'meaningLanguage']) {
      if (settings.containsKey(key) &&
          ![
            'ko-KR',
            'vi-VN',
            'en-US',
            'ja-JP',
            'zh-CN',
            'fr-FR',
            'de-DE',
            'es-ES',
          ].contains(settings[key])) {
        throw const FormatException('Invalid speech language.');
      }
    }
    for (final key in [
      'starredOnly',
      'trackProgress',
      'reverse',
      'speechEnabled',
      'autoSpeak',
      'loop',
      'speakWord',
      'speakMeaning',
    ]) {
      if (settings.containsKey(key) && settings[key] is! bool) {
        throw const FormatException('Cài đặt không hợp lệ.');
      }
    }
    for (final key in ['wordRepeats', 'meaningRepeats']) {
      if (settings.containsKey(key) &&
          (settings[key] is! int || settings[key] < 1 || settings[key] > 5)) {
        throw const FormatException('Số lần đọc không hợp lệ.');
      }
    }
    for (final key in ['flipDelay', 'nextDelay']) {
      final legacy = settings[key];
      if (legacy != null) {
        if (legacy is! num ||
            !legacy.isFinite ||
            legacy < .001 ||
            legacy > 60) {
          throw const FormatException('Thời gian không hợp lệ.');
        }
        settings.putIfAbsent('${key}Ms', () => (legacy * 1000).round());
        settings.remove(key);
      }
      final ms = settings['${key}Ms'];
      if (ms != null && (ms is! int || ms < 1 || ms > 60000)) {
        throw const FormatException('Thời gian phải từ 1 đến 60000 mili giây.');
      }
    }
    if (settings.containsKey('rate') &&
        (settings['rate'] is! num ||
            settings['rate'] < .1 ||
            settings['rate'] > 1)) {
      throw const FormatException('Tốc độ không hợp lệ.');
    }
    if (settings.containsKey('font') &&
        !['system', 'serif', 'monospace'].contains(settings['font'])) {
      throw const FormatException('Kiểu chữ không hợp lệ.');
    }
    for (final key in ['koVoice', 'viVoice']) {
      final voice = settings[key];
      if (voice != null &&
          (voice is! Map ||
              voice['name'] is! String ||
              voice['locale'] is! String)) {
        throw const FormatException('Giọng đọc không hợp lệ.');
      }
    }
    return StudyData(
      sets: sets,
      sessions: count('sessions'),
      correct: count('correct'),
      answers: count('answers'),
      darkMode: j['darkMode'] == true,
      folders: folders,
      settings: settings,
    );
  }
  factory StudyData.demo() => StudyData(
    sets: [
      StudySet(
        id: 'english',
        title: 'English · Mỗi ngày một chút',
        subject: 'Ngoại ngữ',
        description: 'Những từ nhỏ, mở ra một thế giới lớn.',
        cards: [
          StudyCard(
            id: 'e1',
            term: 'Serendipity',
            definition: 'Sự tình cờ may mắn',
          ),
          StudyCard(
            id: 'e2',
            term: 'Resilience',
            definition: 'Khả năng phục hồi',
          ),
          StudyCard(id: 'e3', term: 'Curiosity', definition: 'Sự tò mò'),
          StudyCard(id: 'e4', term: 'Gratitude', definition: 'Lòng biết ơn'),
          StudyCard(
            id: 'e5',
            term: 'Wanderlust',
            definition: 'Niềm đam mê khám phá',
          ),
          StudyCard(id: 'e6', term: 'Mindfulness', definition: 'Sự tỉnh thức'),
        ],
      ),
      StudySet(
        id: 'biology',
        title: 'Sinh học · Tế bào',
        subject: 'Khoa học',
        description: 'Khám phá đơn vị cơ bản của sự sống.',
        cards: [
          StudyCard(
            id: 'b1',
            term: 'Ty thể',
            definition: 'Bào quan tạo năng lượng cho tế bào',
          ),
          StudyCard(
            id: 'b2',
            term: 'Ribosome',
            definition: 'Nơi tổng hợp protein',
          ),
          StudyCard(
            id: 'b3',
            term: 'Nhân tế bào',
            definition: 'Chứa vật chất di truyền',
          ),
          StudyCard(
            id: 'b4',
            term: 'Màng sinh chất',
            definition: 'Kiểm soát trao đổi chất của tế bào',
          ),
        ],
      ),
    ],
  );
}
