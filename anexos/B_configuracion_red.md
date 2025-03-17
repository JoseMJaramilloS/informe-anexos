## **1. Configuración de IP Estática**

Para asignar una dirección IP estática a cada nodo, editar el archivo de configuración de **Netplan**:

```bash
sudo nano /etc/netplan/01-netcfg.yaml
```

Reemplazar `X` con el número correspondiente al nodo:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses: [192.168.100.X/24]
      gateway4: 192.168.100.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4, 192.168.100.1, 200.24.19.250, 200.24.19.252]
```

Aplicar los cambios:

```bash
sudo netplan apply
```

Si aparece un error relacionado con `systemd-networkd.service`, habilitarlo y reiniciarlo:

```bash
sudo systemctl enable systemd-networkd
sudo systemctl start systemd-networkd
```

Luego volver a aplicar los cambios de `netplan` .

---

## **2. Configuración de Hostnames**

Cada nodo debe tener un nombre de host único para facilitar la administración y comunicación en el clúster. Para cambiarlo de forma permanente, editar los siguientes archivos:

1. **Editar el archivo `/etc/hostname`**
    
    ```bash
    sudo nano /etc/hostname
    ```
    
    Ingresar el nuevo nombre de host y guardar.
    
2. **Configurar el archivo `/etc/hosts` en todos los nodos**
    
    ```bash
    sudo nano /etc/hosts
    ```
    
    Incluir las siguientes asignaciones de hostnames en cada nodo:
    
    ```yaml
    127.0.0.1       localhost
    127.0.1.1       nodeX # reemplazar X por el nodo correspondiente
    
    # IPv6 configuration
    ::1     ip6-localhost ip6-loopback
    fe00::0 ip6-localnet
    ff00::0 ip6-mcastprefix
    ff02::1 ip6-allnodes
    ff02::2 ip6-allrouters
    
    # Servidor principal y NAS
    192.168.100.1   servergita.udea.edu.co  broly
    192.168.100.2   serverhome
    
    # Nodos del clúster
    192.168.100.30  SBC-JNANO-30  node1
    192.168.100.31  SBC-JNANO-31  node2
    192.168.100.32  SBC-JNANO-32  node3
    192.168.100.33  SBC-JNANO-33  node4
    192.168.100.34  SBC-JNANO-34  node5
    192.168.100.35  SBC-JNANO-35  node6
    192.168.100.36  SBC-JNANO-36  node7
    192.168.100.37  SBC-JNANO-37  node8
    192.168.100.38  SBC-JNANO-38  node9
    192.168.100.39  SBC-JNANO-39  node10
    
    ```
    

Para que los cambios surtan efecto, reiniciar el nodo:

```bash
sudo reboot
```

---

## **3. Configuración de SSH sin Contraseña**

Para permitir la comunicación SSH sin necesidad de autenticación manual:

1. **Generar las claves SSH en el nodo principal**
    
    ```bash
    ssh-keygen
    ```
    
2. **Copiar la clave pública a los nodos de cómputo**
    
    ```bash
    ssh-copy-id jetson@node1
    ssh-copy-id jetson@node2
    ssh-copy-id jetson@nodeX
    ```
    

Ejecutar este comando para cada nodo del clúster.

---

## **4. Configuración del Servidor NTP de la UdeA**

Debido a restricciones de la universidad, el acceso a servidores NTP públicos está bloqueado. Para sincronizar los nodos, se configura el **servidor NTP institucional** de la UdeA.

1. **Editar la configuración de TimesyncD**
    
    ```bash
    sudo nano /etc/systemd/timesyncd.conf
    ```
    
    Descomentar la línea `NTP=` y cambiarla por:
    
    ```yaml
    NTP=ntp.udea.red
    ```
    
2. **Reiniciar el servicio de sincronización**
    
    ```bash
    systemctl restart systemd-timesyncd.service
    ```
    
3. **Verificar la sincronización**
    
    ```bash
    timedatectl status
    ```
    
    **Salida esperada:**
    
    ```yaml
                   Local time: Mon 2025-03-10 20:58:19 -05
               Universal time: Tue 2025-03-11 01:58:19 UTC
                     RTC time: Tue 2025-03-11 01:58:20
                    Time zone: America/Bogota (-05, -0500)
    System clock synchronized: yes
                  NTP service: active
              RTC in local TZ: no
    ```
    

Si es necesario cambiar la **zona horaria**, ejecutar:

```bash
sudo timedatectl set-timezone America/Bogota
```
