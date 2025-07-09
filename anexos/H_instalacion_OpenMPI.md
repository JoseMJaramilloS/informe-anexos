# Instalacion OpenMPI

## Instalar dependencias

```bash
sudo apt update
sudo apt install libevent-dev
```

## Paso 1: Descargar OpenMPI

Descargar la última versión de OpenMPI desde su sitio oficial, en este caso `5.0.5`

```bash
wget https://download.open-mpi.org/release/open-mpi/v5.0/openmpi-5.0.5.tar.bz2
```

## Paso 2: Extraer el Archivo

Descomprimir el archivo descargado:

```bash
tar -xvjf openmpi-5.0.5.tar.bz2
cd openmpi-5.0.5
```

## Paso 3: Configuración con SLURM y PMIx

Para garantizar que OpenMPI funcione bien con SLURM y tenga soporte para PMIx, se configura la compulación de OpenMPI con las siguientes opciones:

```bash
./configure --prefix=/usr/local/openmpi \
            --with-slurm \
            --with-pmix=/opt/pmix/install/4.2.8 \

```

1. **`-prefix=/usr/local/openmpi`**: Define el directorio de instalación de OpenMPI.
2. **`-with-slurm`**: Habilita la compatibilidad directa con SLURM.
3. **`-with-pmix=`**: Indica la ruta a PMIx si tienes una versión específica instalada.

## Paso 4: Compilación e Instalación

Compilar OpenMPI

```bash
sudo make -j$(nproc)
```

Luego, instalar en una carpeta destino:

```bash
mkdir /home/jetson/mpi-package
sudo make -j install DESTDIR=/home/jetson/mpi-package
# esta carpeta se puede borrar despues de empaquetar
```

Crear paquete

```bash
fpm -s dir -t deb -n openmpi --version 5.0.5 --prefix=/ -C ~/mpi-package .
```

Instalar paquete

```bash
sudo dpkg -i openmpi_5.0.5_arm64.deb
```
El paquete puede ser descargado desde [acá](https://drive.google.com/file/d/17tHsSZZYbKYlwdVkzxpU6Z3lTzC7Y5px/view?usp=sharing)

## Paso 5: Actualizar las Variables de Entorno

Para asegurar que el sistema use la versión recién instalada, actualizar las variables de entorno en el archivo `~/.bashrc`:

```bash
echo 'export PATH=/usr/local/openmpi/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/openmpi/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc

```

## Paso 6: Verificar la Instalación

Para confirmar que la versión de OpenMPI se instaló correctamente:

```bash
mpirun --version
```

## Instalar en otros nodos

Copiar el paquete a los demás nodos o al NAS e instalar

```bash
cp /export/jmjarami/openmpi_5.0.5_arm64.deb .
sudo dpkg -i openmpi_5.0.5_arm64.deb
```

Recordar actualizar las variables de entorno con el paso 5.
