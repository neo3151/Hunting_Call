
class FreemiumConfig {
  /// These IDs are UNLOCKED in the Free version.
  /// All other calls will be locked.
  static const Set<String> freeCallIds = {
    // Predators/Big Game (Requested Specifics)
    'wolf_howl',
    'wolf_bark',
    'wolf_yelp',
    'wolf_growl',
    'wolf_whine',
    
    'hog_grunt',
    'hog_bark',
    'hog_squeal_loud',
    'hog_squeal',
    
    'coyote_howl',
    'coyote_challenge',
  };
}
