import 'package:flutter/material.dart';
import 'package:cn_pocket_hr/ui/break_points.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    Key? key,
    required this.mobileBody,
    this.tabletBody,
  }) : super(key: key);

  final Widget mobileBody;
  final Widget? tabletBody;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= TabletBreakePoint) {
          if (tabletBody != null) {
            return tabletBody!;
          }
          final mediaQuery = MediaQuery.of(context);
          final constrainedWidth =
              constraints.maxWidth.clamp(0.0, TabletBreakePoint);
          final constrainedHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : mediaQuery.size.height;

          return ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: TabletBreakePoint),
                child: MediaQuery(
                  data: mediaQuery.copyWith(
                    size: Size(constrainedWidth, constrainedHeight),
                  ),
                  child: mobileBody,
                ),
              ),
            ),
          );
        }
        return mobileBody;
      },
    );
  }
}

