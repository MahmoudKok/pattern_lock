import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pattern_lock_bloc.dart';

// Your main Pattern Lock Screen
class PatternLockScreen extends StatefulWidget {
  final List<int> correctPattern;
  const PatternLockScreen({super.key, required this.correctPattern});

  @override
  State<PatternLockScreen> createState() => _PatternLockScreenState();
}

class _PatternLockScreenState extends State<PatternLockScreen> {
  final GlobalKey _gridKey = GlobalKey();

  // Helper: Convert global touch position to local grid position
  Offset _getLocalPosition(Offset globalPosition) {
    final box = _gridKey.currentContext!.findRenderObject() as RenderBox;
    return box.globalToLocal(globalPosition);
  }

  int? _getNodeIndex(Size gridSize, Offset position) {
    final cell = gridSize.width / 3;
    final dotRadius = cell / 7;
    for (int i = 0; i < 9; i++) {
      final center = Offset(
        (i % 3 + 0.5) * cell,
        (i ~/ 3 + 0.5) * cell,
      );
      if ((position - center).distance <= dotRadius * 1.3) {
        return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PatternLockBloc(correctPattern: widget.correctPattern),
      child: BlocBuilder<PatternLockBloc, PatternLockState>(
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              // Always a centered square, min(width, height * 0.55) for good ratio
              final double gridSize =
                  constraints.maxWidth < constraints.maxHeight * 0.55
                      ? constraints.maxWidth
                      : constraints.maxHeight * 0.55;
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                      const Color(0xFFfc00ff),
                      const Color(0xFF00dbde),
                    ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                  ),
                  // Gesture area
                  Center(
                    child: SizedBox(
                      key: _gridKey,
                      width: gridSize,
                      height: gridSize,
                      child: GestureDetector(
                        onPanStart: (details) {
                          final localPos =
                              _getLocalPosition(details.globalPosition);
                          final node =
                              _getNodeIndex(Size(gridSize, gridSize), localPos);
                          context
                              .read<PatternLockBloc>()
                              .add(PatternPointerMoved(localPos));
                          if (node != null) {
                            context
                                .read<PatternLockBloc>()
                                .add(PatternStarted(node));
                          }
                        },
                        onPanUpdate: (details) {
                          final localPos =
                              _getLocalPosition(details.globalPosition);
                          final node =
                              _getNodeIndex(Size(gridSize, gridSize), localPos);
                          context
                              .read<PatternLockBloc>()
                              .add(PatternPointerMoved(localPos));
                          if (node != null) {
                            context
                                .read<PatternLockBloc>()
                                .add(PatternUpdated(node));
                          }
                        },
                        onPanEnd: (_) {
                          context
                              .read<PatternLockBloc>()
                              .add(const PatternCompleted());
                          context
                              .read<PatternLockBloc>()
                              .add(const PatternPointerMoved(null));
                        },
                        child: CustomPaint(
                          painter: PatternPainter(
                            selectedNodes: state.selectedNodes,
                            status: state.status,
                            fingerPosition: state.fingerPosition,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                  // Glass Hello overlay
                  if (state.status == PatternStatus.success) const GlassHello(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// PatternPainter can be your existing painter
class PatternPainter extends CustomPainter {
  final List<int> selectedNodes;
  final PatternStatus status;
  final Offset? fingerPosition;

  PatternPainter({
    required this.selectedNodes,
    required this.status,
    required this.fingerPosition,
  });

  final Color _mainNodeColor = Colors.white;
  final Color _mainLineColor = Color.fromARGB(255, 238, 209, 255); // purple
  final Color _errorColor = Colors.redAccent;
  final Color _successColor = Colors.greenAccent;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 3;
    final dotRadius = cell / 16;

    // Draw lines between selected nodes
    for (int i = 0; i < selectedNodes.length - 1; i++) {
      final from = _center(selectedNodes[i], cell);
      final to = _center(selectedNodes[i + 1], cell);
      // Glow
      final glowLine = Paint()
        ..color = status == PatternStatus.error
            ? _errorColor.withOpacity(0.6)
            : status == PatternStatus.success
                ? _successColor.withOpacity(0.6)
                : _mainLineColor.withOpacity(0.6)
        ..strokeWidth = 10
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawLine(from, to, glowLine);
      // Actual line
      final linePaint = Paint()
        ..color = status == PatternStatus.error
            ? _errorColor
            : status == PatternStatus.success
                ? _successColor
                : _mainLineColor
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(from, to, linePaint);
    }

    // Live dragging line
    if (selectedNodes.isNotEmpty &&
        fingerPosition != null &&
        status == PatternStatus.drawing) {
      final last = _center(selectedNodes.last, cell);
      final glowLinePaint = Paint()
        ..color = _mainLineColor.withOpacity(0.4)
        ..strokeWidth = 18
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 16);
      final linePaint = Paint()
        ..color = _mainLineColor
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(last, fingerPosition!, glowLinePaint);
      canvas.drawLine(last, fingerPosition!, linePaint);
    }

    // Draw dots
    for (int i = 0; i < 9; i++) {
      final center = _center(i, cell);
      // Glow behind selected
      if (selectedNodes.contains(i)) {
        final glow = Paint()
          ..color = status == PatternStatus.error
              ? _errorColor.withOpacity(0.7)
              : status == PatternStatus.success
                  ? _successColor.withOpacity(0.7)
                  : _mainNodeColor.withOpacity(0.7)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18);
        canvas.drawCircle(center, dotRadius * 2.3, glow);
      }
      // Main dot
      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, dotRadius, dotPaint);
      // Border (changes with status)
      final borderPaint = Paint()
        ..color = status == PatternStatus.error
            ? _errorColor
            : status == PatternStatus.success
                ? _successColor
                : Colors.grey.shade400
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, dotRadius, borderPaint);
      // Center highlight if selected
      if (selectedNodes.contains(i)) {
        final fillPaint = Paint()
          ..color = status == PatternStatus.error
              ? _errorColor
              : status == PatternStatus.success
                  ? _successColor
                  : _mainLineColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, dotRadius * 0.7, fillPaint);
      }
    }
  }

  Offset _center(int index, double cell) {
    return Offset(
      (index % 3 + 0.5) * cell,
      (index ~/ 3 + 0.5) * cell,
    );
  }

  @override
  bool shouldRepaint(covariant PatternPainter oldDelegate) {
    return oldDelegate.selectedNodes != selectedNodes ||
        oldDelegate.status != status ||
        oldDelegate.fingerPosition != fingerPosition;
  }
}

class GlassHello extends StatefulWidget {
  const GlassHello({super.key});

  @override
  State<GlassHello> createState() => _GlassHelloState();
}

class _GlassHelloState extends State<GlassHello>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fading blur glass effect over the whole screen
        FadeTransition(
          opacity: _fade,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: 100, sigmaY: 100, tileMode: TileMode.mirror),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
          ),
        ),
        // Centered "Hello :)" with fade+scale animation
        Center(
          child: FadeTransition(
            opacity: _fade,
            child: Material(
              color: const Color.fromRGBO(0, 0, 0, 0),
              child: Text(
                'Hello :)',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 213, 238, 238),
                  letterSpacing: 1.4,
                  // shadows: [
                  //   Shadow(
                  //     blurRadius: 16,
                  //     color: Colors.black.withOpacity(0.24),
                  //     offset: const Offset(0, 2),
                  //   ),
                  // ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
