# HPL

**HPL** es un software que resuelve sistemas de ecuaciones lineales densos en precisión doble (64 bits) en computadoras con memoria distribuida. Es una implementación portátil y de acceso libre del High Performance Computing Linpack Benchmark.

Para usar **HPL**, el sistema debe contar con una implementación de **MPI** y también con **BLAS** o **VSIPL**. Existen versiones genéricas y específicas para distintas máquinas de estas bibliotecas.

HPL es un benchmark de CPU+MPI por lo que no usará la GPU Maxwell de la Jetson Nano.


# Pre requisitos

MPI: disponible en los nodos con versión 5.0.5.

OpenBLAS: instalar en todos los nodos con:

```
sudo apt install libopenblas-dev
```

(Versión instalada: **0.3.8**)

# Descarga e instalación

Descargar y extraer la ultima version de HPL:

```
wget https://www.netlib.org/benchmark/hpl/hpl-2.3.tar.gz
tar -xvf hpl-2.3.tar.gz
cd hpl-2.3
```

Configurar la compilación para **Jetson Nano**:

```
cp setup/Make.Linux_Intel64 Make.Linux_ARM
nano Make.Linux_ARM
```

Modificar el archivo para adaptarlo a la arquitectura **ARM**. El archivo final es el siguiente:

```
#  
#  -- High Performance Computing Linpack Benchmark (HPL)                
#     HPL - 2.3 - December 2, 2018                          
#     Antoine P. Petitet                                                
#     University of Tennessee, Knoxville                                
#     Innovative Computing Laboratory                                 
#     (C) Copyright 2000-2008 All Rights Reserved                       
#                                                                       
#  -- Copyright notice and Licensing terms:                             
#                                                                       
#  Redistribution  and  use in  source and binary forms, with or without
#  modification, are  permitted provided  that the following  conditions
#  are met:                                                             
#                                                                       
#  1. Redistributions  of  source  code  must retain the above copyright
#  notice, this list of conditions and the following disclaimer.        
#                                                                       
#  2. Redistributions in binary form must reproduce  the above copyright
#  notice, this list of conditions,  and the following disclaimer in the
#  documentation and/or other materials provided with the distribution. 
#                                                                       
#  3. All  advertising  materials  mentioning  features  or  use of this
#  software must display the following acknowledgement:                 
#  This  product  includes  software  developed  at  the  University  of
#  Tennessee, Knoxville, Innovative Computing Laboratory.             
#                                                                       
#  4. The name of the  University,  the name of the  Laboratory,  or the
#  names  of  its  contributors  may  not  be used to endorse or promote
#  products  derived   from   this  software  without  specific  written
#  permission.                                                          
#                                                                       
#  -- Disclaimer:                                                       
#                                                                       
#  THIS  SOFTWARE  IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,  INCLUDING,  BUT NOT
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE UNIVERSITY
#  OR  CONTRIBUTORS  BE  LIABLE FOR ANY  DIRECT,  INDIRECT,  INCIDENTAL,
#  SPECIAL,  EXEMPLARY,  OR  CONSEQUENTIAL DAMAGES  (INCLUDING,  BUT NOT
#  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA OR PROFITS; OR BUSINESS INTERRUPTION)  HOWEVER CAUSED AND ON ANY
#  THEORY OF LIABILITY, WHETHER IN CONTRACT,  STRICT LIABILITY,  OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
# ######################################################################
#  
# ----------------------------------------------------------------------
# - shell --------------------------------------------------------------
# ----------------------------------------------------------------------
#
SHELL        = /bin/sh
#
CD           = cd
CP           = cp
LN_S         = ln -fs
MKDIR        = mkdir -p
RM           = /bin/rm -f
TOUCH        = touch
#
# ----------------------------------------------------------------------
# - Platform identifier ------------------------------------------------
# ----------------------------------------------------------------------
#
ARCH         = Linux_ARM
#
# ----------------------------------------------------------------------
# - HPL Directory Structure / HPL library ------------------------------
# ----------------------------------------------------------------------
#
#TOPdir       = $(HOME)/hpl-2.3
TOPdir       = /home/jetson/hpl-2.3
INCdir       = $(TOPdir)/include
BINdir       = $(TOPdir)/bin/$(ARCH)
LIBdir       = $(TOPdir)/lib/$(ARCH)
#
HPLlib       = $(LIBdir)/libhpl.a
#
# ----------------------------------------------------------------------
# - Message Passing library (MPI) --------------------------------------
# ----------------------------------------------------------------------
# MPinc tells the  C  compiler where to find the Message Passing library
# header files,  MPlib  is defined  to be the name of  the library to be
# used. The variable MPdir is only used for defining MPinc and MPlib.
#
MPdir        = /usr/local/openmpi
MPinc        = -I$(MPdir)/include
MPlib        = -L$(MPdir)/lib -lmpi
#
# ----------------------------------------------------------------------
# - Linear Algebra library (BLAS or VSIPL) -----------------------------
# ----------------------------------------------------------------------
# LAinc tells the  C  compiler where to find the Linear Algebra  library
# header files,  LAlib  is defined  to be the name of  the library to be
# used. The variable LAdir is only used for defining LAinc and LAlib.
#

LAdir        = /usr/lib/aarch64-linux-gnu
LAinc        =
LAlib        = -L$(LAdir) -lopenblas

#
# ----------------------------------------------------------------------
# - F77 / C interface --------------------------------------------------
# ----------------------------------------------------------------------
# You can skip this section  if and only if  you are not planning to use
# a  BLAS  library featuring a Fortran 77 interface.  Otherwise,  it  is
# necessary  to  fill out the  F2CDEFS  variable  with  the  appropriate
# options.  **One and only one**  option should be chosen in **each** of
# the 3 following categories:
#
# 1) name space (How C calls a Fortran 77 routine)
#
# -DAdd_              : all lower case and a suffixed underscore  (Suns,
#                       Intel, ...),                           [default]
# -DNoChange          : all lower case (IBM RS6000),
# -DUpCase            : all upper case (Cray),
# -DAdd__             : the FORTRAN compiler in use is f2c.
#
# 2) C and Fortran 77 integer mapping
#
# -DF77_INTEGER=int   : Fortran 77 INTEGER is a C int,         [default]
# -DF77_INTEGER=long  : Fortran 77 INTEGER is a C long,
# -DF77_INTEGER=short : Fortran 77 INTEGER is a C short.
#
# 3) Fortran 77 string handling
#
# -DStringSunStyle    : The string address is passed at the string loca-
#                       tion on the stack, and the string length is then
#                       passed as  an  F77_INTEGER  after  all  explicit
#                       stack arguments,                       [default]
# -DStringStructPtr   : The address  of  a  structure  is  passed  by  a
#                       Fortran 77  string,  and the structure is of the
#                       form: struct {char *cp; F77_INTEGER len;},
# -DStringStructVal   : A structure is passed by value for each  Fortran
#                       77 string,  and  the  structure is  of the form:
#                       struct {char *cp; F77_INTEGER len;},
# -DStringCrayStyle   : Special option for  Cray  machines,  which  uses
#                       Cray  fcd  (fortran  character  descriptor)  for
#                       interoperation.
#
F2CDEFS      = -DAdd_ -DF77_INTEGER=int -DStringSunStyle
#
# ----------------------------------------------------------------------
# - HPL includes / libraries / specifics -------------------------------
# ----------------------------------------------------------------------
#
# HPL_INCLUDES = -I$(INCdir) -I$(INCdir)/$(ARCH) -I$(LAinc) $(MPinc)
HPL_INCLUDES = -I$(INCdir) -I$(INCdir)/$(ARCH) $(MPinc)
HPL_LIBS     = $(HPLlib) $(LAlib) $(MPlib)
#
# - Compile time options -----------------------------------------------
#
# -DHPL_COPY_L           force the copy of the panel L before bcast;
# -DHPL_CALL_CBLAS       call the cblas interface;
# -DHPL_CALL_VSIPL       call the vsip  library;
# -DHPL_DETAILED_TIMING  enable detailed timers;
#
# By default HPL will:
#    *) not copy L before broadcast,
#    *) call the BLAS Fortran 77 interface,
#    *) not display detailed timing information.
#
HPL_OPTS     = -DHPL_DETAILED_TIMING -DHPL_PROGRESS_REPORT
#
# ----------------------------------------------------------------------
#
HPL_DEFS     = $(F2CDEFS) $(HPL_OPTS) $(HPL_INCLUDES)
#
# ----------------------------------------------------------------------
# - Compilers / linkers - Optimization flags ---------------------------
# ----------------------------------------------------------------------
#
CC       = mpicc
CCNOOPT  = $(HPL_DEFS)
# OMP_DEFS = -openmp
CCFLAGS  = $(HPL_DEFS) -O3 -fomit-frame-pointer -funroll-loops -Wall
#
# On some platforms,  it is necessary  to use the Fortran linker to find
# the Fortran internals used in the BLAS library.
#
LINKER       = $(CC)
LINKFLAGS    = $(CCFLAGS)
#
ARCHIVER     = ar
ARFLAGS      = r
RANLIB       = echo
#
# ----------------------------------------------------------------------
```

Compilar **HPL**:

```
make arch=Linux_ARM
```

Esto generará el ejecutable `xhpl` en `bin/Linux_ARM/`.

# Prueba básica en un solo nodo

Ejecutar en el nodo actual sin utilizar otros nodos:

```
cd /home/jetson/hpl-2.3/bin/Linux_ARM/
mpirun -n 4 ./xhpl > output.txt
```

El archivo de salida `HPL.out` mostrará los GFLOPS obtenidos y el tiempo total.

## Consideraciones importantes

Después de realizar algunas pruebas con SLURM y OpenMPI, se ha observado que:

- Para correr correctamente programas que usan MPI junto con SLURM, se debe indicar el plugin instalado, en este caso, PMIx, usando la opción de `srun --mpi=pmix`
    
    ```bash
    srun --mpi=pmix -N 4 ./xhpl
    ```
    
- Lo ideal es correr desde el NAS, evitando la tediosa tarea de crear y modificar archivos en cada nodo.
- Los problemas relacionados con protocolos TCP se pueden resolver excluyendo las interfaces de red que no se utilizan para la comunicación de los nodos del cluster (o simplemente incluyendo la interfaz que sí se usa).

# Ejecución en cluster

Crear una carpeta en el `home` compartido del NAS. 

```bash
mkdir export/jmjarami/HPL_test
cd HPL_test
```

Copiar el ejecutable `xhpl` y el archivo `HPL.dat` desde la Jetson donde fue compilado.

```
cp ~/hpl-2.3/bin/Linux_ARM/* export/jmjarami/HPL_test
```

Hacer ejecutable `xhpl` con `chmod +x xhpl`.

Crear el script `hpl_job.sh` para lanzar el benchmark con SLURM. 

```bash
#!/bin/bash
#SBATCH --job-name=hpl_job           # Nombre del job
#SBATCH --nodes=10                   # Número de nodos a usar
#SBATCH --ntasks=40                  # Número total de procesos
#SBATCH --time=10:00:00              # Tiempo máximo de ejecución (HH:MM:SS)
#SBATCH --output=hpl_job_%j.log      # Archivo de salida (usa %j para el JobID)
#SBATCH --partition=nano

# Configura la interfaz de red a usar
export OMPI_MCA_btl_tcp_if_include=eth0

# Ejecuta el benchmark HPL con srun.
srun --mpi=pmix ./xhpl
```

Para monitorear el consumo de energía durante la ejecución del benchmark, se utiliza **tegrastats** en cada nodo. La estrategia emplea dos scripts: **`launcher.sh`**, que inicia `tegrastats` en todos los nodos y lanza sbatch con el trabajo, y **`hpl_job.slurm`**, que ejecuta el benchmark. Este enfoque permite recopilar métricas de consumo energético de manera eficiente y sin interferencias.

---
⚠️ **Nota:** desde el usuario **jetson**, se otorgaron permisos sudo a `jmjarami` en todos los nodos para ejecutar `tegrastats` sin solicitar contraseña:

```bash
sudo usermod -aG sudo jmjarami
sudo visudo
```

Agregar al final del archivo:

```bash
jmjarami ALL=(ALL) NOPASSWD: ALL
```

---

Crear script `launcher.sh` y volver ejecutable: `chmod +x launcher.sh` :

```bash
#!/bin/bash

echo "Iniciando tegrastats en cada nodo..."
LOG_DIR="/export/jmjarami/HPL_test"
NODES=("node1" "node2" "node3" "node4" "node5" "node6" "node7" "node8" "node9" "node10")

JOBID=""

# Función para detener tegrastats en todos los nodos
stop_tegrastats() {
  echo "Deteniendo tegrastats en todos los nodos..."
  for node in "${NODES[@]}"; do
    ssh "$node" "sudo pkill -f tegrastats" 2>/dev/null
  done
  
}

abort() {
  echo "Abortando operacion..."
  stop_tegrastats
  if [[ -n "$JOBID" ]]; then
    echo "Cancelando job: $JOBID"
    scancel "$JOBID"
  fi
  exit 1
}

# Capturar señales de interrupción (Ctrl+C, kill, etc.)
trap abort SIGINT SIGTERM

# Iniciar tegrastats en cada nodo
for node in "${NODES[@]}"; do
  ssh "$node" "sudo tegrastats --interval 500 > ${LOG_DIR}/tegrastats_\$(hostname).log" &
done

# Espera unos segundos para asegurarte que tegrastats ya esté corriendo en todos los nodos.
sleep 5

# Lanzando benchmark
echo "Iniciando benchmark HPL..."
START_TIME=$(date +%s)  # Captura el tiempo de inicio

JOBID=$(sbatch hpl_job.sh | awk '{print $4}')
echo "El job HPL es: $JOBID"

echo "Esperar a que el job termine..."
while squeue -j "$JOBID" 2>/dev/null | grep -q "$JOBID"; do
  sleep 30
done

END_TIME=$(date +%s)  # Captura el tiempo de finalización
EXECUTION_TIME=$((END_TIME - START_TIME))  # Calcula el tiempo total

echo "Script finalizado."
echo "Tiempo total de ejecución de XHPL: $EXECUTION_TIME segundos."

# Cuando el benchmark termine, detiene tegrastats
stop_tegrastats
```

# Los parametros de HPL.dat

- **`Ns` (problem size):** Define el tamaño de la matriz, que se almacena en RAM. Se recomienda establecer el valor más alto posible sin exceder la capacidad de memoria disponible, ya que un tamaño excesivo cancelará el trabajo.
- **`NBs` (block size):** Controla el tamaño de los bloques en la multiplicación de matrices, optimizando el rendimiento en comparación con una ejecución elemento por elemento.
- **`P` y `Q` (proceso grid):** Deben configurarse para coincidir con el número total de procesos lanzados. Su producto (`P × Q`) debe ser igual al número de procesos en ejecución.

Para evitar limitaciones en el rendimiento, es fundamental:

1. Ajustar `Ns`, `P` y `Q` adecuadamente, considerando la memoria disponible en cada nodo (4 GB).
2. Desbloquear la frecuencia de los nodos antes de la ejecución.
3. Verificar que el número de procesos sea compatible con la configuración del archivo `HPL.dat`.

Para más detalles sobre la elección de estos parámetros, se recomienda la siguiente referencia:

🔗 [Ajuste de HPL.dat - Tecnologías avanzadas de agrupación](https://www.advancedclustering.com/act_kb/tune-hpl-dat-file/)

Editar el archivo `HPL.dat` para configurar la ejecución del test

```bash
HPLinpack benchmark input file
Innovative Computing Laboratory, University of Tennessee
HPL.out      output file name (if any)
6            device out (6=stdout,7=stderr,file)
1            # of problems sizes (N)
25000        Ns
1            # of NBs
192          NBs
0            PMAP process mapping (0=Row-,1=Column-major)
1            # of process grids (P x Q)
4            Ps
10           Qs
16.0         threshold
3            # of panel fact
0 1 2        PFACTs (0=left, 1=Crout, 2=Right)
2            # of recursive stopping criterium
2 4          NBMINs (>= 1)
1            # of panels in recursion
2            NDIVs
3            # of recursive panel fact.
0 1 2        RFACTs (0=left, 1=Crout, 2=Right)
1            # of broadcast
0            BCASTs (0=1rg,1=1rM,2=2rg,3=2rM,4=Lng,5=LnM)
1            # of lookahead depth
0            DEPTHs (>=0)
2            SWAP (0=bin-exch,1=long,2=mix)
64           swapping threshold
0            L1 in (0=transposed,1=no-transposed) form
0            U  in (0=transposed,1=no-transposed) form
1            Equilibration (0=no,1=yes)
8            memory alignment in double (> 0)

```

Bloquear la frecuencia de los nodos.

```bash
# activar
sudo jetson_clocks

# desactivar
sudo jetson_clocks --restore
```

Abrir una sesión de `screen` y lanzar con `./launcher.sh`
