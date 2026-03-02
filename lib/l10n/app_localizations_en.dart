// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'OUTCALL';

  @override
  String get settings => 'SETTINGS';

  @override
  String get appearance => 'APPEARANCE';

  @override
  String get preferences => 'PREFERENCES';

  @override
  String get audioAndHaptics => 'AUDIO & HAPTICS';

  @override
  String get account => 'ACCOUNT';

  @override
  String get about => 'ABOUT';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeSubtitle => 'Light, Dark, or System';

  @override
  String get appTheme => 'App Theme';

  @override
  String get appThemeSubtitle => 'Choose your color palette';

  @override
  String get distanceUnit => 'Distance Unit';

  @override
  String get distanceUnitImperial => 'Imperial (yards, °F)';

  @override
  String get distanceUnitMetric => 'Metric (meters, °C)';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSubtitle => 'Daily challenge reminders';

  @override
  String get soundEffects => 'Sound Effects';

  @override
  String get soundEffectsSubtitle => 'UI sounds and feedback';

  @override
  String get hapticFeedback => 'Haptic Feedback';

  @override
  String get hapticFeedbackSubtitle => 'Vibration on interactions';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get version => 'Version';

  @override
  String get signOut => 'Sign Out';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String homeGreeting(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get dailyChallenge => 'DAILY CHALLENGE';

  @override
  String get dailyChallengeSubtitle => 'New call every day';

  @override
  String get startPracticing => 'START PRACTICING';

  @override
  String get startPracticingSubtitle => 'Record & get scored';

  @override
  String get globalRankings => 'Global\nRankings';

  @override
  String get globalRankingsSubtitle => 'Compete worldwide';

  @override
  String get globalRankingsOffline => 'Rankings\nOffline';

  @override
  String get globalRankingsOfflineSubtitle => 'Coming back soon';

  @override
  String get globalRankingsMaintenanceMsg =>
      'Global Rankings is currently undergoing maintenance.';

  @override
  String get practiceHistory => 'Practice\nHistory';

  @override
  String get practiceHistorySubtitle => 'Track your progress';

  @override
  String get recentHunts => 'RECENT HUNTS';

  @override
  String get noRecordingsYet => 'No recordings yet';

  @override
  String get startFirstHunt => 'Start your first hunt! 🎯';

  @override
  String get overallProficiency => 'OVERALL PROFICIENCY';

  @override
  String overallProficiencyLabel(int score) {
    return 'Overall proficiency: $score percent';
  }

  @override
  String get aiFeedback => 'AI FEEDBACK';

  @override
  String aiFeedbackLabel(String feedback) {
    return 'AI Feedback: $feedback';
  }

  @override
  String get tryAgain => 'TRY AGAIN';

  @override
  String get saveShareRecording => 'SAVE / SHARE RECORDING';

  @override
  String get viewGlobalRankings => 'VIEW GLOBAL RANKINGS';

  @override
  String get globalRankingsLocked => 'GLOBAL RANKINGS (LOCKED)';

  @override
  String get doneReturnToCamp => 'DONE & RETURN TO CAMP';

  @override
  String get pitch => 'PITCH';

  @override
  String get timbre => 'TIMBRE';

  @override
  String get rhythm => 'RHYTHM';

  @override
  String get air => 'AIR';

  @override
  String metricLabel(String metric, int score) {
    return '$metric: $score percent';
  }

  @override
  String get realityCheck => 'REALITY CHECK';

  @override
  String get primaryFlaw => 'PRIMARY FLAW';

  @override
  String challengeStreak(int days) {
    return '🔥 $days-Day Streak';
  }

  @override
  String daysRemaining(int days) {
    return '$days days left';
  }

  @override
  String get startChallenge => 'Start Today\'s Challenge';

  @override
  String get challengeCompleted => 'Challenge Completed!';

  @override
  String get totalSessions => 'Total Sessions';

  @override
  String get averageScore => 'Average Score';

  @override
  String get bestScore => 'Best Score';

  @override
  String get scoreTrend => 'Score Trend';

  @override
  String get challengeStreakTitle => 'Challenge Streak';

  @override
  String get currentStreak => 'Current';

  @override
  String get longestStreak => 'Longest';

  @override
  String get animalBreakdown => 'PER-ANIMAL BREAKDOWN';

  @override
  String sessions(int count) {
    return '$count sessions';
  }

  @override
  String bestLabel(int score) {
    return 'Best: $score%';
  }

  @override
  String get recording => 'Recording...';

  @override
  String get tapToRecord => 'Tap to Record';

  @override
  String get tapToStop => 'Tap to Stop';

  @override
  String get analyzing => 'Analyzing your call...';

  @override
  String get selectAnimal => 'Select Animal';

  @override
  String get searchAnimals => 'Search animals...';

  @override
  String get noAnimalsFound => 'No animals found';

  @override
  String scoreShareText(int score, String animal) {
    return 'I scored $score% on $animal in OUTCALL! 🎯 Can you beat me?';
  }

  @override
  String get achievementUnlocked => 'Achievement Unlocked!';

  @override
  String get achievementFirstBlood => 'First Blood';

  @override
  String get achievementFirstBloodDesc => 'Record your very first animal call.';

  @override
  String get achievementGettingStarted => 'Getting Started';

  @override
  String get achievementGettingStartedDesc => 'Complete 10 recordings.';

  @override
  String get achievementDedicatedHunter => 'Dedicated Hunter';

  @override
  String get achievementDedicatedHunterDesc => 'Complete 25 recordings.';

  @override
  String get achievementMarathonHunter => 'Marathon Hunter';

  @override
  String get achievementMarathonHunterDesc => 'Complete 50 recordings.';

  @override
  String get achievementCenturion => 'Centurion';

  @override
  String get achievementCenturionDesc =>
      'Complete 100 recordings. You\'re obsessed.';

  @override
  String get achievementLivingLegend => 'Living Legend';

  @override
  String get achievementLivingLegendDesc =>
      'Complete 250 recordings. Touch grass.';

  @override
  String get achievementBronzeHunter => 'Bronze Hunter';

  @override
  String get achievementBronzeHunterDesc => 'Score 70% or higher on any call.';

  @override
  String get achievementSilverHunter => 'Silver Hunter';

  @override
  String get achievementSilverHunterDesc => 'Score 80% or higher on any call.';

  @override
  String get achievementGoldHunter => 'Gold Hunter';

  @override
  String get achievementGoldHunterDesc => 'Score 90% or higher on any call.';

  @override
  String get achievementMasterCaller => 'Master Caller';

  @override
  String get achievementMasterCallerDesc =>
      'Score 95% or higher. Near perfection.';

  @override
  String get achievementPerfectionist => 'The Perfectionist';

  @override
  String get achievementPerfectionistDesc =>
      'Score 99% or higher. Are you even human?';

  @override
  String get achievementReliableShot => 'Reliable Shot';

  @override
  String get achievementReliableShotDesc =>
      'Score 80%+ on 5 different recordings.';

  @override
  String get achievementSharpshooter => 'Sharpshooter';

  @override
  String get achievementSharpshooterDesc =>
      'Score 90%+ on 10 different recordings.';

  @override
  String get achievementEliteAverage => 'Elite Average';

  @override
  String get achievementEliteAverageDesc =>
      'Maintain an overall average score of 85+.';

  @override
  String get achievementExplorer => 'Explorer';

  @override
  String get achievementExplorerDesc => 'Practice 3 different species.';

  @override
  String get achievementDiversePicker => 'Diverse Picker';

  @override
  String get achievementDiversePickerDesc => 'Practice 5 different species.';

  @override
  String get achievementWildlifeExpert => 'Wildlife Expert';

  @override
  String get achievementWildlifeExpertDesc => 'Practice 10 different species.';

  @override
  String get achievementCallCollector => 'Call Collector';

  @override
  String get achievementCallCollectorDesc =>
      'Practice 15 different unique call types.';

  @override
  String get achievementChallenger => 'Challenger';

  @override
  String get achievementChallengerDesc =>
      'Complete your first daily challenge.';

  @override
  String get achievementThreePeat => 'Three-Peat';

  @override
  String get achievementThreePeatDesc => 'Achieve a 3-day challenge streak.';

  @override
  String get achievementWeeklyWarrior => 'Weekly Warrior';

  @override
  String get achievementWeeklyWarriorDesc =>
      'Achieve a 7-day challenge streak.';

  @override
  String get achievementTwoWeekTerror => 'Two-Week Terror';

  @override
  String get achievementTwoWeekTerrorDesc =>
      'Maintain a 14-day challenge streak.';

  @override
  String get achievementMonthlyMonster => 'Monthly Monster';

  @override
  String get achievementMonthlyMonsterDesc =>
      '30-day challenge streak. Absolutely unhinged.';

  @override
  String get achievementChallengeVeteran => 'Challenge Veteran';

  @override
  String get achievementChallengeVeteranDesc =>
      'Complete 25 daily challenges total.';

  @override
  String get achievementSpecialist => 'Specialist';

  @override
  String get achievementSpecialistDesc =>
      'Score 85%+ three times on the same call.';

  @override
  String get achievementMasterOfOne => 'Master of One';

  @override
  String get achievementMasterOfOneDesc =>
      'Score 90%+ five times on the same call.';

  @override
  String get achievementNightOwl => 'Night Owl';

  @override
  String get achievementNightOwlDesc =>
      'Practice between midnight and 5 AM. Sleep is overrated.';

  @override
  String get achievementEarlyBird => 'Early Bird';

  @override
  String get achievementEarlyBirdDesc =>
      'Practice before 6 AM. The deer are still sleeping.';

  @override
  String get achievementComebackKid => 'Comeback Kid';

  @override
  String get achievementComebackKidDesc =>
      'Score below 40%, then score above 85% on the same call.';

  @override
  String get achievementSpeedDemon => 'Speed Demon';

  @override
  String get achievementSpeedDemonDesc =>
      'Complete 5 recordings in a single day.';

  @override
  String get achievementTheGrinder => 'The Grinder';

  @override
  String get achievementTheGrinderDesc =>
      'Complete 10 recordings in a single day. Respect.';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get offlineBanner => 'You\'re offline — some features may be limited.';

  @override
  String get backOnline => 'Back online! Welcome back.';

  @override
  String get premiumRequired => 'Premium Feature';

  @override
  String get upgradeToPremium => 'Upgrade to unlock this feature.';
}
