import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/core/theme/theme_cubit.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final showSlaSettings = authState is Authenticated && 
              (authState.user.role == 'lawyer_office' || 
               authState.user.role == 'lawyer_associated');

          return ListView(
            children: [
              ListTile(
                leading: const Icon(LucideIcons.bell),
                title: const Text('Notificações'),
                subtitle: const Text('Gerencie suas preferências de notificação'),
                onTap: () {
                  // Navegar para a tela de configurações de notificação
                },
              ),
              
              // Configurações SLA (apenas para advogados de escritório)
              if (showSlaSettings)
                ListTile(
                  leading: const Icon(LucideIcons.clock),
                  title: const Text('Configurações SLA'),
                  subtitle: const Text('Gerencie prazos de delegação interna do escritório'),
                  onTap: () {
                    context.push('/sla-settings');
                  },
                ),
              
              SwitchListTile(
                title: const Text('Tema Escuro'),
                subtitle: const Text('Ative para uma experiência com cores escuras'),
                value: context.watch<ThemeCubit>().state == ThemeMode.dark,
                onChanged: (bool value) {
                  context.read<ThemeCubit>().setTheme(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                },
                secondary: const Icon(LucideIcons.moon),
              ),
              ListTile(
                leading: const Icon(LucideIcons.shield),
                title: const Text('Privacidade e Segurança'),
                subtitle: const Text('Ajuste suas configurações de privacidade'),
                onTap: () {
                  // Navegar para a tela de privacidade
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.helpCircle),
                title: const Text('Ajuda e Suporte'),
                subtitle: const Text('Encontre ajuda ou entre em contato conosco'),
                onTap: () {
                  // Abrir link de suporte
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(LucideIcons.logOut, color: Colors.red.shade700),
                title: Text('Sair', style: TextStyle(color: Colors.red.shade700)),
                onTap: () {
                  // Lógica de logout
                },
              ),
            ],
          );
        },
      ),
    );
  }
} 
              ListTile(
                leading = const Icon(LucideIcons.helpCircle),
                title = const Text('Ajuda e Suporte'),
                subtitle = const Text('Encontre ajuda ou entre em contato conosco'),
                onTap = () {
                  // Abrir link de suporte
                },
              ),
              Divider(),
              ListTile(
                leading = Icon(LucideIcons.logOut, color: Colors.red.shade700),
                title = Text('Sair', style: TextStyle(color: Colors.red.shade700)),
                onTap = () {
                  // Lógica de logout
                },
              ),
            ],
          );
        },
      ),
    );
  }
} 