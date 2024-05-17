#!/bin/bash

# Configuration
POSTGRES_CONTAINER_NAME="postgis"
POSTGRES_DB="treecover"
POSTGRES_USER="admin"
POSTGRES_PASSWORD="admin"
TIFF_FILE="TCL_DATA.tif"
TABLE_NAME="tree_cover_loss"

# Check if the TIFF file exists
if [ ! -f "$TIFF_FILE" ]; then
  echo "Error: TIFF file '$TIFF_FILE' not found!"
  exit 1
fi

# Copy the TIFF file into the PostGIS container
echo "Copying TIFF file into the PostGIS container..."
docker cp "$TIFF_FILE" "$POSTGRES_CONTAINER_NAME":/tmp/"$TIFF_FILE"

# Access the PostGIS container and upload the TIFF file to the database
echo "Uploading TIFF file to the PostGIS database..."



# Install PostGIS extension in the Docker container
echo "Installing PostGIS extension in the Docker container..."
docker exec -it $POSTGRES_CONTAINER_NAME bash -c "
  apt-get update -y &&
  apt-get install postgis -y
"

# Enable PostGIS extension in the database
echo "Enabling PostGIS extension in the database..."
docker exec -e PGPASSWORD=$POSTGRES_PASSWORD -it $POSTGRES_CONTAINER_NAME psql -U $POSTGRES_USER -d $POSTGRES_DB -c "
  CREATE EXTENSION postgis_raster;
"

docker exec -e PGPASSWORD=$POSTGRES_PASSWORD -it $POSTGRES_CONTAINER_NAME bash -c "
  raster2pgsql -s 4326 -I -C -M /tmp/$TIFF_FILE -t auto public.$TABLE_NAME | psql -h localhost -U $POSTGRES_USER -d $POSTGRES_DB
"

# Check if the upload was successful
if [ $? -eq 0 ]; then
  echo "TIFF file successfully uploaded to the PostGIS database."
else
  echo "Error: Failed to upload the TIFF file to the PostGIS database."
  exit 1
fi


echo "Done."
