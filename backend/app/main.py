from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import auth, evidence, users, audit
from app.core.database import engine, Base, SessionLocal
from app.models.role import Role
from app.models.user import User
from app.core.security import get_password_hash

def init_db():
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
            
        # Demo Supervisor (Google Auth Mock via email)
        supervisor = db.query(User).filter(User.email == "demo.supervisor@gmail.com").first()
        if not supervisor:
            supervisor = User(
                email="demo.supervisor@gmail.com",
                google_subject_id="demo_google_sup_123",
                name="Demo Supervisor",
                department="Management",
                role_id=roles["SUPERVISOR"].id,
                is_active=True
            )
            db.add(supervisor)
            
        # Demo Users
        for i in range(1, 4):
            user_email = f"demo.user{i}@gmail.com"
            user = db.query(User).filter(User.email == user_email).first()
            if not user:
                user = User(
                    email=user_email,
                    google_subject_id=f"demo_google_user_{i}",
                    name=f"Demo User {i}",
                    department="Field Ops",
                    role_id=roles["USER"].id,
                    is_active=True
                )
                db.add(user)

        db.commit()
    finally:
        db.close()

@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield

app = FastAPI(
    title="GeoEvidence API",
    description="Backend API for the GeoEvidence Prototype",
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

@app.get("/")
def root():
    return {"message": "Welcome to GeoEvidence API"}
