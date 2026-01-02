import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/bill.dart';

class InstapayUsernameNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null;
    // TODO: Load from Hive on app start in Phase 2 or later in Phase 1
  }

  void update(String? name) {
    state = name;
  }
}

final instapayUsernameProvider = NotifierProvider<InstapayUsernameNotifier, String?>(InstapayUsernameNotifier.new);

class TaxDistributionModeNotifier extends Notifier<TaxDistributionMode> {
  @override
  TaxDistributionMode build() {
    return TaxDistributionMode.proportional;
  }

  void update(TaxDistributionMode mode) {
    state = mode;
  }
}

final taxDistributionModeProvider = NotifierProvider<TaxDistributionModeNotifier, TaxDistributionMode>(TaxDistributionModeNotifier.new);
