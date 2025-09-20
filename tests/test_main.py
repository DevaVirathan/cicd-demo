# tests/test_main.py
import pytest
from fastapi.testclient import TestClient

from app.main import app, users_db

client = TestClient(app)


@pytest.fixture(autouse=True)
def clear_db():
    """Clear the users database before each test"""
    users_db.clear()
    yield
    users_db.clear()


class TestHealthEndpoints:
    """Test health and root endpoints"""

    def test_root_endpoint(self):
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "status" in data
        assert data["status"] == "healthy"

    def test_health_check(self):
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
        assert data["version"] == "1.0.0"
        assert "users_count" in data


class TestUserCRUD:
    """Test user CRUD operations"""

    def test_create_user_success(self):
        user_data = {"name": "John Doe", "email": "john@example.com", "age": 30}
        response = client.post("/users", json=user_data)
        assert response.status_code == 200

        data = response.json()
        assert data["id"] == 1
        assert data["name"] == "John Doe"
        assert data["email"] == "john@example.com"
        assert data["age"] == 30

    def test_create_user_invalid_age(self):
        user_data = {
            "name": "Invalid User",
            "email": "invalid@example.com",
            "age": -1,  # Invalid age
        }
        response = client.post("/users", json=user_data)
        assert response.status_code == 400
        assert "Age must be between 0 and 150" in response.json()["detail"]

    def test_create_user_duplicate_email(self):
        user_data = {"name": "First User", "email": "duplicate@example.com", "age": 25}
        # Create first user
        response1 = client.post("/users", json=user_data)
        assert response1.status_code == 200

        # Try to create user with same email
        user_data["name"] = "Second User"
        response2 = client.post("/users", json=user_data)
        assert response2.status_code == 400
        assert "Email already exists" in response2.json()["detail"]

    def test_get_all_users_empty(self):
        response = client.get("/users")
        assert response.status_code == 200
        assert response.json() == []

    def test_get_all_users_with_data(self):
        # Create test users
        users = [
            {"name": "Alice", "email": "alice@example.com", "age": 25},
            {"name": "Bob", "email": "bob@example.com", "age": 30},
        ]

        for user in users:
            client.post("/users", json=user)

        response = client.get("/users")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        assert data[0]["name"] == "Alice"
        assert data[1]["name"] == "Bob"

    def test_get_user_by_id_success(self):
        # Create a user first
        user_data = {"name": "Test User", "email": "test@example.com", "age": 28}
        create_response = client.post("/users", json=user_data)
        user_id = create_response.json()["id"]

        # Get the user
        response = client.get(f"/users/{user_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Test User"
        assert data["email"] == "test@example.com"

    def test_get_user_by_id_not_found(self):
        response = client.get("/users/999")
        assert response.status_code == 404
        assert "User not found" in response.json()["detail"]

    def test_delete_user_success(self):
        # Create a user first
        user_data = {"name": "Delete Me", "email": "delete@example.com", "age": 35}
        create_response = client.post("/users", json=user_data)
        user_id = create_response.json()["id"]

        # Delete the user
        response = client.delete(f"/users/{user_id}")
        assert response.status_code == 200
        assert f"User {user_id} deleted successfully" in response.json()["message"]

        # Verify user is deleted
        get_response = client.get(f"/users/{user_id}")
        assert get_response.status_code == 404

    def test_delete_user_not_found(self):
        response = client.delete("/users/999")
        assert response.status_code == 404
        assert "User not found" in response.json()["detail"]


class TestDataValidation:
    """Test input validation"""

    def test_create_user_missing_fields(self):
        incomplete_data = {"name": "Incomplete User"}
        response = client.post("/users", json=incomplete_data)
        assert response.status_code == 422  # Validation error

    def test_create_user_invalid_types(self):
        invalid_data = {
            "name": "Valid Name",
            "email": "valid@example.com",
            "age": "not_a_number",  # Should be int
        }
        response = client.post("/users", json=invalid_data)
        assert response.status_code == 422


# Performance/Load test (basic)
class TestPerformance:
    """Basic performance tests"""

    def test_multiple_users_creation(self):
        """Test creating multiple users doesn't break anything"""
        for i in range(10):
            user_data = {
                "name": f"User {i}",
                "email": f"user{i}@example.com",
                "age": 20 + i,
            }
            response = client.post("/users", json=user_data)
            assert response.status_code == 200

        # Verify all users were created
        response = client.get("/users")
        assert len(response.json()) == 10
