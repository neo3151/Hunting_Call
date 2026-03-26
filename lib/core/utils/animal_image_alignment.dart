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
    'barred_owl.webp':        Alignment(0.0, -0.2),  // face centered, slightly north
    'black_bear.webp':        Alignment(0.0, 0.3),   // head in lower-half, centering eyes/ears 
    'cottontail_rabbit.webp': Alignment(0.0, -0.3),  // ears clipped at top
    'coyote.webp':            Alignment(0.0, -0.3),  // ears clipped at top
    'elk.webp':               Alignment(0.0, 0.4),   // head is lower, shift up
    'crow.webp':              Alignment(0.0, -0.4),  // head is upper-center
    'fallow_deer.webp':       Alignment(0.0, 0.4),   // head/antlers, shift face up
    'great_horned_owl.webp':   Alignment(0.0, -0.6),  // head is high
    'mourning_dove.webp':     Alignment(0.0, -0.4),  // head is high
    'quail.webp':             Alignment(0.0, -0.4),  // plume/head is high
    'specklebelly_goose.webp': Alignment(0.0, -0.7),  // head is at very top
    'turkey.webp':            Alignment(0.0, -0.4),  // head is high
    'willow_ptarmigan.webp':   Alignment(0.0, -0.3),  // head is upper-center
    'woodcock.webp':          Alignment(0.0, -0.4),  // head is high
  };

  /// Returns the optimal [Alignment] for the given image path,
  /// ensuring the animal's face stays visible when cropped.
  ///
  /// Falls back to [Alignment.center] for unknown images.
  static Alignment forImage(String imageUrl) {
    // Extract filename from path like "assets/images/animals/badger.webp"
    final filename = imageUrl.split('/').last;
    return _map[filename] ?? Alignment.center;
  }
}
