# 🎨 Guia Prático: Como Restaurar as Cores e Tema Originais

## 📋 Objetivo

Este guia mostra como implementar as cores e tema originais do LITGO5/LITGO6 (React Native) no app Flutter atual, mantendo compatibilidade com o sistema existente.

## 🔍 Cores Originais Identificadas

### Android Original
```xml
<!-- archive/android_backup/app/src/main/res/values/colors.xml -->
<color name="colorPrimary">#023c69</color>         <!-- Azul petróleo escuro -->
<color name="colorPrimaryDark">#ffffff</color>     <!-- Branco -->
<color name="splashscreen_background">#FFFFFF</color> <!-- Fundo branco -->
<color name="iconBackground">#ffffff</color>       <!-- Ícones brancos -->
```

### Conversão para Flutter
```dart
// Cores extraídas do design original
static const Color originalPrimary = Color(0xFF023c69);      // Azul petróleo
static const Color originalPrimaryDark = Color(0xFF001a2e);  // Azul mais escuro
static const Color originalBackground = Color(0xFFFFFFFF);   // Branco puro
static const Color originalCard = Color(0xFFFFFFFF);         // Cartões brancos
```

## 🛠️ Implementação: Opção 1 - Substituição Direta

### Modificar AppColors Existente
```dart
// Arquivo: apps/app_flutter/lib/src/shared/utils/app_colors.dart

class AppColors {
  // CORES PRIMÁRIAS - RESTAURADAS AO ORIGINAL
  static const Color primaryBlue = Color(0xFF023c69);      // Original azul petróleo
  static const Color primaryDark = Color(0xFF001a2e);      // Azul mais escuro
  static const Color primaryLight = Color(0xFF2d5a87);     // Azul mais claro
  
  // CORES SECUNDÁRIAS - MANTIDAS
  static const Color secondaryGreen = Color(0xFF10B981);
  static const Color secondaryRed = Color(0xFFEF4444);
  static const Color secondaryYellow = Color(0xFFF59E0B);
  static const Color secondaryPurple = Color(0xFF8B5CF6);
  
  // CORES DE FUNDO - RESTAURADAS AO ORIGINAL
  static const Color lightBackground = Color(0xFFFFFFFF);   // Branco puro original
  static const Color lightCard = Color(0xFFFFFFFF);         // Cartões brancos
  static const Color lightBorder = Color(0xFFE2E8F0);       // Bordas sutis
  
  // CORES DE TEXTO - AJUSTADAS PARA CONTRASTE
  static const Color lightText = Color(0xFF1E293B);
  static const Color lightText2 = Color(0xFF64748B);
  static const Color lightTextSecondary = Color(0xFF94A3B8);
  
  // TEMA ESCURO - BASEADO NO ORIGINAL
  static const Color darkBackground = Color(0xFF001a2e);    // Baseado no primaryDark
  static const Color darkCard = Color(0xFF023c69);          // Usando primary original
  static const Color darkBorder = Color(0xFF2d5a87);        // Azul intermediário
  
  // CORES DE TEXTO ESCURO
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkText2 = Color(0xFFCBD5E1);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  
  // ... resto das cores mantidas
}
```

## 🎭 Implementação: Opção 2 - Tema Clássico Opcional

### Criar Novo Arquivo de Tema Clássico
```dart
// Novo arquivo: apps/app_flutter/lib/src/core/theme/classic_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ClassicAppColors {
  // Paleta original do LITGO5/LITGO6
  static const Color primary = Color(0xFF023c69);        // Azul petróleo original
  static const Color primaryDark = Color(0xFF001a2e);    // Azul escuro
  static const Color primaryLight = Color(0xFF2d5a87);   // Azul claro
  
  static const Color background = Color(0xFFFFFFFF);     // Branco puro
  static const Color surface = Color(0xFFFFFFFF);        // Superfícies brancas
  static const Color border = Color(0xFFE5E7EB);         // Bordas sutis
  
  static const Color text = Color(0xFF1F2937);           // Texto escuro
  static const Color textSecondary = Color(0xFF6B7280);  // Texto secundário
  static const Color textLight = Color(0xFF9CA3AF);      // Texto claro
}

class ClassicTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: false);
    
    return base.copyWith(
      // Cores principais
      primaryColor: ClassicAppColors.primary,
      scaffoldBackgroundColor: ClassicAppColors.background,
      
      colorScheme: base.colorScheme.copyWith(
        primary: ClassicAppColors.primary,
        primaryContainer: ClassicAppColors.primaryLight,
        secondary: ClassicAppColors.primary,
        surface: ClassicAppColors.surface,
        background: ClassicAppColors.background,
      ),
      
      // Tipografia
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: ClassicAppColors.text,
        displayColor: ClassicAppColors.text,
      ),
      
      // AppBar no estilo original
      appBarTheme: AppBarTheme(
        backgroundColor: ClassicAppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // Cartões no estilo original
      cardTheme: CardThemeData(
        color: ClassicAppColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Bordas menos arredondadas
        ),
      ),
      
      // Bottom Navigation no estilo original
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: ClassicAppColors.primary,
        unselectedItemColor: ClassicAppColors.textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8, // Mais elevação para o estilo original
      ),
      
      // Botões no estilo original
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ClassicAppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
  
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: false);
    
    return base.copyWith(
      // Tema escuro baseado no azul petróleo
      primaryColor: ClassicAppColors.primary,
      scaffoldBackgroundColor: ClassicAppColors.primaryDark,
      
      colorScheme: base.colorScheme.copyWith(
        primary: ClassicAppColors.primary,
        secondary: ClassicAppColors.primary,
        surface: ClassicAppColors.primary,
        background: ClassicAppColors.primaryDark,
      ),
      
      // ... resto da configuração escura
    );
  }
}
```

### Integrar no Sistema de Temas
```dart
// Modificar: apps/app_flutter/lib/src/core/theme/theme_cubit.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'classic_theme.dart'; // Importar novo tema

enum AppThemeMode {
  light,
  dark,
  classicLight,  // NOVO: Tema clássico claro
  classicDark,   // NOVO: Tema clássico escuro
}

class ThemeCubit extends Cubit<AppThemeMode> {
  ThemeCubit() : super(AppThemeMode.dark);

  void setTheme(AppThemeMode themeMode) {
    emit(themeMode);
  }
  
  // Método para obter o ThemeData baseado no modo
  ThemeData getThemeData(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return AppTheme.light();
      case AppThemeMode.dark:
        return AppTheme.dark();
      case AppThemeMode.classicLight:
        return ClassicTheme.light();  // NOVO
      case AppThemeMode.classicDark:
        return ClassicTheme.dark();   // NOVO
    }
  }
}
```

### Adicionar Seletor de Tema na UI
```dart
// Em alguma tela de configurações
class ThemeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppThemeMode>(
      builder: (context, currentTheme) {
        return Column(
          children: [
            ListTile(
              title: Text('Tema Moderno Claro'),
              leading: Icon(Icons.light_mode),
              trailing: currentTheme == AppThemeMode.light 
                ? Icon(Icons.check, color: Colors.green) 
                : null,
              onTap: () => context.read<ThemeCubit>().setTheme(AppThemeMode.light),
            ),
            ListTile(
              title: Text('Tema Moderno Escuro'),
              leading: Icon(Icons.dark_mode),
              trailing: currentTheme == AppThemeMode.dark 
                ? Icon(Icons.check, color: Colors.green) 
                : null,
              onTap: () => context.read<ThemeCubit>().setTheme(AppThemeMode.dark),
            ),
            Divider(),
            ListTile(
              title: Text('Tema Clássico Claro'),
              subtitle: Text('Design original LITGO5/LITGO6'),
              leading: Icon(Icons.palette, color: Color(0xFF023c69)),
              trailing: currentTheme == AppThemeMode.classicLight 
                ? Icon(Icons.check, color: Colors.green) 
                : null,
              onTap: () => context.read<ThemeCubit>().setTheme(AppThemeMode.classicLight),
            ),
            ListTile(
              title: Text('Tema Clássico Escuro'),
              subtitle: Text('Baseado no azul petróleo original'),
              leading: Icon(Icons.palette, color: Color(0xFF001a2e)),
              trailing: currentTheme == AppThemeMode.classicDark 
                ? Icon(Icons.check, color: Colors.green) 
                : null,
              onTap: () => context.read<ThemeCubit>().setTheme(AppThemeMode.classicDark),
            ),
          ],
        );
      },
    );
  }
}
```

## 🎯 Recomendação de Implementação

### Abordagem Sugerida: **Opção 2 (Tema Clássico Opcional)**

**Vantagens:**
- ✅ Mantém compatibilidade com design atual
- ✅ Oferece opção nostálgica para usuários antigos
- ✅ Permite A/B testing entre designs
- ✅ Não quebra código existente

**Passos:**
1. Implementar `ClassicTheme` e `ClassicAppColors`
2. Estender `ThemeCubit` para suportar 4 modos
3. Adicionar seletor de tema nas configurações
4. Testar ambos os temas em diferentes telas

## 📊 Comparação Visual

| Elemento | Original (LITGO5/6) | Atual (LITIG-1) | Clássico Proposto |
|----------|-------------------|----------------|------------------|
| **Primary** | #023c69 (Azul petróleo) | #2563EB (Azul moderno) | #023c69 (Restaurado) |
| **Background** | #FFFFFF (Branco) | #F8FAFC (Cinza claro) | #FFFFFF (Restaurado) |
| **Cards** | Bordas quadradas | Bordas arredondadas (16px) | Bordas sutis (8px) |
| **Elevação** | Mais pronunciada | Sutil (4px) | Moderada (2px) |
| **AppBar** | Azul petróleo sólido | Gradiente azul | Azul petróleo sólido |

## 🚀 Próximos Passos

1. **Escolher abordagem** (substituição ou tema opcional)
2. **Implementar código** seguindo o guia
3. **Testar em diferentes telas** do app
4. **Coletar feedback** dos usuários
5. **Ajustar cores** se necessário para acessibilidade

---

**Resultado esperado:** App com opção de usar o design original do LITGO5/LITGO6 mantendo toda a funcionalidade moderna do Flutter.