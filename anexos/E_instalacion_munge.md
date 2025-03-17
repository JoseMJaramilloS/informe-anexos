# Instalación Munge

MUNGE es un sistema de autenticación que protege la comunicación entre los nodos de un clúster. Permite que los nodos se reconozcan entre sí sin necesidad de configuraciones complejas como TLS o Kerberos. Una vez instalado, facilita la comunicación segura sin requerir autenticaciones constantes.

Realizar la instalación en todos los nodos.

## Dependencias

```bash
sudo apt install build-essential libssl-dev
```

## Configuracion UID y GID

```bash
export MUNGEUSER=1002
sudo groupadd -g $MUNGEUSER munge
sudo useradd -m -c "MUNGE Uid 'N' Gid Emporium" -d /var/lib/munge -u $MUNGEUSER -g munge -s /sbin/nologin munge
```

Si se presentan problemas con el numero UID usar otro numero que no esté en uso.

## Clonación e Instalación de MUNGE

```bash
git clone https://github.com/dun/munge.git
```

Configurar instalación

```
cd munge/
./bootstrap
./configure \
     --prefix=/usr \
     --sysconfdir=/etc \
     --localstatedir=/var \
     --runstatedir=/run
```

Compilar e instalar **MUNGE** en el sistema.

```
make
sudo make install
```

La carpeta `munge` se puede borrar después de la instalación.

## Generación y distribución de Munge key

1. En el **head node o nodo principal**, generar la clave:
    
    ```bash
    sudo create-munge-key
    ```
    
2. Luego, distribuir el archivo de clave **/etc/munge/munge.key** a todos los nodos de cómputo. Esto se puede hacer con **scp** o algún otro mecanismo de copia segura:
    
    ```bash
    scp /etc/munge/munge.key <user>@<compute-node>:/etc/munge
    ```
    
    Por problemas de permiso en el nodo destino se debe usar directorios intermedios, y luego pasarlo a la carpeta correspondiente
    
    ```bash
    # En head
    sudo scp /etc/munge/munge.key jetson@node1:/tmp/munge.key
    
    # En nodeX
    sudo mv /tmp/munge.key /etc/munge/
    ```
    
3. En cada nodo, asegurarse de que las propiedades y permisos del archivo de clave sean correctos:
    
    ```bash
    sudo chown munge:munge /etc/munge/munge.key
    sudo chmod 400 /etc/munge/munge.key
    ```
    
4. Asignar permisos antes de arrancar proceso
    
    ```bash
    sudo chown -R munge: /etc/munge/ /var/log/munge/ /var/lib/munge/  /run/munge/
    sudo chmod 0700 /etc/munge/ /var/log/munge/ /var/lib/munge/
    sudo chmod 0711 /run/munge/
    ```
    
    Si la carpeta `/run/munge` no existe, omitir error.
    
5. Iniciar proceso y verificar
    
    ```bash
    sudo systemctl enable munge
    sudo systemctl start munge
    # sudo systemctl status munge
    
    sudo munge -n | unmunge | grep STATUS
    # La salida debe ser Sucess (0)
    
    munged -V
    ```
    

## Comprobando servicio desde head hacia nodeX

```bash
ssh jetson@nodeX munge -n | unmunge
```
