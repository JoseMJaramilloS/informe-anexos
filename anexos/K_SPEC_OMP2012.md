# SPEC OMP2012

Esta guía proporciona los pasos necesarios para instalar y configurar el benchmark **SPEC OMP2012**, una suite diseñada para evaluar el rendimiento de sistemas con múltiples núcleos utilizando programación paralela con OpenMP. Se cubren los requisitos previos, el proceso de instalación y la configuración inicial para ejecutar pruebas de manera eficiente.


# Instalación de SPEC OMP2012

Para descargar el benchmark se debe realizar una solicitud a la organización en el sitio oficial de SPEC, indicando qué tests se desean descargar. Esta solicitud se hace bajo una licencia abierta no-comercial.

La descarga es una imagen de disco comprimida:

```bash
omp2012-1.1.iso.xz
```

Se crea una carpeta en el almacenamiento NAS de prueba llamada `benchmarks` :

```bash
/mnt/cluster-storage/benchmarks/
```

Para descomprimir el archivo ISO:

```bash
cd /mnt/cluster-storage/benchmarks/
xz -d omp2012-1.1.iso.xz
```

Intentar montar la imagen ISO (por defecto en /mnt):

```bash
sudo mount -t iso9660 -o ro,loop omp2012-1.1.iso /mnt
```

Si lo anterior falla, extraer directamente los datos del ISO:

```bash
mkdir omp2012
7z x omp2012-1.1.iso -o/mnt/cluster-storage/benchmarks/omp2012/
```

Instalar el benchmark en la ruta deseada, en este caso `/usr/omp2012` :

```bash
sudo mkdir /usr/omp2012
sudo chown jetson:jetson /usr/omp2012/
cd /mnt/cluster-storage/benchmarks/omp2012
./install.sh -d /usr/omp2012
```

Aparece el siguiente mensaje de confirmación. Revisar que la rutas sean correctas:

```bash
SPEC OMP2012 Installation

Top of the OMP2012 tree is '/mnt/cluster-storage/benchmarks/omp2012'

Installing FROM /mnt/cluster-storage/benchmarks/omp2012
Installing TO /usr/omp2012

Is this correct? (Please enter 'yes' or 'no')

```

Luego de indicar que sí, la herramienta realiza la instalación de la suite en la Jetson

```bash
The following toolset is expected to work on your platform.  If the
automatically installed one does not work, please re-run install.sh and
exclude that toolset using the '-e' switch.

The toolset selected will not affect your benchmark scores.

linux-apm-arm64               For 64-bit ARM-based Linux systems.
                              Built on APM Linux with GCC 4.8.1 (APM-6.0.4).
                              These tools are expected to work on Fedora 19
                              and later and Ubuntu 13.1 and later.

=================================================================
Attempting to install the linux-apm-arm64 toolset...

Unpacking OMP2012 base files (930.2 MB)

Checking the integrity of your source tree...

Checksums are all okay.

Unpacking binary tools for linux-apm-arm64...

Checking the integrity of your binary tools...

Checksums are all okay.

Testing the tools installation (this may take a minute)

........................................................................o.................................................................................................................................................

Installation successful.  Source the shrc or cshrc in
/usr/omp2012
to set up your environment for the benchmark.
```

Después de la instalación, cambiar al directorio principal de omp2012

```bash
cd /usr/omp2012/
```

Y ejecutar lo siguiente

```bash
. ./shrc         #<-- that's dot-space-dot-slash-shrc
```

Esto establecerá las variables de entorno y rutas de archivos de SPEC. Lo anterior no es una configuración persistente, se debe repetir cada vez que se vaya a correr el benchmarking luego de haber iniciado una nueva sesión.

# Compilando y corriendo la suite de benchmarks

Para compilar los tests de la suite, se debe usar un archivo de configuración compatible con el sistema y la arquitectura en la que va a correr. La instalación anterior identificó como arquitectura de la Jetson a `linux-apm-arm64` . Dentro de la carpeta *config* no se encuentra ningún archivo específico para esta arquitectura, por lo que se deberá crear a partir de alguno de los ejemplos.

```bash
cd $SPEC/config
```

```bash
nano arm64-jetson.cfg
```

Lo siguiente se construye basado en el archivo de configuración `aarch64-chibchohaec.cfg` para la VIM3 desarrollado por el profesor Luis Germán García.

```bash
#----------------------------------------------------------------------
# Document Title: arm64-jetson.cfg
# Last Update: November 2019
# 
# This configuration file has been tested with Linux Ubuntu 20.04 GCC
# compiler.
# SBCs: Jetson Nano.
#----------------------------------------------------------------------

ext                   = arm64-jetson
tune                  = base
output_format         = csv, html, txt
runlist               = all_c, all_cpp, all_fortran
command_add_redirect  = yes
makeflags             = -j4

#----------------------------------------------------------------------
# Compiler Section
#----------------------------------------------------------------------
default:
CC  = gcc 
CXX = g++
FC  = f77

#----------------------------------------------------------------------
# Optimization Settings
#----------------------------------------------------------------------
default:
COPTIMIZE    = -fopenmp
CXXOPTIMIZE  = -fopenmp
FOPTIMIZE    = -fopenmp 

default=base:
COPTIMIZE    += -O0
CXXOPTIMIZE  += -O0
FOPTIMIZE    += -O0 
EXTRA_LIBS   = 

default=peak:
COPTIMIZE    += -O3
CXXOPTIMIZE  += -O3
FOPTIMIZE    += -O3 
EXTRA_LIBS   = 

#----------------------------------------------------------------------
# Portability Flags
#----------------------------------------------------------------------
default=default=default=default:
FPORTABILITY = -ffree-form -fno-range-check

351.bwaves,357.bt331,363.swim,370.mgrid331=default=default=default:
FPORTABILITY =

367.imagick=default=default=default:
FPORTABILITY = -std=c99

```

Luego se compila un solo benchmark (md: molecular dynamic) usando la herramienta instalada de SPEC OMP2012

```bash
runspec --config=arm64-jetson.cfg --action=build --tune=base md
```

Y se corre utilizando un dataset de prueba

```bash
runspec --config=arm64-jetson.cfg --size=test --noreportable --tune=base --iterations=1 --threads=4 md
```

Parámetros:

**`--config`**: Define el archivo de configuración con opciones de compilación y optimización específicas para la plataforma.

**`--size:`** Determina el tamaño del conjunto de datos usado en la prueba.

**`--noreportable:`** Indica que los resultados no serán válidos para comparación oficial.

**`--tune:`** Especifica el nivel de optimización aplicado en la ejecución.

**`--iterations:`** Define cuántas veces se ejecutará el benchmark.

**`--threads:`** Controla la cantidad de hilos utilizados para la ejecución en paralelo.

**md**: Indica el nombre del benchmark a ejecutar (molecular dynamic).

Correr el benchmark con dataset real

```bash
runspec --config=arm64-jetson.cfg --size=ref --noreportable --tune=base --iterations=1 --threads=4 md
```

Comprobado el funcionamiento del benchmark, se puede lanzar la suite completa.

---

**Importante:** 

- configurar `jetson_clocks` antes de lanzar la suite. Esto bloquea la frecuencia del procesador a su valor máximo, ofreciendo un mayor rendimiento.
    
    Puede hacerse en la interfaz de *jtop (pestaña CTRL)* o mediante comandos
    
    ```bash
    # activar
    sudo jetson_clocks
    
    # desactivar
    sudo jetson_clocks --restore
    ```
    
- Usar *swap memory* de 10GB (de manera temporal)
    
    ```
    sudo swapoff -a
    sudo dd if=/dev/zero of=/swapfile bs=1G count=10 status=progress
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    ```
    

---

Compilar todos los tests y correr con dataset de prueba, para descartar aquellos que no corran:

```
runspec --config=arm64-jetson.cfg --action=build --tune=base
runspec -I --config=arm64-jetson.cfg --size=test --tune=base --iterations=1 --threads=4
```

La opcion `-I`  omite los errores que detienen la ejecucion del benchmark, permitiendo correrlos todos hasta el final.

Finalmente, correr los benchmark que pasaron la prueba, pero usando esta vez dataset de referencia

```
runspec -I --config=arm64-jetson.cfg --size=ref --tune=base --iterations=1 --threads=4 350 352 358 367 376 > jetson_spec_omp2012.log
```

# Correr junto con `tegrastats`

```bash
cd /usr/omp2012/
 . ./shrc
```

```bash
nano launcher.sh
```

El script `launcher.sh` contiene lo siguiente:

```bash
#!/bin/bash

echo "Iniciando tegrastats..."
sudo tegrastats --interval 500 --logfile tegrastats_omp2012_$(date "+%Y-%m-%d_%H-%M-%S").log --start

# Espera unos segundos para asegurarte que tegrastats ya esté corriendo en todos los nodos.
sleep 5

# Lanzando benchmark
echo "Iniciando benchmark OMP2012..."
runspec -I --config=arm64-jetson.cfg --size=ref --tune=base --iterations=1 --threads=4 350 352 358 367 376 > jetson_omp2012_ref_$(date "+%Y-%m-%d_%H-%M-%S").log
echo "Benchmark finalizado. Deteniendo tegrastats..."
sudo tegrastats --stop

```

Volver ejecutable:

```bash
chmod +x launcher.sh
```
Bloquear procesador a máxima frecuencia

```bash
sudo jetson_clocks
```

Abrir una sesión de `screen` y correr:

```bash
./launcher.sh
```


# Referencias:

[SPEC OMP 2012](https://www.spec.org/omp2012/)

[SPEC Docs](https://www.spec.org/omp2012/Docs/)

[SPEC runspec](https://www.spec.org/omp2012/Docs/runspec.html)
