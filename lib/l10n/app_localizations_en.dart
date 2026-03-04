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
  String get tapToRecord => 'TAP TO RECORD';

  @override
  String get tapToStop => 'STOP REFERENCE';

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

  @override
  String get globalRankingsTitle => 'GLOBAL RANKINGS';

  @override
  String get noGlobalRankingsYet => 'No global rankings yet.';

  @override
  String get completeCallsToGetRanked => 'Complete calls to get ranked!';

  @override
  String callsTotal(int count) {
    return '$count calls total';
  }

  @override
  String get recordCall => 'RECORD CALL';

  @override
  String get listenReference => 'Listen to Reference';

  @override
  String get startRecording => 'Start Recording';

  @override
  String get resetRecording => 'Reset';

  @override
  String get analyzeCall => 'Analyze Call';

  @override
  String get signIn => 'Sign In';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get speciesBreakdown => 'SPECIES BREAKDOWN';

  @override
  String get recentTrend => 'RECENT TREND';

  @override
  String sessionsAgo(int count) {
    return '$count sessions ago';
  }

  @override
  String get latest => 'Latest';

  @override
  String get noProfileData => 'No profile data';

  @override
  String get getReady => 'GET READY...';

  @override
  String get recordingInProgress => 'RECORDING IN PROGRESS';

  @override
  String get matchReferenceHint =>
      'Match the reference call above to improve your score';

  @override
  String get goBack => 'GO BACK';

  @override
  String savedToDownloads(String fileName) {
    return 'Saved to Downloads: $fileName (Opening folder...)';
  }

  @override
  String errorSavingFile(String error) {
    return 'Error saving file: $error';
  }

  @override
  String shareScoreText(String score, String animal) {
    return 'I just scored $score% on the $animal call in OUTCALL! Think you can beat me? 🦌🦆';
  }

  @override
  String get selectCategory => 'SELECT CATEGORY';

  @override
  String get selectCall => 'SELECT CALL';

  @override
  String get achievements => 'ACHIEVEMENTS';

  @override
  String unlocked(int earned, int total) {
    return '$earned / $total Unlocked';
  }

  @override
  String moreToUnlock(int count) {
    return '$count more to unlock';
  }

  @override
  String get startRecordingForAchievements =>
      'Start recording to earn achievements!';

  @override
  String get allAchievementsEarned =>
      'You\'ve earned every achievement. Legend.';

  @override
  String get trackYourProgress => 'Track your progress';

  @override
  String get performanceAndStorage => 'PERFORMANCE & STORAGE';

  @override
  String get imageQuality => 'Image Quality';

  @override
  String get imageQualitySubtitle => 'Lower quality saves memory';

  @override
  String get audioCleanup => 'Audio Cleanup';

  @override
  String get audioCleanupSubtitle => 'Auto-delete old recordings';

  @override
  String get calibrateScoring => 'Calibrate Scoring';

  @override
  String get calibrateScoringSubtitle => 'Adjust scores for your device';

  @override
  String calibrateLastDate(String date) {
    return 'Last: $date';
  }

  @override
  String get feedbackAndSupport => 'FEEDBACK & SUPPORT';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get sendFeedbackSubtitle => 'Report a bug or suggest a feature';

  @override
  String get privacyPolicySubtitle => 'How we handle your data';

  @override
  String get appVersion => 'App Version';

  @override
  String get resetSettings => 'Reset to Defaults';

  @override
  String get resetSettingsTitle => 'Reset Settings?';

  @override
  String get resetSettingsMessage =>
      'This will restore all settings to their defaults.';

  @override
  String get cancel => 'CANCEL';

  @override
  String get reset => 'RESET';

  @override
  String get huntingLog => 'HUNTING LOG';

  @override
  String huntingLogEntries(int count) {
    return '$count ENTRIES';
  }

  @override
  String get noLogsYet => 'No Logs Yet';

  @override
  String get noLogsTapToAdd => 'Tap + to record your first hunt.';

  @override
  String get deleteEntry => 'Delete Entry?';

  @override
  String get deleteEntryMessage =>
      'This log entry will be permanently deleted.';

  @override
  String get delete => 'DELETE';

  @override
  String get newEntry => 'NEW ENTRY';

  @override
  String get animalField => 'Animal';

  @override
  String get animalHint => 'e.g. Whitetail Buck, Turkey, etc.';

  @override
  String get notesField => 'Notes';

  @override
  String get notesHint => 'What happened? Conditions, behavior, etc.';

  @override
  String get notesRequired => 'Please enter some notes';

  @override
  String get tagLocation => 'Tag Location';

  @override
  String get locationCaptured => 'Location Captured';

  @override
  String get useCurrentLocation => 'Use your current GPS coordinates';

  @override
  String get saveEntry => 'SAVE ENTRY';

  @override
  String leaderboardExperts(String animal) {
    return '$animal EXPERTS';
  }

  @override
  String get noExpertsYet => 'No experts yet.';

  @override
  String get beFirstToScore => 'Be the first to score high!';

  @override
  String get couldNotOpenEmail => 'Could not open email app.';
}
