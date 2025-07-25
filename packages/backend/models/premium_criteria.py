from sqlalchemy import (
    Column, Integer, Text, Boolean, Numeric, TIMESTAMP, JSON, String, Enum
)
from sqlalchemy.sql import func
from database import Base

class PremiumCriteria(Base):
    __tablename__ = "premium_criteria"

    id = Column(Integer, primary_key=True)
    service_code = Column(Text, nullable=False)
    subservice_code = Column(Text, nullable=True)
    name = Column(Text, nullable=False)
    enabled = Column(Boolean, nullable=False, server_default="true")
    min_valor_causa = Column(Numeric, nullable=True)
    max_valor_causa = Column(Numeric, nullable=True)
    min_urgency_h = Column(Integer, nullable=True)
    complexity_levels = Column(JSON, server_default="[]", nullable=False)  # JSON em vez de ARRAY
    vip_client_plans = Column(JSON, server_default="[]", nullable=False)   # JSON em vez de ARRAY
    created_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now()
    )
    updated_at = Column(
        TIMESTAMP(timezone=True),
        onupdate=func.now()
    )

# Client model for profiles table (users who are clients)
class Client(Base):
    __tablename__ = "profiles"

    id = Column(String, primary_key=True)
    user_id = Column(String, nullable=False, unique=True)
    full_name = Column(String, nullable=True)
    avatar_url = Column(String, nullable=True)
    role = Column(String, nullable=False, default='client')
    phone = Column(String, nullable=True)
    plan = Column(
        Enum('FREE', 'VIP', 'ENTERPRISE', name='clientplan'),
        nullable=False,
        default='FREE'
    )
    created_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now()
    )
    updated_at = Column(
        TIMESTAMP(timezone=True),
        onupdate=func.now()
    ) 