import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.margin,
    this.padding,
  });

  /// Factory for full-width cards or list items
  factory SkeletonLoader.card({
    double height = 120,
    double borderRadius = 16,
    EdgeInsetsGeometry? margin,
  }) {
    return SkeletonLoader(
      width: double.infinity,
      height: height,
      borderRadius: borderRadius,
      margin: margin,
    );
  }

  /// Factory for circular shapes like profile pictures
  factory SkeletonLoader.circular({
    required double size,
    EdgeInsetsGeometry? margin,
  }) {
    return SkeletonLoader(
      width: size,
      height: size,
      borderRadius: size / 2,
      margin: margin,
    );
  }
  
  /// Factory for small text lines
  factory SkeletonLoader.text({
    double width = 100,
    double height = 14,
    int lines = 1,
    EdgeInsetsGeometry? margin,
  }) {
    if (lines == 1) {
      return SkeletonLoader(
        width: width,
        height: height,
        borderRadius: 4,
        margin: margin,
      );
    }
    
    return SkeletonLoader(
      width: width,
      height: height * lines + (lines - 1) * 8, // Account for spacing
      borderRadius: 0, // Handled internally
      margin: margin,
    ); // Placeholder until Column implementation if needed
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF2A2A2A),
        highlightColor: const Color(0xFF3A3A3A), // Dark mode friendly shine
        period: const Duration(milliseconds: 1500),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.black, // Shimmer requires an opaque color to mask
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              SkeletonLoader.circular(size: 60),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader.text(width: 120, height: 20),
                  const SizedBox(height: 8),
                  SkeletonLoader.text(width: 80, height: 14),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Section Title
          SkeletonLoader.text(width: 150, height: 24),
          const SizedBox(height: 16),
          
          // Cards
          SkeletonLoader.card(height: 180, margin: const EdgeInsets.only(bottom: 16)),
          SkeletonLoader.card(height: 120, margin: const EdgeInsets.only(bottom: 16)),
          SkeletonLoader.card(height: 120, margin: const EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  final int itemCount;
  
  const ListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              SkeletonLoader.circular(size: 50),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader.text(width: double.infinity, height: 16),
                    const SizedBox(height: 8),
                    SkeletonLoader.text(width: 100, height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
