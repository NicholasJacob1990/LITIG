import 'package:equatable/equatable.dart';

class AdminAuditLog extends Equatable {
  final String id;
  final String action;
  final String userId;
  final String? userName;
  final String? userEmail;
  final String? userType;
  final Map<String, dynamic>? details;
  final String? ipAddress;
  final String? userAgent;
  final DateTime timestamp;
  final String? sessionId;
  final String? resourceType;
  final String? resourceId;
  final String? severity; // 'low', 'medium', 'high', 'critical'
  final bool isSuccessful;
  final String? errorMessage;

  const AdminAuditLog({
    required this.id,
    required this.action,
    required this.userId,
    this.userName,
    this.userEmail,
    this.userType,
    this.details,
    this.ipAddress,
    this.userAgent,
    required this.timestamp,
    this.sessionId,
    this.resourceType,
    this.resourceId,
    this.severity,
    required this.isSuccessful,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        id,
        action,
        userId,
        userName,
        userEmail,
        userType,
        details,
        ipAddress,
        userAgent,
        timestamp,
        sessionId,
        resourceType,
        resourceId,
        severity,
        isSuccessful,
        errorMessage,
      ];

  AdminAuditLog copyWith({
    String? id,
    String? action,
    String? userId,
    String? userName,
    String? userEmail,
    String? userType,
    Map<String, dynamic>? details,
    String? ipAddress,
    String? userAgent,
    DateTime? timestamp,
    String? sessionId,
    String? resourceType,
    String? resourceId,
    String? severity,
    bool? isSuccessful,
    String? errorMessage,
  }) {
    return AdminAuditLog(
      id: id ?? this.id,
      action: action ?? this.action,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userType: userType ?? this.userType,
      details: details ?? this.details,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      timestamp: timestamp ?? this.timestamp,
      sessionId: sessionId ?? this.sessionId,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      severity: severity ?? this.severity,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // Getters para facilitar acesso aos dados
  bool get isAuthAction => action.startsWith('auth_');
  bool get isCaseAction => action.startsWith('case_');
  bool get isPaymentAction => action.startsWith('payment_');
  bool get isSystemAction => action.startsWith('system_');
  bool get isAdminAction => action.startsWith('admin_');
  
  bool get isHighSeverity => severity == 'high' || severity == 'critical';
  bool get isCritical => severity == 'critical';
  
  String get formattedTimestamp => 
      '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  
  String get displayName => userName ?? userEmail ?? userId;
} 