import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:collection/collection.dart';

part 'pattern_lock_event.dart';
part 'pattern_lock_state.dart';

class PatternLockBloc extends Bloc<PatternLockEvent, PatternLockState> {
  final List<int> correctPattern;

  PatternLockBloc({required this.correctPattern})
      : super(const PatternLockState()) {
    on<PatternStarted>(_onPatternStarted);
    on<PatternUpdated>(_onPatternUpdated);
    on<PatternCompleted>(_onPatternCompleted);
    on<PatternReset>(_onPatternReset);
    on<PatternPointerMoved>(_onPointerMoved);
  }

  void _onPatternStarted(PatternStarted event, Emitter<PatternLockState> emit) {
    emit(state.copyWith(
      selectedNodes: [event.node],
      status: PatternStatus.drawing,
    ));
  }

  void _onPatternUpdated(PatternUpdated event, Emitter<PatternLockState> emit) {
    if (!state.selectedNodes.contains(event.node)) {
      emit(state.copyWith(
        selectedNodes: List.from(state.selectedNodes)..add(event.node),
        status: PatternStatus.drawing,
      ));
    }
  }

  Future<void> _onPatternCompleted(
      PatternCompleted event, Emitter<PatternLockState> emit) async {
    if (state.selectedNodes.length < 3) {
      emit(state.copyWith(status: PatternStatus.error));
      await Future.delayed(const Duration(milliseconds: 700));
      add(const PatternReset());
    } else if (const ListEquality()
        .equals(state.selectedNodes, correctPattern)) {
      emit(state.copyWith(status: PatternStatus.success));
      await Future.delayed(const Duration(milliseconds: 5000));
      add(const PatternReset());
    } else {
      emit(state.copyWith(status: PatternStatus.error));
      await Future.delayed(const Duration(milliseconds: 700));
      add(const PatternReset());
    }
  }

  void _onPatternReset(PatternReset event, Emitter<PatternLockState> emit) {
    emit(const PatternLockState());
  }

  // Add this handler at the end of your bloc class:
  void _onPointerMoved(
      PatternPointerMoved event, Emitter<PatternLockState> emit) {
    emit(state.copyWith(fingerPosition: event.position));
  }
}
