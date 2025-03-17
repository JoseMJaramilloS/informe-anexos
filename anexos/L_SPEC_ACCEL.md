
# SPEC ACCEL

El benchmark **SPEC ACCEL** evalúa el rendimiento de aceleradores utilizando dos tecnologías: **OpenCL y OpenACC**. Sin embargo, ejecutar este benchmark en la **Jetson Nano** presenta desafíos debido a la falta de soporte nativo para OpenCL en los chips **Tegra** y a las limitaciones del entorno de OpenACC en esta plataforma.

Inicialmente, se intentó utilizar **OpenACC** con el **NVIDIA HPC SDK**, ya que la Jetson Nano es compatible con esta tecnología. Sin embargo, esta opción fue descartada debido a que las herramientas oficiales de NVIDIA solo funcionan en arquitecturas y sistemas operativos diseñados para servidores, lo que generó incompatibilidades al intentar ejecutar los programas compilados.

Ante esta limitación, se exploró la posibilidad de ejecutar **OpenCL** mediante **PoCL (Portable Computing Language)**, una implementación de OpenCL que permite la ejecución en plataformas sin soporte nativo. Para ello, fue necesario instalar **LLVM y Clang**, ya que PoCL depende de este framework de compilación.

Finalmente, con PoCL, se logró ejecutar correctamente varios de los tests basados en OpenCL, siendo esta la única parte del benchmark SPEC ACCEL que pudo correr en la Jetson Nano. Cabe destacar que pueden existir limitaciones de rendimiento y compatibilidad en comparación con sistemas con soporte nativo para OpenCL.



## Requisitos

SPEC ofrece versiones pre-compiladas para la instalacion del benchmark en distintas arquitecturas. En el caso de la Jetson, se tiene disponible el *toolset* para `linux-apm-arm64` por lo que se espera una instalación limpia, sin la necesidad de compilar desde la fuente ni realizar una configuración tediosa.

SPEC recomienda al menos 4 GB de memoria RAM y 2 GB de memoria en el acelerador gráfico. Al menos 9 GB de almacenamiento disponible son necesarios.

## Instalación de SPEC ACCEL

El archivo compartido por SPEC es el siguiente: `accel-1.4.tar.xz` . Se crea una carpeta en la ruta deseada para descomprimir el archivo:

```
mkdir /home/jetson/accel
cp accel-1.4.tar.xz /home/jetson/accel
cd /home/jetson/accel
tar -xvf accel-1.4.tar.xz
```

Ejecutar el instalador:

```bash
./install.sh
```

Nota: se intentó usar el parametro `-d` para realizar la instalación de la suite en un directorio diferente, pero el instalador no resolvía las rutas correctamente lo que provocaba error, razón por la cual se descartó.

Se confirma el proceso de instalación.

```bash
SPEC ACCEL Installation

Top of the ACCEL tree is '/home/jetson/accel'

Installing FROM /home/jetson/accel
Installing TO /home/jetson/accel

Is this correct? (Please enter 'yes' or 'no')
yes

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

Checking the integrity of your source tree...

Checksums are all okay.

Unpacking binary tools for linux-apm-arm64...

Checking the integrity of your binary tools...

Checksums are all okay.

Testing the tools installation (this may take a minute)

........................................................................o.................................................................................................................................................

Installation successful.  Source the shrc or cshrc in
/home/jetson/accel
to set up your environment for the benchmark.
```

Una vez instalado se establecen las variables de entorno y rutas de archivos de SPEC.

```bash
cd /home/jetson/accel
. ./shrc         #<-- that's dot-space-dot-slash-shrc
```

Recordar ejecutar `. ./shrc`  luego de iniciar una nueva sesión en el sistema.

## Instalación de PoCL

[Instalación PoCL](anexos/instalacion_pocl.md)

## Compilando y corriendo la suite

Primero se debe crear un archivo de configuración compatible con el sistema, algunos ejemplos pueden encontrarse en la carpeta `config`

```bash
cd $SPEC/config
cp Example-nvhpc.cfg arm64-jetson.cfg
```

El archivo `arm64-jetson.cfg` contiene lo siguiente:

```bash
#
#      Compiler name/version:       NVIDIA CUDA
#      Operating system version:    Ubuntu 20.04 
#      CPU:                         ARM Cortex-A57
#
####################################################################
# Tester information
####################################################################
license_num     = 0000
prepared_by     = Jose Miguel Jaramillo Sanchez (josem.jaramillo@udea.edu.co)
tester          = Universidad de Antioquia
test_sponsor    = SISTEMIC

######################################################################
# The header section of the config file.  Must appear
# before any instances of "default="
#
# ext = how the binaries you generated will be identified
# tune = specify "base" or "peak" or "all"
# the rest are default values

ext           = arm64-jetson
output_format = asc, text, html
teeout        = yes
teerunout     = yes
tune          = base,peak
makeflags      = -j 4
#output_root   = /local/home/<user>/SPECACCEL

####################################################################
# HOST Hardware information
####################################################################
default=default=default=default:
hw_avail           = Nov-2024
hw_cpu_name        = ARM Cortex-A57
hw_cpu_mhz         = 1470
hw_fpu             = Integrated
hw_nchips          = 1
hw_ncores          = 4
hw_ncoresperchip   = 4
hw_nthreadspercore = 1
hw_ncpuorder       = 1 chip
hw_pcache          = 48 KB I + 32 KB D on chip per core
hw_scache          = 2 MB I+D on chip per chip
hw_tcache          = None
hw_ocache          = None
hw_vendor          = NVIDIA
hw_model           = Jetson Nano Developer Kit
hw_disk            = MicroSD, 128 GB
hw_memory          = 4 GB LPDDR4
hw_other           = None

####################################################################
# Accelerator Hardware information
####################################################################
hw_accel_model     = Maxwell
hw_accel_vendor    = NVIDIA
hw_accel_name      = NVIDIA Maxwell GPU
hw_accel_type      = GPU
hw_accel_connect   = Integrated
hw_accel_ecc       = No
hw_accel_desc      = Integrated GPU with 128 CUDA cores
####################################################################
# Software information
####################################################################
openacc=default=default=default:
sw_avail         = Nov-2024
sw_compiler      = NVIDIA CUDA 10.2
sw_other         = JetPack 4.6
sw_accel_driver  = NVIDIA UNIX aarch64 

default=default=default:
CC           = gcc
CXX          = g++
FC           = gfortran 
OPTIMIZE     = -O3 -march=armv8-a -ffast-math 

# Update the path to the CUDA version
opencl=default=default=default:
LIBS           = -L/usr/local/cuda-10.2/lib64 -lOpenCL
EXTRA_CXXFLAGS = -I/usr/local/cuda-10.2/include
EXTRA_CFLAGS   = -I/usr/local/cuda-10.2/include

openmp=default=default=default:
OPTIMIZE     += -fopenmp 

openacc=default=default=default:
OPTIMIZE     += -acc -gpu=cc50,fastmath

116.histo=default=default=default:
CPORTABILITY += -DSPEC_LOCAL_MEMORY_HEADROOM=1

359.miniGhost,559.pmniGhost:
EXTRA_LDFLAGS += -Mnomain

```

Se compila y ejecuta correctamente uno de los tests con el dataset de prueba (`test`):

```bash
runspec --config=arm64-jetson.cfg --platform NVIDIA --device GPU --size=test --tune=base --iterations=1 fft
```

Sin embargo, al usar el dataset de referencia (`ref`) para `fft`, falla.

El test 103 parece funcionar correctamente con el dataset `ref` y se observa uso de GPU en `jtop` por lo que se confirma la utilización de OpenCL exitosamente.

```bash
 runspec --config=arm64-jetson.cfg --platform NVIDIA --device GPU --size=ref --tune=base --iterations=1 103
```

Corriendo todos los tests de OpenCL

```bash
runspec -I --config=arm64-jetson.cfg --platform NVIDIA --device GPU --size=ref --tune=base --iterations=1 opencl > jetson_accel_ref_$(date "+%Y-%m-%d_%H-%M-%S").log
```

## Corriendo los tests de OpenCL junto con`tegrastats`

Se crea un script para correr los tests junto con `tegrastats` para medir el rendimiento del sistema.

```bash
 cd /home/jetson/accel
 . ./shrc # Siempre que se va a correr despues de iniciar una nueva sesion
```

```bash
nano launcher.sh
```

El script `launcher.sh` contiene lo siguiente:

```bash
#!/bin/bash

echo "Iniciando tegrastats..."
sudo tegrastats --interval 500 --logfile tegrastats_accel_$(date "+%Y-%m-%d_%H-%M-%S").log --start

# Espera unos segundos para asegurarte que tegrastats ya esté corriendo en todos los nodos.
sleep 5

# Lanzando benchmark
echo "Iniciando benchmark ACCEL..."
runspec -I --config=arm64-jetson.cfg --platform NVIDIA --device GPU --size=ref --tune=base --iterations=1 001 103 104 112 118 122 123 124 126 127 > jetson_accel_ref_$(date "+%Y-%m-%d_%H-%M-%S").log

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




## Referencias

https://www.spec.org/accel/docs/system-requirements.html

https://forums.developer.nvidia.com/t/opencl-support-on-jetson-nano/72584

[https://forums.developer.nvidia.com/t/opencl-support/74071](https://forums.developer.nvidia.com/t/opencl-support/74071?utm_source=chatgpt.com)

https://forums.developer.nvidia.com/t/jetson-nano-and-hpc-sdk/160750/10

https://www.spec.org/accel/Docs/
