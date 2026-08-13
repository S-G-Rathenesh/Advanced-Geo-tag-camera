from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import auth, evidence
from app.core.database import engine, Base, SessionLocal
from app.models.role import Role
from app.models.user import User
from app.core.security import get_password_hash

def init_db():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        roles = {}
        for role_name in ["FIELD_OFFICER", "OFFICIAL", "ADMIN"]:
            role = db.query(Role).filter(Role.name == role_name).first()
            if not role:
                role = Role(name=role_name)
                db.add(role)
                db.commit()
                db.refresh(role)
            roles[role_name] = role

        demo_users = [
            ("officer@geotag.com", "password123", "Officer James Chen", "Field Ops", roles["FIELD_OFFICER"]),
            ("supervisor@geotag.com", "password123", "Supervisor Maria Santos", "Management", roles["OFFICIAL"]),
            ("admin@geotag.com", "password123", "System Admin", "IT Security", roles["ADMIN"]),
            ("testuser", "password123", "Test User", "Field Ops", roles["FIELD_OFFICER"]),
        ]

        for username, password, full_name, dept, role in demo_users:
            user = db.query(User).filter(User.username == username).first()
            if not user:
                user = User(
                    username=username,
                    password_hash=get_password_hash(password),
                    full_name=full_name,
                    department=dept,
                    role_id=role.id,
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

@app.get("/")
def root():
    return {"message": "Welcome to GeoEvidence API"}
