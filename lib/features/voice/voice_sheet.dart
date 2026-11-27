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
Future<String?> showVoiceSheet(BuildContext context, {String? hint}) {
  return showModalBottomSheet<String>(
    context: context,
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

  late _Lang _lang;
  String _text = '';
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
      _lang = Localizations.localeOf(context).languageCode == 'bn'
          ? _Lang.bn
          : _Lang.en;
      unawaited(_start());
    });
    _lang = _Lang.en;
  }

  @override
  void dispose() {
    unawaited(_speech.cancel());
    super.dispose();
  }

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _text = '';
      _error = null;
    });
    final ok = await _speech.initialize(
      onError: _onError,
      onStatus: (status) {
        if (!mounted) return;
        setState(() => _listening = status == SpeechToText.listeningStatus);
        if (status == SpeechToText.doneStatus) _finishSoon();
      },
    );
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
    var localeId = _lang == _Lang.bn ? _bnLocale : _enLocale;
    if (_lang == _Lang.bn && _bnLocale == null) {
      _notice = l10n.voiceBanglaMissing;
      localeId = _enLocale;
    }
    unawaited(HapticFeedback.selectionClick());
    await _speech.listen(
      onResult: (r) {
        if (!mounted) return;
        setState(() => _text = r.recognizedWords);
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

  void _onError(SpeechRecognitionError e) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _listening = false;
      _error = e.errorMsg.contains('permission')
          ? l10n.voiceMicDenied
          : l10n.voiceNoMatch;
    });
  }

  Timer? _finish;

  /// Closes with the result a moment after speech ends, so the user sees
  /// what was heard.
  void _finishSoon() {
    if (_text.trim().isEmpty) return;
    _finish?.cancel();
    _finish = Timer(const Duration(milliseconds: 600), () {
      if (mounted) Navigator.pop(context, _text.trim());
    });
  }

  Future<void> _switch(_Lang lang) async {
    if (lang == _lang) return;
    _finish?.cancel();
    await _speech.cancel();
    setState(() {
      _lang = lang;
      _notice = null;
    });
    await _start();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final hasText = _text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.md,
        Space.screen,
        Space.xl,
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
          _MicOrb(active: _listening, color: c.brand, onColor: c.onBrand),
          const SizedBox(height: Space.xl),
          AnimatedSwitcher(
            duration: Motion.fast,
            child: Text(
              _error ??
                  (hasText
                      ? _text
                      : _listening
                      ? l10n.voiceListening
                      : l10n.voiceSpeak),
              key: ValueKey('$_error$_text$_listening'),
              textAlign: TextAlign.center,
              style: hasText && _error == null
                  ? AppType.titleMedium.copyWith(color: c.ink)
                  : AppType.body.copyWith(
                      color: _error == null ? c.inkMuted : c.expense,
                    ),
            ),
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
                      ? () => Navigator.pop(context, _text.trim())
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
