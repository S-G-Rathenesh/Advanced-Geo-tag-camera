from pydantic import BaseModel, ConfigDict, field_validator

class UserBase(BaseModel):
    username: str | None = None
    email: str | None = None
    name: str | None = None
    profile_image: str | None = None
    department: str | None = None
    is_active: bool = True

class UserCreate(UserBase):
    password: str | None = None
    role_name: str

class UserResponse(UserBase):
    id: str
    role: str

    @field_validator('role', mode='before')
    @classmethod
    def extract_role_name(cls, v):
        if hasattr(v, 'name'):
            return v.name
        return v

    model_config = ConfigDict(from_attributes=True)
