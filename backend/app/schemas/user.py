from pydantic import BaseModel

class UserBase(BaseModel):
    username: str
    full_name: str | None = None
    department: str | None = None
    is_active: bool = True

class UserCreate(UserBase):
    password: str
    role_name: str

class UserResponse(UserBase):
    id: str
    role: str

    class Config:
        from_attributes = True
