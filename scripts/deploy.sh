set -e

echo "🚀 Deploying Application..."

# Default values
ENVIRONMENT="local"
PORT=3000
CONTAINER_NAME="cicd-demo-app"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -e, --env     Environment (local, staging, production) [default: local]"
            echo "  -p, --port    Port number [default: 3000]"
            echo "  -h, --help    Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Set container name based on environment
CONTAINER_NAME="cicd-demo-$ENVIRONMENT"

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker image exists
if ! docker images cicd-demo-app:latest | grep -q cicd-demo-app; then
    print_error "Docker image 'cicd-demo-app:latest' not found. Please run ./scripts/build.sh first"
    exit 1
fi

print_status "Deploying to $ENVIRONMENT environment on port $PORT..."

# Stop existing container if running
if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    print_warning "Stopping existing container: $CONTAINER_NAME"
    docker stop $CONTAINER_NAME || true
    docker rm $CONTAINER_NAME || true
fi

# Run new container
print_status "Starting new container: $CONTAINER_NAME"
docker run -d \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    -p $PORT:3000 \
    -e ENV=$ENVIRONMENT \
    cicd-demo-app:latest

# Health check
print_status "Performing health check..."
for i in {1..30}; do
    if curl -f http://localhost:$PORT/health >/dev/null 2>&1; then
        print_status "✅ Deployment successful!"
        print_status "Application is running at: http://localhost:$PORT"
        print_status "Health check: http://localhost:$PORT/health"
        print_status "API docs: http://localhost:$PORT/docs"
        break
    fi
    print_warning "Health check attempt $i/30 - waiting..."
    sleep 2
done

# Final verification
if ! curl -f http://localhost:$PORT/health >/dev/null 2>&1; then
    print_error "Deployment failed - health check unsuccessful"
    print_error "Check container logs: docker logs $CONTAINER_NAME"
    exit 1
fi

echo
print_status "🎉 Deployment completed successfully!"