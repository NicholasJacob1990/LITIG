import 'package:flutter/material.dart';

/// Sistema de breakpoints responsivos para LITIG-1
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double widescreen = 1600;
  
  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < desktop;
  static bool isDesktop(double width) => width >= desktop;
  static bool isWidescreen(double width) => width >= widescreen;
}

/// Widget responsivo que adapta layout baseado na largura
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? widescreen;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.widescreen,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        if (ResponsiveBreakpoints.isWidescreen(width) && widescreen != null) {
          return widescreen!;
        } else if (ResponsiveBreakpoints.isDesktop(width) && desktop != null) {
          return desktop!;
        } else if (ResponsiveBreakpoints.isTablet(width) && tablet != null) {
          return tablet!;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Card de perfil responsivo
class ResponsiveProfileCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? description;
  final Widget? avatar;
  final List<Widget> actions;
  
  const ResponsiveProfileCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.description,
    this.avatar,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileCard(context),
      tablet: _buildTabletCard(context),
      desktop: _buildDesktopCard(context),
    );
  }

  Widget _buildMobileCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, isVertical: true),
            if (description != null) ...[
              const SizedBox(height: 12),
              Text(description!),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabletCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, isVertical: false),
            if (description != null) ...[
              const SizedBox(height: 16),
              Text(description!),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: actions.map((action) => 
                  Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: action,
                  ))
                ).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isVertical: false),
                  if (description != null) ...[
                    const SizedBox(height: 16),
                    Text(description!),
                  ],
                ],
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: Column(
                  children: actions,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isVertical}) {
    if (isVertical) {
      return Column(
        children: [
          if (avatar != null) ...[
            avatar!,
            const SizedBox(height: 12),
          ],
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
    } else {
      return Row(
        children: [
          if (avatar != null) ...[
            avatar!,
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      );
    }
  }
} 