import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 8,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: ListTile(
            leading: Container(width: 56, height: 56, color: Colors.white),
            title: Container(height: 14, width: 100, color: Colors.white),
            subtitle: Container(height: 14, width: 150, color: Colors.white),
          ),
        );
      },
    );
  }
}
