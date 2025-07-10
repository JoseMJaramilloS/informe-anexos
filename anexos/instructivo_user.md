# Instructivo de uso - Cluster de Jetson Nano

## Índice

1. [Especificaciones del clúster](https://www.notion.so/Instructivo-de-uso-Cluster-de-Jetson-Nano-214fa7ade15c804ba5f0e4c96e0d4660?pvs=21)
2. [Acceso y uso básico del clúster](https://www.notion.so/Instructivo-de-uso-Cluster-de-Jetson-Nano-214fa7ade15c804ba5f0e4c96e0d4660?pvs=21)
3. [Comandos útiles en SLURM](https://www.notion.so/Instructivo-de-uso-Cluster-de-Jetson-Nano-214fa7ade15c804ba5f0e4c96e0d4660?pvs=21)
4. [Ejemplos de ejecución](https://www.notion.so/Instructivo-de-uso-Cluster-de-Jetson-Nano-214fa7ade15c804ba5f0e4c96e0d4660?pvs=21)
    
    4.1 Script SLURM básico
    
    4.2 Ejecución de programa MPI simple
    
5. [Notas y advertencias](https://www.notion.so/Instructivo-de-uso-Cluster-de-Jetson-Nano-214fa7ade15c804ba5f0e4c96e0d4660?pvs=21)
    - Mensaje `No protocol specified`
6. [Referencias adicionales](https://www.notion.so/Instructivo-de-uso-Cluster-de-Jetson-Nano-214fa7ade15c804ba5f0e4c96e0d4660?pvs=21)

---

# Especificaciones del cluster:

**Infraestructura general:**

- **Total de nodos Jetson**: 10 (node[1-10])
- **Partición SLURM activa**: `nano`
- **Nodo controlador**: servidor x86_64 con acceso LDAP y NFS
- **Red de interconexión**: conmutadores Netgear JGS524 (Gigabit)
- **Almacenamiento compartido**: NAS vía NFSv3
- **Distribución de energía**: Fuentes ATX EVGA 1200W con líneas de 5V dedicadas

**Hardware de cada nodo (Jetson Nano):**

- **CPU**: Quad-core ARM Cortex-A57 a 1.43 GHz
- **GPU**: NVIDIA Maxwell con 128 núcleos CUDA
- **RAM**: 4 GB LPDDR4
- **Almacenamiento**: MicroSD con Ubuntu 20.04 personalizado
- **Red**: Interfaz Ethernet Gigabit
- **Consumo**: 5W (modo ahorro) / 10W (modo alto rendimiento)

**Software del sistema:**

- **Sistema operativo Jetson**: Ubuntu 20.04 con JetPack 4.6
- **Gestor de colas**: SLURM con autenticación Munge
- **Comunicación entre procesos**: OpenMPI + PMIx
- **Autenticación**: LDAP centralizado
- **Monitoreo local**: `tegrastats`, `jtop`

---

# 1. Acceso y uso básico del clúster

**Requisitos previos**:

- Contar con usuario válido en el sistema LDAP del servidor `broly` de GITA.
- Tener conexión SSH habilitada.

**Pasos para ingresar y trabajar**:

1. **Conectarse por SSH al nodo principal** (`broly`):
    
    ```bash
    ssh <usuario>@modgita.udea.edu.co -p 22666
    ```
    
2. **Verificar el estado de los nodos:**
    
    ```bash
    sinfo
    ```
    
3. **Ver la cola de trabajos:**
    
    ```bash
    squeue
    ```
    
4. **Ejecutar un comando simple en 10 nodos:**
    
    ```bash
    srun -N10 -p nano hostname
    ```
    
    `-N` : número de nodos
    
    `-n` : número de trabajos
    
    `-p` : nombre de la partición
    
5. **Lanzar 4 trabajos en un solo nodo:**
    
    ```bash
    srun -N1 -n4 -p nano hostname
    ```
    
6. **Enviar un script batch a la partición `nano`:**
    
    ```bash
    sbatch mi_trabajo.sh
    ```
    

---

# 2. Comandos útiles en SLURM

| Comando | Descripción |
| --- | --- |
| `sinfo` | Muestra el estado de las particiones y nodos. |
| `squeue` | Lista los trabajos en cola o en ejecución. |
| `scontrol show node=nodeX` | Muestra información detallada del nodo X |
| `srun` | Ejecuta un comando de forma distribuida. |
| `sbatch <archivo.sh>`  | Encola un trabajo batch. |
| `scancel <job_id>`  | Cancela un trabajo. |
| `salloc` | Asigna recursos de manera interactiva. |

---

# 3. Ejemplos de ejecución

### 3.1. Script SLURM básico (`test_job.sh`):

Crear archivo batch:

```bash
nano test_job.sh
```

Copiar el siguiente contenido:

```bash
#!/bin/bash
#SBATCH --job-name=test_job        # Nombre del trabajo
#SBATCH --nodes=2                  # Numero de nodos
#SBATCH --output=output_test.txt   # Archivo de salida
#SBATCH --ntasks=8                 # Número de tareas
#SBATCH --time=00:01:00            # Tiempo limite de ejecucion
#SBATCH --partition=nano           # Partición en la que correra

echo "Iniciando trabajo en SLURM"
srun hostname
sleep 10
echo "Trabajo completado"
```

El archivo debe tener permisos de ejecución:

```bash
chmod +x test_job.sh
```

Y ejecutar usando **`sbatch`** 

```bash
sbatch test_job.sh
```

---

### 3.2. Ejecución de programa MPI simple:

```bash
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

> ⚠️ Si la compilación se realiza desde el servidor (un sistema x86) los nodos no podrán ejecutar el programa, pues no tienen la misma arquitectura (aarch64). Una alternativa es realizar compilación cruzada. Otra, es acceder a uno de los nodos con el usuario y compilar desde allí.


Se compila lanzando el comando por `ssh` desde el servidor a uno de los nodos Jetson.

```bash
ssh node2 "mpicc /export/jmjarami/test/hello_mpi.c -o /export/jmjarami/test/hello_mpi"
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

# Especificar explicitamente la interfaz de red en uso
export OMPI_MCA_btl_tcp_if_include=eth0

# Ejecuta el programa con srun, que se integra con SLURM
srun --mpi=pmix ./hello_mpi
```

> ⚠️ La opción `--mpi=pmix` permite que SLURM y OpenMPI se comuniquen correctamente. Mientras que el parámetro `OMPI_MCA_btl_tcp_if_include=eth0` evita errores de comunicación TCP entre los procesos que usan MPI.


```bash
chmod +x mpi_job.sh
```

Se lanza el trabajo:

```bash
sbatch mpi_job.sh
```

# Notas y advertencias

> ⚠️ **Mensaje No protocol specified:**
> Al ejecutar programas con MPI puede aparecer el mensaje `No protocol specified`.
> Esto ocurre porque los procesos intentan acceder al entorno gráfico (X11) del nodo de control, incluso si el programa no tiene interfaz gráfica.
> Es un aviso inofensivo y no afecta la ejecución. Para ocultarlo agregar `2>/dev/null` al final del comando `srun`:
>  ```bash
>  srun --mpi=pmix ./hello_mpi 2>/dev/null
>  ```


---
