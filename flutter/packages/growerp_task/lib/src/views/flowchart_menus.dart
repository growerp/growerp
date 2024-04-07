import 'package:flutter/material.dart';
import 'package:flutter_flow_chart/flutter_flow_chart.dart';
import 'package:star_menu/star_menu.dart';

class FlowchartMenus {
  /// Display a drop down menu when tapping on a handler
  static displayHandlerMenu(
    BuildContext context,
    Offset position,
    Handler handler,
    FlowElement element,
    Dashboard dashboard,
  ) {
    StarMenuOverlay.displayStarMenu(
      context,
      StarMenu(
        params: StarMenuParameters(
          shape: MenuShape.linear,
          openDurationMs: 60,
          linearShapeParams: const LinearShapeParams(
            angle: 270,
            space: 10,
          ),
          onHoverScale: 1.1,
          useTouchAsCenter: true,
          centerOffset: position -
              Offset(
                dashboard.dashboardSize.width / 2,
                dashboard.dashboardSize.height / 2,
              ),
        ),
        onItemTapped: (index, controller) => controller.closeMenu!(),
        items: [
          FloatingActionButton(
            child: const Icon(Icons.delete),
            onPressed: () =>
                dashboard.removeElementConnection(element, handler),
          )
        ],
        parentContext: context,
      ),
    );
  }

  /// Display a drop down menu when tapping on an element
}
