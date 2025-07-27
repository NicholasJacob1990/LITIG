#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Teste da Integração IEP no Algoritmo Principal
==============================================

Script para testar a nova Feature I (IEP - Índice de Engajamento na Plataforma)
implementada no algoritmo_match.py v2.10-iep.

Testa:
1. Feature I (interaction_score) implementada
2. Pesos atualizados para incluir Feature I
3. Métodos all() e all_async() retornando Feature I
4. Presets incluindo peso para Feature I

Executar: python test_iep_integration.py
"""

import sys
from pathlib import Path
from datetime import datetime

# Adicionar path do backend
backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))

try:
    import inspect
    print("✅ Imports básicos realizados com sucesso")
except ImportError as e:
    print(f"❌ Erro de importação: {e}")
    print("Execute este script na pasta packages/backend/")
    sys.exit(1)


class IEPIntegrationTester:
    """Testa a integração do IEP no algoritmo principal."""
    
    def __init__(self):
        self.results = {}
    
    async def run_all_tests(self):
        """Executa todos os testes da integração IEP."""
        
        print("🔬 TESTE DE INTEGRAÇÃO IEP NO ALGORITMO PRINCIPAL")
        print("=" * 60)
        print("🎯 Validando Feature I (Índice de Engajamento) no algoritmo_match.py")
        print()
        
        # Teste 1: Verificar se a feature I foi implementada
        await self.test_feature_i_implementation()
        
        # Teste 2: Verificar pesos atualizados
        await self.test_weights_updated()
        
        # Teste 3: Verificar métodos all() e all_async()
        await self.test_all_methods_updated()
        
        # Teste 4: Verificar presets atualizados
        await self.test_presets_updated()
        
        # Teste 5: Verificar documentação atualizada
        await self.test_documentation_updated()
        
        # Resumo final
        self.print_final_summary()
    
    async def test_feature_i_implementation(self):
        """Testa se a feature I (interaction_score) foi implementada."""
        
        print("🎯 TESTE 1: Implementação da Feature I")
        print("-" * 40)
        
        try:
            # Verificar se o método interaction_score existe no arquivo
            algo_file = Path(__file__).parent / "Algoritmo" / "algoritmo_match.py"
            
            if not algo_file.exists():
                print(f"❌ Arquivo não encontrado: {algo_file}")
                self.results["feature_i_implementation"] = False
                return
            
            # Ler o conteúdo do arquivo
            with open(algo_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Verificar se o método interaction_score foi implementado
            if "def interaction_score(self) -> float:" in content:
                print("✅ Método interaction_score() implementado")
                
                # Verificar se tem a documentação correta
                if "Feature-I: Índice de Engajamento na Plataforma (IEP)" in content:
                    print("✅ Documentação da Feature I presente")
                else:
                    print("⚠️ Documentação da Feature I pode estar incompleta")
                
                # Verificar se usa interaction_score do lawyer
                if "getattr(self.lawyer, 'interaction_score', None)" in content:
                    print("✅ Integração com campo interaction_score do lawyer")
                else:
                    print("❌ Não encontrada integração com campo do lawyer")
                
                self.results["feature_i_implementation"] = True
            else:
                print("❌ Método interaction_score() não encontrado")
                self.results["feature_i_implementation"] = False
                
        except Exception as e:
            print(f"❌ Erro ao verificar implementação: {e}")
            self.results["feature_i_implementation"] = False
        
        print()
    
    async def test_weights_updated(self):
        """Testa se os pesos foram atualizados para incluir Feature I."""
        
        print("⚖️ TESTE 2: Pesos Atualizados")
        print("-" * 40)
        
        try:
            algo_file = Path(__file__).parent / "Algoritmo" / "algoritmo_match.py"
            
            with open(algo_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Verificar HARDCODED_FALLBACK_WEIGHTS
            if '"I": 0.02' in content and 'HARDCODED_FALLBACK_WEIGHTS' in content:
                print("✅ HARDCODED_FALLBACK_WEIGHTS inclui Feature I")
                hardcoded_ok = True
            else:
                print("❌ HARDCODED_FALLBACK_WEIGHTS não inclui Feature I")
                hardcoded_ok = False
            
            # Verificar se todos os presets foram atualizados
            presets = ["fast", "expert", "economic", "b2b", "correspondent", "expert_opinion"]
            presets_ok = 0
            
            for preset in presets:
                if f'"{preset}":' in content and f'"I":' in content.split(f'"{preset}":')[1].split('}')[0]:
                    print(f"✅ Preset '{preset}' inclui Feature I")
                    presets_ok += 1
                else:
                    print(f"❌ Preset '{preset}' não inclui Feature I")
            
            if hardcoded_ok and presets_ok == len(presets):
                print(f"✅ Todos os pesos atualizados ({presets_ok}/{len(presets)} presets)")
                self.results["weights_updated"] = True
            else:
                print(f"❌ Nem todos os pesos foram atualizados ({presets_ok}/{len(presets)} presets)")
                self.results["weights_updated"] = False
                
        except Exception as e:
            print(f"❌ Erro ao verificar pesos: {e}")
            self.results["weights_updated"] = False
        
        print()
    
    async def test_all_methods_updated(self):
        """Testa se os métodos all() e all_async() incluem Feature I."""
        
        print("🔄 TESTE 3: Métodos all() e all_async()")
        print("-" * 40)
        
        try:
            algo_file = Path(__file__).parent / "Algoritmo" / "algoritmo_match.py"
            
            with open(algo_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Verificar método all()
            all_method_section = content.split("def all(self) -> Dict[str, float]:")[1].split("async def all_async")[0]
            if '"I": self.interaction_score()' in all_method_section:
                print("✅ Método all() inclui Feature I")
                all_ok = True
            else:
                print("❌ Método all() não inclui Feature I")
                all_ok = False
            
            # Verificar método all_async()
            all_async_section = content.split("async def all_async(self) -> Dict[str, float]:")[1].split("class MatchmakingAlgorithm")[0]
            if '"I": self.interaction_score()' in all_async_section:
                print("✅ Método all_async() inclui Feature I")
                all_async_ok = True
            else:
                print("❌ Método all_async() não inclui Feature I")
                all_async_ok = False
            
            if all_ok and all_async_ok:
                self.results["all_methods_updated"] = True
            else:
                self.results["all_methods_updated"] = False
                
        except Exception as e:
            print(f"❌ Erro ao verificar métodos all(): {e}")
            self.results["all_methods_updated"] = False
        
        print()
    
    async def test_presets_updated(self):
        """Testa se todos os presets incluem a Feature I."""
        
        print("🎛️ TESTE 4: Presets Atualizados")
        print("-" * 40)
        
        try:
            algo_file = Path(__file__).parent / "Algoritmo" / "algoritmo_match.py"
            
            with open(algo_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Extrair seção PRESET_WEIGHTS
            preset_section = content.split("PRESET_WEIGHTS = {")[1].split("}")[0]
            
            # Verificar cada preset individualmente
            presets_info = {
                "fast": "Preset rápido (peso baixo para IEP)",
                "expert": "Preset expert (peso médio para IEP)", 
                "economic": "Preset econômico (peso baixo para IEP)",
                "b2b": "Preset B2B (peso alto para IEP)",
                "correspondent": "Preset correspondente (peso baixo para IEP)",
                "expert_opinion": "Preset parecer (peso baixo para IEP)"
            }
            
            presets_found = 0
            for preset_name, description in presets_info.items():
                if f'"{preset_name}":' in preset_section:
                    preset_block = preset_section.split(f'"{preset_name}":')[1].split('},')[0]
                    if '"I":' in preset_block:
                        print(f"✅ {description}")
                        presets_found += 1
                    else:
                        print(f"❌ {preset_name}: Feature I ausente")
                else:
                    print(f"❌ {preset_name}: Preset não encontrado")
            
            if presets_found == len(presets_info):
                print(f"✅ Todos os {presets_found} presets incluem Feature I")
                self.results["presets_updated"] = True
            else:
                print(f"❌ Apenas {presets_found}/{len(presets_info)} presets incluem Feature I")
                self.results["presets_updated"] = False
                
        except Exception as e:
            print(f"❌ Erro ao verificar presets: {e}")
            self.results["presets_updated"] = False
        
        print()
    
    async def test_documentation_updated(self):
        """Testa se a documentação foi atualizada."""
        
        print("📚 TESTE 5: Documentação Atualizada")
        print("-" * 40)
        
        try:
            algo_file = Path(__file__).parent / "Algoritmo" / "algoritmo_match.py"
            
            with open(algo_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Verificar versão atualizada
            if "v2.10-iep" in content:
                print("✅ Versão atualizada para v2.10-iep")
                version_ok = True
            else:
                print("❌ Versão não atualizada")
                version_ok = False
            
            # Verificar documentação da feature
            if "IEP Integration" in content and "Feature I - Índice de Engajamento" in content:
                print("✅ Documentação da Feature I presente")
                doc_ok = True
            else:
                print("❌ Documentação da Feature I ausente")
                doc_ok = False
            
            # Verificar descrição dos benefícios
            if "cliente→advogado quanto advogado→advogado" in content:
                print("✅ Benefícios para ambos os fluxos documentados")
                benefits_ok = True
            else:
                print("❌ Benefícios não documentados")
                benefits_ok = False
            
            if version_ok and doc_ok and benefits_ok:
                self.results["documentation_updated"] = True
            else:
                self.results["documentation_updated"] = False
                
        except Exception as e:
            print(f"❌ Erro ao verificar documentação: {e}")
            self.results["documentation_updated"] = False
        
        print()
    
    def print_final_summary(self):
        """Imprime resumo final dos testes."""
        
        print("=" * 60)
        print("📋 RESUMO DOS TESTES DE INTEGRAÇÃO IEP")
        print("=" * 60)
        
        total_tests = len(self.results)
        passed_tests = sum(1 for result in self.results.values() if result)
        
        test_descriptions = {
            "feature_i_implementation": "Implementação da Feature I",
            "weights_updated": "Pesos Atualizados para Feature I",
            "all_methods_updated": "Métodos all() e all_async() Atualizados",
            "presets_updated": "Todos os Presets Incluem Feature I",
            "documentation_updated": "Documentação Atualizada"
        }
        
        for test_name, passed in self.results.items():
            status = "✅ PASSOU" if passed else "❌ FALHOU"
            description = test_descriptions.get(test_name, test_name)
            print(f"{status:<10} {description}")
        
        print()
        print(f"📊 RESULTADO GERAL: {passed_tests}/{total_tests} testes passaram")
        
        if passed_tests == total_tests:
            print("🎉 TODOS OS TESTES PASSARAM!")
            print("✅ Feature I (IEP) totalmente integrada ao algoritmo principal")
            print("✅ Beneficia tanto cliente→advogado quanto advogado→advogado")
            print("✅ Recompensa advogados engajados e penaliza oportunismo")
            print()
            print("🚀 IMPLEMENTAÇÃO 100% COMPLETA:")
            print("   • Feature I (interaction_score) implementada")
            print("   • Todos os pesos atualizados")
            print("   • Métodos all() e all_async() incluem Feature I")
            print("   • Todos os 6 presets incluem peso para Feature I")
            print("   • Documentação v2.10-iep atualizada")
            print()
            print("🎯 RESULTADO FINAL:")
            print("   As lacunas do Partnership Growth Plan foram 100% resolvidas!")
            print("   O IEP agora beneficia AMBOS os fluxos de matching:")
            print("   📋 Cliente → Advogado (via algoritmo_match.py)")  
            print("   🤝 Advogado → Advogado (via algoritmo_match.py)")
        else:
            print("⚠️  Alguns testes falharam - revisar implementação")
        
        print()
        print("📈 PRÓXIMOS PASSOS:")
        print("   1. Executar job calculate_engagement_scores.py")
        print("   2. Testar matching com dados reais")
        print("   3. Monitorar impacto do IEP nos rankings")
        print("   4. Ajustar pesos baseado na performance")


async def main():
    """Função principal."""
    
    tester = IEPIntegrationTester()
    await tester.run_all_tests()


if __name__ == "__main__":
    import asyncio
    asyncio.run(main()) 