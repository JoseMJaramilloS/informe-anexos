# SPEC MPI2007

Esta guía detalla el proceso de instalación y compilación de la suite SPEC MPI2007 en la **Jetson Nano**, abordando errores comunes debido a incompatibilidades con arquitecturas y configuraciones modernas. Dado que la suite no cuenta con una versión precompilada para esta arquitectura, es necesario realizar ajustes en archivos de código fuente y configurar correctamente las herramientas de compilación. En la sección **"Detalle de errores presentados"**, se explican las causas de cada problema encontrado durante la compilación.

Debe instalarse en el NAS, para que todos los nodos puedan acceder a la suite. En un cluster hibrido como este, donde el controlador se ejecuta en una maquina con arquitectura x86 y los nodos son de arquitectura arm64, debe tomarse en cuenta que los binarios compilados para la Jetson Nano, no pueden ser ejecutados por el controlador. Para solucionarlo se deben alojar todos los recursos desde uno de los nodos usando `salloc` esto permite lanzar el ejecutable desde uno de los nodos aunque no sea el controlador.



El archivo obtenido después de la solicitud y desde SPEC es

```bash
mpi2007-2.0.1.tar.bz2
```

Descomprimir el archivo en la carpeta compartida del NAS

```bash
mkdir mpi2007
tar -xvjf mpi2007-2.0.1.tar.bz2 -C mpi2007/
```

Correr el instalador

```bash
	cd mpi2007
	./install.sh
```

Lamentablemente no existe un toolset compatible para la arquitectura de la Jetson.

```bash
We do not appear to have working vendor-supplied binaries for your
architecture.  You will have to compile the tool binaries by
yourself.  Please read the file

    /home/jetson/mpi2007/Docs/tools_build.html

for instructions on how you might be able to build them.

Please only attempt this as a last resort.
```

Se deben usar las herramientas de compilación que vienen con la suite para realizar la instalación en nuestra arquitectura. Mas información: [Tools Build SPEC MPI2007](https://www.spec.org/mpi2007/Docs/tools-build.html)

# Compilación de la suite en la Jetson Nano

## 1. Actualizar archivos  `config.guess` y `config.sub`

Evita el error `config.guess: unable to guess system type` al compilar en sistemas modernos. (Ver ERROR 1).

Actualizar estos archivos en los siguientes directorios:

```bash
cd mpi2007/tools/src/make-3.81/config
cd mpi2007/tools/src/tar-1.15.1/config
```

En cada uno, ejecutar lo siguiente:

```bash
mv config.guess config.guess.ORIGINAL
mv config.sub config.sub.ORIGINAL

wget -O config.guess "http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess"
wget -O config.sub "http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub"
# alternantivas:
wget -O config.guess https://raw.githubusercontent.com/gcc-mirror/gcc/master/config.guess
wget -O config.sub https://raw.githubusercontent.com/gcc-mirror/gcc/master/config.sub

chmod +x config.guess
chmod +x config.sub
```

## 2. **Modificar `glob.c` para corregir referencias indefinidas**

Soluciona errores de compilación por distintas referencias indefinidas en el archivo `glob.c` . (Ver ERROR 2)

Modificar el siguiente archivo:

```bash
nano mpi2007/tools/src/make-3.81/glob/glob.c
```

Agregando en la parte inicial del código:

```c
#define _GNU_SOURCE

#include <alloca.h>
#ifndef __alloca
#define __alloca alloca
#endif

#include <string.h>
#ifndef __mempcpy
#define __mempcpy mempcpy
#endif

#include <sys/stat.h>
#ifndef __stat
#define __stat stat
#endif
```

## 3. **Comentar declaraciones en `getline.h`**

Previene errores por definiciones conflictivas de `getline` y `getdelim` en sistemas modernos. (Ver ERROR 4)

Comentar las siguientes líneas en el archivo `getline.h` 

```c
nano mpi2007/tools/src/specmd5sum/lib/getline.h

// int
// getline PARAMS ((char **_lineptr, size_t *_n, FILE *_stream));

// int
// getdelim PARAMS ((char **_lineptr, size_t *_n, int _delimiter, FILE *_stream));
```

## 4. Modificar `unix.c` para corregir el uso de `open()`

Evita el error `open with O_CREAT needs 3 arguments`, asegurando que la función tenga los permisos correctos. (Ver ERROR 5)

Editar archivo `unix.c` 

```c
nano mpi2007/tools/src/specinvoke/unix.c

// Linea 127, cambiar
infd = open(tmpfile, O_RDWR|O_CREAT|O_TRUNC);
// por
infd = open(tmpfile, O_RDWR|O_CREAT|O_TRUNC, 0644);
```

## 5. Reconfigurar el enlace simbólico de `/bin/sh` a Bash (revertir al final)

Soluciona posibles problemas de compatibilidad con scripts que asumen que `/bin/sh` es Bash. (Ver ERROR 7)

Eliminar el enlace simbólico y crear uno nuevo. **Advertencia:** no olvidar revertir después de terminar el proceso. Puede afectar el comportamiento general del sistema.

```bash
sudo rm /bin/sh
sudo ln -s /bin/bash /bin/sh

# Se revierte con
ls -l /bin/sh

```

## 6. Modificar `SysV.xs` para eliminar dependencias de `asm/page.h`

Corrige el error `asm/page.h: No such file or directory`, evitando problemas en la compilación de Perl. (Ver ERROR 8)

Quitar `# include <asm/page.h>` y agregar `#define PAGE_SIZE 4096`

```bash
nano mpi2007/tools/src/perl-5.8.8/ext/IPC/SysV/SysV.xs

	#include <sys/types.h>
	#ifdef __linux__
-	#   include <asm/page.h> 
+	#define PAGE_SIZE      4096
	#endif
```

## 7. Configurar variables de entorno y compilar con las banderas adecuadas

Evita errores de compilación en Perl y otros paquetes al definir `CFLAGS`, `LDFLAGS` y `PERLFLAGS` correctamente. (Ver ERROR 3, 6, y 9)

```bash
export CFLAGS="-O3 -march=armv8-a -D_FILE_OFFSET_BITS=64 -fcommon -fno-stack-protector -U_FORTIFY_SOURCE"
export CXXFLAGS=$CFLAGS
export LDFLAGS="-D_FILE_OFFSET_BITS=64 -lm -Wl,--allow-multiple-definition"
export PERLFLAGS="-A libs=-lm -A libs=-ldl"

./buildtools
```

Nota: durante la compilación de Perl, algunas pruebas pueden fallar, este es un comportamiento esperado y no es relevante. Confirmar con “y” cuando se pregunte por continuar el proceso.

Una vez finalizada la compilación exitosa, cambiar a la raiz del directorio de instalación y verificar:

```bash
cd mpi2007/
. ./shrc
runspec -V
runspec --test
```

---

# Compilar y correr benchmark

Construir archivo de configuración a partir de alguno de los ejemplos de la carpeta `config` .

Se usa como base, el ejemplo `example-hp-linux-ia64-intel-hpmpi.cfg`

```bash
cp example-hp-linux-ia64-intel-hpmpi.cfg arm64-jetson.cfg
nano arm64-jetson.cfg
```

El archivo `arm64-jetson.cfg` contiene lo siguiente:

```bash
# This is a sample config file for SPEC MPI 2007 on a Jetson Nano (ARM64)

%define MPIRUN_OPTIONS --mpi=pmix
%define CMD_PREFIX ulimit -s unlimited;
%define PARTITION --partition=nano
%define MPI_FLAGS OMPI_MCA_btl_tcp_if_include=eth0

action=validate
env_vars= 1

# OMPI_MCA_btl_tcp_if_include=eth0

submit= %{CMD_PREFIX} %{MPI_FLAGS} srun %{MPIRUN_OPTIONS} %{PARTITION}  --ntasks=$ranks $command

use_submit_for_speed = yes

tune=base
makeflags = -j 4
ext=arm64-jetson
output_format = csv, html, txt

# Use MPI wrapper compilers for GCC on ARM
FC = mpif90
CC = mpicc
CXX = mpicxx

default=default=default=default:
# Set optimization flags for GCC on ARMv8-A
BOPTS= -O3 -march=armv8-a

COPTIMIZE = ${BOPTS}
FOPTIMIZE = ${BOPTS}
CXXOPTIMIZE = ${BOPTS}

use_submit_for_speed=1

121.pop2:
CPORTABILITY= -DSPEC_MPI_CASE_FLAG

127.wrf2:
CPORTABILITY =  -DSPEC_MPI_CASE_FLAG  -DSPEC_MPI_LINUX
```

---

Una vez instalado y comprobado su funcionamiento, acceder con `ssh` a uno de los nodos , por ejemplo `node1` , y alojar todos los recursos disponibles en la particion `nano`:

```bash
salloc --nodes=10 --ntasks=40 --partition=nano
# equivalente:
salloc -N 10 -n 40 -p nano
```

---

Compilado un solo test

```bash
runspec --config=arm64-jetson.cfg  --action=build --tune=base --size=mtest 137.lu 
```

Corriendo un solo test

```bash
runspec -I --config=arm64-jetson.cfg --tune=base --size=mtest --ranks=40 --iterations=1 137.lu 
```

Corriendo la suite con el set de pruebas `medium` con dataset `test`

```c
runspec -I --config=arm64-jetson.cfg --tune=base --size=mtest --ranks=40 --iterations=1 medium > jetson_mpi_test_$(date "+%Y-%m-%d_%H-%M-%S").log 
```

Esta suite dispone de 4 datasets: mtest, mref, ltest y lref.

---

# Lanzando benchmark junto con tegrastats

Usar `jetson_clocks`. Lanzar usando `screen` y recordar establecer las variables de entorno con `. ./srhc`

```bash
#!/bin/bash

TEST="mref"
echo "Starting tegrastats on each node..."
LOG_DIR="/export/jmjarami/MPI2007_test/$(TEST)_$(date "+%Y-%m-%d_%H-%M-%S")"
mkdir -p ${LOG_DIR}
NODES=("node1" "node2" "node3" "node4" "node5" "node6" "node7" "node8" "node9" "node10") # Configure according to the cluster nodes

# Function to stop tegrastats on all nodes
stop_tegrastats() {
  echo "Stopping tegrastats on all nodes..."
  for node in "${NODES[@]}"; do
    ssh "$node" "sudo pkill -f tegrastats" 2>/dev/null
  done
}

# Function to handle script abortion (e.g., due to Ctrl+C or termination signals)
abort() {
  echo "Aborting operation..."
  stop_tegrastats
  exit 1
}

# Capture interruption signals (Ctrl+C, kill, etc.) and call abort()
trap abort SIGINT SIGTERM

# Start tegrastats on each node
for node in "${NODES[@]}"; do
  ssh "$node" "sudo tegrastats --interval 500 > ${LOG_DIR}/tegrastats_\$(hostname).log" &
done

# Wait a few seconds to ensure tegrastats is running on all nodes
sleep 5

# Launching the benchmark
echo "Starting MPI 2007 benchmark..."
START_TIME=$(date +%s)  # Capture the start time

# Run the SPEC MPI benchmark suite
runspec -I --config=arm64-jetson.cfg --tune=base --size=${TEST} --ranks=40 --iterations=1 \
	122 125 126 128 132 142 143  > "jetson_mpi_${TEST}_$(date "+%Y-%m-%d_%H-%M-%S").log"

END_TIME=$(date +%s)  # Capture the end time
EXECUTION_TIME=$((END_TIME - START_TIME))  # Calculate total execution time

echo "Script finished."
echo "Total execution time of MPI 2007: $EXECUTION_TIME seconds."

# Stop tegrastats when the benchmark finishes
stop_tegrastats

```

---

# Detalle de errores presentados durante compilación

## ERROR 1: config.guess: unable to guess system type

```bash
checking build system type... config/config.guess: unable to guess system type
```

El script `config.guess`, responsable de detectar el sistema en el que se ejecuta la compilación, no reconoce la arquitectura `aarch64` porque la suite de herramientas es antigua.

## ERROR 2: undefined reference to

```bash
/usr/bin/ld: glob.o: in function `glob_in_dir':
glob.c:(.text+0x1f4): undefined reference to `__alloca'
/usr/bin/ld: glob.c:(.text+0x424): undefined reference to `__alloca'
/usr/bin/ld: glob.c:(.text+0x4c4): undefined reference to `__alloca'
/usr/bin/ld: glob.c:(.text+0x538): undefined reference to `__alloca'
/usr/bin/ld: glob.c:(.text+0x600): undefined reference to `__alloca'
/usr/bin/ld: glob.o:glob.c:(.text+0x658): more undefined references to `__alloca' follow
collect2: error: ld returned 1 exit status
```

Durante la compilación, el enlazador (`ld`) no encuentra referencias a las funciones `alloca`, `mempcpy` y `stat` en el archivo `glob.c`. Esto ocurre porque estas funciones no están declaradas explícitamente en el código fuente, lo que genera referencias indefinidas.

## ERROR 3: multiple definition of argp_fmtstream_puts’

```c
/usr/bin/ld: ../lib/libtar.a(argp-fmtstream.o): in function `argp_fmtstream_puts':
argp-fmtstream.c:(.text+0x980): multiple definition of `argp_fmtstream_puts'; ../lib/libtar.a(argp-help.o):argp-help.c:(.text+0x1eb8): first defined here
collect2: error: ld returned 1 exit status
```

El proceso de enlace encuentra múltiples definiciones de la función `argp_fmtstream_puts`, lo que ocurre cuando un símbolo está definido en más de un archivo de la biblioteca `libtar.a`.

En versiones antiguas de C, las definiciones duplicadas eran aceptadas de forma predeterminada, pero en compiladores modernos es necesario especificar explícitamente que se permitan.

## ERROR 4: conflicting types for 'getline’

```c
In file included from md5sum.c:38:
lib/getline.h:31:1: error: conflicting types for 'getline'
 getline PARAMS ((char **_lineptr, size_t *_n, FILE *_stream));
 ^~~~~~~
In file included from md5sum.c:26:
/usr/include/stdio.h:616:18: note: previous declaration of 'getline' was here
 extern __ssize_t getline (char **__restrict __lineptr,
                  ^~~~~~~
In file included from md5sum.c:38:
lib/getline.h:34:1: error: conflicting types for 'getdelim'
 getdelim PARAMS ((char **_lineptr, size_t *_n, int _delimiter, FILE *_stream));
 ^~~~~~~~
In file included from md5sum.c:26:
/usr/include/stdio.h:606:18: note: previous declaration of 'getdelim' was here
 extern __ssize_t getdelim (char **__restrict __lineptr,
                  ^~~~~~~~
```

El archivo `getline.h` dentro del código fuente contiene una declaración de la función `getline`, pero esta ya está definida en `stdio.h` de la biblioteca estándar del sistema. Esto genera un conflicto porque el compilador detecta que hay dos definiciones diferentes de la misma función.

## ERROR 5: open with O_CREAT needs 3 arguments

```c
In function 'open',
    inlined from 'invoke' at unix.c:127:15:
/usr/include/aarch64-linux-gnu/bits/fcntl2.h:50:4: error: call to '__open_missing_mode' declared with attribute error: open with O_CREAT or O_TMPFILE in second argument needs 3 arguments
    __open_missing_mode ();
    ^~~~~~~~~~~~~~~~~~~~~~
```

El uso de `open()` con la bandera `O_CREAT` requiere un tercer argumento para definir los permisos del archivo creado. Si se omite este argumento, el compilador genera un error porque en sistemas modernos es obligatorio.

## ERROR 6: undefined reference to 'pow', 'log', 'sin’

```c
/usr/bin/ld: libperl.a(pp.o): in function `Perl_pp_pow':
pp.c:(.text+0x2e0c): undefined reference to `pow'
/usr/bin/ld: pp.c:(.text+0x2f1c): undefined reference to `pow'
/usr/bin/ld: libperl.a(pp.o): in function `Perl_pp_modulo':
pp.c:(.text+0x3b00): undefined reference to `fmod'
/usr/bin/ld: libperl.a(pp.o): in function `Perl_pp_atan2':
pp.c:(.text+0x8958): undefined reference to `atan2'
/usr/bin/ld: libperl.a(pp.o): in function `Perl_pp_sin':
pp.c:(.text+0x8a6c): undefined reference to `sin'
/usr/bin/ld: libperl.a(pp.o): in function `Perl_pp_cos':
pp.c:(.text+0x8bf4): undefined reference to `cos'
/usr/bin/ld: libperl.a(pp.o): in function `Perl_pp_exp':
pp.c:(.text+0x8fa4): undefined reference to `exp'
/usr/bin/ld: libperl.a(pp.o): in function `Perl_pp_log':
pp.c:(.text+0x9130): undefined reference to `log'
/usr/bin/ld: libperl.a(pp.o): in function `Perl_pp_sqrt':
pp.c:(.text+0x9444): undefined reference to `sqrt'
collect2: error: ld returned 1 exit status
```

El enlazador no encuentra referencias a funciones matemáticas (`pow`, `log`, `sin`, etc.), lo que ocurre cuando el código fuente no está vinculando la biblioteca matemática (`-lm`).

[ubuntu 14.04 - Building old Perl from source - How to add math library? - Server Faul](https://serverfault.com/questions/761966/building-old-perl-from-source-how-to-add-math-library)

## ERROR 7: You haven't done a "make depend" yet!

```c
        Making x2p stuff
make[1]: Entering directory `/home/jetson/mpi2007/tools/src/perl-5.8.8/x2p'
You haven't done a "make depend" yet!
make[1]: *** [hash.o] Error 1
make[1]: Leaving directory `/home/jetson/mpi2007/tools/src/perl-5.8.8/x2p'
make: *** [translators] Error 2
+ testordie error building Perl
+ test 2 -ne 0
+ echo !!! error building Perl
!!! error building Perl
+ kill -TERM 351712
+ exit 1
!!!!! buildtools killed
```

Este error aparece porque el sistema espera que las dependencias sean generadas antes de la compilación con `make depend`. Algunos scripts de compilación pueden estar diseñados para ejecutarse en un shell diferente al predeterminado en el sistema, lo que provoca fallos inesperados.

## ERROR 8: fatal error: asm/page.h: No such file or directory

```bash
SysV.xs:7:13: fatal error: asm/page.h: No such file or directory
 #   include <asm/page.h>
             ^~~~~~~~~~~~
compilation terminated.
make[1]: *** [SysV.o] Error 1
make[1]: Leaving directory `/home/jetson/mpi2007/tools/src/perl-5.8.8/ext/IPC/SysV'
make: *** [lib/auto/IPC/SysV/SysV.so] Error 2
+ testordie 'error building Perl'
+ test 2 -ne 0
+ echo '!!! error building Perl'
!!! error building Perl
+ kill -TERM 203246
+ exit 1
!!!!! buildtools killed
```

El archivo `asm/page.h`, antes presente en versiones antiguas del kernel de Linux, ha sido eliminado o reubicado en versiones recientes. Cualquier código que intente incluir este archivo fallará en la compilación.

[Install / execute spec cpu2006 benchmark | hacklog](https://sjp38.github.io/post/spec_cpu2006_install/)

## ERROR 9: buffer overflow detected

```bash
All tests successful.
Files=12, Tests=161, 37 wallclock secs ( 0.61 cusr +  0.32 csys =  0.93 CPU)
+ testordie 'error running File-NFSLock-1.20 test suite'
+ test 0 -ne 0
cp: cannot stat '/home/jetson/mpi2007/tools/output/bin/libperl*': No such file or directory
*** buffer overflow detected ***: terminated
*** buffer overflow detected ***: terminated
Top of SPEC benchmark tree is '/home/jetson/mpi2007'
Can't locate strict.pm in @INC (@INC contains: /home/jetson/mpi2007/bin /home/jetson/mpi2007/bin/lib .) at bin/relocate line 3.
BEGIN failed--compilation aborted at bin/relocate line 3.
Uhoh! I appear to have had problems relocating the tree.
Once you fix the problem (is your SPEC environment variable set?) you can make
the tools work by sourcing the shrc and running /home/jetson/mpi2007/bin/relocate by hand.
```

Este error indica que un programa intentó escribir más datos de los permitidos en una región de memoria, lo que puede deberse a un desbordamiento de búfer o a una mala gestión de punteros. Ocurre durante la ejecución de pruebas tras la compilación y, en este caso, no impide el funcionamiento correcto de la suite.
