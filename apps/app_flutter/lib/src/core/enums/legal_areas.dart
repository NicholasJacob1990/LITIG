/// Enum para áreas jurídicas suportadas - Cobertura completa do mercado brasileiro
enum LegalArea {
  // Áreas Principais (já existentes)
  trabalhista('Trabalhista', 'Direito do Trabalho'),
  civil('Civil', 'Direito Civil'),
  criminal('Criminal', 'Direito Criminal'),
  tributario('Tributário', 'Direito Tributário'),
  previdenciario('Previdenciário', 'Direito Previdenciário'),
  consumidor('Consumidor', 'Direito do Consumidor'),
  familia('Família', 'Direito de Família'),
  empresarial('Empresarial', 'Direito Empresarial'),
  
  // Direito Público (alta prioridade)
  administrativo('Administrativo', 'Direito Administrativo'),
  constitucional('Constitucional', 'Direito Constitucional'),
  eleitoral('Eleitoral', 'Direito Eleitoral'),
  
  // Direito Especializado (alta demanda)
  imobiliario('Imobiliário', 'Direito Imobiliário'),
  ambiental('Ambiental', 'Direito Ambiental'),
  bancario('Bancário', 'Direito Bancário'),
  seguros('Seguros', 'Direito de Seguros'),
  saude('Saúde', 'Direito da Saúde'),
  educacional('Educacional', 'Direito Educacional'),
  
  // Direito Empresarial Especializado
  propriedadeIntelectual('Propriedade Intelectual', 'Direito de Propriedade Intelectual'),
  concorrencial('Concorrencial', 'Direito Concorrencial'),
  societario('Societário', 'Direito Societário'),
  recuperacaoJudicial('Recuperação Judicial', 'Recuperação Judicial e Falência'),
  
  // Direito Internacional e Regulatório
  internacional('Internacional', 'Direito Internacional'),
  regulatorio('Regulatório', 'Direito Regulatório'),
  telecomunicacoes('Telecomunicações', 'Direito das Telecomunicações'),
  energia('Energia', 'Direito da Energia'),
  
  // Direitos Especiais
  militar('Militar', 'Direito Militar'),
  agrario('Agrário', 'Direito Agrário'),
  maritimo('Marítimo', 'Direito Marítimo'),
  aeronautico('Aeronáutico', 'Direito Aeronáutico'),
  
  // Direitos Emergentes
  digital('Digital', 'Direito Digital'),
  desportivo('Desportivo', 'Direito Desportivo'),
  medico('Médico', 'Direito Médico');

  final String value;
  final String displayName;

  const LegalArea(this.value, this.displayName);

  /// Retorna todas as áreas organizadas por categoria
  static Map<String, List<LegalArea>> get categorized => {
    'Áreas Principais': [
      LegalArea.trabalhista,
      LegalArea.civil,
      LegalArea.criminal,
      LegalArea.tributario,
      LegalArea.previdenciario,
      LegalArea.consumidor,
      LegalArea.familia,
      LegalArea.empresarial,
    ],
    'Direito Público': [
      LegalArea.administrativo,
      LegalArea.constitucional,
      LegalArea.eleitoral,
    ],
    'Direito Especializado': [
      LegalArea.imobiliario,
      LegalArea.ambiental,
      LegalArea.bancario,
      LegalArea.seguros,
      LegalArea.saude,
      LegalArea.educacional,
    ],
    'Direito Empresarial': [
      LegalArea.propriedadeIntelectual,
      LegalArea.concorrencial,
      LegalArea.societario,
      LegalArea.recuperacaoJudicial,
    ],
    'Direito Internacional e Regulatório': [
      LegalArea.internacional,
      LegalArea.regulatorio,
      LegalArea.telecomunicacoes,
      LegalArea.energia,
    ],
    'Direitos Especiais': [
      LegalArea.militar,
      LegalArea.agrario,
      LegalArea.maritimo,
      LegalArea.aeronautico,
    ],
    'Direitos Emergentes': [
      LegalArea.digital,
      LegalArea.desportivo,
      LegalArea.medico,
    ],
  };

  /// Converte string para LegalArea
  static LegalArea? fromString(String value) {
    try {
      return LegalArea.values.firstWhere(
        (area) => area.value.toLowerCase() == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Retorna lista de áreas a partir de strings
  static List<LegalArea> fromStringList(List<String> values) {
    return values
        .map((v) => fromString(v))
        .where((area) => area != null)
        .cast<LegalArea>()
        .toList();
  }

  /// Converte lista de LegalArea para strings
  static List<String> toStringList(List<LegalArea> areas) {
    return areas.map((area) => area.value).toList();
  }
}

/// Extension methods para LegalArea
extension LegalAreaExtension on LegalArea {
  /// Retorna ícone sugerido para a área
  String get icon {
    switch (this) {
      case LegalArea.trabalhista:
        return '⚒️';
      case LegalArea.civil:
        return '📜';
      case LegalArea.criminal:
        return '⚖️';
      case LegalArea.tributario:
        return '💰';
      case LegalArea.previdenciario:
        return '🏛️';
      case LegalArea.consumidor:
        return '🛒';
      case LegalArea.familia:
        return '👨‍👩‍👧‍👦';
      case LegalArea.empresarial:
        return '🏢';
      case LegalArea.administrativo:
        return '🏛️';
      case LegalArea.constitucional:
        return '📋';
      case LegalArea.eleitoral:
        return '🗳️';
      case LegalArea.imobiliario:
        return '🏠';
      case LegalArea.ambiental:
        return '🌿';
      case LegalArea.bancario:
        return '🏦';
      case LegalArea.seguros:
        return '🛡️';
      case LegalArea.saude:
        return '🏥';
      case LegalArea.educacional:
        return '🎓';
      case LegalArea.propriedadeIntelectual:
        return '💡';
      case LegalArea.concorrencial:
        return '🏆';
      case LegalArea.societario:
        return '🤝';
      case LegalArea.recuperacaoJudicial:
        return '🔄';
      case LegalArea.internacional:
        return '🌍';
      case LegalArea.regulatorio:
        return '📊';
      case LegalArea.telecomunicacoes:
        return '📡';
      case LegalArea.energia:
        return '⚡';
      case LegalArea.militar:
        return '🎖️';
      case LegalArea.agrario:
        return '🌾';
      case LegalArea.maritimo:
        return '🚢';
      case LegalArea.aeronautico:
        return '✈️';
      case LegalArea.digital:
        return '💻';
      case LegalArea.desportivo:
        return '⚽';
      case LegalArea.medico:
        return '⚕️';
    }
  }

  /// Retorna cor sugerida para a área
  int get color {
    switch (this) {
      case LegalArea.trabalhista:
        return 0xFF2563EB; // Blue
      case LegalArea.civil:
        return 0xFF7C3AED; // Purple
      case LegalArea.criminal:
        return 0xFFDC2626; // Red
      case LegalArea.tributario:
        return 0xFF16A34A; // Green
      case LegalArea.previdenciario:
        return 0xFFF59E0B; // Amber
      case LegalArea.consumidor:
        return 0xFFEC4899; // Pink
      case LegalArea.familia:
        return 0xFF8B5CF6; // Violet
      case LegalArea.empresarial:
        return 0xFF0891B2; // Cyan
      case LegalArea.administrativo:
        return 0xFF6366F1; // Indigo
      case LegalArea.constitucional:
        return 0xFF84CC16; // Lime
      case LegalArea.eleitoral:
        return 0xFFF97316; // Orange
      case LegalArea.imobiliario:
        return 0xFF14B8A6; // Teal
      case LegalArea.ambiental:
        return 0xFF10B981; // Emerald
      case LegalArea.bancario:
        return 0xFF3B82F6; // Blue
      case LegalArea.seguros:
        return 0xFF6B7280; // Gray
      case LegalArea.saude:
        return 0xFFEF4444; // Red
      case LegalArea.educacional:
        return 0xFF8B5CF6; // Violet
      case LegalArea.propriedadeIntelectual:
        return 0xFFF59E0B; // Amber
      case LegalArea.concorrencial:
        return 0xFFEC4899; // Pink
      case LegalArea.societario:
        return 0xFF2563EB; // Blue
      case LegalArea.recuperacaoJudicial:
        return 0xFF7C3AED; // Purple
      case LegalArea.internacional:
        return 0xFF0891B2; // Cyan
      case LegalArea.regulatorio:
        return 0xFF6366F1; // Indigo
      case LegalArea.telecomunicacoes:
        return 0xFF3B82F6; // Blue
      case LegalArea.energia:
        return 0xFFF59E0B; // Amber
      case LegalArea.militar:
        return 0xFF16A34A; // Green
      case LegalArea.agrario:
        return 0xFF84CC16; // Lime
      case LegalArea.maritimo:
        return 0xFF0891B2; // Cyan
      case LegalArea.aeronautico:
        return 0xFF3B82F6; // Blue
      case LegalArea.digital:
        return 0xFF8B5CF6; // Violet
      case LegalArea.desportivo:
        return 0xFF10B981; // Emerald
      case LegalArea.medico:
        return 0xFFEF4444; // Red
    }
  }
}