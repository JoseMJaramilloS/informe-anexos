#!/bin/bash

# Variables de configuración
VERSION="4.2.8"
INSTALL_DIR="/opt/pmix"
BUILD_DIR="$INSTALL_DIR/build/$VERSION"
SOURCE_DIR="$INSTALL_DIR/source"
INSTALL_PREFIX="$INSTALL_DIR/install/$VERSION"

# Función para imprimir mensajes
log() {
    echo -e "\e[1;32m$1\e[0m"
}

# Verificar permisos de root
if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse como root o con sudo." >&2
    exit 1
fi

# Crear directorios necesarios
log "Creando directorios en $INSTALL_DIR..."
mkdir -p "$BUILD_DIR" "$INSTALL_PREFIX"
chown -R $(whoami):$(whoami) "$INSTALL_DIR"

# Clonar el repositorio
if [[ ! -d "$SOURCE_DIR" ]]; then
    log "Clonando el repositorio de PMIx..."
    git clone https://github.com/pmix/pmix.git "$SOURCE_DIR"
else
    log "El repositorio ya está clonado en $SOURCE_DIR."
fi

# Cambiar al branch o tag específico
log "Cambiando a la versión $VERSION..."
cd "$SOURCE_DIR"
git fetch --all
git checkout "v$VERSION"
git submodule update --init --recursive

# Generar archivos de configuración
log "Generando archivos de configuración con autogen.pl..."
./autogen.pl

# Configurar el entorno de compilación
log "Configurando PMIx para su instalación en $INSTALL_PREFIX..."
cd "$BUILD_DIR"
"$SOURCE_DIR/configure" --prefix="$INSTALL_PREFIX"

# Compilar e instalar
log "Compilando e instalando PMIx..."
make -j$(nproc)
make install

# Verificar instalación
log "Verificando la instalación..."
"$INSTALL_PREFIX/bin/pmix_info"

# Añadir rutas a las variables de entorno (opcional)
log "Agregando rutas de PMIx a PATH y LD_LIBRARY_PATH..."
echo "export PATH=$INSTALL_PREFIX/bin:\$PATH" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=$INSTALL_PREFIX/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc
source ~/.bashrc

log "Instalación completada. PMIx $VERSION está instalado en $INSTALL_PREFIX."
