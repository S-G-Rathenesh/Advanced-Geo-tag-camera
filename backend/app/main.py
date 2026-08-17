from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import auth, evidence, users, audit, health
from app.core.database import engine, Base, SessionLocal
from app.models.role import Role
from app.models.user import User
from app.core.security import get_password_hash
from alembic.config import Config
from alembic import command
import os

def init_db():
    # Automatically apply Alembic migrations
    try:
        alembic_ini_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "alembic.ini")
        if os.path.exists(alembic_ini_path):
            alembic_cfg = Config(alembic_ini_path)
            command.upgrade(alembic_cfg, "head")
    except Exception as e:
        print(f"Alembic migration failed, continuing with create_all: {e}")

    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        roles = {}
        for role_name in ["OFFICER", "SUPERVISOR", "USER"]:
            role = db.query(Role).filter(Role.name == role_name).first()
            if not role:
                role = Role(name=role_name)
                db.add(role)
                db.commit()
                db.refresh(role)
            roles[role_name] = role

        # Demo Officer (DB Login)
        officer = db.query(User).filter(User.username == "demo_officer").first()
        if not officer:
            officer = User(
                username="demo_officer",
                password_hash=get_password_hash("password123"),
                name="Demo Officer",
                department="Field Ops",
                role_id=roles["OFFICER"].id,
                is_active=True
            )
            db.add(officer)
        else:
            officer.username = "demo_officer"
            officer.password_hash = get_password_hash("password123")
            officer.name = "Demo Officer"
            officer.department = "Field Ops"
            officer.role_id = roles["OFFICER"].id
            officer.is_active = True
            
        # Demo Supervisor
        supervisor = db.query(User).filter(User.email == "demo.supervisor@gmail.com").first()
        if not supervisor:
            supervisor = User(
                username="demo_supervisor",
                password_hash=get_password_hash("password123"),
                email="demo.supervisor@gmail.com",
                google_subject_id="demo_google_sup_123",
                name="Demo Supervisor",
                department="Field Ops",
                role_id=roles["SUPERVISOR"].id,
                is_active=True
            )
            db.add(supervisor)
        else:
            supervisor.username = "demo_supervisor"
            supervisor.password_hash = get_password_hash("password123")
            supervisor.google_subject_id = "demo_google_sup_123"
            supervisor.name = "Demo Supervisor"
            supervisor.department = "Field Ops"
            supervisor.role_id = roles["SUPERVISOR"].id
            supervisor.is_active = True
            
        # Demo Users
        for i in range(1, 4):
            user_email = f"demo.user{i}@gmail.com"
            user = db.query(User).filter(User.email == user_email).first()
            if not user:
                user = User(
                    username=f"demo_user{i}",
                    password_hash=get_password_hash("password123"),
                    email=user_email,
                    google_subject_id=f"demo_google_user_{i}",
                    name=f"Demo User {i}",
                    department="Field Ops",
                    role_id=roles["USER"].id,
                    is_active=True
                )
                db.add(user)
            else:
                user.username = f"demo_user{i}"
                user.password_hash = get_password_hash("password123")
                user.google_subject_id = f"demo_google_user_{i}"
                user.name = f"Demo User {i}"
                user.department = "Field Ops"
                user.role_id = roles["USER"].id
                user.is_active = True

        db.commit()
    finally:
        db.close()

@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield

app = FastAPI(
    title="Capturovert API",
    description="Backend API for the Capturovert Prototype",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(evidence.router, prefix="/api/v1/evidence", tags=["evidence"])
app.include_router(users.router, prefix="/api/v1/users", tags=["users"])
app.include_router(audit.router, prefix="/api/v1/audit", tags=["audit"])
app.include_router(health.router, prefix="/api/v1/health", tags=["health"])

@app.get("/")
def root():
    return {"message": "Welcome to Capturovert API"}
