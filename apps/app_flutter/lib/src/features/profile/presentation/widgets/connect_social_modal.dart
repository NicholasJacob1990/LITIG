import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import '../../../../core/services/social_auth_service.dart';

/// Resultado da conexão com rede social
class SocialConnectionResult {
  final bool success;
  final String provider;
  final String? message;
  final Map<String, dynamic>? data;
  
  const SocialConnectionResult({
    required this.success,
    required this.provider,
    this.message,
    this.data,
  });
  
  factory SocialConnectionResult.success({
    required String provider,
    Map<String, dynamic>? data,
  }) {
    return SocialConnectionResult(
      success: true,
      provider: provider,
      data: data,
    );
  }
  
  factory SocialConnectionResult.error({
    required String provider,
    required String message,
  }) {
    return SocialConnectionResult(
      success: false,
      provider: provider,
      message: message,
    );
  }
}

/// Modal para conectar uma conta de rede social
/// 
/// Permite ao usuário inserir credenciais e conectar sua conta
class ConnectSocialModal extends StatefulWidget {
  final String provider;

  const ConnectSocialModal({
    super.key,
    required this.provider,
  });

  @override
  State<ConnectSocialModal> createState() => _ConnectSocialModalState();
}

class _ConnectSocialModalState extends State<ConnectSocialModal> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late final SocialAuthService _socialService;
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _socialService = SocialAuthService(GetIt.instance<Dio>());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildForm(),
                const SizedBox(height: 24),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getProviderColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getProviderIcon(),
                color: _getProviderColor(),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Conectar ${_getProviderName()}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Digite suas credenciais para conectar sua conta do ${_getProviderName()}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: _getUsernameLabel(),
              hintText: _getUsernameHint(),
              border: const OutlineInputBorder(),
              prefixIcon: Icon(_getUsernameIcon()),
            ),
            keyboardType: widget.provider == 'linkedin' 
                ? TextInputType.emailAddress 
                : TextInputType.text,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Este campo é obrigatório';
              }
              if (widget.provider == 'linkedin' && !value.contains('@')) {
                return 'Digite um e-mail válido';
              }
              return null;
            },
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Senha',
              hintText: 'Digite sua senha',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
              ),
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _connectAccount(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Este campo é obrigatório';
              }
              if (value.length < 6) {
                return 'A senha deve ter pelo menos 6 caracteres';
              }
              return null;
            },
            enabled: !_isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _connectAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: _getProviderColor(),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text('Conectar ${_getProviderName()}'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(height: 16),
        _buildSecurityInfo(),
      ],
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: Colors.grey[600],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Suas credenciais são criptografadas e armazenadas com segurança',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connectAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Vibração de feedback
    HapticFeedback.lightImpact();

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      SocialConnectionResult result;

      switch (widget.provider) {
        case 'linkedin':
          result = await _socialService.connectLinkedIn(
            username: username,
            password: password,
          );
          break;
        case 'instagram':
          result = await _socialService.connectInstagram(
            username: username,
            password: password,
          );
          break;
        case 'facebook':
          result = await _socialService.connectFacebook(
            username: username,
            password: password,
          );
          break;
        default:
          result = SocialConnectionResult.error(
            provider: widget.provider,
            message: 'Provedor não suportado',
          );
      }

      setState(() {
        _isLoading = false;
      });

      if (result.success) {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop(result);
      } else {
        setState(() {
          _errorMessage = result.message;
        });
        HapticFeedback.selectionClick();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro inesperado. Tente novamente.';
      });
      HapticFeedback.selectionClick();
    }
  }

  String _getProviderName() {
    switch (widget.provider) {
      case 'linkedin':
        return 'LinkedIn';
      case 'instagram':
        return 'Instagram';
      case 'facebook':
        return 'Facebook';
      default:
        return widget.provider.toUpperCase();
    }
  }

  IconData _getProviderIcon() {
    switch (widget.provider) {
      case 'linkedin':
        return Icons.business;
      case 'instagram':
        return Icons.camera_alt;
      case 'facebook':
        return Icons.facebook;
      default:
        return Icons.share;
    }
  }

  IconData _getUsernameIcon() {
    switch (widget.provider) {
      case 'linkedin':
        return Icons.email;
      case 'instagram':
      case 'facebook':
        return Icons.person;
      default:
        return Icons.account_circle;
    }
  }

  Color _getProviderColor() {
    switch (widget.provider) {
      case 'linkedin':
        return const Color(0xFF0A66C2);
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'facebook':
        return const Color(0xFF1877F2);
      default:
        return Theme.of(context).primaryColor;
    }
  }

  String _getUsernameLabel() {
    switch (widget.provider) {
      case 'linkedin':
        return 'E-mail';
      case 'instagram':
      case 'facebook':
        return 'Usuário ou E-mail';
      default:
        return 'Usuário';
    }
  }

  String _getUsernameHint() {
    switch (widget.provider) {
      case 'linkedin':
        return 'seu@email.com';
      case 'instagram':
        return '@seuusuario ou email';
      case 'facebook':
        return 'usuário ou email';
      default:
        return 'Digite seu usuário';
    }
  }
} 