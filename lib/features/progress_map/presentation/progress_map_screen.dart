import 'package:flutter/material.dart';
import 'package:outcall/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outcall/features/recording/presentation/recorder_page.dart';
import 'package:outcall/features/progress_map/domain/world_info.dart';
import 'package:outcall/features/progress_map/presentation/controllers/progress_map_controller.dart';
import 'package:outcall/features/progress_map/presentation/widgets/world_map_painter.dart';

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
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _particleController;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(progressMapNotifierProvider.notifier)
          .loadData(widget.userId);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(progressMapNotifierProvider);
    final world = worlds[mapState.selectedWorld];

    return Scaffold(
      backgroundColor: world.bgColorBot,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildTopBar(world, mapState),
            _buildWorldTabs(mapState),
            Expanded(
              child: mapState.isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                              color: Theme.of(context).primaryColor),
                          const SizedBox(height: 16),
                          Text('Loading world...',
                              style: GoogleFonts.pressStart2p(
                                  color: AppColors.of(context).textSubtle, fontSize: 8)),
                        ],
                      ),
                    )
                  : mapState.worldNodes.isEmpty
                      ? Center(
                          child: Text('No calls found',
                              style: GoogleFonts.oswald(
                                  color: AppColors.of(context).textTertiary)))
                      : _buildWorldMap(mapState),
            ),
            if (mapState.selectedNode != null)
              _buildDetailCard(mapState, world),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  TOP BAR
  // ═══════════════════════════════════════════════

  Widget _buildTopBar(WorldInfo world, ProgressMapState mapState) {
    final nodes = mapState.worldNodes.isNotEmpty
        ? mapState.worldNodes[mapState.selectedWorld]
        : <MapNode>[];
    final mastered =
        nodes.where((n) => n.state == NodeState.mastered).length;
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Navigator.canPop(context)
                  ? IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: AppColors.of(context).textPrimary, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                    )
                  : const SizedBox(width: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'WORLD ${mapState.selectedWorld + 1}',
                            style: GoogleFonts.pressStart2p(
                                color: world.accentColor, fontSize: 7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            world.subtitle.toUpperCase(),
                            style: GoogleFonts.pressStart2p(
                                color: AppColors.of(context).textSubtle, fontSize: 6),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      world.name,
                      style: GoogleFonts.pressStart2p(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 13,
                        height: 1.2,
                        shadows: [
                          const Shadow(color: Colors.black87, blurRadius: 6),
                          Shadow(
                              color: world.primaryColor
                                  .withValues(alpha: 0.5),
                              blurRadius: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: world.accentColor.withValues(alpha: 0.4),
                      width: 2),
                ),
                alignment: Alignment.center,
                child: Text(world.emoji,
                    style: const TextStyle(fontSize: 24)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amberAccent, size: 14),
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
                      width: (MediaQuery.of(context).size.width - 100) *
                          progressPct,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amberAccent, world.accentColor],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.amberAccent
                                  .withValues(alpha: 0.4),
                              blurRadius: 6),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$mastered/$total',
                style: GoogleFonts.pressStart2p(
                    color: Colors.amberAccent, fontSize: 9),
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

  Widget _buildWorldTabs(ProgressMapState mapState) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.black38,
        border: Border(
            bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: worlds.length,
        itemBuilder: (ctx, i) {
          final w = worlds[i];
          final selected = i == mapState.selectedWorld;
          final mastered = mapState.worldNodes.length > i
              ? mapState.worldNodes[i]
                  .where((n) => n.state == NodeState.mastered)
                  .length
              : 0;
          final total = mapState.worldNodes.length > i
              ? mapState.worldNodes[i].length
              : 0;

          return GestureDetector(
            onTap: () => ref
                .read(progressMapNotifierProvider.notifier)
                .selectWorld(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(colors: [
                        w.primaryColor.withValues(alpha: 0.9),
                        w.primaryColor.withValues(alpha: 0.6),
                      ])
                    : null,
                color: selected
                    ? null
                    : AppColors.of(context).cardOverlay,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? w.accentColor.withValues(alpha: 0.6)
                      : AppColors.of(context).border,
                  width: selected ? 1.5 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                            color:
                                w.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8)
                      ]
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
                          color: selected
                              ? Colors.white
                              : Colors.white54,
                          fontSize: 8,
                        ),
                      ),
                      if (total > 0)
                        Text(
                          '$mastered/$total',
                          style: GoogleFonts.pressStart2p(
                            color: selected
                                ? w.accentColor
                                : Colors.white30,
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

  Widget _buildWorldMap(ProgressMapState mapState) {
    final nodes = mapState.worldNodes[mapState.selectedWorld];
    final world = worlds[mapState.selectedWorld];

    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;

      return AnimatedBuilder(
        animation: Listenable.merge(
            [_pulseController, _glowController, _particleController]),
        builder: (context, _) {
          return GestureDetector(
            onTap: () => ref
                .read(progressMapNotifierProvider.notifier)
                .clearSelectedNode(),
            child: Stack(
              children: [
                CustomPaint(
                  size: size,
                  painter: WorldMapPainter(
                    nodes: nodes,
                    world: world,
                    pulseValue: _pulseController.value,
                    glowValue: _glowController.value,
                    particleValue: _particleController.value,
                  ),
                ),
                ...nodes.map(
                    (node) => _buildNodeWidget(node, size, world)),
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
          border:
              Border.all(color: AppColors.error, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.red.withValues(alpha: 0.4), blurRadius: 8),
            const BoxShadow(
                color: Colors.black45,
                blurRadius: 4,
                offset: Offset(0, 2)),
          ],
        ),
        child: Text(
          'START',
          style: GoogleFonts.pressStart2p(
            color: AppColors.of(context).textPrimary,
            fontSize: 7,
            shadows: [const Shadow(color: Colors.black, blurRadius: 2)],
          ),
        ),
      ),
    );
  }

  Widget _buildNodeWidget(
      MapNode node, Size mapSize, WorldInfo world) {
    final mapState = ref.watch(progressMapNotifierProvider);
    final x = mapSize.width * node.position.dx;
    final y = mapSize.height * node.position.dy;
    const double nodeRadius = 28;

    final isCurrent = node.state == NodeState.current;
    final isMastered = node.state == NodeState.mastered;
    final isLocked = node.state == NodeState.locked;
    final isSelected = mapState.selectedNode == node;

    final scale = isCurrent ? 0.9 + _pulseController.value * 0.2 : 1.0;
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
            ref
                .read(progressMapNotifierProvider.notifier)
                .selectNode(node);
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
              border:
                  Border.all(color: borderColor, width: borderWidth),
              boxShadow: [
                if (isCurrent)
                  BoxShadow(
                    color: world.primaryColor.withValues(
                        alpha: 0.3 + glowIntensity * 0.3),
                    blurRadius: 16 + glowIntensity * 8,
                    spreadRadius: 2,
                  ),
                if (isMastered)
                  BoxShadow(
                    color: Colors.green.withValues(
                        alpha: 0.2 + glowIntensity * 0.15),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                if (isSelected)
                  BoxShadow(
                    color:
                        Colors.amberAccent.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
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
                Container(
                  width: nodeRadius * 2 - 10,
                  height: nodeRadius * 2 - 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isMastered
                              ? Colors.green
                              : isLocked
                                  ? Colors.grey.shade700
                                  : Colors.white)
                          .withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                ),
                if (isLocked)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock,
                          color: AppColors.of(context).border, size: 16),
                      Text(
                        '${node.index}',
                        style: GoogleFonts.pressStart2p(
                            color: Colors.white
                                .withValues(alpha: 0.2),
                            fontSize: 6),
                      ),
                    ],
                  )
                else if (isMastered)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        getAnimalEmoji(node.call.animalName),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 1),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(Icons.check,
                            color: AppColors.of(context).textPrimary, size: 8),
                      ),
                    ],
                  )
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        getAnimalEmoji(node.call.animalName),
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        '${node.index}',
                        style: GoogleFonts.pressStart2p(
                          color: isCurrent
                              ? Colors.white
                              : Colors.white54,
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

  Widget _buildDetailCard(ProgressMapState mapState, WorldInfo world) {
    final node = mapState.selectedNode!;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E1E1E),
            Color(0xFF252525),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: world.primaryColor.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
              color: world.primaryColor.withValues(alpha: 0.2),
              blurRadius: 12),
          const BoxShadow(
              color: Colors.black54,
              blurRadius: 8,
              offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
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
              border: Border.all(
                  color: world.primaryColor.withValues(alpha: 0.5),
                  width: 2),
            ),
            alignment: Alignment.center,
            child: node.state == NodeState.mastered
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${node.bestScore ?? 0}',
                        style: GoogleFonts.pressStart2p(
                            color: Colors.greenAccent, fontSize: 12),
                      ),
                      const Icon(Icons.star,
                          color: Colors.amberAccent, size: 10),
                    ],
                  )
                : Text(
                    getAnimalEmoji(node.call.animalName),
                    style: const TextStyle(fontSize: 26),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            world.primaryColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'STAGE ${node.index}',
                        style: GoogleFonts.pressStart2p(
                            color: world.accentColor, fontSize: 6),
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
                    color: AppColors.of(context).textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  node.call.callType,
                  style: GoogleFonts.lato(
                      color: AppColors.of(context).textTertiary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (node.bestScore != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.emoji_events,
                          color: Colors.amberAccent, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Best Score: ${node.bestScore}',
                        style: GoogleFonts.lato(
                            color: Colors.amberAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
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
                  colors: [
                    world.primaryColor,
                    world.primaryColor.withValues(alpha: 0.7)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                    color: world.accentColor.withValues(alpha: 0.5),
                    width: 2),
                boxShadow: [
                  BoxShadow(
                      color: world.primaryColor
                          .withValues(alpha: 0.4),
                      blurRadius: 10),
                  const BoxShadow(
                      color: Colors.black38,
                      blurRadius: 4,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Icon(Icons.play_arrow_rounded,
                  color: AppColors.of(context).textPrimary, size: 30),
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
}
