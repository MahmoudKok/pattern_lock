part of 'pattern_lock_bloc.dart';

enum PatternStatus { initial, drawing, error, success }

class PatternLockState extends Equatable {
  final List<int> selectedNodes;
  final PatternStatus status;
  final Offset? fingerPosition; // <--- ADD THIS

  const PatternLockState({
    this.selectedNodes = const [],
    this.status = PatternStatus.initial,
    this.fingerPosition, // <--- ADD THIS
  });

  PatternLockState copyWith({
    List<int>? selectedNodes,
    PatternStatus? status,
    Offset? fingerPosition, // <--- ADD THIS
  }) {
    return PatternLockState(
      selectedNodes: selectedNodes ?? this.selectedNodes,
      status: status ?? this.status,
      fingerPosition: fingerPosition ?? this.fingerPosition, // <--- ADD THIS
    );
  }

  @override
  List<Object?> get props => [selectedNodes, status, fingerPosition];
}
