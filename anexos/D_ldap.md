# Configuración de cliente LDAP en las Jetson Nano

Esta sección documenta el procedimiento seguido para habilitar la autenticación de usuarios a través de LDAP en los nodos del clúster Jetson Nano. Cabe aclarar que **únicamente se realizó la configuración del lado del cliente**, ya que el servidor LDAP es administrado externamente por el equipo del servidor principal de la red del laboratorio.

### 1. Instalación de `sssd`

Se utilizó el paquete `sssd` para integrar los servicios de autenticación de usuario, `sudo` y nombre de usuario (NSS) con el directorio LDAP:

```bash
sudo apt install sssd -y
```

### 2. Configuración del nombre del servidor LDAP

Para permitir la resolución del nombre del servidor desde cada nodo, se añadió una entrada al archivo `/etc/hosts` apuntando al servidor LDAP:

```bash
192.168.100.1 servergita.udea.edu.co
```

### 3. Archivo de configuración `/etc/sssd/sssd.conf`

Se creó el archivo de configuración del cliente `sssd` con los parámetros entregados por el administrador del servicio LDAP:

```
[sssd]
config_file_version = 2
domains = udea.edu.co
services = nss, pam, sudo

[domain/udea.edu.co]
id_provider = ldap
auth_provider = ldap
ldap_uri = ldap://servergita.udea.edu.co
cache_credentials = True
ldap_search_base = dc=udea,dc=edu,dc=co
sudo_provider = ldap
ldap_sudo_search_base = ou=sudoers,dc=udea,dc=edu,dc=co
ldap_sudo_full_refresh_interval=300
```

Este archivo debe contar con los permisos correctos para proteger la configuración sensible:

```bash
sudo chown root:root /etc/sssd/sssd.conf
sudo chmod 600 /etc/sssd/sssd.conf
```

### 4. Instalación del certificado

Se copió el certificado proporcionado por el administrador del servidor (disponible [acá](https://drive.google.com/file/d/1_4zF0W5NmCqJH4WwK250wzMQ500RxTtW/view?usp=drive_link)) a la ruta correspondiente en cada nodo:

```bash
sudo nano /usr/local/share/ca-certificates/udea.crt
```

Luego se instaló con:

```bash
sudo update-ca-certificates
```

### 5. Instalación de `libsss-sudo`

Este paquete permite la gestión centralizada de permisos `sudo` desde el servidor LDAP:

```bash
sudo apt install libsss-sudo
```

Finalmente, se reinició el servicio `sssd` para aplicar todos los cambios:

```bash
sudo systemctl restart sssd.service
```
