import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../processing/presets.dart';

/// The enhancement preset chosen on the scanner hub.
///
/// Carried from the scanner screen through the review → enhance pipeline so the
/// happy-path "Continue" and the "Adjust" enhance screen both default to the
/// user's pick. A plain [StateProvider] (no codegen) — it needs no build_runner.
final selectedPresetProvider =
    StateProvider<ProcessingPreset>((ref) => ProcessingPreset.auto);
