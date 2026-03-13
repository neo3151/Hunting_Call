import 'dart:math' as math;

/// Bayesian post-processing layer for BirdNET classification.
///
/// Combines the model's blind species predictions with contextual priors
/// (what species the user selected from the library) to produce more
/// accurate classification results. Pure Dart math — zero dependencies.
class BayesianFusionService {
  /// The multiplicative boost applied to species that match the reference.
  /// A value of 10 means "we consider this species 10× more likely a priori
  /// because the user explicitly chose it from the library."
  static const double _priorBoost = 10.0;

  /// Minimum confidence floor (%) after fusion. Results below this are dropped.
  static const double _confidenceFloor = 5.0;

  /// Apply Bayesian priors to BirdNET's raw classification results.
  ///
  /// [rawResults] — BirdNET output: label → confidence (0-100%).
  /// [scientificName] — e.g. "Meleagris gallopavo" from [ReferenceCall].
  /// [commonName] — e.g. "Wild Turkey" from [ReferenceCall].
  ///
  /// Returns a new map with Bayesian-adjusted confidences, sorted descending.
  /// If no reference context is provided, returns [rawResults] unchanged.
  static Map<String, double> applyPriors({
    required Map<String, double> rawResults,
    String? scientificName,
    String? commonName,
  }) {
    // No context → passthrough (backwards-compatible)
    if (rawResults.isEmpty ||
        (scientificName == null || scientificName.isEmpty) &&
            (commonName == null || commonName.isEmpty)) {
      return rawResults;
    }

    final scientificLower = scientificName?.toLowerCase() ?? '';
    final commonLower = commonName?.toLowerCase() ?? '';

    // Step 1: Compute unnormalized posteriors
    //   posterior_i = likelihood_i × prior_i
    // where likelihood = raw sigmoid confidence, prior = boost if label matches
    final Map<String, double> posteriors = {};
    double posteriorSum = 0.0;

    for (final entry in rawResults.entries) {
      final labelLower = entry.key.toLowerCase();
      final likelihood = entry.value; // already 0-100

      // Check if this BirdNET label matches the reference species.
      // BirdNET labels look like "Wild Turkey", "Red Junglefowl", etc.
      // (scientific prefix is stripped during label formatting in BioacousticScorer)
      final bool isMatch = _labelMatchesReference(
        labelLower,
        scientificLower,
        commonLower,
      );

      final prior = isMatch ? _priorBoost : 1.0;
      final posterior = likelihood * prior;

      posteriors[entry.key] = posterior;
      posteriorSum += posterior;
    }

    // Step 2: Re-normalize so percentages are proportional
    if (posteriorSum == 0) return rawResults;

    // We want to preserve the original scale feeling (not force sum-to-100),
    // so we scale relative to the original total, not to 100.
    final double originalSum =
        rawResults.values.fold(0.0, (sum, v) => sum + v);
    final double scaleFactor = originalSum / posteriorSum;

    final Map<String, double> result = {};
    for (final entry in posteriors.entries) {
      final scaled = entry.value * scaleFactor;
      // Cap at 99% to avoid false certainty
      final capped = math.min(scaled, 99.0);
      if (capped >= _confidenceFloor) {
        result[entry.key] = capped;
      }
    }

    // Sort descending by confidence
    final sorted = Map.fromEntries(
      result.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );

    return sorted;
  }

  /// Fuzzy substring matching: does this BirdNET label refer to the same
  /// species as the reference?
  static bool _labelMatchesReference(
    String labelLower,
    String scientificLower,
    String commonLower,
  ) {
    // Direct substring match against common name
    if (commonLower.isNotEmpty && labelLower.contains(commonLower)) return true;
    if (commonLower.isNotEmpty && commonLower.contains(labelLower)) return true;

    // Match key tokens (e.g. "Turkey" in "Wild Turkey" matches "Hen Yelp" label "Turkey")
    if (commonLower.isNotEmpty) {
      final commonTokens = commonLower.split(RegExp(r'\s+'));
      for (final token in commonTokens) {
        if (token.length >= 4 && labelLower.contains(token)) return true;
      }
    }

    // Scientific name match (BirdNET raw labels contain scientific names before the _)
    // Even though we strip them in formatting, check just in case
    if (scientificLower.isNotEmpty) {
      final genusSpecies = scientificLower.split(RegExp(r'\s+'));
      for (final part in genusSpecies) {
        if (part.length >= 4 && labelLower.contains(part)) return true;
      }
    }

    return false;
  }
}
