import 'package:equatable/equatable.dart';
import '../../domain/entities/client_profile.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final ClientProfile profile;
  final Map<String, dynamic>? socialProfiles;

  const ProfileLoaded(this.profile, {this.socialProfiles});

  @override
  List<Object?> get props => [profile, socialProfiles];

  ProfileLoaded copyWith({
    ClientProfile? profile,
    Map<String, dynamic>? socialProfiles,
  }) {
    return ProfileLoaded(
      profile ?? this.profile,
      socialProfiles: socialProfiles ?? this.socialProfiles,
    );
  }
}

class ProfileUpdated extends ProfileState {
  final ClientProfile profile;

  const ProfileUpdated(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}