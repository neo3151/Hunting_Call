import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DemoAccessTier { publicPreview, prospectDemo }

class DemoModeState {
  final bool isActive;
  final bool isPremium;
  final bool hasSeenTour;
  final bool isTourOpen;
  final bool isPresenterMode;
  final int xp;
  final DemoAccessTier accessTier;

  const DemoModeState({
    this.isActive = false,
    this.isPremium = false,
    this.hasSeenTour = false,
    this.isTourOpen = false,
    this.isPresenterMode = false,
    this.xp = 420,
    this.accessTier = DemoAccessTier.publicPreview,
  });

  bool get canPreviewPremium => accessTier == DemoAccessTier.prospectDemo || isPresenterMode;

  DemoModeState copyWith({
    bool? isActive,
    bool? isPremium,
    bool? hasSeenTour,
    bool? isTourOpen,
    bool? isPresenterMode,
    int? xp,
    DemoAccessTier? accessTier,
  }) {
    return DemoModeState(
      isActive: isActive ?? this.isActive,
      isPremium: isPremium ?? this.isPremium,
      hasSeenTour: hasSeenTour ?? this.hasSeenTour,
      isTourOpen: isTourOpen ?? this.isTourOpen,
      isPresenterMode: isPresenterMode ?? this.isPresenterMode,
      xp: xp ?? this.xp,
      accessTier: accessTier ?? this.accessTier,
    );
  }
}

class DemoModeNotifier extends Notifier<DemoModeState> {
  @override
  DemoModeState build() => const DemoModeState();

  void activate({DemoAccessTier tier = DemoAccessTier.publicPreview}) {
    state = state.copyWith(isActive: true, accessTier: tier);
  }

  void togglePresenterMode() {
    state = state.copyWith(
      isActive: true,
      isPresenterMode: !state.isPresenterMode,
      accessTier: !state.isPresenterMode ? DemoAccessTier.prospectDemo : state.accessTier,
    );
  }

  bool enablePremium() {
    if (!state.canPreviewPremium) return false;
    state = state.copyWith(isActive: true, isPremium: true);
    return true;
  }

  bool beginTour() {
    if (state.hasSeenTour || state.isTourOpen) return false;
    state = state.copyWith(isTourOpen: true);
    return true;
  }

  void completeTour() {
    state = state.copyWith(hasSeenTour: true, isTourOpen: false);
  }

  void addXp(int amount) {
    state = state.copyWith(xp: state.xp + amount);
  }

  void resetProgress() {
    state = state.copyWith(
      isPremium: false,
      hasSeenTour: false,
      isTourOpen: false,
      isPresenterMode: false,
      xp: 420,
    );
  }

  void reset() {
    state = const DemoModeState();
  }
}

final demoModeProvider = NotifierProvider<DemoModeNotifier, DemoModeState>(
  DemoModeNotifier.new,
);

