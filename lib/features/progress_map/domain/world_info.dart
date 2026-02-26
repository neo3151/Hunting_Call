import 'package:flutter/material.dart';
import 'package:outcall/features/library/domain/reference_call_model.dart';

// ──────────────────────────────────────────────────────────
//  WORLD INFO
// ──────────────────────────────────────────────────────────

class WorldInfo {
  final String name;
  final String subtitle;
  final String category;
  final String emoji;
  final Color primaryColor;
  final Color accentColor;
  final Color bgColorTop;
  final Color bgColorBot;
  final Color pathColor;
  final Color pathBorder;
  final List<Color> treeColors;
  final List<Color> groundColors;

  const WorldInfo({
    required this.name,
    required this.subtitle,
    required this.category,
    required this.emoji,
    required this.primaryColor,
    required this.accentColor,
    required this.bgColorTop,
    required this.bgColorBot,
    required this.pathColor,
    required this.pathBorder,
    required this.treeColors,
    required this.groundColors,
  });
}

/// All available worlds in the progress map.
const worlds = [
  WorldInfo(
    name: 'MARSHLANDS',
    subtitle: 'Waterfowl',
    category: 'Waterfowl',
    emoji: '🦆',
    primaryColor: Color(0xFF1976D2),
    accentColor: Color(0xFF64B5F6),
    bgColorTop: Color(0xFF0A2E1A),
    bgColorBot: Color(0xFF061A10),
    pathColor: Color(0xFF5D4037),
    pathBorder: Color(0xFF3E2723),
    treeColors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
    groundColors: [Color(0xFF1A3A2A), Color(0xFF0D4420), Color(0xFF2196F3)],
  ),
  WorldInfo(
    name: 'THE RIDGE',
    subtitle: 'Big Game',
    category: 'Big Game',
    emoji: '🦌',
    primaryColor: Color(0xFF8D6E63),
    accentColor: Color(0xFFBCAAA4),
    bgColorTop: Color(0xFF2E1A0E),
    bgColorBot: Color(0xFF1A0F06),
    pathColor: Color(0xFF6D4C41),
    pathBorder: Color(0xFF4E342E),
    treeColors: [Color(0xFF33691E), Color(0xFF558B2F), Color(0xFF689F38)],
    groundColors: [Color(0xFF795548), Color(0xFF6D4C41), Color(0xFF5D4037)],
  ),
  WorldInfo(
    name: 'HOWL CANYON',
    subtitle: 'Predators',
    category: 'Predators',
    emoji: '🐺',
    primaryColor: Color(0xFFE65100),
    accentColor: Color(0xFFFF9800),
    bgColorTop: Color(0xFF1A1206),
    bgColorBot: Color(0xFF120C04),
    pathColor: Color(0xFF795548),
    pathBorder: Color(0xFF4E342E),
    treeColors: [Color(0xFF827717), Color(0xFF9E9D24), Color(0xFF6D4C41)],
    groundColors: [Color(0xFF8D6E63), Color(0xFFBF360C), Color(0xFF6D4C41)],
  ),
  WorldInfo(
    name: 'SHADOW PEAK',
    subtitle: 'Big Cats',
    category: 'Big Cats',
    emoji: '🐆',
    primaryColor: Color(0xFF7B1FA2),
    accentColor: Color(0xFFCE93D8),
    bgColorTop: Color(0xFF1A0A2E),
    bgColorBot: Color(0xFF0D061A),
    pathColor: Color(0xFF4A148C),
    pathBorder: Color(0xFF311B92),
    treeColors: [Color(0xFF1B5E20), Color(0xFF004D40), Color(0xFF006064)],
    groundColors: [Color(0xFF4A148C), Color(0xFF311B92), Color(0xFF1A237E)],
  ),
  WorldInfo(
    name: 'TIMBER HOLLOW',
    subtitle: 'Land Birds',
    category: 'Land Birds',
    emoji: '🐦',
    primaryColor: Color(0xFF2E7D32),
    accentColor: Color(0xFFFF8C00),
    bgColorTop: Color(0xFF0D1A0D),
    bgColorBot: Color(0xFF060F06),
    pathColor: Color(0xFF5D4037),
    pathBorder: Color(0xFF3E2723),
    treeColors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
    groundColors: [Color(0xFF33691E), Color(0xFF1B5E20), Color(0xFF2E7D32)],
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
  if (lower.contains('duck') || lower.contains('mallard') || lower.contains('teal') || lower.contains('pintail') || lower.contains('canvasback')) return '🦆';
  if (lower.contains('elk')) return '🦌';
  if (lower.contains('deer') || lower.contains('whitetail') || lower.contains('mule') || lower.contains('fallow') || lower.contains('caribou') || lower.contains('pronghorn') || lower.contains('red stag')) return '🦌';
  if (lower.contains('turkey')) return '🦃';
  if (lower.contains('coyote') || lower.contains('wolf')) return '🐺';
  if (lower.contains('bobcat') || lower.contains('cougar') || lower.contains('mountain lion') || lower.contains('puma')) return '🐆';
  if (lower.contains('goose')) return '🦆';
  if (lower.contains('owl')) return '🦉';
  if (lower.contains('moose')) return '🦌';
  if (lower.contains('bear')) return '🐻';
  if (lower.contains('fox')) return '🦊';
  if (lower.contains('rabbit')) return '🐰';
  if (lower.contains('raccoon')) return '🦝';
  if (lower.contains('crow')) return '🐦‍⬛';
  if (lower.contains('quail') || lower.contains('pheasant') || lower.contains('woodcock') || lower.contains('dove') || lower.contains('grouse') || lower.contains('awebo') || lower.contains('ptarmigan')) return '🐦';
  if (lower.contains('hog')) return '🐗';
  if (lower.contains('badger')) return '🦡';
  return '🎯';
}
