# Configuración de NAS usando NFS en las Jetson Nano

Este anexo describe el procedimiento seguido para montar un sistema de almacenamiento en red (NAS) ya configurado, utilizando el protocolo **NFS (Network File System)**. Esta configuración permite que los usuarios accedan a sus directorios personales desde cualquier nodo del clúster.

> ⚠️ Nota: Este procedimiento se limita a la configuración del cliente. La configuración del servidor NAS no fue realizada ni documentada por el autor, ya que fue administrada por el equipo de red del laboratorio.
> 

### 1. Creación del punto de montaje

Primero, se crea el directorio local donde se montará el recurso compartido:

```bash
sudo mkdir /export
```

### 2. Edición del archivo `/etc/fstab`

Se añade una entrada en el archivo `/etc/fstab` para montar automáticamente el recurso compartido en cada inicio del sistema:

```bash
sudo nano /etc/fstab
```

Agregar la siguiente línea:

```
serverhome:/export      /export     nfs     defaults     0   0
```

Donde `serverhome` es el nombre del servidor que exporta el recurso mediante NFS. Este nombre debe estar resoluble mediante `/etc/hosts` o un servicio DNS, y la dirección IP correspondiente debe estar previamente autorizada en el servidor para aceptar conexiones desde el nodo.

### 3. Montaje del recurso compartido

Se monta el recurso con:

```bash
sudo mount -a
```

### 4. Funcionalidad del sistema compartido

El directorio `/export` contiene los datos que componen los directorios personales de los usuarios (`/home`) a través de enlaces simbólicos o configuraciones adicionales (realizadas en el servidor). Esta estrategia permite:

- Que un mismo usuario tenga acceso a su directorio personal desde cualquier nodo del clúster.
- Una gestión centralizada de usuarios y archivos.
- Facilitar la administración de respaldos y mantenimiento del sistema.
