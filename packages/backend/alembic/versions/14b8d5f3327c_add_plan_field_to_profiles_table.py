"""add plan field to profiles table

Revision ID: 14b8d5f3327c
Revises: a6f9c059751b
Create Date: 2025-07-24 09:57:18.367553

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '14b8d5f3327c'
down_revision: Union[str, Sequence[str], None] = 'a6f9c059751b'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Create the ENUM type if it doesn't exist
    op.execute("""
        DO $$ BEGIN
            CREATE TYPE clientplan AS ENUM ('FREE', 'VIP', 'ENTERPRISE');
        EXCEPTION
            WHEN duplicate_object THEN null;
        END $$;
    """)
    
    # Add plan field to profiles table with ENUM constraint
    op.add_column(
        'profiles',
        sa.Column(
            'plan',
            sa.Enum('FREE', 'VIP', 'ENTERPRISE', name='clientplan'),
            server_default='FREE',
            nullable=False
        )
    )


def downgrade() -> None:
    """Downgrade schema."""
    # Remove plan column
    op.drop_column('profiles', 'plan')
    
    # Drop the ENUM type
    op.execute("DROP TYPE IF EXISTS clientplan")
