import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ExportMode { fast, precise }

class ExportModeNotifier extends Notifier<ExportMode> {
  @override
  ExportMode build() => ExportMode.fast;

  void toggleMode() {
    state = state == ExportMode.fast ? ExportMode.precise : ExportMode.fast;
  }
}

final exportModeProvider = NotifierProvider<ExportModeNotifier, ExportMode>(ExportModeNotifier.new);
