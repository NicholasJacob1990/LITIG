import 'package:flutter/material.dart';
import '../../core/enums/legal_areas.dart';

/// Widget para seleção múltipla de áreas jurídicas
class LegalAreasSelector extends StatefulWidget {
  final List<String> initialValues;
  final Function(List<String>) onChanged;
  final String? label;
  final bool required;

  const LegalAreasSelector({
    super.key,
    required this.initialValues,
    required this.onChanged,
    this.label,
    this.required = false,
  });

  @override
  State<LegalAreasSelector> createState() => _LegalAreasSelectorState();
}

class _LegalAreasSelectorState extends State<LegalAreasSelector> {
  late List<LegalArea> selectedAreas;

  @override
  void initState() {
    super.initState();
    selectedAreas = LegalArea.fromStringList(widget.initialValues);
  }

  void _showSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _LegalAreasDialog(
          selectedAreas: selectedAreas,
          onConfirm: (areas) {
            setState(() {
              selectedAreas = areas;
            });
            widget.onChanged(LegalArea.toStringList(areas));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.label!,
              style: theme.textTheme.labelLarge,
            ),
          ),
        InkWell(
          onTap: _showSelectionDialog,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: selectedAreas.isEmpty
                      ? Text(
                          'Selecione as áreas de atuação',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedAreas.map((area) {
                            return Chip(
                              label: Text(
                                '${area.icon} ${area.value}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Color(area.color).withOpacity(0.1),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  selectedAreas.remove(area);
                                });
                                widget.onChanged(LegalArea.toStringList(selectedAreas));
                              },
                            );
                          }).toList(),
                        ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        if (widget.required && selectedAreas.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Selecione pelo menos uma área',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

/// Dialog para seleção de áreas jurídicas
class _LegalAreasDialog extends StatefulWidget {
  final List<LegalArea> selectedAreas;
  final Function(List<LegalArea>) onConfirm;

  const _LegalAreasDialog({
    required this.selectedAreas,
    required this.onConfirm,
  });

  @override
  State<_LegalAreasDialog> createState() => _LegalAreasDialogState();
}

class _LegalAreasDialogState extends State<_LegalAreasDialog> {
  late List<LegalArea> tempSelectedAreas;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    tempSelectedAreas = List.from(widget.selectedAreas);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categorizedAreas = LegalArea.categorized;

    return AlertDialog(
      title: Column(
        children: [
          const Text('Selecione as Áreas de Atuação'),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar área...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView(
          children: categorizedAreas.entries.map((category) {
            final filteredAreas = category.value.where((area) {
              return searchQuery.isEmpty ||
                  area.value.toLowerCase().contains(searchQuery) ||
                  area.displayName.toLowerCase().contains(searchQuery);
            }).toList();

            if (filteredAreas.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    category.key,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...filteredAreas.map((area) {
                  final isSelected = tempSelectedAreas.contains(area);
                  return CheckboxListTile(
                    title: Text('${area.icon} ${area.displayName}'),
                    subtitle: Text(area.value),
                    value: isSelected,
                    activeColor: Color(area.color),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          tempSelectedAreas.add(area);
                        } else {
                          tempSelectedAreas.remove(area);
                        }
                      });
                    },
                  );
                }).toList(),
                const Divider(),
              ],
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            widget.onConfirm(tempSelectedAreas);
            Navigator.of(context).pop();
          },
          child: Text('Confirmar (${tempSelectedAreas.length})'),
        ),
      ],
    );
  }
}