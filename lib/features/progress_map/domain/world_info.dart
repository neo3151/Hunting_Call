import 'package:flutter/material.dart';
import 'package:outcall/features/library/domain/reference_call_model.dart';

// ──────────────────────────────────────────────────────────
//  WORLD INFO
// ──────────────────────────────────────────────────────────

class WorldInfo {
  final String name;
  final String subtitle;
  final String emoji;
  final Color primaryColor;
  final Color accentColor;
  final Color bgColorTop;
  final Color bgColorBot;
  final Color pathColor;
  final Color pathBorder;
  final List<Color> treeColors;
  final List<Color> groundColors;

  /// Which animal names belong to this world.
  final List<String> animalNames;

  /// Which categories belong to this world (used when animalNames is empty).
  final List<String> categories;

  const WorldInfo({
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.primaryColor,
    required this.accentColor,
    required this.bgColorTop,
    required this.bgColorBot,
    required this.pathColor,
    required this.pathBorder,
    required this.treeColors,
    required this.groundColors,
    this.animalNames = const [],
    this.categories = const [],
  });

  /// Returns true if the given call belongs to this world.
  bool containsCall(ReferenceCall call) {
    if (animalNames.isNotEmpty) {
      return animalNames.contains(call.animalName);
    }
    if (categories.isNotEmpty) {
      return categories.contains(call.category);
    }
    return false;
  }
}

/// All available worlds in the progress map.
/// Balanced to ~10-14 calls per world for an even progression.
const worlds = [
  // ─── W1: MARSHLANDS — Dabbling Ducks (11 calls) ───────
  // Mallard(8) + Gadwall(3) = 11
  WorldInfo(
    name: 'MARSHLANDS',
    subtitle: 'Dabbling Ducks',
    emoji: '🦆',
    primaryColor: Color(0xFF1976D2),
    accentColor: Color(0xFF64B5F6),
    bgColorTop: Color(0xFF0A2E1A),
    bgColorBot: Color(0xFF061A10),
    pathColor: Color(0xFF5D4037),
    pathBorder: Color(0xFF3E2723),
    treeColors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
    groundColors: [Color(0xFF1A3A2A), Color(0xFF0D4420), Color(0xFF2196F3)],
    animalNames: ['Mallard Duck', 'Gadwall'],
  ),

  // ─── W2: TIDEWATER BAY — Teal & Small Ducks (13 calls) ──
  // BW Teal(4) + GW Teal(4) + Wigeon(2) + Bufflehead(3) = 13
  WorldInfo(
    name: 'TIDEWATER BAY',
    subtitle: 'Teal & Small Ducks',
    emoji: '🌊',
    primaryColor: Color(0xFF00897B),
    accentColor: Color(0xFF80CBC4),
    bgColorTop: Color(0xFF0A1E2E),
    bgColorBot: Color(0xFF061018),
    pathColor: Color(0xFF4E6B5A),
    pathBorder: Color(0xFF2E4A3A),
    treeColors: [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF00796B)],
    groundColors: [Color(0xFF1A3040), Color(0xFF0D2440), Color(0xFF00838F)],
    animalNames: ['Blue-Winged Teal', 'Green-Winged Teal', 'American Wigeon', 'Bufflehead'],
  ),

  // ─── W3: BAYOU CROSSING — Wood Ducks & Exotics (11 calls) ──
  // Wood Duck(5) + N. Shoveler(3) + Canvasback(1) + Muscovy(1) + Fulvous(1) = 11
  WorldInfo(
    name: 'BAYOU CROSSING',
    subtitle: 'Wood Ducks & Exotics',
    emoji: '🪶',
    primaryColor: Color(0xFF5D4037),
    accentColor: Color(0xFFA1887F),
    bgColorTop: Color(0xFF1A1A0E),
    bgColorBot: Color(0xFF0F0F06),
    pathColor: Color(0xFF4E342E),
    pathBorder: Color(0xFF3E2723),
    treeColors: [Color(0xFF33691E), Color(0xFF558B2F), Color(0xFF4E342E)],
    groundColors: [Color(0xFF3E2723), Color(0xFF4E342E), Color(0xFF5D4037)],
    animalNames: ['Wood Duck', 'Northern Shoveler', 'Canvasback Duck', 'Muscovy Duck', 'Fulvous Whistling-Duck'],
  ),

  // ─── W4: FLYWAY DELTA — Geese (4 calls → starter world) ──
  // Canada Goose(2) + Specklebelly(2) = 4
  // Small but acts as a "breather" world before Big Game
  WorldInfo(
    name: 'FLYWAY DELTA',
    subtitle: 'Geese',
    emoji: '🪿',
    primaryColor: Color(0xFF546E7A),
    accentColor: Color(0xFF90A4AE),
    bgColorTop: Color(0xFF1A2420),
    bgColorBot: Color(0xFF0F1A14),
    pathColor: Color(0xFF5D6037),
    pathBorder: Color(0xFF3E4023),
    treeColors: [Color(0xFF33691E), Color(0xFF558B2F), Color(0xFF689F38)],
    groundColors: [Color(0xFF37474F), Color(0xFF455A64), Color(0xFF546E7A)],
    animalNames: ['Canada Goose', 'Specklebelly Goose'],
  ),

  // ─── W5: THE RIDGE — Big Game (12 calls) ──────────────
  // Elk(3) + Whitetail(3) + Fallow(2) + Mule(2) + Hog(2) = 12

  WorldInfo(
    name: 'THE RIDGE',
    subtitle: 'Big Game',
    emoji: '🦌',
    primaryColor: Color(0xFF8D6E63),
    accentColor: Color(0xFFBCAAA4),
    bgColorTop: Color(0xFF2E1A0E),
    bgColorBot: Color(0xFF1A0F06),
    pathColor: Color(0xFF6D4C41),
    pathBorder: Color(0xFF4E342E),
    treeColors: [Color(0xFF33691E), Color(0xFF558B2F), Color(0xFF689F38)],
    groundColors: [Color(0xFF795548), Color(0xFF6D4C41), Color(0xFF5D4037)],
    categories: ['Big Game'],
  ),

  // ─── W6: HOWL CANYON — Pack Hunters (12 calls) ─────────
  // Coyote(3) + Wolf(2) + Fox(2) + Arctic Fox(1) + Bear(2) + Rabbit(2) = 12
  WorldInfo(
    name: 'HOWL CANYON',
    subtitle: 'Pack Hunters',
    emoji: '🐺',
    primaryColor: Color(0xFFE65100),
    accentColor: Color(0xFFFF9800),
    bgColorTop: Color(0xFF1A1206),
    bgColorBot: Color(0xFF120C04),
    pathColor: Color(0xFF795548),
    pathBorder: Color(0xFF4E342E),
    treeColors: [Color(0xFF827717), Color(0xFF9E9D24), Color(0xFF6D4C41)],
    groundColors: [Color(0xFF8D6E63), Color(0xFFBF360C), Color(0xFF6D4C41)],
    animalNames: ['Coyote', 'Gray Wolf', 'Red Fox', 'Arctic Fox', 'Black Bear', 'Cottontail Rabbit'],
  ),

  // ─── W7: SHADOW PEAK — Stalkers (11 calls) ────────────
  // Bobcat(3) + Puma(4) + Lion(1) + Raccoon(2) + Badger(1) = 11
  WorldInfo(
    name: 'SHADOW PEAK',
    subtitle: 'Stalkers',
    emoji: '🐆',
    primaryColor: Color(0xFF7B1FA2),
    accentColor: Color(0xFFCE93D8),
    bgColorTop: Color(0xFF1A0A2E),
    bgColorBot: Color(0xFF0D061A),
    pathColor: Color(0xFF4A148C),
    pathBorder: Color(0xFF311B92),
    treeColors: [Color(0xFF1B5E20), Color(0xFF004D40), Color(0xFF006064)],
    groundColors: [Color(0xFF4A148C), Color(0xFF311B92), Color(0xFF1A237E)],
    animalNames: ['Bobcat', 'Puma', 'Lion', 'Raccoon', 'American Badger'],
  ),

  // ─── W8: TIMBER HOLLOW — Birds (15 calls) ────────
  // Turkey(5) + Crow(3) + Barred Owl(1) + Great Horned Owl(1) +
  // Quail(1) + Pheasant(1) + Woodcock(1) + Dove(1) + Awebo(1) = 15
  WorldInfo(
    name: 'TIMBER HOLLOW',
    subtitle: 'Birds',
    emoji: '🐦',
    primaryColor: Color(0xFF2E7D32),
    accentColor: Color(0xFFFF8C00),
    bgColorTop: Color(0xFF0D1A0D),
    bgColorBot: Color(0xFF060F06),
    pathColor: Color(0xFF5D4037),
    pathBorder: Color(0xFF3E2723),
    treeColors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
    groundColors: [Color(0xFF33691E), Color(0xFF1B5E20), Color(0xFF2E7D32)],
    animalNames: [
      'Wild Turkey', 'American Crow', 'Barred Owl', 'Great Horned Owl',
      'Bobwhite Quail', 'Ring-Necked Pheasant', 'American Woodcock',
      'Mourning Dove', 'Awebo',
    ],
  ),
];

// ──────────────────────────────────────────────────────────
//  NODE STATE
// ──────────────────────────────────────────────────────────

enum NodeState { mastered, current, available, locked }

class MapNode {
  final ReferenceCall call;
  final int index;
  final Offset position;
  NodeState state;
  int? bestScore;

  MapNode({
    required this.call,
    required this.index,
    required this.position,
    this.state = NodeState.available,
    this.bestScore,
  });
}

// ──────────────────────────────────────────────────────────
//  UTILITY
// ──────────────────────────────────────────────────────────

/// Maps animal names to emoji for map display.
String getAnimalEmoji(String animalName) {
  final lower = animalName.toLowerCase();
  if (lower.contains('mallard') || lower.contains('canvasback') || lower.contains('shoveler') || lower.contains('gadwall')) return '🦆';
  if (lower.contains('teal') || lower.contains('wigeon') || lower.contains('bufflehead')) return '🦆';
  if (lower.contains('wood duck')) return '🦆';
  if (lower.contains('muscovy') || lower.contains('fulvous')) return '🦆';
  if (lower.contains('goose')) return '🪿';
  if (lower.contains('elk')) return '🦌';
  if (lower.contains('deer') || lower.contains('whitetail') || lower.contains('mule') || lower.contains('fallow')) return '🦌';
  if (lower.contains('turkey')) return '🦃';
  if (lower.contains('coyote') || lower.contains('wolf')) return '🐺';
  if (lower.contains('bobcat') || lower.contains('cougar') || lower.contains('puma')) return '🐆';
  if (lower.contains('lion')) return '🦁';
  if (lower.contains('owl')) return '🦉';
  if (lower.contains('bear')) return '🐻';
  if (lower.contains('fox')) return '🦊';
  if (lower.contains('rabbit')) return '🐰';
  if (lower.contains('raccoon')) return '🦝';
  if (lower.contains('crow')) return '🐦‍⬛';
  if (lower.contains('quail') || lower.contains('pheasant') || lower.contains('woodcock') || lower.contains('dove') || lower.contains('grouse') || lower.contains('ptarmigan')) return '🐦';
  if (lower.contains('hog')) return '🐗';
  if (lower.contains('badger')) return '🦡';
  if (lower.contains('awebo')) return '✨';
  return '🎯';
}
