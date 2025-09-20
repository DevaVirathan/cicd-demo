set -e  # Exit on error

echo "🚀 Setting up CI/CD Demo Environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Python 3.11+ is installed
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install Python 3.11+"
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
print_status "Python version: $PYTHON_VERSION"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker"
    exit 1
fi

print_status "Docker version: $(docker --version)"

# Create virtual environment
if [ ! -d "venv" ]; then
    print_status "Creating virtual environment..."
    python3 -m venv venv
else
    print_warning "Virtual environment already exists"
fi

# Activate virtual environment
print_status "Activating virtual environment..."
source venv/bin/activate

# Install dependencies
print_status "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements-dev.txt

# Create necessary directories
print_status "Creating project directories..."
mkdir -p app tests scripts .github/workflows

# Create empty __init__.py files
touch app/__init__.py tests/__init__.py

# Copy environment variables
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        print_status "Created .env file from .env.example"
    else
        print_warning "No .env.example found, skipping .env creation"
    fi
fi

print_status "✅ Setup completed successfully!"
echo
print_status "Next steps:"
echo "1. Activate virtual environment: source venv/bin/activate"
echo "2. Run tests: ./scripts/test.sh"
echo "3. Start the application: uvicorn app.main:app --reload"
echo "4. Build Docker image: ./scripts/build.sh"
