import 'package:equatable/equatable.dart';

class ConnectedAccountEntity extends Equatable {
  final String id;
  final String provider;
  final String accountId;
  final String? accountName;
  final String? accountEmail;
  final bool isActive;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? tokenExpiresAt;
  final DateTime? lastSyncAt;
  final String syncStatus;
  final String? errorMessage;

  const ConnectedAccountEntity({
    required this.id,
    required this.provider,
    required this.accountId,
    this.accountName,
    this.accountEmail,
    this.isActive = true,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiresAt,
    this.lastSyncAt,
    this.syncStatus = 'pending',
    this.errorMessage,
  });

  ConnectedAccountEntity copyWith({
    String? id,
    String? provider,
    String? accountId,
    String? accountName,
    String? accountEmail,
    bool? isActive,
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpiresAt,
    DateTime? lastSyncAt,
    String? syncStatus,
    String? errorMessage,
  }) {
    return ConnectedAccountEntity(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      accountEmail: accountEmail ?? this.accountEmail,
      isActive: isActive ?? this.isActive,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncStatus: syncStatus ?? this.syncStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isTokenExpired {
    if (tokenExpiresAt == null) return false;
    return DateTime.now().isAfter(tokenExpiresAt!);
  }

  bool get needsRefresh {
    if (tokenExpiresAt == null) return false;
    // Refresh token 5 minutes before expiry
    return DateTime.now().add(const Duration(minutes: 5)).isAfter(tokenExpiresAt!);
  }

  bool get hasValidToken {
    return accessToken != null && !isTokenExpired;
  }

  @override
  List<Object?> get props => [
        id,
        provider,
        accountId,
        accountName,
        accountEmail,
        isActive,
        accessToken,
        refreshToken,
        tokenExpiresAt,
        lastSyncAt,
        syncStatus,
        errorMessage,
      ];

  @override
  String toString() {
    return 'ConnectedAccountEntity{id: $id, provider: $provider, accountName: $accountName, isActive: $isActive, syncStatus: $syncStatus}';
  }
}