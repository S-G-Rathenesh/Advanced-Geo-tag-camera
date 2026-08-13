import os
import sys

# Add the backend directory to sys.path to allow imports from app
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.main import init_db

def seed_db():
    print("Seeding database with demo data...")
    init_db()
    print("Database seeding completed.")

if __name__ == "__main__":
    seed_db()
