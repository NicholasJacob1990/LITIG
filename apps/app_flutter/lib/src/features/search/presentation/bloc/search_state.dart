import 'package:equatable/equatable.dart';

sealed class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchLoaded extends SearchState {
  final List<dynamic> results;
  final String? appliedPreset;

  const SearchLoaded({
    required this.results, 
    this.appliedPreset,
  });

  @override
  List<Object?> get props => [results, appliedPreset];
}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
} 
 