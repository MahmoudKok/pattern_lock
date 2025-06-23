part of 'pattern_lock_bloc.dart';

abstract class PatternLockEvent extends Equatable {
  const PatternLockEvent();
  @override
  List<Object?> get props => [];
}

class PatternStarted extends PatternLockEvent {
  final int node;
  const PatternStarted(this.node);

  @override
  List<Object?> get props => [node];
}

class PatternUpdated extends PatternLockEvent {
  final int node;
  const PatternUpdated(this.node);

  @override
  List<Object?> get props => [node];
}

class PatternCompleted extends PatternLockEvent {
  const PatternCompleted();
}

class PatternReset extends PatternLockEvent {
  const PatternReset();
}

// Add at the end of your event file

class PatternPointerMoved extends PatternLockEvent {
  final Offset? position;
  const PatternPointerMoved(this.position);

  @override
  List<Object?> get props => [position];
}
