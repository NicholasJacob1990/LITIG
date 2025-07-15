import 'package:equatable/equatable.dart';
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';
import 'package:meu_app/src/features/partnerships/domain/entities/partnership.dart';

abstract class HybridPartnershipsState extends Equatable {
  const HybridPartnershipsState();

  @override
  List<Object?> get props => [];
}

class HybridPartnershipsInitial extends HybridPartnershipsState {
  const HybridPartnershipsInitial();
}

class HybridPartnershipsLoading extends HybridPartnershipsState {
  const HybridPartnershipsLoading();
}

class HybridPartnershipsLoaded extends HybridPartnershipsState {
  final List<Partnership> lawyerPartnerships;
  final List<LawFirm> firmPartnerships;
  final bool hasMore;
  final int currentPage;

  const HybridPartnershipsLoaded({
    required this.lawyerPartnerships,
    required this.firmPartnerships,
    this.hasMore = false,
    this.currentPage = 0,
  });

  @override
  List<Object?> get props => [lawyerPartnerships, firmPartnerships, hasMore, currentPage];

  HybridPartnershipsLoaded copyWith({
    List<Partnership>? lawyerPartnerships,
    List<LawFirm>? firmPartnerships,
    bool? hasMore,
    int? currentPage,
  }) {
    return HybridPartnershipsLoaded(
      lawyerPartnerships: lawyerPartnerships ?? this.lawyerPartnerships,
      firmPartnerships: firmPartnerships ?? this.firmPartnerships,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class HybridPartnershipsError extends HybridPartnershipsState {
  final String message;

  const HybridPartnershipsError({required this.message});

  @override
  List<Object?> get props => [message];
}

class HybridPartnershipsLoadingMore extends HybridPartnershipsState {
  final List<Partnership> lawyerPartnerships;
  final List<LawFirm> firmPartnerships;
  final int currentPage;

  const HybridPartnershipsLoadingMore({
    required this.lawyerPartnerships,
    required this.firmPartnerships,
    this.currentPage = 0,
  });

  @override
  List<Object?> get props => [lawyerPartnerships, firmPartnerships, currentPage];
} 