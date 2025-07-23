import 'package:equatable/equatable.dart';
import '../../domain/entities/client_profile.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  final String userId;

  const LoadProfile(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateProfile extends ProfileEvent {
  final ClientProfile profile;

  const UpdateProfile(this.profile);

  @override
  List<Object?> get props => [profile];
}

class UpdatePersonalData extends ProfileEvent {
  final PersonalData personalData;

  const UpdatePersonalData(this.personalData);

  @override
  List<Object?> get props => [personalData];
}

class UpdateContactData extends ProfileEvent {
  final ContactData contactData;

  const UpdateContactData(this.contactData);

  @override
  List<Object?> get props => [contactData];
}

class UpdateAddresses extends ProfileEvent {
  final List<Address> addresses;

  const UpdateAddresses(this.addresses);

  @override
  List<Object?> get props => [addresses];
}

class AddDocument extends ProfileEvent {
  final Document document;

  const AddDocument(this.document);

  @override
  List<Object?> get props => [document];
}

class RemoveDocument extends ProfileEvent {
  final String documentId;

  const RemoveDocument(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

class LoadSocialProfiles extends ProfileEvent {
  const LoadSocialProfiles();

  @override
  List<Object?> get props => [];
}