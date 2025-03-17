# Imagen preconfigurada para la Jetson Nano

Para este proyecto, se utilizó una imagen preconfigurada basada en **Ubuntu 20.04**, disponible en el repositorio de **Q-engineering**:

**Repositorio de la imagen:**

🔗 [GitHub - Qengineering/Jetson-Nano-Ubuntu-20-image](https://github.com/Qengineering/Jetson-Nano-Ubuntu-20-image)

**Guía de instalación oficial:**

🔗 [Install Ubuntu 20.04 on Jetson Nano - Q-engineering](https://qengineering.eu/install-ubuntu-20.04-on-jetson-nano.html)

### **Software preinstalado en la imagen**

La imagen utilizada incluye las siguientes herramientas instaladas:

- **Ubuntu 20.04**
- **OpenCV 4.8.0** (procesamiento de imágenes)
- **PyTorch 1.13.0 y TorchVision 0.14.0** (aprendizaje profundo)
- **TensorRT 8.0.1.6** (optimización de modelos para GPU)
- **TeamViewer 15.24.5 aarch64** (gestión remota)
- **Jtop 4.2.1** (monitoreo de recursos de hardware)

# **Flasheo de la Imagen en una MicroSD**

Para instalar el sistema operativo en cada **Jetson Nano**, la imagen de disco se grabó en una **tarjeta microSD de al menos 128GB** utilizando **Raspberry Pi Imager**.

### **Pasos básicos:**

1. **Descargar** la imagen desde el repositorio.
2. **Instalar** Raspberry Pi Imager desde [raspberrypi.com/software](https://www.raspberrypi.com/software/).
3. **Seleccionar** la opción *"Use custom"* y cargar la imagen descargada.
4. **Elegir** la tarjeta microSD como destino y escribir la imagen.
5. **Expulsar** la microSD e insertarla en la Jetson Nano.

El sistema viene preconfigurado con el siguiente acceso:

- **Usuario:** `jetson`
- **Contraseña:** `jetson`

La única configuración adicional necesaria es la **expansión manual de la partición del sistema** si se usa una microSD de mayor capacidad, ya que la imagen está limitada inicialmente a **32GB**. Esto se puede realizar con herramientas como `gparted` o `resize2fs` después del primer arranque.

# Modo headless

La Jetson Nano se puede utilizar en **modo headless**, es decir, sin necesidad de conectar periféricos como teclado, mouse o pantalla. Para ello, es necesario alimentar la tarjeta mediante el **puerto plug jack (J25)** o los **pines de alimentación en J41** y conectarla a un PC a través de un **cable microUSB a USB**

Por defecto, la Jetson Nano asigna la dirección **192.168.55.1** para la conexión mediante USB. Esto permite acceder al sistema vía **SSH**, utilizando el siguiente comando en una terminal:

```bash
ssh jetson@192.168.55.1
```

## Solución a problemas en Windows

En algunos casos, Windows puede no detectar correctamente la conexión debido a la configuración de adaptadores de red. Para solucionar esto:  

1. Ir a Panel de Control > Redes e Internet > Centro de redes y recursos compartidos. 
2. En panel izquierdo, seleccionar  Cambiar configuración del adaptador.
3. Buscar el adaptador con la descripción: Remote NDIS Compatible Device. 
4. Asignar una dirección IP en la misma subred que la Jetson Nano, por ejemplo:
    - **IP:** `192.168.55.X` (donde `X` es cualquier número distinto de 1)
    - **Máscara de subred:** `255.255.255.0`
5. Guardar los cambios e intentar reconectar.

Otro error común ocurre cuando se conectan varias Jetson Nano al mismo PC usando la dirección **192.168.55.1**. Esto genera conflictos en la autenticación, ya que el sistema asocia la dirección IP con una clave única para prevenir suplantaciones. Para solucionarlo, es necesario eliminar las entradas de `192.168.55.1` en el archivo `known_hosts`, ubicado en la carpeta **`.ssh`** dentro del directorio del usuario.

# Ajustando espacio de particion en Linux

Dado que el acceso a las tarjetas se realiza a través de la terminal, se utiliza la herramienta `parted` para expandir la partición del sistema y aprovechar el total de la capacidad de la microSD.

Listar los discos y sus particiones:

```bash
sudo parted -l
```

Elegir el disco a modificar. En este caso:

```bash
sudo parted /dev/mmcblk0
```

Una vez abierta la sesión interactiva de `parted`. Listamos las particiones que componen el disco seleccionado

```bash
print 
```

Para redimensionar una partición se usa la sintaxis `resizepart <NUMERO_PARTICION> <NUEVO_TAMAÑO>`. La partición objetivo será aquella que tenga formato `ext4`, en este caso la partición 1. El tamaño puede ser el que se considere adecuado, lo recomendado sería disponer de todo el tamaño de la tarjeta SD. Para conocer el tamaño total real de la SD se puede usar el comando `lsblk` .

```bash
resizepart 1 116GB
```

Se pedirá confirmación, escribir nuevamente el tamaño (`116GB`) y presionar **Enter**.
Salir de `parted` con:

```bash
quit
```

Finalmente, para que el sistema reconozca el nuevo espacio, ejecutar lo siguiente (únicamente compatible para particiones `ext4`):

```bash
sudo resize2fs /dev/mmcblk0p1
```

Para confirmar que los cambios fueron aplicados correctamente:

```bash
df -h
```
