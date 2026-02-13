import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hunting_calls_perfection/di_providers.dart';
import '../../library/data/reference_database.dart';
import '../../library/domain/reference_call_model.dart';
import '../../profile/domain/profile_model.dart';
import '../../recording/presentation/recorder_page.dart';

// ──────────────────────────────────────────────────────────
//  WORLD DATA
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

const _worlds = [
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
    accentColor: Color(0xFF81C784),
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
//  PROGRESS MAP SCREEN
// ──────────────────────────────────────────────────────────

class ProgressMapScreen extends ConsumerStatefulWidget {
  final String userId;
  const ProgressMapScreen({super.key, required this.userId});

  @override
  ConsumerState<ProgressMapScreen> createState() => _ProgressMapScreenState();
}

class _ProgressMapScreenState extends ConsumerState<ProgressMapScreen>
    with TickerProviderStateMixin {
  int _selectedWorld = 0;
  List<List<MapNode>> _worldNodes = [];
  bool _isLoading = true;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  MapNode? _selectedNode;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _loadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await ReferenceDatabase.init();
      final profile = await ref
          .read(profileRepositoryProvider)
          .getProfile(widget.userId);

      // Best scores from history
      final Map<String, int> bestScores = {};
      for (final h in profile.history) {
        final score = h.result.score.toInt();
        final prev = bestScores[h.animalId] ?? 0;
        if (score > prev) bestScores[h.animalId] = score;
      }

      _worldNodes = [];
      for (final world in _worlds) {
        final calls = ReferenceDatabase.calls
            .where((c) => c.category == world.category)
            .toList();
        final nodes = <MapNode>[];
        for (int i = 0; i < calls.length; i++) {
          final call = calls[i];
          final score = bestScores[call.id];
          NodeState state;
          if (score != null && score >= 70) {
            state = NodeState.mastered;
          } else {
            state = NodeState.available;
          }
          nodes.add(MapNode(
            call: call,
            index: i + 1,
            position: _getNodePosition(i, calls.length),
            state: state,
            bestScore: score,
          ));
        }

        // Mark first non-mastered as current
        bool foundCurrent = false;
        for (final n in nodes) {
          if (n.state == NodeState.available && !foundCurrent) {
            n.state = NodeState.current;
            foundCurrent = true;
          }
        }

        // Lock premium calls
        for (final n in nodes) {
          if (ReferenceDatabase.isLocked(n.call.id, profile.isPremium)) {
            if (n.state != NodeState.mastered) {
              n.state = NodeState.locked;
            }
          }
        }

        _worldNodes.add(nodes);
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('ProgressMap Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Offset _getNodePosition(int index, int total) {
    const int cols = 3;
    const double padX = 0.15;
    const double padTop = 0.10;
    const double padBot = 0.06;

    final int row = index ~/ cols;
    final int col = index % cols;
    final int totalRows = (total / cols).ceil();
    final bool leftToRight = row.isEven;
    final double colFraction = cols > 1 ? col / (cols - 1) : 0.5;
    final double x =
        padX + (1 - 2 * padX) * (leftToRight ? colFraction : 1 - colFraction);
    final double rowSpacing =
        totalRows > 1 ? (1 - padTop - padBot) / totalRows : 0.4;
    final double y = padTop + rowSpacing * (row + 0.5);

    // Add slight jitter for organic feel
    final rng = Random(index * 7 + total * 13);
    final jitterX = (rng.nextDouble() - 0.5) * 0.04;
    final jitterY = (rng.nextDouble() - 0.5) * 0.02;

    return Offset(
      (x + jitterX).clamp(0.1, 0.9),
      (y + jitterY).clamp(0.05, 0.95),
    );
  }

  @override
  Widget build(BuildContext context) {
    final world = _worlds[_selectedWorld];

    return Scaffold(
      backgroundColor: world.bgColorBot,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildTopBar(world),
            _buildWorldTabs(),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Color(0xFF81C784)),
                          const SizedBox(height: 16),
                          Text('Loading world...', style: GoogleFonts.pressStart2p(color: Colors.white38, fontSize: 8)),
                        ],
                      ),
                    )
                  : _worldNodes.isEmpty
                      ? Center(child: Text('No calls found', style: GoogleFonts.oswald(color: Colors.white54)))
                      : _buildWorldMap(),
            ),
            if (_selectedNode != null) _buildDetailCard(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  TOP BAR
  // ═══════════════════════════════════════════════

  Widget _buildTopBar(WorldInfo world) {
    final nodes = _worldNodes.isNotEmpty ? _worldNodes[_selectedWorld] : <MapNode>[];
    final mastered = nodes.where((n) => n.state == NodeState.mastered).length;
    final total = nodes.length;
    final progressPct = total > 0 ? mastered / total : 0.0;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 12,
        right: 12,
        bottom: 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            world.primaryColor.withValues(alpha: 0.95),
            world.primaryColor.withValues(alpha: 0.6),
            world.bgColorTop,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: world.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Back
              Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'WORLD ${_selectedWorld + 1}',
                            style: GoogleFonts.pressStart2p(color: world.accentColor, fontSize: 7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          world.subtitle.toUpperCase(),
                          style: GoogleFonts.pressStart2p(color: Colors.white38, fontSize: 6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      world.name,
                      style: GoogleFonts.pressStart2p(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.2,
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 6),
                          Shadow(color: world.primaryColor.withValues(alpha: 0.5), blurRadius: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Emoji
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                  border: Border.all(color: world.accentColor.withValues(alpha: 0.4), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(world.emoji, style: const TextStyle(fontSize: 24)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          Row(
            children: [
              Icon(Icons.star, color: Colors.amberAccent, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      height: 8,
                      width: (MediaQuery.of(context).size.width - 100) * progressPct,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amberAccent, world.accentColor],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(color: Colors.amberAccent.withValues(alpha: 0.4), blurRadius: 6),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$mastered/$total',
                style: GoogleFonts.pressStart2p(color: Colors.amberAccent, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  WORLD TABS
  // ═══════════════════════════════════════════════

  Widget _buildWorldTabs() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.black38,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: _worlds.length,
        itemBuilder: (ctx, i) {
          final w = _worlds[i];
          final selected = i == _selectedWorld;
          final mastered = _worldNodes.length > i
              ? _worldNodes[i].where((n) => n.state == NodeState.mastered).length
              : 0;
          final total = _worldNodes.length > i ? _worldNodes[i].length : 0;

          return GestureDetector(
            onTap: () => setState(() {
              _selectedWorld = i;
              _selectedNode = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(colors: [
                        w.primaryColor.withValues(alpha: 0.9),
                        w.primaryColor.withValues(alpha: 0.6),
                      ])
                    : null,
                color: selected ? null : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? w.accentColor.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.1),
                  width: selected ? 1.5 : 1,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: w.primaryColor.withValues(alpha: 0.3), blurRadius: 8)]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(w.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'W${i + 1}',
                        style: GoogleFonts.pressStart2p(
                          color: selected ? Colors.white : Colors.white54,
                          fontSize: 8,
                        ),
                      ),
                      if (total > 0)
                        Text(
                          '$mastered/$total',
                          style: GoogleFonts.pressStart2p(
                            color: selected ? w.accentColor : Colors.white30,
                            fontSize: 6,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  WORLD MAP
  // ═══════════════════════════════════════════════

  Widget _buildWorldMap() {
    final nodes = _worldNodes[_selectedWorld];
    final world = _worlds[_selectedWorld];

    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;

      return AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _glowController, _particleController]),
        builder: (context, _) {
          return GestureDetector(
            onTap: () => setState(() => _selectedNode = null),
            child: Stack(
              children: [
                // Background + decorations + path
                CustomPaint(
                  size: size,
                  painter: _WorldMapPainter(
                    nodes: nodes,
                    world: world,
                    pulseValue: _pulseController.value,
                    glowValue: _glowController.value,
                    particleValue: _particleController.value,
                  ),
                ),

                // Node widgets
                ...nodes.map((node) => _buildNodeWidget(node, size, world)),

                // START banner
                if (nodes.isNotEmpty)
                  _buildStartBanner(nodes.first, size),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildStartBanner(MapNode firstNode, Size mapSize) {
    final x = mapSize.width * firstNode.position.dx;
    final y = mapSize.height * firstNode.position.dy - 48;

    return Positioned(
      left: x - 28,
      top: y,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFF5252), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 8),
            const BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Text(
          'START',
          style: GoogleFonts.pressStart2p(
            color: Colors.white,
            fontSize: 7,
            shadows: [const Shadow(color: Colors.black, blurRadius: 2)],
          ),
        ),
      ),
    );
  }

  Widget _buildNodeWidget(MapNode node, Size mapSize, WorldInfo world) {
    final x = mapSize.width * node.position.dx;
    final y = mapSize.height * node.position.dy;
    const double nodeRadius = 28;

    final isCurrent = node.state == NodeState.current;
    final isMastered = node.state == NodeState.mastered;
    final isLocked = node.state == NodeState.locked;
    final isSelected = _selectedNode == node;

    // Pulse scale for current node
    final scale = isCurrent ? 0.9 + _pulseController.value * 0.2 : 1.0;
    // Glow intensity
    final glowIntensity = _glowController.value;

    Color bgColor;
    Color borderColor;
    double borderWidth;

    if (isMastered) {
      bgColor = const Color(0xFF1B5E20);
      borderColor = const Color(0xFF4CAF50);
      borderWidth = 3;
    } else if (isCurrent) {
      bgColor = world.primaryColor;
      borderColor = world.accentColor;
      borderWidth = 3;
    } else if (isLocked) {
      bgColor = const Color(0xFF37474F).withValues(alpha: 0.6);
      borderColor = Colors.grey.shade700;
      borderWidth = 2;
    } else {
      bgColor = const Color(0xFF37474F);
      borderColor = Colors.white38;
      borderWidth = 2;
    }

    if (isSelected) {
      borderColor = Colors.amberAccent;
      borderWidth = 3.5;
    }

    return Positioned(
      left: x - nodeRadius,
      top: y - nodeRadius,
      child: GestureDetector(
        onTap: () {
          if (!isLocked) {
            setState(() {
              _selectedNode = _selectedNode == node ? null : node;
            });
          }
        },
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: nodeRadius * 2,
            height: nodeRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  bgColor.withValues(alpha: 0.9),
                  bgColor,
                  bgColor.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: [
                // Outer glow
                if (isCurrent)
                  BoxShadow(
                    color: world.primaryColor.withValues(alpha: 0.3 + glowIntensity * 0.3),
                    blurRadius: 16 + glowIntensity * 8,
                    spreadRadius: 2,
                  ),
                if (isMastered)
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.2 + glowIntensity * 0.15),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                if (isSelected)
                  BoxShadow(
                    color: Colors.amberAccent.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                // Drop shadow
                const BoxShadow(
                  color: Colors.black54,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Inner ring
                Container(
                  width: nodeRadius * 2 - 10,
                  height: nodeRadius * 2 - 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isMastered ? Colors.green : isLocked ? Colors.grey.shade700 : Colors.white).withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                ),
                // Content
                if (isLocked)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, color: Colors.white24, size: 16),
                      Text(
                        '${node.index}',
                        style: GoogleFonts.pressStart2p(color: Colors.white.withValues(alpha: 0.2), fontSize: 6),
                      ),
                    ],
                  )
                else if (isMastered)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getAnimalEmoji(node.call.animalName),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 1),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 8),
                      ),
                    ],
                  )
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getAnimalEmoji(node.call.animalName),
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        '${node.index}',
                        style: GoogleFonts.pressStart2p(
                          color: isCurrent ? Colors.white : Colors.white54,
                          fontSize: 7,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  DETAIL CARD
  // ═══════════════════════════════════════════════

  Widget _buildDetailCard() {
    final node = _selectedNode!;
    final world = _worlds[_selectedWorld];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E1E1E),
            const Color(0xFF252525),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: world.primaryColor.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(color: world.primaryColor.withValues(alpha: 0.2), blurRadius: 12),
          const BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Score/emoji circle
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  world.primaryColor.withValues(alpha: 0.3),
                  world.primaryColor.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(color: world.primaryColor.withValues(alpha: 0.5), width: 2),
            ),
            alignment: Alignment.center,
            child: node.state == NodeState.mastered
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${node.bestScore ?? 0}',
                        style: GoogleFonts.pressStart2p(color: Colors.greenAccent, fontSize: 12),
                      ),
                      const Icon(Icons.star, color: Colors.amberAccent, size: 10),
                    ],
                  )
                : Text(
                    _getAnimalEmoji(node.call.animalName),
                    style: const TextStyle(fontSize: 26),
                  ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: world.primaryColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'STAGE ${node.index}',
                        style: GoogleFonts.pressStart2p(color: world.accentColor, fontSize: 6),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildDifficultyChip(node.call.difficulty),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  node.call.animalName,
                  style: GoogleFonts.oswald(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  node.call.callType,
                  style: GoogleFonts.lato(color: Colors.white54, fontSize: 12),
                ),
                if (node.bestScore != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.amberAccent, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Best Score: ${node.bestScore}',
                        style: GoogleFonts.lato(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Play button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecorderPage(
                    userId: widget.userId,
                    preselectedAnimalId: node.call.id,
                  ),
                ),
              );
            },
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [world.primaryColor, world.primaryColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: world.accentColor.withValues(alpha: 0.5), width: 2),
                boxShadow: [
                  BoxShadow(color: world.primaryColor.withValues(alpha: 0.4), blurRadius: 10),
                  const BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = const Color(0xFF66BB6A);
        break;
      case 'intermediate':
        color = const Color(0xFFFFCA28);
        break;
      case 'pro':
      case 'hard':
        color = const Color(0xFFEF5350);
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: GoogleFonts.pressStart2p(color: color, fontSize: 5),
      ),
    );
  }

  String _getAnimalEmoji(String animalName) {
    final lower = animalName.toLowerCase();
    if (lower.contains('duck') || lower.contains('mallard') || lower.contains('teal') || lower.contains('pintail') || lower.contains('canvasback')) return '🦆';
    if (lower.contains('elk')) return '🦌';
    if (lower.contains('deer') || lower.contains('whitetail') || lower.contains('mule') || lower.contains('fallow') || lower.contains('caribou') || lower.contains('pronghorn') || lower.contains('red stag')) return '🦌';
    if (lower.contains('turkey')) return '🦃';
    if (lower.contains('coyote') || lower.contains('wolf')) return '🐺';
    if (lower.contains('goose')) return '🦆';
    if (lower.contains('owl')) return '🦉';
    if (lower.contains('moose')) return '🦌';
    if (lower.contains('bear')) return '🐻';
    if (lower.contains('fox')) return '🦊';
    if (lower.contains('bobcat') || lower.contains('cougar') || lower.contains('mountain lion') || lower.contains('puma')) return '🐆';
    if (lower.contains('rabbit')) return '🐰';
    if (lower.contains('raccoon')) return '🦝';
    if (lower.contains('crow')) return '🐦‍⬛';
    if (lower.contains('quail') || lower.contains('pheasant') || lower.contains('woodcock') || lower.contains('dove') || lower.contains('grouse') || lower.contains('awebo') || lower.contains('ptarmigan')) return '🐦';
    if (lower.contains('hog')) return '🐗';
    if (lower.contains('badger')) return '🦡';
    return '🎯';
  }
}

// ──────────────────────────────────────────────────────────
//  CUSTOM PAINTER
// ──────────────────────────────────────────────────────────

class _WorldMapPainter extends CustomPainter {
  final List<MapNode> nodes;
  final WorldInfo world;
  final double pulseValue;
  final double glowValue;
  final double particleValue;

  _WorldMapPainter({
    required this.nodes,
    required this.world,
    required this.pulseValue,
    required this.glowValue,
    required this.particleValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawGroundPatches(canvas, size);
    _drawDecorations(canvas, size);
    if (nodes.length >= 2) _drawPath(canvas, size);
    _drawParticles(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    // Base gradient
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [world.bgColorTop, world.bgColorBot, world.bgColorTop.withValues(alpha: 0.8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle hex grid texture
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.015)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (double y = 0; y < size.height; y += 40) {
      for (double x = 0; x < size.width; x += 35) {
        final offset = (y ~/ 40).isOdd ? 17.5 : 0.0;
        _drawHex(canvas, Offset(x + offset, y), 12, gridPaint);
      }
    }

    // Vignette overlay
    final vigPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.4),
        ],
        stops: const [0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vigPaint);
  }

  void _drawHex(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * pi / 180;
      final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawGroundPatches(Canvas canvas, Size size) {
    final rng = Random(world.name.hashCode + 42);
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw larger ground patches (grass, dirt, water)
    for (int i = 0; i < 12; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height;

      bool tooClose = false;
      for (final n in nodes) {
        final nx = n.position.dx * size.width;
        final ny = n.position.dy * size.height;
        if ((cx - nx).abs() < 60 && (cy - ny).abs() < 60) {
          tooClose = true;
          break;
        }
      }
      if (tooClose) continue;

      paint.color = world.groundColors[rng.nextInt(world.groundColors.length)]
          .withValues(alpha: 0.08 + rng.nextDouble() * 0.12);

      final w = 30.0 + rng.nextDouble() * 60;
      final h = 20.0 + rng.nextDouble() * 40;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rng.nextDouble() * 0.3);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        paint,
      );
      canvas.restore();
    }
  }

  void _drawDecorations(Canvas canvas, Size size) {
    final rng = Random(world.name.hashCode + 99);

    // Large trees (bushy, layered)
    for (int i = 0; i < 18; i++) {
      final tx = rng.nextDouble() * size.width;
      final ty = rng.nextDouble() * size.height;

      bool tooClose = false;
      for (final n in nodes) {
        final nx = n.position.dx * size.width;
        final ny = n.position.dy * size.height;
        if ((tx - nx).abs() < 55 && (ty - ny).abs() < 55) {
          tooClose = true;
          break;
        }
      }
      if (tooClose) continue;

      final treeHeight = 12.0 + rng.nextDouble() * 18;
      final treeColor = world.treeColors[rng.nextInt(world.treeColors.length)];
      final alpha = 0.25 + rng.nextDouble() * 0.35;

      // Shadow
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(tx + 2, ty + treeHeight * 0.5 + 3),
          width: treeHeight * 0.8,
          height: treeHeight * 0.2,
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.15),
      );

      // Trunk
      final trunkPaint = Paint()
        ..color = const Color(0xFF4E342E).withValues(alpha: alpha + 0.1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(tx, ty + treeHeight * 0.3),
            width: treeHeight * 0.12,
            height: treeHeight * 0.5,
          ),
          const Radius.circular(2),
        ),
        trunkPaint,
      );

      // Three layered triangles (Mario style)
      for (int layer = 0; layer < 3; layer++) {
        final layerOffset = layer * treeHeight * 0.22;
        final layerWidth = treeHeight * (0.7 - layer * 0.08);
        final treePaint = Paint()
          ..color = treeColor.withValues(alpha: alpha - layer * 0.05);

        final path = Path()
          ..moveTo(tx, ty - treeHeight * 0.6 + layerOffset)
          ..lineTo(tx - layerWidth * 0.5, ty - treeHeight * 0.1 + layerOffset)
          ..lineTo(tx + layerWidth * 0.5, ty - treeHeight * 0.1 + layerOffset)
          ..close();
        canvas.drawPath(path, treePaint);
      }
    }

    // Small bushes
    for (int i = 0; i < 10; i++) {
      final bx = rng.nextDouble() * size.width;
      final by = rng.nextDouble() * size.height;

      bool tooClose = false;
      for (final n in nodes) {
        final nx = n.position.dx * size.width;
        final ny = n.position.dy * size.height;
        if ((bx - nx).abs() < 45 && (by - ny).abs() < 45) {
          tooClose = true;
          break;
        }
      }
      if (tooClose) continue;

      final bushSize = 6.0 + rng.nextDouble() * 10;
      final bushColor = world.treeColors[rng.nextInt(world.treeColors.length)];
      final paint = Paint()..color = bushColor.withValues(alpha: 0.2 + rng.nextDouble() * 0.2);

      // Three overlapping circles
      canvas.drawCircle(Offset(bx - bushSize * 0.3, by), bushSize * 0.5, paint);
      canvas.drawCircle(Offset(bx + bushSize * 0.3, by), bushSize * 0.5, paint);
      canvas.drawCircle(Offset(bx, by - bushSize * 0.3), bushSize * 0.55, paint);
    }

    // Rocks
    for (int i = 0; i < 6; i++) {
      final rx = rng.nextDouble() * size.width;
      final ry = rng.nextDouble() * size.height;

      bool tooClose = false;
      for (final n in nodes) {
        final nx = n.position.dx * size.width;
        final ny = n.position.dy * size.height;
        if ((rx - nx).abs() < 45 && (ry - ny).abs() < 45) {
          tooClose = true;
          break;
        }
      }
      if (tooClose) continue;

      final rockSize = 4.0 + rng.nextDouble() * 8;

      // Shadow
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rx + 1, ry + 2), width: rockSize * 1.6, height: rockSize * 0.7),
        Paint()..color = Colors.black.withValues(alpha: 0.1),
      );

      // Rock body
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rx, ry), width: rockSize * 1.4, height: rockSize * 0.9),
        Paint()..color = Colors.grey.shade800.withValues(alpha: 0.25),
      );

      // Highlight
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rx - 1, ry - 1), width: rockSize * 0.8, height: rockSize * 0.5),
        Paint()..color = Colors.grey.shade600.withValues(alpha: 0.12),
      );
    }
  }

  void _drawPath(Canvas canvas, Size size) {
    // Build path through all nodes
    final path = Path();
    path.moveTo(
      nodes.first.position.dx * size.width,
      nodes.first.position.dy * size.height,
    );

    for (int i = 1; i < nodes.length; i++) {
      final prev = nodes[i - 1].position;
      final curr = nodes[i].position;

      final px = prev.dx * size.width;
      final py = prev.dy * size.height;
      final cx = curr.dx * size.width;
      final cy = curr.dy * size.height;

      // Smooth bezier curves
      final midX = (px + cx) / 2;
      final midY = (py + cy) / 2;
      final dx = cx - px;
      final dy = cy - py;
      final curveOffset = (i.isEven ? 1 : -1) * 20.0;

      path.quadraticBezierTo(
        midX + (dy.abs() > 10 ? curveOffset : 0),
        midY + (dx.abs() > 10 ? curveOffset : 0),
        cx,
        cy,
      );
    }

    // Path shadow
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Outer border (dark)
    canvas.drawPath(
      path,
      Paint()
        ..color = world.pathBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Inner path (lighter)
    canvas.drawPath(
      path,
      Paint()
        ..color = world.pathColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Centre highlight
    canvas.drawPath(
      path,
      Paint()
        ..color = world.pathColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dotted centre line
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          canvas.drawCircle(tangent.position, 1.5, dotPaint);
        }
        distance += 12;
      }
    }

    // Draw mastered path segments in green
    for (int i = 1; i < nodes.length; i++) {
      if (nodes[i - 1].state == NodeState.mastered &&
          nodes[i].state == NodeState.mastered) {
        final segPath = Path();
        final prev = nodes[i - 1].position;
        final curr = nodes[i].position;
        final px = prev.dx * size.width;
        final py = prev.dy * size.height;
        final cx = curr.dx * size.width;
        final cy = curr.dy * size.height;
        final midX = (px + cx) / 2;
        final midY = (py + cy) / 2;
        final dx = cx - px;
        final dy = cy - py;
        final curveOffset = (i.isEven ? 1 : -1) * 20.0;

        segPath.moveTo(px, py);
        segPath.quadraticBezierTo(
          midX + (dy.abs() > 10 ? curveOffset : 0),
          midY + (dx.abs() > 10 ? curveOffset : 0),
          cx,
          cy,
        );

        canvas.drawPath(
          segPath,
          Paint()
            ..color = const Color(0xFF4CAF50).withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }
  }

  void _drawParticles(Canvas canvas, Size size) {
    // Floating ambient particles (fireflies / dust motes)
    final rng = Random(world.name.hashCode + 777);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 15; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final phase = rng.nextDouble();

      final t = (particleValue * speed + phase) % 1.0;
      final driftX = sin(t * 2 * pi) * 8;
      final driftY = cos(t * 3 * pi) * 5 - t * 20;

      final alpha = sin(t * pi) * 0.4;
      if (alpha <= 0) continue;

      paint.color = world.accentColor.withValues(alpha: alpha.clamp(0.0, 0.35));
      canvas.drawCircle(
        Offset(baseX + driftX, (baseY + driftY) % size.height),
        1 + sin(t * pi) * 1.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WorldMapPainter old) => true;
}
