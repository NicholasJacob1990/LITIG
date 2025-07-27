#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Validação das Otimizações de Retreino
====================================

Script para validar se todas as melhorias de retreino foram implementadas corretamente.
"""

import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple


class RetrainOptimizationValidator:
    """Validador das otimizações de retreino implementadas"""
    
    def __init__(self):
        self.backend_dir = Path(__file__).parent
        self.validation_results = {}
        
    def validate_all(self) -> Dict[str, bool]:
        """Executa todas as validações"""
        
        print("🔍 VALIDANDO OTIMIZAÇÕES DE RETREINO")
        print("=" * 50)
        
        # Validação 1: Celery App Configuration
        self.validate_celery_configuration()
        
        # Validação 2: Partnership Retrain Optimizations
        self.validate_partnership_optimizations()
        
        # Validação 3: LTR Optimizations
        self.validate_ltr_optimizations()
        
        # Validação 4: Clustering Optimizations
        self.validate_clustering_optimizations()
        
        # Validação 5: New Jobs Implementation
        self.validate_new_jobs()
        
        # Resumo final
        self.print_validation_summary()
        
        return self.validation_results
    
    def validate_celery_configuration(self):
        """Valida as mudanças no celery_app.py"""
        
        print("\n📅 1. VALIDANDO CONFIGURAÇÃO CELERY")
        print("-" * 40)
        
        celery_file = self.backend_dir / "celery_app.py"
        
        if not celery_file.exists():
            self.validation_results["celery_config"] = False
            print("❌ Arquivo celery_app.py não encontrado")
            return
            
        content = celery_file.read_text()
        
        # Verificações específicas
        checks = [
            ("partnership_full_retrain", "auto-retrain-partnerships-full", "Retreino completo de parcerias"),
            ("partnership_quick_update", "auto-retrain-partnerships-quick", "Atualização rápida de parcerias"),
            ("clustering_lawyers_12h", "hour='2,14'", "Clustering lawyers otimizado (12h)"),
            ("clustering_cases_8h", "hour='0,8,16'", "Clustering cases otimizado (8h)"),
            ("soft_skills_3x_week", "day_of_week='0,2,4'", "Soft skills 3x por semana"),
            ("iep_daily", "calculate-iep-daily", "IEP job diário"),
            ("geo_features", "update-geo-features", "Geo features job")
        ]
        
        all_passed = True
        for check_id, pattern, description in checks:
            if pattern in content:
                print(f"✅ {description}")
                self.validation_results[check_id] = True
            else:
                print(f"❌ {description} - PADRÃO NÃO ENCONTRADO: {pattern}")
                self.validation_results[check_id] = False
                all_passed = False
        
        self.validation_results["celery_config"] = all_passed
    
    def validate_partnership_optimizations(self):
        """Valida otimizações do algoritmo de parcerias"""
        
        print("\n🤝 2. VALIDANDO OTIMIZAÇÕES DE PARCERIAS")
        print("-" * 40)
        
        partnership_file = self.backend_dir / "jobs" / "partnership_retrain.py"
        
        if not partnership_file.exists():
            self.validation_results["partnership_optimizations"] = False
            print("❌ Arquivo partnership_retrain.py não encontrado")
            return
            
        content = partnership_file.read_text()
        
        # Verificações
        checks = [
            ("days_back_14", "days_back: int = 14", "Janela de dados 14 dias"),
            ("min_feedback_75", "min_feedback_count: int = 75", "Mínimo 75 samples"),
            ("quick_update_task", "quick_weights_update_task", "Task de atualização rápida"),
            ("quick_update_implementation", "def quick_weights_update_task", "Implementação quick update")
        ]
        
        all_passed = True
        for check_id, pattern, description in checks:
            if pattern in content:
                print(f"✅ {description}")
                self.validation_results[check_id] = True
            else:
                print(f"❌ {description}")
                self.validation_results[check_id] = False
                all_passed = False
        
        self.validation_results["partnership_optimizations"] = all_passed
    
    def validate_ltr_optimizations(self):
        """Valida otimizações do LTR"""
        
        print("\n🎯 3. VALIDANDO OTIMIZAÇÕES LTR")
        print("-" * 40)
        
        ltr_file = self.backend_dir / "jobs" / "auto_retrain.py"
        
        if not ltr_file.exists():
            self.validation_results["ltr_optimizations"] = False
            print("❌ Arquivo auto_retrain.py não encontrado")
            return
            
        content = ltr_file.read_text()
        
        # Verificações
        checks = [
            ("ltr_14_days", "days_back=14", "Janela de dados 14 dias"),
            ("ltr_200_samples", "< 200 and not force_retrain", "Mínimo 200 samples"),
            ("ltr_optimization_comment", "OTIMIZADO: 14 dias", "Comentário de otimização")
        ]
        
        all_passed = True
        for check_id, pattern, description in checks:
            if pattern in content:
                print(f"✅ {description}")
                self.validation_results[check_id] = True
            else:
                print(f"❌ {description}")
                self.validation_results[check_id] = False
                all_passed = False
        
        self.validation_results["ltr_optimizations"] = all_passed
    
    def validate_clustering_optimizations(self):
        """Valida otimizações de clustering"""
        
        print("\n🔍 4. VALIDANDO OTIMIZAÇÕES CLUSTERING")
        print("-" * 40)
        
        celery_file = self.backend_dir / "celery_app.py"
        content = celery_file.read_text()
        
        # Verificar frequências otimizadas
        lawyers_12h = "hour='2,14'" in content  # 12 horas
        cases_8h = "hour='0,8,16'" in content   # 8 horas
        
        if lawyers_12h:
            print("✅ Clustering lawyers: 12 horas (economia 33% CPU)")
            self.validation_results["clustering_lawyers_optimized"] = True
        else:
            print("❌ Clustering lawyers: não otimizado")
            self.validation_results["clustering_lawyers_optimized"] = False
            
        if cases_8h:
            print("✅ Clustering cases: 8 horas (economia 25% CPU)")
            self.validation_results["clustering_cases_optimized"] = True
        else:
            print("❌ Clustering cases: não otimizado")
            self.validation_results["clustering_cases_optimized"] = False
        
        self.validation_results["clustering_optimizations"] = lawyers_12h and cases_8h
    
    def validate_new_jobs(self):
        """Valida implementação de novos jobs"""
        
        print("\n🆕 5. VALIDANDO NOVOS JOBS")
        print("-" * 40)
        
        # Verificar arquivos de jobs
        jobs_to_check = [
            ("geo_updater.py", "Geo Features Job"),
            ("calculate_engagement_scores.py", "IEP Job")
        ]
        
        jobs_valid = True
        
        for filename, description in jobs_to_check:
            job_file = self.backend_dir / "jobs" / filename
            
            if job_file.exists():
                content = job_file.read_text()
                
                # Verificar se tem task Celery
                if "@shared_task" in content:
                    print(f"✅ {description}: Implementado com task Celery")
                    self.validation_results[f"job_{filename.replace('.py', '')}"] = True
                else:
                    print(f"⚠️  {description}: Arquivo existe mas sem task Celery")
                    self.validation_results[f"job_{filename.replace('.py', '')}"] = False
                    jobs_valid = False
            else:
                print(f"❌ {description}: Arquivo não encontrado")
                self.validation_results[f"job_{filename.replace('.py', '')}"] = False
                jobs_valid = False
        
        self.validation_results["new_jobs"] = jobs_valid
    
    def print_validation_summary(self):
        """Imprime resumo da validação"""
        
        print("\n" + "=" * 50)
        print("📊 RESUMO DA VALIDAÇÃO")
        print("=" * 50)
        
        # Contar sucessos
        total_checks = len(self.validation_results)
        passed_checks = sum(1 for result in self.validation_results.values() if result)
        
        success_rate = (passed_checks / total_checks) * 100 if total_checks > 0 else 0
        
        print(f"\n🎯 RESULTADO GERAL: {passed_checks}/{total_checks} verificações passaram")
        print(f"📈 Taxa de Sucesso: {success_rate:.1f}%")
        
        if success_rate >= 90:
            print("\n🎉 EXCELENTE! Otimizações implementadas com sucesso!")
        elif success_rate >= 70:
            print("\n✅ BOM! Maioria das otimizações implementadas.")
        else:
            print("\n⚠️  ATENÇÃO! Várias otimizações precisam ser revisadas.")
        
        # Detalhes por categoria
        print("\n📋 DETALHES POR CATEGORIA:")
        
        categories = {
            "Configuração Celery": ["celery_config"],
            "Parcerias": ["partnership_optimizations"],
            "LTR": ["ltr_optimizations"],
            "Clustering": ["clustering_optimizations"],
            "Novos Jobs": ["new_jobs"]
        }
        
        for category, keys in categories.items():
            category_results = [self.validation_results.get(key, False) for key in keys]
            category_success = all(category_results)
            status = "✅" if category_success else "❌"
            print(f"   {status} {category}")
        
        print("\n🚀 PRÓXIMOS PASSOS:")
        print("   1. Testar jobs em ambiente de desenvolvimento")
        print("   2. Monitorar performance após implementação")
        print("   3. A/B testing para validar melhorias")
        print("   4. Rollback automático se degradação > 5%")


def main():
    """Função principal"""
    
    validator = RetrainOptimizationValidator()
    results = validator.validate_all()
    
    # Retornar código de saída baseado no sucesso
    total_checks = len(results)
    passed_checks = sum(1 for result in results.values() if result)
    success_rate = (passed_checks / total_checks) * 100 if total_checks > 0 else 0
    
    # Sucesso se >= 90% das verificações passaram
    exit_code = 0 if success_rate >= 90 else 1
    sys.exit(exit_code)


if __name__ == "__main__":
    main() 