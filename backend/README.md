# Capturovert Backend (FastAPI + PostgreSQL)

This is the Stage 2 backend for the Capturovert Flutter prototype.

## Requirements
- Python 3.12+
- PostgreSQL 15+

## Setup Instructions

1. **Database Setup**
   Ensure PostgreSQL is running locally. Create a database named `capturovert`.
   ```bash
   psql -U postgres -c "CREATE DATABASE capturovert;"
   ```

2. **Environment Configuration**
   Copy the example environment file and update credentials if necessary.
   ```bash
   cp .env.example .env
   ```

3. **Virtual Environment**
   Create and activate a virtual environment, then install dependencies.
   ```bash
   python -m venv venv
   source venv/bin/activate  # Or `.\venv\Scripts\activate` on Windows
   pip install -r requirements.txt
   ```

4. **Run the Server**
   Start the FastAPI server using Uvicorn. The database tables will be auto-generated for this prototype.
   ```bash
   uvicorn app.main:app --reload
   ```

## Architecture

- **Auth**: JWT-based authentication with bcrypt password hashing.
- **RBAC**: Endpoints are protected by roles (`FIELD_OFFICER`, `OFFICIAL`, `ADMIN`).
- **Evidence Workflow**: The Flutter client POSTs a multipart payload containing the AES-256 encrypted evidence file and metadata. The server verifies the `payload_hash`, uploads the raw encrypted file to Cloudinary, and stores metadata in PostgreSQL.
- **Audit Logging**: All significant actions (Logins, Uploads, Views) are stored in the `audit_logs` table.

## Endpoints

- `POST /api/v1/auth/login`: Authenticate and receive JWT.
- `POST /api/v1/evidence/upload`: Upload encrypted evidence (requires FIELD_OFFICER).
- `GET /api/v1/evidence/{capture_id}`: Retrieve evidence metadata (requires authentication).
- `POST /api/v1/evidence/{capture_id}/verify`: Verify evidence integrity (requires OFFICIAL/ADMIN).
