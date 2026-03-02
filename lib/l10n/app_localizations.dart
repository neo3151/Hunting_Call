import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// App title
  ///
  /// In en, this message translates to:
  /// **'OUTCALL'**
  String get appName;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get appearance;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get preferences;

  /// No description provided for @audioAndHaptics.
  ///
  /// In en, this message translates to:
  /// **'AUDIO & HAPTICS'**
  String get audioAndHaptics;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get account;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get about;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Light, Dark, or System'**
  String get darkModeSubtitle;

  /// No description provided for @appTheme.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get appTheme;

  /// No description provided for @appThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your color palette'**
  String get appThemeSubtitle;

  /// No description provided for @distanceUnit.
  ///
  /// In en, this message translates to:
  /// **'Distance Unit'**
  String get distanceUnit;

  /// No description provided for @distanceUnitImperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial (yards, °F)'**
  String get distanceUnitImperial;

  /// No description provided for @distanceUnitMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric (meters, °C)'**
  String get distanceUnitMetric;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily challenge reminders'**
  String get notificationsSubtitle;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get soundEffects;

  /// No description provided for @soundEffectsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'UI sounds and feedback'**
  String get soundEffectsSubtitle;

  /// No description provided for @hapticFeedback.
  ///
  /// In en, this message translates to:
  /// **'Haptic Feedback'**
  String get hapticFeedback;

  /// No description provided for @hapticFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vibration on interactions'**
  String get hapticFeedbackSubtitle;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String homeGreeting(String name);

  /// No description provided for @dailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'DAILY CHALLENGE'**
  String get dailyChallenge;

  /// No description provided for @dailyChallengeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New call every day'**
  String get dailyChallengeSubtitle;

  /// No description provided for @startPracticing.
  ///
  /// In en, this message translates to:
  /// **'START PRACTICING'**
  String get startPracticing;

  /// No description provided for @startPracticingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record & get scored'**
  String get startPracticingSubtitle;

  /// No description provided for @globalRankings.
  ///
  /// In en, this message translates to:
  /// **'Global\nRankings'**
  String get globalRankings;

  /// No description provided for @globalRankingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compete worldwide'**
  String get globalRankingsSubtitle;

  /// No description provided for @globalRankingsOffline.
  ///
  /// In en, this message translates to:
  /// **'Rankings\nOffline'**
  String get globalRankingsOffline;

  /// No description provided for @globalRankingsOfflineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Coming back soon'**
  String get globalRankingsOfflineSubtitle;

  /// No description provided for @globalRankingsMaintenanceMsg.
  ///
  /// In en, this message translates to:
  /// **'Global Rankings is currently undergoing maintenance.'**
  String get globalRankingsMaintenanceMsg;

  /// No description provided for @practiceHistory.
  ///
  /// In en, this message translates to:
  /// **'Practice\nHistory'**
  String get practiceHistory;

  /// No description provided for @practiceHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your progress'**
  String get practiceHistorySubtitle;

  /// No description provided for @recentHunts.
  ///
  /// In en, this message translates to:
  /// **'RECENT HUNTS'**
  String get recentHunts;

  /// No description provided for @noRecordingsYet.
  ///
  /// In en, this message translates to:
  /// **'No recordings yet'**
  String get noRecordingsYet;

  /// No description provided for @startFirstHunt.
  ///
  /// In en, this message translates to:
  /// **'Start your first hunt! 🎯'**
  String get startFirstHunt;

  /// No description provided for @overallProficiency.
  ///
  /// In en, this message translates to:
  /// **'OVERALL PROFICIENCY'**
  String get overallProficiency;

  /// No description provided for @overallProficiencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Overall proficiency: {score} percent'**
  String overallProficiencyLabel(int score);

  /// No description provided for @aiFeedback.
  ///
  /// In en, this message translates to:
  /// **'AI FEEDBACK'**
  String get aiFeedback;

  /// No description provided for @aiFeedbackLabel.
  ///
  /// In en, this message translates to:
  /// **'AI Feedback: {feedback}'**
  String aiFeedbackLabel(String feedback);

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'TRY AGAIN'**
  String get tryAgain;

  /// No description provided for @saveShareRecording.
  ///
  /// In en, this message translates to:
  /// **'SAVE / SHARE RECORDING'**
  String get saveShareRecording;

  /// No description provided for @viewGlobalRankings.
  ///
  /// In en, this message translates to:
  /// **'VIEW GLOBAL RANKINGS'**
  String get viewGlobalRankings;

  /// No description provided for @globalRankingsLocked.
  ///
  /// In en, this message translates to:
  /// **'GLOBAL RANKINGS (LOCKED)'**
  String get globalRankingsLocked;

  /// No description provided for @doneReturnToCamp.
  ///
  /// In en, this message translates to:
  /// **'DONE & RETURN TO CAMP'**
  String get doneReturnToCamp;

  /// No description provided for @pitch.
  ///
  /// In en, this message translates to:
  /// **'PITCH'**
  String get pitch;

  /// No description provided for @timbre.
  ///
  /// In en, this message translates to:
  /// **'TIMBRE'**
  String get timbre;

  /// No description provided for @rhythm.
  ///
  /// In en, this message translates to:
  /// **'RHYTHM'**
  String get rhythm;

  /// No description provided for @air.
  ///
  /// In en, this message translates to:
  /// **'AIR'**
  String get air;

  /// No description provided for @metricLabel.
  ///
  /// In en, this message translates to:
  /// **'{metric}: {score} percent'**
  String metricLabel(String metric, int score);

  /// No description provided for @realityCheck.
  ///
  /// In en, this message translates to:
  /// **'REALITY CHECK'**
  String get realityCheck;

  /// No description provided for @primaryFlaw.
  ///
  /// In en, this message translates to:
  /// **'PRIMARY FLAW'**
  String get primaryFlaw;

  /// No description provided for @challengeStreak.
  ///
  /// In en, this message translates to:
  /// **'🔥 {days}-Day Streak'**
  String challengeStreak(int days);

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String daysRemaining(int days);

  /// No description provided for @startChallenge.
  ///
  /// In en, this message translates to:
  /// **'Start Today\'s Challenge'**
  String get startChallenge;

  /// No description provided for @challengeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Challenge Completed!'**
  String get challengeCompleted;

  /// No description provided for @totalSessions.
  ///
  /// In en, this message translates to:
  /// **'Total Sessions'**
  String get totalSessions;

  /// No description provided for @averageScore.
  ///
  /// In en, this message translates to:
  /// **'Average Score'**
  String get averageScore;

  /// No description provided for @bestScore.
  ///
  /// In en, this message translates to:
  /// **'Best Score'**
  String get bestScore;

  /// No description provided for @scoreTrend.
  ///
  /// In en, this message translates to:
  /// **'Score Trend'**
  String get scoreTrend;

  /// No description provided for @challengeStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge Streak'**
  String get challengeStreakTitle;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentStreak;

  /// No description provided for @longestStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest'**
  String get longestStreak;

  /// No description provided for @animalBreakdown.
  ///
  /// In en, this message translates to:
  /// **'PER-ANIMAL BREAKDOWN'**
  String get animalBreakdown;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions'**
  String sessions(int count);

  /// No description provided for @bestLabel.
  ///
  /// In en, this message translates to:
  /// **'Best: {score}%'**
  String bestLabel(int score);

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recording;

  /// No description provided for @tapToRecord.
  ///
  /// In en, this message translates to:
  /// **'Tap to Record'**
  String get tapToRecord;

  /// No description provided for @tapToStop.
  ///
  /// In en, this message translates to:
  /// **'Tap to Stop'**
  String get tapToStop;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your call...'**
  String get analyzing;

  /// No description provided for @selectAnimal.
  ///
  /// In en, this message translates to:
  /// **'Select Animal'**
  String get selectAnimal;

  /// No description provided for @searchAnimals.
  ///
  /// In en, this message translates to:
  /// **'Search animals...'**
  String get searchAnimals;

  /// No description provided for @noAnimalsFound.
  ///
  /// In en, this message translates to:
  /// **'No animals found'**
  String get noAnimalsFound;

  /// No description provided for @scoreShareText.
  ///
  /// In en, this message translates to:
  /// **'I scored {score}% on {animal} in OUTCALL! 🎯 Can you beat me?'**
  String scoreShareText(int score, String animal);

  /// No description provided for @achievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement Unlocked!'**
  String get achievementUnlocked;

  /// No description provided for @achievementFirstBlood.
  ///
  /// In en, this message translates to:
  /// **'First Blood'**
  String get achievementFirstBlood;

  /// No description provided for @achievementFirstBloodDesc.
  ///
  /// In en, this message translates to:
  /// **'Record your very first animal call.'**
  String get achievementFirstBloodDesc;

  /// No description provided for @achievementGettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get achievementGettingStarted;

  /// No description provided for @achievementGettingStartedDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete 10 recordings.'**
  String get achievementGettingStartedDesc;

  /// No description provided for @achievementDedicatedHunter.
  ///
  /// In en, this message translates to:
  /// **'Dedicated Hunter'**
  String get achievementDedicatedHunter;

  /// No description provided for @achievementDedicatedHunterDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete 25 recordings.'**
  String get achievementDedicatedHunterDesc;

  /// No description provided for @achievementMarathonHunter.
  ///
  /// In en, this message translates to:
  /// **'Marathon Hunter'**
  String get achievementMarathonHunter;

  /// No description provided for @achievementMarathonHunterDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete 50 recordings.'**
  String get achievementMarathonHunterDesc;

  /// No description provided for @achievementCenturion.
  ///
  /// In en, this message translates to:
  /// **'Centurion'**
  String get achievementCenturion;

  /// No description provided for @achievementCenturionDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete 100 recordings. You\'re obsessed.'**
  String get achievementCenturionDesc;

  /// No description provided for @achievementLivingLegend.
  ///
  /// In en, this message translates to:
  /// **'Living Legend'**
  String get achievementLivingLegend;

  /// No description provided for @achievementLivingLegendDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete 250 recordings. Touch grass.'**
  String get achievementLivingLegendDesc;

  /// No description provided for @achievementBronzeHunter.
  ///
  /// In en, this message translates to:
  /// **'Bronze Hunter'**
  String get achievementBronzeHunter;

  /// No description provided for @achievementBronzeHunterDesc.
  ///
  /// In en, this message translates to:
  /// **'Score 70% or higher on any call.'**
  String get achievementBronzeHunterDesc;

  /// No description provided for @achievementSilverHunter.
  ///
  /// In en, this message translates to:
  /// **'Silver Hunter'**
  String get achievementSilverHunter;

  /// No description provided for @achievementSilverHunterDesc.
  ///
  /// In en, this message translates to:
  /// **'Score 80% or higher on any call.'**
  String get achievementSilverHunterDesc;

  /// No description provided for @achievementGoldHunter.
  ///
  /// In en, this message translates to:
  /// **'Gold Hunter'**
  String get achievementGoldHunter;

  /// No description provided for @achievementGoldHunterDesc.
  ///
  /// In en, this message translates to:
  /// **'Score 90% or higher on any call.'**
  String get achievementGoldHunterDesc;

  /// No description provided for @achievementMasterCaller.
  ///
  /// In en, this message translates to:
  /// **'Master Caller'**
  String get achievementMasterCaller;

  /// No description provided for @achievementMasterCallerDesc.
  ///
  /// In en, this message translates to:
  /// **'Score 95% or higher. Near perfection.'**
  String get achievementMasterCallerDesc;

  /// No description provided for @achievementPerfectionist.
  ///
  /// In en, this message translates to:
  /// **'The Perfectionist'**
  String get achievementPerfectionist;

  /// No description provided for @achievementPerfectionistDesc.
  ///
  /// In en, this message translates to:
  /// **'Score 99% or higher. Are you even human?'**
  String get achievementPerfectionistDesc;

  /// No description provided for @achievementReliableShot.
  ///
  /// In en, this message translates to:
  /// **'Reliable Shot'**
  String get achievementReliableShot;

  /// No description provided for @achievementReliableShotDesc.
  ///
  /// In en, this message translates to:
  /// **'Score 80%+ on 5 different recordings.'**
  String get achievementReliableShotDesc;

  /// No description provided for @achievementSharpshooter.
  ///
  /// In en, this message translates to:
  /// **'Sharpshooter'**
  String get achievementSharpshooter;

  /// No description provided for @achievementSharpshooterDesc.
  ///
  /// In en, this message translates to:
  /// **'Score 90%+ on 10 different recordings.'**
  String get achievementSharpshooterDesc;

  /// No description provided for @achievementEliteAverage.
  ///
  /// In en, this message translates to:
  /// **'Elite Average'**
  String get achievementEliteAverage;

  /// No description provided for @achievementEliteAverageDesc.
  ///
  /// In en, this message translates to:
  /// **'Maintain an overall average score of 85+.'**
  String get achievementEliteAverageDesc;

  /// No description provided for @achievementExplorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get achievementExplorer;

  /// No description provided for @achievementExplorerDesc.
  ///
  /// In en, this message translates to:
  /// **'Practice 3 different species.'**
  String get achievementExplorerDesc;

  /// No description provided for @achievementDiversePicker.
  ///
  /// In en, this message translates to:
  /// **'Diverse Picker'**
  String get achievementDiversePicker;

  /// No description provided for @achievementDiversePickerDesc.
  ///
  /// In en, this message translates to:
  /// **'Practice 5 different species.'**
  String get achievementDiversePickerDesc;

  /// No description provided for @achievementWildlifeExpert.
  ///
  /// In en, this message translates to:
  /// **'Wildlife Expert'**
  String get achievementWildlifeExpert;

  /// No description provided for @achievementWildlifeExpertDesc.
  ///
  /// In en, this message translates to:
  /// **'Practice 10 different species.'**
  String get achievementWildlifeExpertDesc;

  /// No description provided for @achievementCallCollector.
  ///
  /// In en, this message translates to:
  /// **'Call Collector'**
  String get achievementCallCollector;

  /// No description provided for @achievementCallCollectorDesc.
  ///
  /// In en, this message translates to:
  /// **'Practice 15 different unique call types.'**
  String get achievementCallCollectorDesc;

  /// No description provided for @achievementChallenger.
  ///
  /// In en, this message translates to:
  /// **'Challenger'**
  String get achievementChallenger;

  /// No description provided for @achievementChallengerDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete your first daily challenge.'**
  String get achievementChallengerDesc;

  /// No description provided for @achievementThreePeat.
  ///
  /// In en, this message translates to:
  /// **'Three-Peat'**
  String get achievementThreePeat;

  /// No description provided for @achievementThreePeatDesc.
  ///
  /// In en, this message translates to:
  /// **'Achieve a 3-day challenge streak.'**
  String get achievementThreePeatDesc;

  /// No description provided for @achievementWeeklyWarrior.
  ///
  /// In en, this message translates to:
  /// **'Weekly Warrior'**
  String get achievementWeeklyWarrior;

  /// No description provided for @achievementWeeklyWarriorDesc.
  ///
  /// In en, this message translates to:
  /// **'Achieve a 7-day challenge streak.'**
  String get achievementWeeklyWarriorDesc;

  /// No description provided for @achievementTwoWeekTerror.
  ///
  /// In en, this message translates to:
  /// **'Two-Week Terror'**
  String get achievementTwoWeekTerror;

  /// No description provided for @achievementTwoWeekTerrorDesc.
  ///
  /// In en, this message translates to:
  /// **'Maintain a 14-day challenge streak.'**
  String get achievementTwoWeekTerrorDesc;

  /// No description provided for @achievementMonthlyMonster.
  ///
  /// In en, this message translates to:
  /// **'Monthly Monster'**
  String get achievementMonthlyMonster;

  /// No description provided for @achievementMonthlyMonsterDesc.
  ///
  /// In en, this message translates to:
  /// **'30-day challenge streak. Absolutely unhinged.'**
  String get achievementMonthlyMonsterDesc;

  /// No description provided for @achievementChallengeVeteran.
  ///
  /// In en, this message translates to:
  /// **'Challenge Veteran'**
  String get achievementChallengeVeteran;

  /// No description provided for @achievementChallengeVeteranDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete 25 daily challenges total.'**
  String get achievementChallengeVeteranDesc;

  /// No description provided for @achievementSpecialist.
  ///
  /// In en, this message translates to:
  /// **'Specialist'**
  String get achievementSpecialist;

  /// No description provided for @achievementSpecialistDesc.
  ///
  /// In en, this message translates to:
  /// **'Score 85%+ three times on the same call.'**
  String get achievementSpecialistDesc;

  /// No description provided for @achievementMasterOfOne.
  ///
  /// In en, this message translates to:
  /// **'Master of One'**
  String get achievementMasterOfOne;

  /// No description provided for @achievementMasterOfOneDesc.
  ///
  /// In en, this message translates to:
  /// **'Score 90%+ five times on the same call.'**
  String get achievementMasterOfOneDesc;

  /// No description provided for @achievementNightOwl.
  ///
  /// In en, this message translates to:
  /// **'Night Owl'**
  String get achievementNightOwl;

  /// No description provided for @achievementNightOwlDesc.
  ///
  /// In en, this message translates to:
  /// **'Practice between midnight and 5 AM. Sleep is overrated.'**
  String get achievementNightOwlDesc;

  /// No description provided for @achievementEarlyBird.
  ///
  /// In en, this message translates to:
  /// **'Early Bird'**
  String get achievementEarlyBird;

  /// No description provided for @achievementEarlyBirdDesc.
  ///
  /// In en, this message translates to:
  /// **'Practice before 6 AM. The deer are still sleeping.'**
  String get achievementEarlyBirdDesc;

  /// No description provided for @achievementComebackKid.
  ///
  /// In en, this message translates to:
  /// **'Comeback Kid'**
  String get achievementComebackKid;

  /// No description provided for @achievementComebackKidDesc.
  ///
  /// In en, this message translates to:
  /// **'Score below 40%, then score above 85% on the same call.'**
  String get achievementComebackKidDesc;

  /// No description provided for @achievementSpeedDemon.
  ///
  /// In en, this message translates to:
  /// **'Speed Demon'**
  String get achievementSpeedDemon;

  /// No description provided for @achievementSpeedDemonDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete 5 recordings in a single day.'**
  String get achievementSpeedDemonDesc;

  /// No description provided for @achievementTheGrinder.
  ///
  /// In en, this message translates to:
  /// **'The Grinder'**
  String get achievementTheGrinder;

  /// No description provided for @achievementTheGrinderDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete 10 recordings in a single day. Respect.'**
  String get achievementTheGrinderDesc;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — some features may be limited.'**
  String get offlineBanner;

  /// No description provided for @backOnline.
  ///
  /// In en, this message translates to:
  /// **'Back online! Welcome back.'**
  String get backOnline;

  /// No description provided for @premiumRequired.
  ///
  /// In en, this message translates to:
  /// **'Premium Feature'**
  String get premiumRequired;

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to unlock this feature.'**
  String get upgradeToPremium;

  /// No description provided for @globalRankingsTitle.
  ///
  /// In en, this message translates to:
  /// **'GLOBAL RANKINGS'**
  String get globalRankingsTitle;

  /// No description provided for @noGlobalRankingsYet.
  ///
  /// In en, this message translates to:
  /// **'No global rankings yet.'**
  String get noGlobalRankingsYet;

  /// No description provided for @completeCallsToGetRanked.
  ///
  /// In en, this message translates to:
  /// **'Complete calls to get ranked!'**
  String get completeCallsToGetRanked;

  /// No description provided for @callsTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} calls total'**
  String callsTotal(int count);

  /// No description provided for @recordCall.
  ///
  /// In en, this message translates to:
  /// **'RECORD CALL'**
  String get recordCall;

  /// No description provided for @listenReference.
  ///
  /// In en, this message translates to:
  /// **'Listen to Reference'**
  String get listenReference;

  /// No description provided for @startRecording.
  ///
  /// In en, this message translates to:
  /// **'Start Recording'**
  String get startRecording;

  /// No description provided for @resetRecording.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetRecording;

  /// No description provided for @analyzeCall.
  ///
  /// In en, this message translates to:
  /// **'Analyze Call'**
  String get analyzeCall;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// No description provided for @speciesBreakdown.
  ///
  /// In en, this message translates to:
  /// **'SPECIES BREAKDOWN'**
  String get speciesBreakdown;

  /// No description provided for @recentTrend.
  ///
  /// In en, this message translates to:
  /// **'RECENT TREND'**
  String get recentTrend;

  /// No description provided for @sessionsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions ago'**
  String sessionsAgo(int count);

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @noProfileData.
  ///
  /// In en, this message translates to:
  /// **'No profile data'**
  String get noProfileData;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
  }

  throw FlutterError(
      'S.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
