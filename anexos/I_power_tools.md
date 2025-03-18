# Herramientas de rendimiento: Jetson Clocks y Perfiles de energía

Para optimizar el rendimiento y la monitorización del cluster basado en Jetson Nano, es fundamental conocer herramientas como Jetson Clocks y los perfiles de energía, las cuales permiten gestionar el rendimiento y alternar los modos de consumo del sistema.

## **1. Jetson Clocks**

Jetson Clocks es un script que permite configurar los relojes del sistema Jetson Nano para operar a su máxima frecuencia, incrementando el rendimiento en cargas de trabajo intensivas.

### **Comandos principales**

- **Habilitar el máximo rendimiento:**
    
    ```bash
    sudo jetson_clocks
    ```
    
    Este comando configura el CPU, GPU y la memoria a sus frecuencias máximas.
    
- **Verificar el estado actual de los relojes:**
    
    ```bash
    sudo jetson_clocks --show
    ```
    
    Muestra la configuración actual de los relojes de la CPU, GPU y la memoria.
    
- **Deshabilitar Jetson Clocks (restaurar valores predeterminados):**
    
    ```bash
    sudo jetson_clocks --restore
    ```
    
    Restaura los valores de fábrica de las frecuencias.
    

Jetson Clocks es útil cuando se requiere máximo rendimiento para tareas de **cómputo intensivo**, sin embargo, mantener siempre las frecuencias máximas puede incrementar el consumo energético y la temperatura, por lo que se recomienda activarlo solo cuando sea necesario.

---

## 2. Cambio de perfil energético en Jetson Nano

La Jetson Nano permite cambiar entre diferentes perfiles energéticos para optimizar el consumo y rendimiento.

### Ver los perfiles de energía disponibles

Para mostrar el perfil de energía actualmente activo ejecute:

```
sudo nvpmodel -q
```

### Cambiar el perfil energético

Para cambiar a un perfil específico, use el siguiente comando:

```
sudo nvpmodel -m <ID_PERFIL>
```

Donde `<ID_PERFIL>` es el número del perfil energético que desea usar.

### Perfiles de energía comunes en Jetson Nano:

- **Modo 0:** Máximo rendimiento (10W, 4 núcleos activos)
    
    ```
    sudo nvpmodel -m 0
    ```
    
- **Modo 1:** Ahorro de energía (5W, 2 núcleos activos)
    
    ```
    sudo nvpmodel -m 1
    ```
