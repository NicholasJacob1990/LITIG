import json, lightgbm as lgb, pathlib, os, datetime as dt
from .config import FEATURES
from typing import Optional, Dict, Any

# ⚡ CHAVE 3: Configuração de publicação automática
MODEL_TXT = pathlib.Path("packages/backend/ltr_pipeline/models/dev/ltr_model.txt")
WEIGHTS_LOCAL = pathlib.Path("packages/backend/models/ltr_weights.json")

# Configurações S3/MinIO para publicação versionada
S3_BUCKET = os.getenv("S3_BUCKET", "litgo-models")
S3_PREFIX = os.getenv("S3_PREFIX", "ltr")
S3_ENDPOINT = os.getenv("S3_ENDPOINT")  # Para MinIO local
AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")

# ⚡ Imports opcionais para S3
try:
    import boto3
    from botocore.exceptions import ClientError, NoCredentialsError
    S3_AVAILABLE = True
except ImportError:
    S3_AVAILABLE = False
    print("⚠️  boto3 não disponível - usando apenas publicação local")

def get_s3_client():
    """Cria cliente S3/MinIO configurado."""
    if not S3_AVAILABLE:
        return None
    
    try:
        # Configuração para MinIO local ou S3
        if S3_ENDPOINT:
            return boto3.client(
                's3',
                endpoint_url=S3_ENDPOINT,
                aws_access_key_id=AWS_ACCESS_KEY_ID,
                aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
                region_name='us-east-1'
            )
        else:
            return boto3.client('s3')
    except Exception as e:
        print(f"❌ Erro criando cliente S3: {e}")
        return None

def publish_to_s3(weights: Dict[str, float], version: str) -> bool:
    """
    ⚡ CHAVE 3: Publica pesos versionados no S3/MinIO.
    
    Args:
        weights: Dicionário de pesos do modelo
        version: Versão do modelo (timestamp)
        
    Returns:
        True se publicação foi bem-sucedida
    """
    if not S3_AVAILABLE:
        print("📦 S3 não disponível - skip publicação remota")
        return False
    
    s3_client = get_s3_client()
    if not s3_client:
        return False
    
    try:
        # Caminho versionado no S3
        s3_key = f"{S3_PREFIX}/{version}/ltr_weights.json"
        
        # Upload dos pesos
        s3_client.put_object(
            Bucket=S3_BUCKET,
            Key=s3_key,
            Body=json.dumps(weights, indent=2),
            ContentType='application/json',
            Metadata={
                'version': version,
                'features': ','.join(FEATURES),
                'created_at': dt.datetime.utcnow().isoformat()
            }
        )
        
        print(f"☁️  Pesos publicados: s3://{S3_BUCKET}/{s3_key}")
        
        # Atualizar symlink "latest"
        latest_key = f"{S3_PREFIX}/latest/ltr_weights.json"
        s3_client.copy_object(
            Bucket=S3_BUCKET,
            CopySource={'Bucket': S3_BUCKET, 'Key': s3_key},
            Key=latest_key
        )
        
        print(f"🔗 Latest atualizado: s3://{S3_BUCKET}/{latest_key}")
        return True
        
    except Exception as e:
        print(f"❌ Erro publicando no S3: {e}")
        return False

def publish_model():
    """
    ⚡ CHAVE 3: Função principal de publicação com versionamento.
    
    Extrai pesos do modelo treinado e publica local + S3 versionado.
    """
    if not MODEL_TXT.exists():
        print(f"❌ Modelo não encontrado: {MODEL_TXT}")
        return
    
    try:
        # Carregar modelo e extrair importâncias
        booster = lgb.Booster(model_file=str(MODEL_TXT))
        gains = booster.feature_importance(importance_type="gain")
        
        # Normalizar pesos (soma = 1.0)
        weights = {f: float(g) for f, g in zip(FEATURES, gains)}
        total = sum(weights.values()) or 1
        weights = {k: v/total for k, v in weights.items()}
        
        # Versão baseada em timestamp
        version = dt.datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        
        # ⚡ CHAVE 3: Publicação local (sempre)
        WEIGHTS_LOCAL.parent.mkdir(parents=True, exist_ok=True)
        WEIGHTS_LOCAL.write_text(json.dumps(weights, indent=2))
        print(f"✅ Pesos locais: {WEIGHTS_LOCAL}")
        
        # ⚡ CHAVE 3: Publicação S3 versionada (se disponível)
        if publish_to_s3(weights, version):
            print(f"🚀 Publicação completa v{version}")
        else:
            print("⚠️  Publicação apenas local")
        
        # Log de auditoria
        print(f"📊 Pesos publicados:")
        for feature, weight in weights.items():
            print(f"   {feature}: {weight:.4f}")
            
        return weights
        
    except Exception as e:
        print(f"❌ Erro na publicação: {e}")
        return None

def rollback_weights(version: str) -> bool:
    """
    🔄 Rollback para versão específica de pesos.
    
    Args:
        version: Versão do modelo (YYYYMMDD_HHMMSS)
        
    Returns:
        True se rollback foi bem-sucedido
    """
    if not S3_AVAILABLE:
        print("❌ Rollback requer S3 configurado")
        return False
    
    s3_client = get_s3_client()
    if not s3_client:
        return False
    
    try:
        # Baixar versão específica
        s3_key = f"{S3_PREFIX}/{version}/ltr_weights.json"
        
        response = s3_client.get_object(Bucket=S3_BUCKET, Key=s3_key)
        weights_data = response['Body'].read().decode('utf-8')
        
        # Salvar localmente
        WEIGHTS_LOCAL.write_text(weights_data)
        print(f"🔄 Rollback para v{version} concluído")
        
        return True
        
    except ClientError as e:
        print(f"❌ Versão {version} não encontrada: {e}")
        return False
    except Exception as e:
        print(f"❌ Erro no rollback: {e}")
        return False 