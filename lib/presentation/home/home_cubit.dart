import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeState extends Equatable {
  final int selectedIndex;

  const HomeState({required this.selectedIndex});

  HomeState copyWith({int? selectedIndex}) {
    return HomeState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }

  @override
  List<Object?> get props => [selectedIndex];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState(selectedIndex: 0));

  void changeTab(int index) {
    emit(state.copyWith(selectedIndex: index));
  }
}

