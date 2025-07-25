"""add preview and accept fields to cases

Revision ID: a6f9c059751b
Revises: 2abe36c774a1
Create Date: 2024-07-24 19:15:33.242942

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'a6f9c059751b'
down_revision = '2abe36c774a1'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('cases', sa.Column('preview_payload', postgresql.JSONB(astext_type=sa.Text()), server_default='{}', nullable=False))
    op.add_column('cases', sa.Column('accepted_by', postgresql.UUID(), nullable=True))
    op.add_column('cases', sa.Column('accepted_at', sa.TIMESTAMP(timezone=True), nullable=True))
    op.create_foreign_key(
        "fk_cases_accepted_by_users", "cases", "users",
        ["accepted_by"], ["id"],
    )


def downgrade():
    op.drop_constraint("fk_cases_accepted_by_users", "cases", type_="foreignkey")
    op.drop_column('cases', 'accepted_at')
    op.drop_column('cases', 'accepted_by')
    op.drop_column('cases', 'preview_payload')
