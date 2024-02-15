#!/bin/zsh

# Variablen setzen
source ~/.docker/.env
IMAGE_NAME="video-nginx"

# In lokales verzeichnis wechseln
VERZEICHNIS=~/dev/docker/video_nginx
cd "$VERZEICHNIS"

# Pfad zur Datei mit der versionsnummer
VERSION_FILE=version.txt

# Überprüfe, ob die Versionsdatei existiert
if [ ! -f $VERSION_FILE ]; then
    echo "0.0.0" > $VERSION_FILE
    echo "Keine Versionsdatei gefunden. Starte mit Version 0.0.0."
fi

# Lese die aktuelle Version aus der Datei
CURRENT_VERSION=$(<$VERSION_FILE)

# Zeige die aktuelle Version an
echo "Aktuelle Version: $CURRENT_VERSION"

# Frage nach der neuen Version
echo "Bitte geben Sie die gewünschte NGINX-Version ein: "
read NEW_VERSION

# Speichere die neue Version in die Datei
echo $NEW_VERSION > $VERSION_FILE

echo "Die Version wurde auf $NEW_VERSION aktualisiert."

# Stelle sicher, dass das Dockerfile im aktuellen Verzeichnis existiert
    if [ ! -f "Dockerfile" ]; then
    echo "Dockerfile nicht gefunden!"
    exit 1
fi

# Docker Login
docker login

# Buildx erstellen
docker buildx create --name mybuilder --use --node mybuilder0

# Build das Docker Image
docker buildx build \
    --build-arg NGINX_VERSION=${NEW_VERSION} \
    --platform linux/amd64,linux/arm64 \
    -t ${DOCKER_USERNAME}/${IMAGE_NAME}:${NEW_VERSION} \
    -t ${DOCKER_USERNAME}/${IMAGE_NAME}:latest \
    --push .
if [ $? -ne 0 ]; then
    echo "Image konnte nicht gebaut werden."
    exit 1
fi

echo "Alle Operationen erfolgreich ausgeführt."
