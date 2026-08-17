"""add_address_and_gnss

Revision ID: ce0ece8d4191
Revises: a3b4c5d6e7f8
Create Date: 2026-08-17 09:28:21.976281

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'ce0ece8d4191'
down_revision: Union[str, Sequence[str], None] = 'a3b4c5d6e7f8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column('evidence', sa.Column('address', sa.String(), nullable=True))
    op.add_column('evidence', sa.Column('gnss_constellations', sa.String(), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column('evidence', 'gnss_constellations')
    op.drop_column('evidence', 'address')
