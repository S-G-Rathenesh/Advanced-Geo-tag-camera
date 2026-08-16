"""Add iv_base64 column to evidence table

Revision ID: a3b4c5d6e7f8
Revises: 22e092f1c7d0
Create Date: 2026-08-14 23:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a3b4c5d6e7f8'
down_revision: Union[str, Sequence[str], None] = '22e092f1c7d0'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add iv_base64 column to evidence table for AES-GCM decryption support."""
    op.add_column('evidence', sa.Column('iv_base64', sa.String(), nullable=True))


def downgrade() -> None:
    """Remove iv_base64 column from evidence table."""
    op.drop_column('evidence', 'iv_base64')
