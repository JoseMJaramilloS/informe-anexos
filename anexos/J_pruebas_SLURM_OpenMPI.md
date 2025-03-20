# Pruebas SLURM y OpenMPI

Este anexo documenta la ejecución y validación de trabajos en el clúster utilizando **SLURM** y **OpenMPI**. Se incluyen pruebas básicas de asignación de tareas, ejecución de scripts en Python y C, solución de problemas de comunicación entre nodos y una evaluación de rendimiento mediante el cálculo de números primos. Estas pruebas verifican el correcto funcionamiento del sistema y su capacidad para ejecutar procesos en paralelo de manera eficiente.

# Comandos utiles

```bash
# Informacion general del estado de los nodos
sinfo

#Informacion detallada de cada nodo
scontrol show nodes

# Cambiar estado de uno o varios nodos
sudo scontrol update nodename=node[1-10] state=idle

# Cola de trabajos
squeue

# Prueba simple: ejecutar comando hostname en 10 nodos
srun -N10 hostname

# Lista de plugins MPI
srun --mpi=list
```

# 1. Trabajo simple: mostrando hostnames de los nodos.

Se crea una carpeta de pruebas en la unidad NFS montada en el cluster para el usuario en uso, este es un home compartido por lo que la terminal mostrará la ruta como `~/carpeta_creada`:

```bash
mkdir /export/jmjarami/SLURM_test
mkdir /export/jmjarami/SLURM_test/1_simple_test
cd /export/jmjarami/SLURM_test/1_simple_test
```

Luego se crea un archivo `.sh` para configurar la ejecucion de la tarea:

```bash
#!/bin/bash
#SBATCH --job-name=test_job        # Nombre del trabajo
#SBATCH --nodes=10                 # Numero de nodos
#SBATCH --output=output_test.txt   # Archivo de salida
#SBATCH --ntasks=10                # Número de tareas
#SBATCH --time=00:01:00            # Tiempo limite
#SBATCH --partition=nano           # Partición en la que correra

echo "Iniciando trabajo en SLURM"
srun hostname
sleep 10
echo "Trabajo completado"
```

El archivo debe tener permisos de ejecución.

```bash
chmod +x test_job.sh
```

Los nodos deben estar activos y esperando. La partición de interes es `nano`:

```bash
jmjarami@broly:~/SLURM_test/1_simple_test/$ sinfo
PARTITION   AVAIL  TIMELIMIT  NODES  STATE NODELIST
full-gpu       up   infinite      3   idle linux[1-3]
full-node1     up   infinite      1   idle linux1
full-node2     up   infinite      1   idle linux2
full-node3     up   infinite      1   idle linux3
small-node4    up   infinite      1   idle linux4
large-gpu      up   infinite      1   idle linux5
nano           up   infinite     10   idle node[1-10]
```

Y ejecutar usando **`sbatch`**

```bash
jmjarami@broly:~/SLURM_test/1_simple_test/$ sbatch test_job.sh
```

Se genera un archivo en la ruta llamado `output_test.txt` que contiene lo siguiente:

```bash
Iniciando trabajo en SLURM
node1
node7
node5
node9
node3
node2
node4
node10
node8
node6
Trabajo completado
```

# 2. Ejecutando un archivo de Python.

Se crea un nueva carpeta y un archivo `.sh` en `/export/jmjarami/SLURM_test/2_python_test`

```bash
#!/bin/bash
#SBATCH --job-name=python_test_job           # Nombre del trabajo
#SBATCH --nodes=10                           # Numero de nodos
#SBATCH --ntasks=10                          # Numero de tareas
#SBATCH --output=output_python_test_%N.txt   # Archivo de salida para cada nodo
#SBATCH --time=00:01:00                      # Tiempo limite
#SBATCH --partition=nano                     # Partición en la que correra

echo "Iniciando trabajo en SLURM"
srun python3 ./test_cpu.py
echo "Trabajo completado"

```

y se crea el programa de Python `test_cpu.py` también en la misma ruta. La salida se configura por nodo y que apunte a la carpeta compartida:

```python
import socket
import time

node_name = socket.gethostname()
output_file = f"/export/jmjarami/SLURM_test/2_python_test/resultado_{node_name}.txt"

# Simular carga de trabajo en CPU
start_time = time.time()
cpu_result = sum(i**2 for i in range(10**6))  # Cálculo simple en CPU
end_time = time.time()

execution_time = end_time - start_time

# Guardar resultado en un archivo
with open(output_file, "w") as file:
    file.write(f"Nodo: {node_name}\n")
    file.write(f"Tiempo de ejecución: {execution_time:.4f} segundos\n")
    file.write(f"Resultado CPU: {cpu_result}\n")

```

Se indica la ruta absoluta del archivo apuntando al NAS del cluster. 

Se revisan permisos y se ejecuta:

```bash
sbatch python_test_job.sh
```

Como se configuro en el batch de SLURM, con el parametro `--output`se genera un archivo de salida llamado `output_python_test_1.txt` . Este archivo no debe confundirse con el resultado de la operación del programa de Python, sino que en este se guardará la salida estándar (stdout) al ejecutar el trabajo o tarea, es decir, todo lo que se vería por consola al ejecutar `sbatch`. En este caso el contenido es:

```
Iniciando trabajo en SLURM
Trabajo completado
```

Además se muestra que solo se genera un archivo de este tipo, y según su nombre, proviene del node1. Esto sucede porque cuando se lanza una tarea desde el nodo principal, en este caso `broly` , el batch se ejecuta en el primer nodo disponible y luego lanza la tarea a los demás. Esto quiere decir que el mensaje fue producido en `node1` mientras que en el resto de los nodos solo se ejecutó el programa de Python. Por defecto, SLURM unifica toda la salida estándar de todas las tareas en un único archivo, y en nuestro caso, lo guarda con el nombre del nodo en el que inició. Mas no significa que el programa se haya ejecutado solo en ese nodo.

Al final se obtiene los siguientes archivos:

```bash
jmjarami@broly:~/SLURM_test/2_python_test$ ls
output_python_test_node1.txt  resultado_node10.txt  resultado_node2.txt  resultado_node4.txt  resultado_node6.txt  resultado_node8.txt test_cpu.py 
python_test_job.sh            resultado_node1.txt   resultado_node3.txt  resultado_node5.txt  resultado_node7.txt  resultado_node9.txt 

```

En todos los archivos se escribe correctamente la respuesta de la operación.

# 3. Prueba simple con OpenMPI

MPI se centra en la ejecución de procesos y la comunicación entre ellos en entornos distribuidos (sistemas con arquitectura de memoria distribuida). Se puede usar con otras herramientas que permiten la paralelización en hilos como OpenMP o pthreads.

Se crea un pequeño programa en C que usa MPI. El “hola mundo” de MPI.

```bash
mkdir /export/jmjarami/SLURM_test/3_MPI_test
cd /export/jmjarami/SLURM_test/3_MPI_test
nano hello_mpi.c
```

```c
#include <mpi.h>
#include <stdio.h>

int main(int argc, char *argv[]) {
    // Inicializa MPI
    MPI_Init(&argc, &argv);

    // Obtén el tamaño (número total de procesos) y el rango (ID de cada proceso)
    int size, rank;
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    // Imprime mensaje desde cada proceso
    printf("Hola desde el proceso %d de %d\n", rank, size);

    // Finaliza MPI
    MPI_Finalize();
    return 0;
}
```

<aside>
⚠️ Si la compilación se realiza desde el servidor (un sistema x86) los nodos no podrán ejecutar el programa, pues no tienen la misma arquitectura (aarch64). Una alternativa es realizar compilación cruzada. Otra, es acceder a uno de los nodos con el usuario compartido y compilar desde allí.

</aside>

Se compila lanzando el comando por `ssh` desde el servidor a uno de los nodos Jetson.

```bash
ssh jmjarami@192.168.100.30 "mpicc /export/jmjarami/SLURM_test/3_MPI_test$/hello_mpi.c -o /export/jmjarami/SLURM_test/3_MPI_test$/hello_mpi"
# Comprobar que sea aarch64
file hello_mpi
```

Volver al nodo principal en el servidor y hacer el programa ejecutable:

```bash
chmod +x hello_mpi
```

Se crean un nuevo script de SLURM para configurar los recursos y lanzar el trabajo:

```bash
nano mpi_job.sh
```

En este caso se puede jugar con la combinación de nodos y tareas.  Se tienen disponibles 10 nodos y cada nodo soporta hasta 4 procesos.

```bash
#!/bin/bash
#SBATCH --job-name=mpi_test       # Nombre del job
#SBATCH --nodes=10                # Número de nodos a usar
#SBATCH --ntasks=40               # Numero total de procesos
#SBATCH --time=00:05:00           # Tiempo máximo de ejecución (HH:MM:SS)
#SBATCH --output=mpi_test_%j.log  # Archivo de salida (usa %j para el JobID)
#SBATCH --partition=nano

# Ejecuta el programa con srun, que se integra con SLURM
srun --mpi=pmix ./hello_mpi

```

La opción `--mpi=pmix` permite que SLURM y OpenMPI se comuniquen correctamente.

Se lanza el trabajo:

```bash
sbatch mpi_job.sh
```

El archivo generado `mpi_test_<job-ID>.log` contiene lo siguiente, lo que confirma el correcto funcionamiento de OpenMPI junto con SLURM:

```
jmjarami@broly:~/SLURM_test/3_MPI_test$ cat mpi_test_2350.log
Hola desde el proceso 28 de 40
Hola desde el proceso 29 de 40
Hola desde el proceso 30 de 40
Hola desde el proceso 31 de 40
Hola desde el proceso 24 de 40
Hola desde el proceso 25 de 40
Hola desde el proceso 26 de 40
Hola desde el proceso 27 de 40
Hola desde el proceso 1 de 40
Hola desde el proceso 32 de 40
Hola desde el proceso 2 de 40
Hola desde el proceso 3 de 40
Hola desde el proceso 8 de 40
Hola desde el proceso 9 de 40
Hola desde el proceso 33 de 40
Hola desde el proceso 10 de 40
Hola desde el proceso 34 de 40
Hola desde el proceso 11 de 40
Hola desde el proceso 35 de 40
Hola desde el proceso 36 de 40
Hola desde el proceso 37 de 40
Hola desde el proceso 38 de 40
Hola desde el proceso 39 de 40
Hola desde el proceso 16 de 40
Hola desde el proceso 4 de 40
Hola desde el proceso 17 de 40
Hola desde el proceso 5 de 40
Hola desde el proceso 18 de 40
Hola desde el proceso 6 de 40
Hola desde el proceso 19 de 40
Hola desde el proceso 7 de 40
Hola desde el proceso 20 de 40
Hola desde el proceso 22 de 40
Hola desde el proceso 23 de 40
Hola desde el proceso 21 de 40
Hola desde el proceso 0 de 40
Hola desde el proceso 13 de 40
Hola desde el proceso 14 de 40
Hola desde el proceso 15 de 40
Hola desde el proceso 12 de 40
```

# 4. Encontrado primos con OpenMPI

```bash
mkdir /export/jmjarami/SLURM_test/4_MPI_primes
cd /export/jmjarami/SLURM_test/4_MPI_primes
```

```bash
nano primes_mpi.c
```

```c
#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

int is_prime(int num)
{
    if (num < 2)
        return 0; // Numbers less than 2 are not prime
    if (num == 2 || num == 3)
        return 1; // 2 and 3 are prime
    if (num % 2 == 0 || num % 3 == 0)
        return 0; // Eliminate multiples of 2 and 3
    if (num > 5 && num % 5 == 0)
        return 0; // Eliminate multiples of 5

    for (int i = 5; i * i <= num; i += 6)
    {
        if (num % i == 0 || num % (i + 2) == 0)
            return 0; // If divisible by i or i+2, it's not prime
    }
    return 1; // If no divisor was found, it is prime
}

int main(int argc, char **argv)
{
    int rank, size;
    long long total_primes = 0;
    long long local_primes = 0;
    const long long UPPER_LIMIT = 1000000;
    double start_time, end_time;
    double duration, max_duration;

    MPI_Init(&argc, &argv);
    
    int mpi_initialized;
    MPI_Initialized(&mpi_initialized);  // Correct: pass the address of an integer variable
    if (!mpi_initialized) {
        fprintf(stderr, "MPI is not initialized\n");
    }

    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    // Barrier to synchronize all processes before starting the measurement (Ready, Set... GO)
    MPI_Barrier(MPI_COMM_WORLD);
    start_time = MPI_Wtime();

    // Count 2 as prime in process 0 (if within limit)
    if (rank == 0 && UPPER_LIMIT >= 2)
        local_primes++;

    // Work division
    long long start = (UPPER_LIMIT / size) * rank + (rank == 0 ? 2 : 1);
    long long end = (UPPER_LIMIT / size) * (rank + 1);
    if (rank == size - 1)
        end = UPPER_LIMIT; // Ensuring full coverage up to the exact limit

    // Adjust start to skip 2 (process only odds)
    if (start <= 2)
        start = 3;

    // Ensure only odd numbers are processed (except 2)
    if (start % 2 == 0)
        start++;

    // Local computation
    for (long long num = start; num <= end; num += 2)
    {
        if (is_prime(num))
            local_primes++;
    }

    // Reduce results and final measurement
    MPI_Reduce(&local_primes, &total_primes, 1, MPI_LONG_LONG, MPI_SUM, 0, MPI_COMM_WORLD);

    end_time = MPI_Wtime();
    duration = end_time - start_time;

    // Get the maximum duration among all processes
    MPI_Reduce(&duration, &max_duration, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);

    if (rank == 0)
    {
        printf("Prime numbers up to %lld: %lld\n", UPPER_LIMIT, total_primes);
        printf("Execution time: %.4f seconds\n", max_duration);
    }

    MPI_Finalize();
    return 0;
}


```

Se compila lanzando el comando por `ssh` desde el servidor a uno de los nodos Jetson.

```bash
ssh jmjarami@node1 "mpicc /export/jmjarami/SLURM_test/4_MPI_primes/primes_mpi.c -o /export/jmjarami/SLURM_test/4_MPI_primes/primes_mpi"
# Comprobar que sea aarch64
file primes_mpi
```

Se corre primero en 2 nodos y 8 tareas.

```bash
#!/bin/bash
#SBATCH --job-name=mpi_primes     # Nombre del job
#SBATCH --nodes=2                 # Número de nodos a usar
#SBATCH --ntasks=8                # Numero total de procesos
#SBATCH --time=00:05:00           # Tiempo máximo de ejecución (HH:MM:SS)
#SBATCH --output=mpi_primes_%j.log  # Archivo de salida (usa %j para el JobID)
#SBATCH --partition=nano

# Ejecuta el programa con srun, que se integra con SLURM
srun --mpi=pmix ./primes_mpi
```

```c
sbatch primes_job.sh
```

Cuando se intenta con un solo nodo, funciona sin problemas. Pero al usar mas de uno, como en el script anterior, sale el siguiente error:

```c
[node1][[59295,0],0][btl_tcp_endpoint.c:668:mca_btl_tcp_endpoint_recv_connect_ack] received unexpected process identifier: got [[59295,0],3] expected [[59295,0],4]
[node2][[59295,0],4][btl_tcp_endpoint.c:668:mca_btl_tcp_endpoint_recv_connect_ack] received unexpected process identifier: got [[59295,0],7] expected [[59295,0],0]
srun: Job step aborted: Waiting up to 32 seconds for job step to finish.
[node1][[59295,0],3][btl_tcp_endpoint.c:668:mca_btl_tcp_endpoint_recv_connect_ack] received unexpected process identifier: got [[59295,0],0] expected [[59295,0],7]
[node1][[59295,0],2][btl_tcp_endpoint.c:668:mca_btl_tcp_endpoint_recv_connect_ack] received unexpected process identifier: got [[59295,0],1] expected [[59295,0],6]
[node1][[59295,0],1][btl_tcp_endpoint.c:668:mca_btl_tcp_endpoint_recv_connect_ack] received unexpected process identifier: got [[59295,0],2] expected [[59295,0],5]
slurmstepd: error: *** STEP 2351.0 ON node1 CANCELLED AT 2025-02-15T10:05:08 ***
[node2][[59295,0],7][btl_tcp_endpoint.c:668:mca_btl_tcp_endpoint_recv_connect_ack] received unexpected process identifier: got [[59295,0],4] expected [[59295,0],3]
[node2][[59295,0],6][btl_tcp_endpoint.c:668:mca_btl_tcp_endpoint_recv_connect_ack] received unexpected process identifier: got [[59295,0],5] expected [[59295,0],2]
[node2][[59295,0],5][btl_tcp_endpoint.c:668:mca_btl_tcp_endpoint_recv_connect_ack] received unexpected process identifier: got [[59295,0],6] expected [[59295,0],1]
srun: error: node1: tasks 0-1,3: Exited with exit code 14
srun: error: node1: task 2: Killed
srun: error: node2: tasks 4-7: Killed

```

El error parece estar relacionado con la existencia de varias interfaces de red en los dispositivos:

[TCP: unexpected process identifier in connect_ack · Issue #6240 · open-mpi/ompi](https://github.com/open-mpi/ompi/issues/6240)

[[OMPI users] Cluster : received unexpected process identifier](https://users.open-mpi.narkive.com/HKNZpSXF/ompi-cluster-received-unexpected-process-identifier)

[How I lost a Day to OpenMPI Being Mental | JamieJQuinn](http://blog.jamiejquinn.com/how-i-lost-a-day-to-openmpi-being-mental)

La solución entonces es usar el parametro `--mca btl_tcp_if_exclude` seguido de las interfaces a excluir y  que podrían generar conflictos, o el parametro `--mca btl_tcp_if_include` seguido de las interfaces a incluir. La interfaz dependerá del sistema que se esté usando y la configuración. Puede ver a que interfaz corresponde la IP de la red de nodos, usando `ifconfig` . En los nodos del cluster la interfaz es `eth0`

Los parámetros puede indicarse de distintas maneras:

```bash
# Con mpirun
mpirun --mca btl_tcp_if_exclude lo,docker0 -np 4 ./cualquier_programa
mpirun --mca btl_tcp_if_include eth0 -np 4 ./cualquier_programa

# Con srun
export OMPI_MCA_btl_tcp_if_exclude=lo,docker0
srun -n 4 ./tu_programa
export OMPI_MCA_btl_tcp_if_include=eth0
srun -n 4 ./tu_programa

# Tambien
OMPI_MCA_btl_tcp_if_exclude=lo srun -n 4 ./tu_programa
OMPI_MCA_btl_tcp_if_include=eth0 srun -n 4 ./tu_programa
```

Otra forma, tal vez la más recomendada, es incluir este enfoque directamente en el script de `sbatch`. En este caso, también se define una función para realizar múltiples ejecuciones, variando la carga de trabajo y el número de procesos.

Además, se añade `2>/dev/null` en el comando `srun`, ya que existe un mensaje de error inofensivo pero molesto relacionado con el servidor X, que genera la salida "No protocol specified" por cada proceso.

```bash
#!/bin/bash
#SBATCH --job-name=mpi_primes     # Nombre del job
#SBATCH --nodes=10                 # Número de nodos a usar
#SBATCH --ntasks=40                # Numero total de procesos
#SBATCH --time=00:05:00           # Tiempo máximo de ejecución (HH:MM:SS)
#SBATCH --output=mpi_primes_%j.log  # Archivo de salida (usa %j para el JobID)
#SBATCH --partition=nano

# Se inlcuye las interfaces a usar
export OMPI_MCA_btl_tcp_if_include=eth0

# Función para ejecutar srun e imprimir la configuración
function run_srun {
    local nodos=$1
    local procesos=$2
    echo "Ejecutando srun con ${nodos} nodo(s) y ${procesos} proceso(s)"
    srun -N${nodos} -n${procesos} --mpi=pmix ./primes_mpi 2>/dev/null
    echo "-------------------------------------------------------------"
}

# Ejecuta diferentes combinaciones del programa con srun
run_srun 1 1
run_srun 1 2
run_srun 1 4
run_srun 2 8
run_srun 4 16
run_srun 6 24
run_srun 8 32
run_srun 10 40
```

Ejemplo: con este último script, se lanza el trabajo para encontrar los números primos hasta 1,000,000, obteniendo como resultado `78,498` números primos. A continuación, se muestra la tabla con los tiempos obtenidos para distintas combinaciones de carga y número de procesos:

| Nodos | Procesos | Tiempo (s) |
| --- | --- | --- |
| 1 | 1 | 0.19233150 |
| 1 | 2 | 0.11821671 |
| 1 | 4 | 0.06264561 |
| 2 | 8 | 0.03209381 |
| 4 | 16 | 0.01699186 |
| 6 | 24 | 0.02006463 |
| 8 | 32 | 0.00892506 |
| 10 | 40 | 0.01602835 |

Esta es sólo una prueba. Los resultados finales pueden variar respecto a estos valores.
