from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import auth, evidence
from app.core.database import engine, Base

# In a real app, use Alembic. For this prototype, we'll create tables here if they don't exist.
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="GeoEvidence API",
    description="Backend API for the GeoEvidence Prototype",
    version="1.0.0"
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
