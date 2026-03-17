CONTAINER_NAME="jwtgen"
IMAGE_NAME="hdo-jwtgen"
EXPIRE_TIME=300 # 5 minutes

echo "Stopping and removing old container if exists..."
docker rm -f $CONTAINER_NAME >/dev/null 2>&1
mkdir -p data/jwtgen
cp jwt_* data/jwtgen

echo "Starting new container with JWT_EXPIRE=$EXPIRE_TIME..."
docker run -d \
  --name $CONTAINER_NAME \
  -e JWT_EXPIRE=$EXPIRE_TIME \
  --volume $PWD/data/jwtgen:/etc/jwtgen:z \
  --volume $PWD/data/ssl/private:/etc/ssl/private:z \
  $IMAGE_NAME

docker logs -f $CONTAINER_NAME