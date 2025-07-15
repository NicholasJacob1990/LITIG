# packages/backend/logger.py
import json
import logging

class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        # Garante que o contexto (args) seja um dicionário
        context = record.args if isinstance(record.args, dict) else {}
        
        return json.dumps({
            "timestamp": self.formatTime(record, self.datefmt),
            "level": record.levelname,
            "message": record.getMessage(),
            "context": context,
        })

# Configuração do logger de auditoria
_handler = logging.StreamHandler()
_handler.setFormatter(JsonFormatter())

AUDIT_LOGGER = logging.getLogger("audit.match")
if not AUDIT_LOGGER.handlers:
    AUDIT_LOGGER.addHandler(_handler)
AUDIT_LOGGER.setLevel(logging.INFO) 