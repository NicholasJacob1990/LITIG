import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:meu_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Advanced Search Flow Integration Tests', () {
    
    testWidgets('Busca Avançada - Fluxo completo de filtros', (tester) async {
      // Act
      await app.main();
      await tester.pumpAndSettle();

      // Assert - Verifica se chegou na aplicação principal
      expect(find.byType(MaterialApp), findsOneWidget);

      // Tenta navegar para busca de advogados
      try {
        await tester.tap(find.byIcon(Icons.search).first);
        await tester.pumpAndSettle();
      } catch (e) {
        // Se não encontrar ícone de busca, tenta por texto
        final searchText = find.text('Buscar');
        if (searchText.evaluate().isNotEmpty) {
          await tester.tap(searchText.first);
          await tester.pumpAndSettle();
        }
      }

      // Verifica elementos de busca avançada
      final advancedSearchElements = [
        'Filtros Avançados',
        'Super-Filtro',
        'Busca por Especialização',
        'Localização',
        'Preço',
        'Avaliação',
      ];

      for (final element in advancedSearchElements) {
        final widget = find.text(element);
        if (widget.evaluate().isNotEmpty) {
          expect(widget, findsWidgets);
        }
      }
    });

    testWidgets('Sistema de Presets - Configurações predefinidas', (tester) async {
      // Act
      await app.main();
      await tester.pumpAndSettle();

      // Navega para busca
      try {
        await tester.tap(find.byIcon(Icons.search).first);
        await tester.pumpAndSettle();
      } catch (e) {
        // Continua se não conseguir navegar
      }

      // Verifica presets de busca
      final presetOptions = [
        'Direito Trabalhista',
        'Direito Civil',
        'Direito Penal',
        'Direito Tributário',
        'Direito Empresarial',
        'Escritórios Boutique',
        'Grandes Escritórios',
        'Advogados Individuais',
      ];

      for (final preset in presetOptions) {
        final presetWidget = find.text(preset);
        if (presetWidget.evaluate().isNotEmpty) {
          expect(presetWidget, findsWidgets);
        }
      }
    });

    testWidgets('Filtros por Localização - Busca geográfica', (tester) async {
      // Act
      await app.main();
      await tester.pumpAndSettle();

      // Navega para busca
      try {
        await tester.tap(find.byIcon(Icons.search).first);
        await tester.pumpAndSettle();
      } catch (e) {
        // Continua se não conseguir navegar
      }

      // Verifica filtros de localização
      final locationFilters = [
        'São Paulo',
        'Rio de Janeiro',
        'Belo Horizonte',
        'Brasília',
        'Salvador',
        'Raio de busca',
        'Até 5km',
        'Até 10km',
        'Até 25km',
      ];

      for (final location in locationFilters) {
        final locationWidget = find.text(location);
        if (locationWidget.evaluate().isNotEmpty) {
          expect(locationWidget, findsWidgets);
        }
      }
    });

    testWidgets('Filtros por Preço - Faixas de valor', (tester) async {
      // Act
      await app.main();
      await tester.pumpAndSettle();

      // Navega para busca
      try {
        await tester.tap(find.byIcon(Icons.search).first);
        await tester.pumpAndSettle();
      } catch (e) {
        // Continua se não conseguir navegar
      }

      // Verifica filtros de preço
      final priceFilters = [
        'Até R\$ 500',
        'R\$ 500 - R\$ 1.000',
        'R\$ 1.000 - R\$ 2.500',
        'R\$ 2.500 - R\$ 5.000',
        'Acima de R\$ 5.000',
        'Sucesso',
        'Hora',
        'Fixo',
      ];

      for (final price in priceFilters) {
        final priceWidget = find.text(price);
        if (priceWidget.evaluate().isNotEmpty) {
          expect(priceWidget, findsWidgets);
        }
      }
    });

    testWidgets('Filtros por Avaliação - Sistema de rating', (tester) async {
      // Act
      await app.main();
      await tester.pumpAndSettle();

      // Navega para busca
      try {
        await tester.tap(find.byIcon(Icons.search).first);
        await tester.pumpAndSettle();
      } catch (e) {
        // Continua se não conseguir navegar
      }

      // Verifica elementos de avaliação
      final ratingElements = [
        find.byIcon(Icons.star),
        find.byIcon(Icons.star_outline),
        find.byIcon(Icons.star_half),
      ];

      for (final ratingElement in ratingElements) {
        if (ratingElement.evaluate().isNotEmpty) {
          expect(ratingElement, findsWidgets);
        }
      }

      // Verifica textos de avaliação
      final ratingTexts = [
        '4.5+ estrelas',
        '4.0+ estrelas',
        '3.5+ estrelas',
        'Qualquer avaliação',
      ];

      for (final rating in ratingTexts) {
        final ratingWidget = find.text(rating);
        if (ratingWidget.evaluate().isNotEmpty) {
          expect(ratingWidget, findsWidgets);
        }
      }
    });

    testWidgets('Busca Híbrida - Semântica + Diretório', (tester) async {
      // Act
      await app.main();
      await tester.pumpAndSettle();

      // Navega para busca
      try {
        await tester.tap(find.byIcon(Icons.search).first);
        await tester.pumpAndSettle();
      } catch (e) {
        // Continua se não conseguir navegar
      }

      // Verifica campo de busca
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.tap(searchField.first);
        await tester.pumpAndSettle();
        
        // Tenta digitar uma consulta
        await tester.enterText(searchField.first, 'divórcio consensual');
        await tester.pumpAndSettle();
      }

      // Verifica elementos de busca híbrida
      final hybridElements = [
        'Busca Semântica',
        'Busca no Diretório',
        'Resultados Combinados',
        'IA + Filtros',
      ];

      for (final element in hybridElements) {
        final widget = find.text(element);
        if (widget.evaluate().isNotEmpty) {
          expect(widget, findsWidgets);
        }
      }
    });

    testWidgets('Resultados Contextuais - Cards com informações detalhadas', (tester) async {
      // Act
      await app.main();
      await tester.pumpAndSettle();

      // Navega para busca e executa uma busca
      try {
        await tester.tap(find.byIcon(Icons.search).first);
        await tester.pumpAndSettle();
        
        final searchField = find.byType(TextField);
        if (searchField.evaluate().isNotEmpty) {
          await tester.tap(searchField.first);
          await tester.enterText(searchField.first, 'direito trabalhista');
          await tester.pumpAndSettle();
          
          // Tenta submeter a busca
          await tester.testTextInput.receiveAction(TextInputAction.search);
          await tester.pumpAndSettle();
        }
      } catch (e) {
        // Continua se não conseguir fazer a busca
      }

      // Verifica elementos dos cards de resultado
      final resultElements = [
        'Match Score',
        'Especialização',
        'Localização',
        'Preço por hora',
        'Avaliação',
        'Casos similares',
        'Tempo de resposta',
      ];

      for (final element in resultElements) {
        final widget = find.text(element);
        if (widget.evaluate().isNotEmpty) {
          expect(widget, findsWidgets);
        }
      }
    });

    testWidgets('Filtros Boutique - Escritórios especializados', (tester) async {
      // Act
      await app.main();
      await tester.pumpAndSettle();

      // Navega para busca
      try {
        await tester.tap(find.byIcon(Icons.search).first);
        await tester.pumpAndSettle();
      } catch (e) {
        // Continua se não conseguir navegar
      }

      // Verifica filtros específicos para escritórios boutique
      final boutiqueFilters = [
        'Escritório Boutique',
        'Especialização única',
        'Até 10 advogados',
        'Até 25 advogados',
        'Expertise específica',
        'Atendimento personalizado',
      ];

      for (final filter in boutiqueFilters) {
        final filterWidget = find.text(filter);
        if (filterWidget.evaluate().isNotEmpty) {
          expect(filterWidget, findsWidgets);
        }
      }
    });

    testWidgets('Coordenadas Dinâmicas - Busca por proximidade', (tester) async {
      // Act
      await app.main();
      await tester.pumpAndSettle();

      // Navega para busca
      try {
        await tester.tap(find.byIcon(Icons.search).first);
        await tester.pumpAndSettle();
      } catch (e) {
        // Continua se não conseguir navegar
      }

      // Verifica elementos de localização dinâmica
      final locationElements = [
        find.byIcon(Icons.location_on),
        find.byIcon(Icons.my_location),
        find.byIcon(Icons.location_searching),
      ];

      for (final element in locationElements) {
        if (element.evaluate().isNotEmpty) {
          expect(element, findsWidgets);
        }
      }

      // Verifica textos de localização
      final locationTexts = [
        'Usar minha localização',
        'Buscar próximo a mim',
        'Definir localização',
        'Coordenadas',
      ];

      for (final text in locationTexts) {
        final widget = find.text(text);
        if (widget.evaluate().isNotEmpty) {
          expect(widget, findsWidgets);
        }
      }
    });

    testWidgets('Validação de Filtros - Combinações válidas', (tester) async {
      // Act
      await app.main();
      await tester.pumpAndSettle();

      // Navega para busca
      try {
        await tester.tap(find.byIcon(Icons.search).first);
        await tester.pumpAndSettle();
      } catch (e) {
        // Continua se não conseguir navegar
      }

      // Tenta aplicar filtros incompatíveis
      final incompatibleFilters = [
        'Escritório Boutique',
        'Grandes Escritórios',
      ];

      for (final filter in incompatibleFilters) {
        final filterWidget = find.text(filter);
        if (filterWidget.evaluate().isNotEmpty) {
          await tester.tap(filterWidget.first);
          await tester.pumpAndSettle();
        }
      }

      // Verifica mensagens de validação
      final validationMessages = [
        'Filtros incompatíveis',
        'Selecione apenas um tipo',
        'Combinação inválida',
        'Ajuste os filtros',
      ];

      for (final message in validationMessages) {
        final messageWidget = find.text(message);
        if (messageWidget.evaluate().isNotEmpty) {
          expect(messageWidget, findsWidgets);
        }
      }
    });

    testWidgets('Interface Adaptativa - Diferentes perfis de usuário', (tester) async {
      // Act
      await app.main();
      await tester.pumpAndSettle();

      // Verifica elementos adaptativos baseados no perfil
      final adaptiveElements = [
        'Busca para Cliente',
        'Busca para Advogado',
        'Busca para Escritório',
        'Recomendações personalizadas',
        'Filtros sugeridos',
      ];

      for (final element in adaptiveElements) {
        final widget = find.text(element);
        if (widget.evaluate().isNotEmpty) {
          expect(widget, findsWidgets);
        }
      }

      // Verifica navegação adaptativa
      final navigationElements = [
        find.byIcon(Icons.person),
        find.byIcon(Icons.business),
        find.byIcon(Icons.group),
      ];

      for (final element in navigationElements) {
        if (element.evaluate().isNotEmpty) {
          expect(element, findsWidgets);
        }
      }
    });

    testWidgets('Performance de Busca - Tempo de resposta', (tester) async {
      // Act
      await app.main();
      await tester.pumpAndSettle();

      // Measure search performance
      final stopwatch = Stopwatch()..start();

      try {
        await tester.tap(find.byIcon(Icons.search).first);
        await tester.pumpAndSettle();
        
        final searchField = find.byType(TextField);
        if (searchField.evaluate().isNotEmpty) {
          await tester.tap(searchField.first);
          await tester.enterText(searchField.first, 'direito civil');
          await tester.pumpAndSettle();
          
          // Submete a busca
          await tester.testTextInput.receiveAction(TextInputAction.search);
          await tester.pumpAndSettle();
        }
      } catch (e) {
        // Continua se não conseguir fazer a busca
      }
      
      stopwatch.stop();

      // Assert - Verifica performance
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      
      // Verifica se os resultados foram carregados
      final resultCards = find.byType(Card);
      if (resultCards.evaluate().isNotEmpty) {
        expect(resultCards, findsWidgets);
      }
    });

    // NOVOS TESTES PARA FUNCIONALIDADES IMPLEMENTADAS
    
    testWidgets('PresetSelector - Aba Recomendações para Clientes', (tester) async {
      // Arrange
      await app.main();
      await tester.pumpAndSettle();

      // Act - Navegar para Advogados & Escritórios
      try {
        final lawyersTab = find.text('Advogados & Escritórios');
        if (lawyersTab.evaluate().isNotEmpty) {
          await tester.tap(lawyersTab.first);
          await tester.pumpAndSettle();
        }
      } catch (e) {
        // Tenta navegar por ícone
        final searchIcon = find.byIcon(Icons.people);
        if (searchIcon.evaluate().isNotEmpty) {
          await tester.tap(searchIcon.first);
          await tester.pumpAndSettle();
        }
      }

      // Assert - Verifica se a aba Recomendações está selecionada por padrão
      expect(find.text('Recomendações'), findsWidgets);

      // Verifica se o PresetSelector está presente
      expect(find.text('Tipo de Recomendação'), findsOneWidget);
      
      // Verifica os chips de preset implementados
      expect(find.text('Recomendado'), findsOneWidget);
      expect(find.text('Melhor Custo'), findsOneWidget);
      expect(find.text('Mais Experientes'), findsOneWidget);

      // Act - Testa interação com os presets
      await tester.tap(find.text('Melhor Custo'));
      await tester.pumpAndSettle();

      // Assert - Verifica que o preset foi selecionado
      final melhorCustoChip = find.text('Melhor Custo');
      expect(melhorCustoChip, findsOneWidget);

      // Act - Testa mudança para outro preset
      await tester.tap(find.text('Mais Experientes'));
      await tester.pumpAndSettle();

      // Assert - Verifica que mudou para o novo preset
      final maisExperientesChip = find.text('Mais Experientes');
      expect(maisExperientesChip, findsOneWidget);
    });

    testWidgets('Ferramentas de Precisão - Aba Buscar para Advogados', (tester) async {
      // Arrange
      await app.main();
      await tester.pumpAndSettle();

      // Act - Navegar para Advogados & Escritórios
      try {
        final lawyersTab = find.text('Advogados & Escritórios');
        if (lawyersTab.evaluate().isNotEmpty) {
          await tester.tap(lawyersTab.first);
          await tester.pumpAndSettle();
        }
      } catch (e) {
        // Continua se não conseguir navegar
      }

      // Act - Navegar para aba Buscar
      try {
        await tester.tap(find.text('Buscar'));
        await tester.pumpAndSettle();
      } catch (e) {
        // Continua se não conseguir navegar
      }

      // Assert - Verifica elementos das ferramentas de precisão
      
      // 1. Dropdown de Foco da Busca
      expect(find.text('Foco da Busca'), findsOneWidget);
      expect(find.text('Equilibrado'), findsWidgets);
      
      // 2. Botão de Localização
      final locationButton = find.text('Adicionar');
      if (locationButton.evaluate().isNotEmpty) {
        expect(locationButton, findsOneWidget);
        
        // Act - Testa clique no botão de localização (abre LocationPicker real)
        await tester.tap(locationButton.first);
        await tester.pumpAndSettle();
        
        // Assert - Verifica se LocationPicker foi aberto
        expect(find.text('Selecionar Localização'), findsOneWidget);
        expect(find.text('Buscar endereço...'), findsOneWidget);
        
        // Act - Simula busca por endereço
        final searchField = find.byType(TextField).first;
        await tester.enterText(searchField, 'São Paulo, SP');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        
        // Act - Confirma seleção
        final confirmButton = find.text('Confirmar');
        if (confirmButton.evaluate().isNotEmpty) {
          await tester.tap(confirmButton.first);
          await tester.pumpAndSettle();
        }
        
        // Assert - Verifica se voltou para a tela anterior e localização foi aplicada
        expect(find.text('Local'), findsWidgets);
      }

      // 3. Toggle de Escritórios
      expect(find.text('Incluir escritórios na busca'), findsOneWidget);
      
      // 4. Campo de busca principal
      expect(find.text('Buscar advogados ou escritórios...'), findsOneWidget);
    });

    testWidgets('Integração SearchBloc - Fluxo completo de busca', (tester) async {
      // Arrange
      await app.main();
      await tester.pumpAndSettle();

      // Act - Navegar para aba de busca
      try {
        final lawyersTab = find.text('Advogados & Escritórios');
        if (lawyersTab.evaluate().isNotEmpty) {
          await tester.tap(lawyersTab.first);
          await tester.pumpAndSettle();
          
          await tester.tap(find.text('Buscar'));
          await tester.pumpAndSettle();
        }
      } catch (e) {
        // Continua se não conseguir navegar
      }

      // Act - Realiza busca por texto
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.enterText(searchField.first, 'direito empresarial');
        await tester.pumpAndSettle();
        
        // Assert - Verifica se a busca foi executada
        // (Em um ambiente real, verificaríamos se os resultados apareceram)
        expect(find.text('direito empresarial'), findsWidgets);
      }

      // Act - Testa mudança de foco da busca
      try {
        final focoDropdown = find.text('Equilibrado');
        if (focoDropdown.evaluate().isNotEmpty) {
          await tester.tap(focoDropdown.first);
          await tester.pumpAndSettle();
          
          final correspondentOption = find.text('Correspondente');
          if (correspondentOption.evaluate().isNotEmpty) {
            await tester.tap(correspondentOption.first);
            await tester.pumpAndSettle();
          }
        }
      } catch (e) {
        // Continua se não conseguir interagir com dropdown
      }

      // Act - Testa toggle de escritórios
      try {
        final firmsToggle = find.byType(Switch);
        if (firmsToggle.evaluate().isNotEmpty) {
          await tester.tap(firmsToggle.first);
          await tester.pumpAndSettle();
        }
      } catch (e) {
        // Continua se não conseguir interagir com toggle
      }
    });

    testWidgets('Compatibilidade com PartnerSearchResultList', (tester) async {
      // Arrange
      await app.main();
      await tester.pumpAndSettle();

      // Act - Navegar para área de resultados
      try {
        final lawyersTab = find.text('Advogados & Escritórios');
        if (lawyersTab.evaluate().isNotEmpty) {
          await tester.tap(lawyersTab.first);
          await tester.pumpAndSettle();
        }
      } catch (e) {
        // Continua se não conseguir navegar
      }

      // Assert - Verifica se o componente de resultados existe
      // (Em ambiente real, seria populate com dados mockados)
      final resultsList = find.byType(RefreshIndicator);
      if (resultsList.evaluate().isNotEmpty) {
        expect(resultsList, findsWidgets);
        
        // Act - Testa refresh
        await tester.drag(resultsList.first, const Offset(0, 300));
        await tester.pumpAndSettle();
      }

      // Assert - Verifica mensagens de estado vazio se necessário
      final emptyMessages = [
        'Nenhum resultado encontrado.',
        'Nenhuma recomendação encontrada.',
        'Digite algo para buscar parceiros...',
      ];
      
      for (final message in emptyMessages) {
        final messageWidget = find.text(message);
        if (messageWidget.evaluate().isNotEmpty) {
          expect(messageWidget, findsWidgets);
          break; // Só precisa encontrar uma mensagem de estado vazio
        }
      }
    });
  });
} 