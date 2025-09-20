
set -e

echo "🏗️ Building Docker Image..."

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

# Build image
docker build -t cicd-demo-app:latest .

# Tag with git commit hash if in git repo
if git rev-parse --git-dir > /dev/null 2>&1; then
    COMMIT_HASH=$(git rev-parse --short HEAD)
    docker tag cicd-demo-app:latest cicd-demo-app:$COMMIT_HASH
    echo -e "${GREEN}[INFO]${NC} Tagged image with commit hash: $COMMIT_HASH"
fi

# Show image info
echo -e "${GREEN}[INFO]${NC} Built image details:"
docker images cicd-demo-app --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}"

echo -e "${GREEN}✅ Build completed successfully!${NC}"