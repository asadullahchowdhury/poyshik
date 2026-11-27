import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../app/theme/theme.dart';
import '../../core/widgets/motion.dart';
import '../../l10n/app_localizations.dart';

/// Listens once and returns what was said, or null if cancelled.
/// Speech recognition is done by the phone (Google's recognizer on most
/// Android phones); Poyshik only receives the text.
/// [hint] replaces the default example phrase.
///
/// Returns the recognizer's guesses, best first (callers pick the one they
/// understand best), or null if cancelled.
Future<List<String>?> showVoiceSheet(BuildContext context, {String? hint}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _VoiceSheet(hint: hint),
  );
}

enum _Lang { en, bn }

class _VoiceSheet extends StatefulWidget {
  const _VoiceSheet({this.hint});

  final String? hint;

  @override
  State<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<_VoiceSheet> {
  // One recognizer for the app: initialising is slow and asks permission.
  static final _speech = SpeechToText();

  /// The language last used, so a Bangla speaker on an English app only
  /// switches once.
  static _Lang? _remembered;

  /// Set once this phone's recognizer turns Bangla down (many Android
  /// speech services don't offer it to apps). Bangla then goes straight to
  /// keyboard mode: Gboard's own mic understands Bangla.
  static bool _bnUnavailable = false;

  /// What was heard, editable: fix a misheard word before using it.
  final _edit = TextEditingController();
  final _editFocus = FocusNode();
  bool _edited = false;
  bool _keyboardMode = false;
  DateTime? _listenStarted;

  late _Lang _lang;
  String _text = '';
  List<String> _guesses = const [];
  String? _error;
  String? _notice;
  bool _listening = false;
  bool _available = true;
  String? _bnLocale;
  String? _enLocale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lang =
          _remembered ??
          (Localizations.localeOf(context).languageCode == 'bn'
              ? _Lang.bn
              : _Lang.en);
      unawaited(_start());
    });
    _lang = _Lang.en;
  }

  @override
  void dispose() {
    unawaited(_speech.cancel());
    _finish?.cancel();
    _edit.dispose();
    _editFocus.dispose();
    super.dispose();
  }

  /// Bangla without the phone's recognizer: type, or use the keyboard's mic.
  void _enterKeyboardMode() {
    unawaited(_speech.cancel());
    _finish?.cancel();
    setState(() {
      _keyboardMode = true;
      _listening = false;
      _error = null;
    });
    _editFocus.requestFocus();
  }

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context);
    if (_lang == _Lang.bn && _bnUnavailable) {
      _enterKeyboardMode();
      return;
    }
    setState(() {
      _text = '';
      _guesses = const [];
      _error = null;
      _keyboardMode = false;
      _edited = false;
      _edit.clear();
    });
    final ok = await _speech.initialize(onError: _onError, onStatus: _onStatus);
    // The recognizer is shared and initialize() only registers callbacks
    // the first time; point them at this sheet every time.
    _speech
      ..errorListener = _onError
      ..statusListener = _onStatus;
    if (!mounted) return;
    if (!ok) {
      final denied = !await _speech.hasPermission;
      if (!mounted) return;
      setState(() {
        _available = false;
        _error = denied ? l10n.voiceMicDenied : l10n.voiceUnavailable;
      });
      return;
    }
    if (_bnLocale == null && _enLocale == null) {
      final locales = await _speech.locales();
      String? find(String lang) => locales
          .map((l) => l.localeId)
          .where((id) => id.toLowerCase().startsWith(lang))
          .firstOrNull;
      _bnLocale = find('bn');
      _enLocale = find('en_') ?? find('en');
    }
    if (!mounted) return;
    // Many phones don't list Bangla even though Google's online recognizer
    // understands it, so ask for bn_BD anyway; an unsupported-language
    // error falls back to English (see _onError).
    final localeId = _lang == _Lang.bn ? (_bnLocale ?? 'bn_BD') : _enLocale;
    unawaited(HapticFeedback.selectionClick());
    _listenStarted = DateTime.now();
    await _speech.listen(
      onResult: (r) {
        if (!mounted) return;
        setState(() {
          _text = r.recognizedWords;
          if (!_edited) _edit.text = r.recognizedWords;
          _guesses = {
            r.recognizedWords.trim(),
            for (final a in r.alternates) a.recognizedWords.trim(),
          }.where((g) => g.isNotEmpty).toList();
        });
        if (r.finalResult) _finishSoon();
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
        pauseFor: const Duration(seconds: 3),
        listenFor: const Duration(seconds: 20),
      ),
    );
  }

  void _onStatus(String status) {
    if (!mounted) return;
    setState(() => _listening = status == SpeechToText.listeningStatus);
    if (status == SpeechToText.doneStatus) _finishSoon();
  }

  void _onError(SpeechRecognitionError e) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    // A recognizer without Bangla either says so, or (Speech Services by
    // Google) ends within a moment reporting no speech, before anyone
    // could talk. Either way: keyboard mode, remembered for this run.
    final instant =
        _listenStarted != null &&
        DateTime.now().difference(_listenStarted!) <
            const Duration(milliseconds: 1500);
    if (_lang == _Lang.bn &&
        (e.errorMsg.contains('language') ||
            (instant &&
                (e.errorMsg.contains('no_match') ||
                    e.errorMsg.contains('speech_timeout'))))) {
      _bnUnavailable = true;
      _enterKeyboardMode();
      return;
    }
    setState(() {
      _listening = false;
      _error = e.errorMsg.contains('permission')
          ? l10n.voiceMicDenied
          : l10n.voiceNoMatch;
    });
  }

  /// What to hand back: the user's own text if they typed or fixed it,
  /// otherwise every recognizer guess, best first.
  List<String> get _result {
    final typed = _edit.text.trim();
    if (_edited || _keyboardMode || _guesses.isEmpty) {
      return [if (typed.isNotEmpty) typed];
    }
    return _guesses;
  }

  Timer? _finish;

  /// Closes with the result a moment after speech ends, so the user sees
  /// what was heard.
  void _finishSoon() {
    // Never close under someone who is fixing or typing the text.
    if (_text.trim().isEmpty || _edited || _keyboardMode) return;
    _finish?.cancel();
    _finish = Timer(const Duration(milliseconds: 600), () {
      if (mounted) Navigator.pop(context, _result);
    });
  }

  Future<void> _switch(_Lang lang) async {
    if (lang == _lang) return;
    _finish?.cancel();
    await _speech.cancel();
    _remembered = lang;
    setState(() {
      _lang = lang;
      _notice = null;
      _keyboardMode = false;
    });
    await _start();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final hasText = _edit.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.screen,
        Space.md,
        Space.screen,
        Space.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<_Lang>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _Lang.en, label: Text('English')),
              ButtonSegment(value: _Lang.bn, label: Text('বাংলা')),
            ],
            selected: {_lang},
            onSelectionChanged: (s) => unawaited(_switch(s.first)),
          ),
          const SizedBox(height: Space.xxl),
          if (_keyboardMode) ...[
            Icon(Icons.keyboard_voice_rounded, size: 44, color: c.brand),
            const SizedBox(height: Space.md),
            Text(
              l10n.voiceKeyboardTitle,
              textAlign: TextAlign.center,
              style: AppType.bodyStrong.copyWith(color: c.ink),
            ),
            const SizedBox(height: Space.xs),
            Text(
              l10n.voiceKeyboardBody,
              textAlign: TextAlign.center,
              style: AppType.caption.copyWith(color: c.inkMuted),
            ),
          ] else ...[
            _MicOrb(active: _listening, color: c.brand, onColor: c.onBrand),
            const SizedBox(height: Space.md),
            AnimatedSwitcher(
              duration: Motion.fast,
              child: Text(
                _error ?? (_listening ? l10n.voiceListening : l10n.voiceSpeak),
                key: ValueKey('$_error$_listening'),
                textAlign: TextAlign.center,
                style: AppType.body.copyWith(
                  color: _error == null ? c.inkMuted : c.expense,
                ),
              ),
            ),
          ],
          const SizedBox(height: Space.lg),
          TextField(
            controller: _edit,
            focusNode: _editFocus,
            minLines: 1,
            maxLines: 3,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.sentences,
            style: AppType.titleMedium.copyWith(color: c.ink),
            decoration: InputDecoration(
              hintText: _keyboardMode
                  ? l10n.voiceKeyboardHint
                  : l10n.voiceEditHint,
              hintMaxLines: 2,
            ),
            onTap: () => _finish?.cancel(),
            onChanged: (_) {
              _finish?.cancel();
              setState(() => _edited = true);
            },
          ),
          const SizedBox(height: Space.sm),
          Text(
            _notice ?? widget.hint ?? l10n.voiceHint,
            textAlign: TextAlign.center,
            style: AppType.caption.copyWith(color: c.inkSubtle),
          ),
          const SizedBox(height: Space.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _available
                      ? () async {
                          _finish?.cancel();
                          await _speech.cancel();
                          await _start();
                        }
                      : null,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.voiceTryAgain),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed: hasText
                      ? () => Navigator.pop(context, _result)
                      : null,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(l10n.voiceUse),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The microphone, breathing while it listens.
class _MicOrb extends StatefulWidget {
  const _MicOrb({
    required this.active,
    required this.color,
    required this.onColor,
  });

  final bool active;
  final Color color;
  final Color onColor;

  @override
  State<_MicOrb> createState() => _MicOrbState();
}

class _MicOrbState extends State<_MicOrb> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_MicOrb old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.active && !Motion.reduced(context)) {
      if (!_pulse.isAnimating) unawaited(_pulse.repeat());
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = _pulse.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final offset in [0.0, 0.5])
                Opacity(
                  opacity: widget.active ? (1 - ((t + offset) % 1)) * 0.35 : 0,
                  child: Container(
                    width: 76 + 64 * ((t + offset) % 1),
                    height: 76 + 64 * ((t + offset) % 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color,
                    ),
                  ),
                ),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
                child: Icon(Icons.mic_rounded, size: 34, color: widget.onColor),
              ),
            ],
          );
        },
      ),
    );
  }
}
