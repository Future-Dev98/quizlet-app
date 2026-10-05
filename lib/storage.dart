import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

import 'models.dart';

abstract class StudyStorage {
  Future<StudyData> load();
  Future<void> save(StudyData data);
}

class LocalStudyStorage implements StudyStorage {
  LocalStudyStorage({this.directory});
  final Directory? directory;
  Future<File> _file() async {
    final dir = directory ?? await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    return File('${dir.path}/study_data.json');
  }

  @override
  Future<StudyData> load() async {
    final f = await _file();
    final backup = File('${f.path}.bak');
    if (!await f.exists() && !await backup.exists()) {
      final data = StudyData.decode(
        await rootBundle.loadString('assets/seed.json'),
      );
      await save(data);
      return data;
    }
    try {
      return StudyData.decode(await f.readAsString());
    } catch (_) {
      if (await backup.exists()) {
        return StudyData.decode(await backup.readAsString());
      }
      rethrow;
    }
  }

  @override
  Future<void> save(StudyData data) async {
    final f = await _file();
    final temp = File('${f.path}.tmp');
    await temp.writeAsString(data.encode(), flush: true);
    if (await f.exists()) {
      final source = await f.readAsString();
      bool valid = false;
      try {
        StudyData.decode(source);
        valid = true;
      } catch (_) {
        /* Preserve the previous valid backup. */
      }
      if (valid) await f.copy('${f.path}.bak');
      await f.delete();
    }
    await temp.rename(f.path);
  }
}
