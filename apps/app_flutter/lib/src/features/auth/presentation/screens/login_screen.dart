import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;
import 'package:meu_app/src/features/auth/domain/entities/user.dart';
import 'package:meu_app/src/features/cases/domain/entities/contextual_case_data.dart';
import 'package:meu_app/src/features/cases/domain/entities/allocation_type.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String _selectedRole = 'client';
  String _selectedAllocationType = 'default';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      // Para modo de teste, usar dados mock baseados no role selecionado
      if (_selectedRole != 'client') {
        _handleTestLogin();
      } else {
        context.read<AuthBloc>().add(
              AuthLoginRequested(
                email: _emailController.text.trim(),
                password: _passwordController.text,
              ),
            );
      }
    }
  }

  void _handleTestLogin() {
    // Simular login com dados mock baseados no role
    final mockUser = _createMockUser();
    final mockContextualData = _createMockContextualData();
    
    // Armazenar dados de teste no contexto global ou shared preferences
    // Por enquanto, vamos usar um evento customizado
    context.read<AuthBloc>().add(
      AuthTestLoginRequested(
        user: mockUser,
        role: _selectedRole,
        allocationType: _selectedAllocationType,
        contextualData: mockContextualData,
      ),
    );
  }

  User _createMockUser() {
    // Mapear roles para os tipos corretos usados na navegação
    String mappedRole = _selectedRole;
    switch (_selectedRole) {
      case 'lawyer_contracting':
        mappedRole = 'lawyer_individual'; // Mapear para individual
        break;
      case 'firm':
        mappedRole = 'lawyer_office'; // Mapear para office
        break;
      default:
        mappedRole = _selectedRole;
    }
    
    return User(
      id: 'test_user_${_selectedRole}',
      email: '${_selectedRole}@test.com',
      fullName: _getRoleDisplayName(_selectedRole),
      role: _selectedRole,
      userRole: mappedRole, // Usar o role mapeado
      permissions: _getPermissionsForRole(_selectedRole),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  ContextualCaseData? _createMockContextualData() {
    switch (_selectedAllocationType) {
      case 'internal_delegation':
        return ContextualCaseData(
          allocationType: AllocationType.internalDelegation,
          delegatedByName: 'Dr. Silva',
          deadlineDays: 15,
          hourlyRate: 150.0,
          hoursBudgeted: 40,
          complexityScore: 7,
        );
      case 'platform_match_direct':
        return ContextualCaseData(
          allocationType: AllocationType.platformMatchDirect,
          matchScore: 0.85,
          partnerName: 'Dr. Santos',
          partnerSpecialization: 'Trabalhista',
          partnerRating: 4.8,
          estimatedValue: 50000.0,
          conversionRate: 0.75,
          complexityScore: 6,
        );
      case 'partnership_proactive_search':
        return ContextualCaseData(
          allocationType: AllocationType.partnershipProactiveSearch,
          partnerName: 'Escritório ABC',
          collaborationArea: 'Trabalhista + Tributário',
          yourShare: 60,
          partnerShare: 40,
          distance: 25.5,
          estimatedValue: 75000.0,
        );
      case 'partnership_platform_suggestion':
        return ContextualCaseData(
          allocationType: AllocationType.partnershipPlatformSuggestion,
          partnerName: 'Dr. Costa',
          partnerSpecialization: 'Direito Empresarial',
          matchScore: 0.92,
          aiSuccessRate: 0.88,
          aiReason: 'Especialização complementar',
          estimatedValue: 60000.0,
        );
      default:
        return null;
    }
  }

  List<String> _getPermissionsForRole(String role) {
    switch (role) {
      case 'client':
        return ['view_own_cases', 'upload_documents'];
      case 'lawyer_associate':
        return ['view_assigned_cases', 'update_case_status', 'time_tracking'];
      case 'lawyer_contracting':
        // Advogados contratantes devem ter as mesmas permissões dos super associados
        return [
          'nav.view.home',
          'nav.view.contractor_offers',
          'nav.view.partners',
          'nav.view.partnerships',
          'nav.view.contractor_cases',
          'nav.view.contractor_messages',
          'nav.view.contractor_profile',
        ];
      case 'lawyer_platform_associate':
        return [
          'nav.view.home',
          'nav.view.contractor_offers',
          'nav.view.partners',
          'nav.view.partnerships',
          'nav.view.contractor_cases',
          'nav.view.contractor_messages',
          'nav.view.contractor_profile',
        ];
      case 'firm':
        // Escritórios também devem ter as mesmas permissões dos super associados
        return [
          'nav.view.home',
          'nav.view.contractor_offers',
          'nav.view.partners',
          'nav.view.partnerships',
          'nav.view.contractor_cases',
          'nav.view.contractor_messages',
          'nav.view.contractor_profile',
        ];
      default:
        return ['view_own_cases'];
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'client':
        return 'Cliente';
      case 'lawyer_associate':
        return 'Advogado Associado';
      case 'lawyer_contracting':
        return 'Advogado Contratante';
      case 'lawyer_platform_associate':
        return 'Super Associado';
      case 'firm':
        return 'Escritório';
      default:
        return 'Cliente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, auth_states.AuthState>(
        listener: (context, state) {
          if (state is auth_states.AuthError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 32),
                    _buildForm(context),
                    const SizedBox(height: 24),
                    _buildDivider(context),
                    const SizedBox(height: 24),
                    _buildSocialLogin(context),
                    const SizedBox(height: 32),
                    _buildRegisterPrompt(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Icon(
          LucideIcons.shieldCheck,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Acesse sua Conta',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        _buildRoleSelector(context),
      ],
    );
  }

  Widget _buildRoleSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🧪 Modo de Teste',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione o tipo de usuário para testar:',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          
          // Seletor de Role
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Usuário',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'client',
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue, size: 16),
                          const SizedBox(width: 8),
                          const Text('Cliente'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'lawyer_associate',
                      child: Row(
                        children: [
                          Icon(Icons.work, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          const Text('Advogado Associado'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'lawyer_contracting',
                      child: Row(
                        children: [
                          Icon(Icons.business, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          const Text('Advogado Contratante'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'lawyer_platform_associate',
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.purple, size: 16),
                          const SizedBox(width: 8),
                          const Text('Super Associado'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'firm',
                      child: Row(
                        children: [
                          Icon(Icons.account_balance, color: Colors.indigo, size: 16),
                          const SizedBox(width: 8),
                          const Text('Escritório'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedAllocationType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Alocação',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'default',
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.grey, size: 16),
                          const SizedBox(width: 8),
                          const Text('Padrão'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'internal_delegation',
                      child: Row(
                        children: [
                          Icon(Icons.people, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          const Text('Delegação Interna'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'platform_match_direct',
                      child: Row(
                        children: [
                          Icon(Icons.trending_up, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          const Text('Match Direto'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'partnership_proactive_search',
                      child: Row(
                        children: [
                          Icon(Icons.handshake, color: Colors.blue, size: 16),
                          const SizedBox(width: 8),
                          const Text('Parceria Ativa'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'partnership_platform_suggestion',
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.purple, size: 16),
                          const SizedBox(width: 8),
                          const Text('Sugestão IA'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAllocationType = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: 'E-mail',
              prefixIcon: Icon(LucideIcons.mail),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || v.isEmpty || !v.contains('@')) ? 'E-mail inválido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              hintText: 'Senha',
              prefixIcon: const Icon(LucideIcons.lock),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                icon: Icon(_isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye),
              ),
            ),
            obscureText: !_isPasswordVisible,
            validator: (v) => (v == null || v.length < 8) ? 'A senha deve ter pelo menos 8 caracteres' : null,
          ),
          const SizedBox(height: 8),
          _buildForgotPassword(context),
          const SizedBox(height: 24),
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildForgotPassword(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // TODO: Implementar lógica de esqueci a senha
        },
        child: Text(
          'Esqueceu a senha?',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return BlocBuilder<AuthBloc, auth_states.AuthState>(
      builder: (context, state) {
        final isLoading = state is auth_states.AuthLoading;
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: isLoading ? null : _handleLogin,
          child: isLoading
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : const Text('Entrar'),
        );
      },
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildSocialLogin(BuildContext context) {
    return BlocBuilder<AuthBloc, auth_states.AuthState>(
      builder: (context, state) {
        final isLoading = state is auth_states.AuthLoading;
        return Column(
          children: [
            // Google OAuth (funcional)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: isLoading
                  ? null
                  : () {
                      context.read<AuthBloc>().add(AuthGoogleSignInRequested());
                    },
              icon: const Icon(LucideIcons.user), // Placeholder for Google icon
              label: const Text('Entrar com Google'),
            ),
            
            const SizedBox(height: 12),
            
            // Redes Sociais (em desenvolvimento)
            Text(
              'Outras opções sociais:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: isLoading ? Colors.grey[400] : const Color(0xFF0077B5), // LinkedIn Blue
                      side: BorderSide(color: isLoading ? Colors.grey[300]! : const Color(0xFF0077B5)),
                    ),
                    onPressed: isLoading ? null : () {
                      context.read<AuthBloc>().add(AuthLinkedInSignInRequested());
                    },
                    icon: const Icon(LucideIcons.briefcase, size: 16),
                    label: const Text('LinkedIn'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: isLoading ? Colors.grey[400] : const Color(0xFFE4405F), // Instagram Pink
                      side: BorderSide(color: isLoading ? Colors.grey[300]! : const Color(0xFFE4405F)),
                    ),
                    onPressed: isLoading ? null : () {
                      context.read<AuthBloc>().add(AuthInstagramSignInRequested());
                    },
                    icon: const Icon(LucideIcons.camera, size: 16),
                    label: const Text('Instagram'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: isLoading ? Colors.grey[400] : const Color(0xFF1877F2), // Facebook Blue
                      side: BorderSide(color: isLoading ? Colors.grey[300]! : const Color(0xFF1877F2)),
                    ),
                    onPressed: isLoading ? null : () {
                      context.read<AuthBloc>().add(AuthFacebookSignInRequested());
                    },
                    icon: const Icon(LucideIcons.facebook, size: 16),
                    label: const Text('Facebook'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRegisterPrompt(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Cadastro de Cliente
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Não tem uma conta?'),
            TextButton(
              onPressed: () => context.go('/register-client'),
              child: Text(
                'Cadastre-se como Cliente',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        
        const Divider(),
        
        const SizedBox(height: 24),

        // Cadastro de Advogado
        Text('É advogado(a)? Cadastre-se como:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.user),
              label: const Text('Autônomo'),
              onPressed: () => context.go('/register-lawyer', extra: {'role': 'lawyer_individual'}),
            ),
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.users),
              label: const Text('Associado'),
              onPressed: () => context.go('/register-lawyer', extra: {'role': 'lawyer_associated'}),
            ),
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.building),
              label: const Text('Escritório'),
              onPressed: () => context.go('/register-lawyer', extra: {'role': 'lawyer_office'}),
            ),
          ],
        )
      ],
    );
  }
}
