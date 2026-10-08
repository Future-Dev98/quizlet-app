import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

import 'main.dart';
import 'models.dart';
import 'app_layout.dart';
import 'app_localization.dart';

class ReadingPage extends StatefulWidget {
  const ReadingPage({
    super.key,
    required this.setId,
    required this.initialText,
    required this.pronunciation,
  });
  final String setId, initialText;
  final bool pronunciation;
  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> with WidgetsBindingObserver {
  AppLocalizations get l10n => context.l10n;
  final recorder = AudioRecorder();
  final player = AudioPlayer();
  final title = TextEditingController();
  final text = TextEditingController();
  final endpoint = TextEditingController();
  Directory? directory;
  List<Map<String, dynamic>> recordings = [];
  bool recording = false, busy = false, loaded = false;
  int elapsed = 0;
  String? error, currentPath, playingPath;
  Map<String, dynamic>? assessment;
  Timer? timer, draftTimer;
  Future<void> draftWrite = Future.value();
  String get draftName =>
      'draft_${base64Url.encode(utf8.encode(widget.setId)).replaceAll('=', '')}.json';
  StreamSubscription<void>? completed;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    text.text = widget.initialText;
    load();
    completed = player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => playingPath = null);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      if (recording) finish();
      if (!Platform.isIOS || state == AppLifecycleState.detached) {
        player.stop();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    draftTimer?.cancel();
    completed?.cancel();
    recorder.dispose();
    player.dispose();
    title.dispose();
    text.dispose();
    endpoint.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final root = await getApplicationDocumentsDirectory();
      directory = Directory('${root.path}/recordings');
      await directory!.create(recursive: true);
      final index = File('${directory!.path}/index.json');
      final backup = File('${index.path}.bak');
      if (await index.exists() || await backup.exists()) {
        String source;
        try {
          source = await index.readAsString();
          jsonDecode(source) as List;
        } catch (_) {
          source = await backup.readAsString();
        }
        recordings = (jsonDecode(source) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      final draft = File('${directory!.path}/$draftName');
      if (!widget.pronunciation && await draft.exists()) {
        final data = jsonDecode(await draft.readAsString());
        title.text = data['title'] ?? '';
        text.text = data['text'] ?? '';
      }
      final config = File('${root.path}/speech_endpoint.txt');
      if (await config.exists()) endpoint.text = await config.readAsString();
      if (mounted) setState(() => loaded = true);
    } catch (_) {
      if (mounted) {
        setState(() => error = l10n.recordingsLoadError);
      }
    }
  }

  Future<void> saveDraft() async {
    if (widget.pronunciation || directory == null) return;
    final snapshot = jsonEncode({'title': title.text, 'text': text.text});
    try {
      draftWrite = draftWrite
          .catchError((_) {})
          .then(
            (_) =>
                File('${directory!.path}/$draftName')
                    .writeAsString(snapshot, flush: true),
          )
          .then((_) {});
      await draftWrite;
    } catch (_) {
      if (mounted) setState(() => error = l10n.draftSaveError);
    }
  }

  void changed(String _) {
    saveDraft();
  }

  Future<void> start() async {
    if (busy || !loaded || recording || text.text.trim().isEmpty) return;
    setState(() {
      busy = true;
      error = null;
      assessment = null;
    });
    try {
      await player.stop();
      if (!await recorder.hasPermission()) {
        throw FormatException(l10n.microphonePermission);
      }
      await saveDraft();
      final path = '${directory!.path}/${newId()}.wav';
      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      if (!mounted) {
        await recorder.cancel();
        return;
      }
      setState(() {
        recording = true;
        elapsed = 0;
        currentPath = path;
      });
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => elapsed++);
        if (elapsed >= (widget.pronunciation ? 29 : 300)) finish();
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is FormatException ? e.message : l10n.microphoneError,
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> writeIndex(List<Map<String, dynamic>> next) async {
    final f = File('${directory!.path}/index.json');
    final temp = File('${f.path}.tmp');
    await temp.writeAsString(jsonEncode(next), flush: true);
    if (await f.exists()) await f.copy('${f.path}.bak');
    if (await f.exists()) await f.delete();
    await temp.rename(f.path);
  }

  Future<void> finish() async {
    if (!recording || busy) return;
    timer?.cancel();
    setState(() {
      recording = false;
      busy = true;
    });
    try {
      final path = await recorder.stop();
      if (path == null ||
          !await File(path).exists() ||
          await File(path).length() <= 44) {
        throw FormatException(l10n.emptyRecording);
      }
      currentPath = path;
      if (widget.pronunciation) {
        await assess(path);
      } else {
        final next = <Map<String, dynamic>>[
          {
            'setId': widget.setId,
            'file': path.split(RegExp(r'[/\\]')).last,
            'title': title.text.trim().isEmpty
                ? l10n.untitledReading
                : title.text.trim(),
            'text': text.text.trim(),
            'seconds': elapsed,
            'date': DateTime.now().toIso8601String(),
          },
          ...recordings,
        ];
        final kept = next.take(5).toList();
        await writeIndex(kept);
        if (mounted) setState(() => recordings = kept);
        for (final old in next.skip(5)) {
          final file = File('${directory!.path}/${old['file']}');
          if (await file.exists()) await file.delete();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is FormatException
              ? e.message
              : l10n.recordingSaveError,
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> assess(String path) async {
    final uri = Uri.tryParse(endpoint.text.trim());
    if (uri == null ||
        uri.host.isEmpty ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty) {
      throw FormatException(l10n.endpointValidation);
    }
    if (!RegExp(r'[\uac00-\ud7a3\u1100-\u11ff\u3130-\u318f]')
        .hasMatch(text.text)) {
      throw FormatException(l10n.koreanAssessmentOnly);
    }
    if (elapsed < 1) throw FormatException(l10n.recordOneSecond);
    final root = await getApplicationDocumentsDirectory();
    await File('${root.path}/speech_endpoint.txt')
        .writeAsString(uri.toString(), flush: true);
    final request = http.MultipartRequest('POST', uri)
      ..fields['term'] = text.text.trim()
      ..files.add(
        await http.MultipartFile.fromPath(
          'audio',
          path,
          filename: 'pronunciation.wav',
        ),
      );
    final client = http.Client();
    try {
      final response = await http.Response.fromStream(
        await client.send(request).timeout(const Duration(seconds: 35)),
      ).timeout(const Duration(seconds: 35));
      final result = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw FormatException(result['error'] ?? l10n.assessmentError);
      }
      if (mounted) {
        setState(() => assessment = Map<String, dynamic>.from(result));
      }
    } finally {
      client.close();
    }
  }

  Future<void> play(String path) async {
    try {
      if (playingPath == path) {
        await player.stop();
        if (mounted) setState(() => playingPath = null);
      } else {
        if (Platform.isIOS) {
          await player.setAudioContext(
            AudioContext(
              iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
            ),
          );
        }
        await player.play(DeviceFileSource(path));
        if (mounted) setState(() => playingPath = path);
      }
    } catch (_) {
      if (mounted) setState(() => error = l10n.recordingPlayError);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !recording && !busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.pronunciation ? l10n.pronunciation : l10n.reading),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: EdgeInsets.all(mobileInset(context)),
              children: [
                Icon(
                  widget.pronunciation
                      ? Icons.record_voice_over
                      : Icons.mic_none,
                  size: 56,
                  color: purple,
                ),
                const SizedBox(height: 20),
                Text(
                  widget.pronunciation
                      ? l10n.listenYourself
                      : l10n.dailyReading,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.pronunciation
                      ? l10n.assessmentNotice
                      : l10n.recordingNotice,
                ),
                const SizedBox(height: 24),
                if (widget.pronunciation) ...[
                  TextField(
                    controller: endpoint,
                    enabled: !recording && !busy,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: l10n.assessmentUrl,
                      hintText: 'https://your-domain/api/pronunciation',
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  TextField(
                    controller: title,
                    enabled: !recording && !busy,
                    onChanged: changed,
                    decoration: InputDecoration(labelText: l10n.readingTitle),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: text,
                  onChanged: (v) {
                    changed(v);
                    setState(() {});
                  },
                  enabled: !recording && !busy,
                  maxLines: widget.pronunciation ? 2 : 7,
                  maxLength: widget.pronunciation ? 300 : null,
                  decoration: InputDecoration(
                    labelText: widget.pronunciation
                        ? l10n.word
                        : l10n.readingText,
                  ),
                ),
                const SizedBox(height: 20),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.deepOrange),
                    ),
                  ),
                if (recording)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      l10n.recordingElapsed(elapsed),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: busy || !loaded || text.text.trim().isEmpty
                      ? null
                      : recording
                      ? finish
                      : start,
                  icon: Icon(recording ? Icons.stop : Icons.mic),
                  label: Text(
                    busy
                        ? l10n.processing
                        : recording
                        ? widget.pronunciation
                              ? l10n.stopAssess
                              : l10n.stopSave
                        : l10n.startRecording,
                  ),
                ),
                if (widget.pronunciation &&
                    currentPath != null &&
                    !recording &&
                    !busy) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => play(currentPath!),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.replayRecording),
                  ),
                  TextButton(
                    onPressed: () async {
                      setState(() => busy = true);
                      try {
                        await assess(currentPath!);
                      } catch (e) {
                        if (mounted) {
                          setState(
                            () => error = e is FormatException
                                ? e.message
                                : l10n.connectionError,
                          );
                        }
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
                    child: Text(l10n.reassessRecording),
                  ),
                ],
                if (assessment != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${assessment!['score']} / 100',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          Text(
                            l10n.assessmentMetrics(
                              assessment!['accuracy'].toString(),
                              assessment!['fluency'].toString(),
                            ),
                          ),
                          Text(
                            l10n.assessmentCompleteness(
                              assessment!['completeness'].toString(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.recognizedText(
                              assessment!['recognized'].toString(),
                            ),
                          ),
                          ...((assessment!['words'] as List?) ?? []).map(
                            (w) => Text(
                              '${w['word']}: ${w['accuracy']} · ${w['error']}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (!widget.pronunciation) ...[
                  const SizedBox(height: 28),
                  Text(
                    l10n.yourRecordings,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (recordings
                      .where((r) => r['setId'] == widget.setId)
                      .isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(l10n.noRecordings),
                    ),
                  ...recordings.where((r) => r['setId'] == widget.setId).map((
                    r,
                  ) {
                    final path = '${directory!.path}/${r['file']}';
                    return Card(
                      child: ExpansionTile(
                        title: Text(r['title']),
                        subtitle: Text(
                          l10n.recordingDetails(
                            r['seconds'].toString(),
                            r['date'].toString().split('T').first,
                          ),
                        ),
                        leading: IconButton(
                          tooltip: l10n.listenRecording,
                          onPressed: recording || busy
                              ? null
                              : () => play(path),
                          icon: Icon(
                            playingPath == path ? Icons.stop : Icons.play_arrow,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(r['text']),
                          ),
                          TextButton.icon(
                            onPressed: recording || busy
                                ? null
                                : () async {
                                    if (!await confirm(
                                      context,
                                      l10n.deleteRecordingConfirm,
                                      l10n.deleteRecordingNotice(
                                        r['title'].toString(),
                                      ),
                                    )) {
                                      return;
                                    }
                                    setState(() => busy = true);
                                    try {
                                      await player.stop();
                                      final next = recordings
                                          .where((item) => item != r)
                                          .toList();
                                      await writeIndex(next);
                                      if (await File(path).exists()) {
                                        await File(path).delete();
                                      }
                                      if (mounted) {
                                        setState(() {
                                          recordings = next;
                                          playingPath = null;
                                        });
                                      }
                                    } catch (_) {
                                      if (mounted) {
                                        setState(
                                          () =>
                                              error = l10n.recordingDeleteError,
                                        );
                                      }
                                    } finally {
                                      if (mounted) setState(() => busy = false);
                                    }
                                  },
                            icon: const Icon(Icons.delete_outline),
                            label: Text(l10n.deleteRecording),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
