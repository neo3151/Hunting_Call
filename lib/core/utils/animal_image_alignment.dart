import 'package:flutter/painting.dart';

/// Per-image focal point alignment for animal photos.
///
/// When images are cropped via [BoxFit.cover] (e.g. portrait → landscape),
/// the alignment tells Flutter where to anchor the crop. This keeps the
/// animal's face/head visible regardless of container aspect ratio.
///
/// Values range from (-1,-1) top-left to (1,1) bottom-right.
/// (0,0) = center (Flutter default).
///
/// All current images use centered compositions, so most entries
/// use the default center alignment. Only override if needed.
class AnimalImageAlignment {
  AnimalImageAlignment._();

  static const _map = <String, Alignment>{
    // Most images have centered face compositions.
    // Only add overrides here if an image needs a non-center anchor.
    'barred_owl.jpg':        Alignment(0.0, -0.2),  // face centered, slightly north
    'black_bear.jpg':        Alignment(0.0, 0.3),   // head in lower-half, centering eyes/ears 
    'cottontail_rabbit.jpg': Alignment(0.0, -0.3),  // ears clipped at top
    'coyote.jpg':            Alignment(0.0, -0.3),  // ears clipped at top
    'elk.jpg':               Alignment(0.0, 0.4),   // head is lower, shift up
    'crow.jpg':              Alignment(0.0, -0.4),  // head is upper-center
    'fallow_deer.jpg':       Alignment(0.0, 0.4),   // head/antlers, shift face up
    'great_horned_owl.jpg':   Alignment(0.0, -0.6),  // head is high
    'mourning_dove.jpg':     Alignment(0.0, -0.4),  // head is high
    'quail.jpg':             Alignment(0.0, -0.4),  // plume/head is high
    'specklebelly_goose.jpg': Alignment(0.0, -0.7),  // head is at very top
    'turkey.jpg':            Alignment(0.0, -0.4),  // head is high
    'willow_ptarmigan.jpg':   Alignment(0.0, -0.3),  // head is upper-center
    'woodcock.jpg':          Alignment(0.0, -0.4),  // head is high
  };

  /// Returns the optimal [Alignment] for the given image path,
  /// ensuring the animal's face stays visible when cropped.
  ///
  /// Falls back to [Alignment.center] for unknown images.
  static Alignment forImage(String imageUrl) {
    // Extract filename from path like "assets/images/animals/badger.jpg"
    final filename = imageUrl.split('/').last;
    return _map[filename] ?? Alignment.center;
  }
}
