import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, required this.child});
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (count > 0)
            Positioned(
              right: -9,
              top: -7,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        height: 1,
                        fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      );
}
