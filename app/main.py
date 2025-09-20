from typing import List, Optional

from fastapi.params import Body
import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(title="CI/CD Demo API", version="1.0.0")

users_db = []


class User(BaseModel):
    id: Optional[int] = None
    name: str
    email: str
    age: int


class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    age: int


@app.get("/")
async def root():
    """Health check endpoint"""
    return {"message": "Hello CI/CD World!", "status": "healthy"}


@app.get("/health")
async def health_check():
    """Detailed health check"""
    return {"status": "ok", "version": "1.0.0", "users_count": len(users_db)}


@app.post("/users", response_model=UserResponse)
async def create_user(user: User):
    """Create a new user"""
    # Simple validation
    if user.age < 0 or user.age > 150:
        raise HTTPException(status_code=400, detail="Age must be between 0 and 150")

    # Check if email already exists
    if any(u["email"] == user.email for u in users_db):
        raise HTTPException(status_code=400, detail="Email already exists")

    user_id = len(users_db) + 1
    user_data = {"id": user_id, "name": user.name, "email": user.email, "age": user.age}
    users_db.append(user_data)
    return UserResponse(**user_data)


@app.get("/users", response_model=List[UserResponse])
async def get_users():
    """Get all users"""
    return [UserResponse(**user) for user in users_db]


@app.get("/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: int):
    """Get user by ID"""
    user = next((u for u in users_db if u["id"] == user_id), None)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return UserResponse(**user)


@app.delete("/users/{user_id}")
async def delete_user(user_id: int):
    """Delete user by ID"""
    global users_db
    user = next((u for u in users_db if u["id"] == user_id), None)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    users_db = [u for u in users_db if u["id"] != user_id]
    return {"message": f"User {user_id} deleted successfully"}


if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=3000)
