
class FreemiumConfig {
  /// These IDs are UNLOCKED in the Free version.
  /// All other calls will be locked behind Premium.
  static const Set<String> freeCallIds = {
    // Waterfowl
    'duck_mallard_greeting',    // Mallard Greeting
    'goose_canadian_honk',      // Canada Goose Honk
    'duck_wood_duck_whistle',   // Wood Duck Whistle

    // Big Game
    'deer_buck_grunt',          // Whitetail Buck Grunt
    'deer_doe_bleat',           // Whitetail Doe Bleat

    // Predators
    'cougar_scream',            // Puma Scream
    'coyote_howl',              // Coyote Lone Howl
    'rabbit_distress',          // Rabbit Distress
    'red_fox_scream',           // Red Fox Scream

    // Land Birds
    'turkey_gobble',            // Turkey Gobble
    'crow_caw',                 // American Crow Standard Caw
    'dove_coo',                 // Mourning Dove Coo
    'owl_barred_hoot',          // Barred Owl Hoot
    'coyote_yip',               // Coyote Yip
    'awebo_call',               // Awebo (Willow Ptarmigan)
  };
}
