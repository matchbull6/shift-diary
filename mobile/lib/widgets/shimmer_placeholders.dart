import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class SummaryCardShimmer extends StatelessWidget {
  const SummaryCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ShimmerBox(width: 140, height: 20),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _ShimmerBox(width: 80, height: 14),
                  _ShimmerBox(width: 60, height: 14),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _ShimmerBox(width: 80, height: 14),
                  _ShimmerBox(width: 60, height: 14),
                ],
              ),
              const SizedBox(height: 20),
              const _ShimmerBox(width: 160, height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class TripListShimmer extends StatelessWidget {
  const TripListShimmer({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const _ShimmerBox(width: 48, height: 48, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _ShimmerBox(width: 120, height: 14),
                    SizedBox(height: 8),
                    _ShimmerBox(width: 80, height: 12),
                  ],
                ),
              ),
              const _ShimmerBox(width: 60, height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
