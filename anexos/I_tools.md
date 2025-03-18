# Herramientas: Jetson Clocks y Tegrastats

Para optimizar el rendimiento y la monitorización del cluster basado en **Jetson Nano**, es fundamental conocer herramientas como **Jetson Clocks** y **Tegrastats**, las cuales permiten gestionar el rendimiento y monitorear el uso de los recursos del sistema.

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

## **2. Tegrastats**

Tegrastats es una herramienta de monitorización que proporciona información en tiempo real sobre el uso de CPU, GPU, memoria RAM, temperaturas y consumo de energía en los dispositivos Jetson.

### **Comandos principales**

- **Ejecutar Tegrastats en tiempo real:**
    
    ```bash
    sudo tegrastats
    ```
    
    Muestra el estado del sistema cada pocos segundos, incluyendo:
    
    - Uso de CPU y GPU
    - Memoria RAM y memoria de intercambio
    - Temperatura
    - Consumo energético del sistema
- **Ejecutar Tegrastats con intervalo de actualización (en milisegundos):**
    
    ```bash
    sudo tegrastats --interval 500
    ```
    
    Muestra las métricas cada 0.5 segundos (500 ms).
    
- **Guardar la salida en un archivo de log:**
    
    ```bash
    sudo tegrastats > registro.log
    
    ```
    
    Registra la información en el archivo `registro.log`, útil para análisis posteriores.
    

El formato de la información entregada por tegrastats en cada muestreo es el siguiente:

```bash
RAM 1245/3964MB (lfb 147x4MB) SWAP 4/1982MB (cached 0MB) IRAM 0/252kB(lfb 252kB) CPU [0%@204,2%@204,0%@204,1%@204] EMC_FREQ 0%@204 GR3D_FREQ 0%@76 APE 25 PLL@25.5C CPU@29C PMIC@50C GPU@27.5C AO@34.5C thermal@28.25C POM_5V_IN 1003/919 POM_5V_GPU 0/0 POM_5V_CPU 166/145
```

A continuación, se describe el significado de los campos mas importantes:

| **Campo** | **Descripción** |
| --- | --- |
| **Memoria** |  |
| `RAM` | Uso actual y total de la memoria RAM en MB. |
| `SWAP` | Uso actual y total de la memoria de intercambio en MB. |
| `IRAM` | Uso de la memoria interna rápida del sistema. |
| **Procesador (CPU)** |  |
| `CPU` | Uso porcentual y frecuencia de cada núcleo del procesador. |
| `CPU_FREQ` | Frecuencia de los núcleos de la CPU en MHz. |
| **Uso de GPU y Memoria** |  |
| `GR3D_FREQ` | Uso (%) y frecuencia de la GPU (Graphics 3D). |
| `EMC_FREQ` | Uso (%) y frecuencia del controlador de memoria. |
| **Temperaturas** |  |
| `PLL@XXC` | Temperatura del circuito PLL (Phase-Locked Loop). |
| `CPU@XXC` | Temperatura de la CPU en grados Celsius. |
| `PMIC@XXC` | Temperatura del regulador de voltaje del sistema. |
| `GPU@XXC` | Temperatura de la GPU en grados Celsius. |
| `AO@XXC` | Temperatura del procesador Always-On. |
| `thermal@XXC` | Promedio de temperatura general del sistema. |
| **Consumo Energético** |  |
| `POM_5V_IN` | Consumo instantáneo y promedio de energía total del dispositivo en mW. |
| `POM_5V_GPU` | Consumo instantáneo y promedio de la GPU en mW. |
| `POM_5V_CPU` | Consumo instantáneo y promedio de la CPU en mW. |

Los archivos log puede ser parseados usando un script de Python para obtener la información deseada, generar archivos en formato CSV y graficar el comportamiento de las variables.

```python
#!/usr/bin/env python3
"""
Este script analiza un archivo de log de tegrastats, extrae los datos relevantes 
y los guarda en un CSV. Luego, grafica la temperatura de la CPU en función del tiempo.
"""

import re
import csv
import matplotlib.pyplot as plt
import argparse
import os

def parse_line(line):
    """
    Extrae los parámetros de una línea de tegrastats y devuelve un diccionario.
    """
    data = {}

    # RAM: "RAM 1245/3964MB"
    m = re.search(r"RAM\s+(\d+)/(\d+)MB", line)
    if m:
        data['RAM_used'] = int(m.group(1))
        data['RAM_total'] = int(m.group(2))

    # SWAP: "SWAP 4/1982MB"
    m = re.search(r"SWAP\s+(\d+)/(\d+)MB", line)
    if m:
        data['SWAP_used'] = int(m.group(1))
        data['SWAP_total'] = int(m.group(2))

    # CPU: "CPU [2%@102,0%@102,0%@102,0%@102]"
    m = re.search(r"CPU\s+\[([^\]]+)\]", line)
    if m:
        cpu_str = m.group(1)
        cpu_values = [s.split('@')[0].replace('%','') for s in cpu_str.split(',')]
        cpu_freq_values = [s.split('@')[1] for s in cpu_str.split(',')]  # Extraer la frecuencia
        data['CPU_percent'] = [int(x) for x in cpu_values]
        data['CPU_freq'] = [int(x) for x in cpu_freq_values]  # Guardar la frecuencia de cada núcleo

    # EMC_FREQ: "EMC_FREQ 0%@204"
    m = re.search(r"EMC_FREQ\s+(\d+)%@(\d+)", line)
    if m:
        data['EMC_usage'] = int(m.group(1))
        data['EMC_freq'] = int(m.group(2))

    # GR3D_FREQ: "GR3D_FREQ 0%@76"
    m = re.search(r"GR3D_FREQ\s+(\d+)%@(\d+)", line)
    if m:
        data['GR3D_usage'] = int(m.group(1))
        data['GR3D_freq'] = int(m.group(2))

    # Temperaturas (en °C)
    m = re.search(r"PLL@([\d.]+)C", line)
    if m:
        data['PLL_temp'] = float(m.group(1))
    m = re.search(r"CPU@([\d.]+)C", line)
    if m:
        data['CPU_temp'] = float(m.group(1))
    m = re.search(r"PMIC@([\d.]+)C", line)
    if m:
        data['PMIC_temp'] = float(m.group(1))
    m = re.search(r"GPU@([\d.]+)C", line)
    if m:
        data['GPU_temp'] = float(m.group(1))
    m = re.search(r"AO@([\d.]+)C", line)
    if m:
        data['AO_temp'] = float(m.group(1))
    m = re.search(r"thermal@([\d.]+)C", line)
    if m:
        data['thermal_temp'] = float(m.group(1))

    # Mediciones de potencia: POM_5V_IN, POM_5V_GPU, POM_5V_CPU
    m = re.search(r"POM_5V_IN\s+(\d+)/(\d+)", line)
    if m:
        data['POM_5V_IN_inst'] = int(m.group(1))
        data['POM_5V_IN_avg'] = int(m.group(2))
    m = re.search(r"POM_5V_GPU\s+(\d+)/(\d+)", line)
    if m:
        data['POM_5V_GPU_inst'] = int(m.group(1))
        data['POM_5V_GPU_avg'] = int(m.group(2))
    m = re.search(r"POM_5V_CPU\s+(\d+)/(\d+)", line)
    if m:
        data['POM_5V_CPU_inst'] = int(m.group(1))
        data['POM_5V_CPU_avg'] = int(m.group(2))

    return data

def main():

    log_filename = "tegrastats_omp2012_2025-02-15_11-49-50.log"

    # Generar el nombre del archivo CSV de salida, insertando '_parsed' antes de la extensión.
    base, ext = os.path.splitext(log_filename)
    csv_filename = f"{base}_parsed.csv"

    data_list = []
    with open(log_filename, 'r') as f:
        lines = f.readlines()

    # Suponiendo que se tomó una línea por segundo, asignamos un "tiempo" (o índice de muestra)
    for i, line in enumerate(lines):
        parsed = parse_line(line)
        parsed['time'] = i  # tiempo en segundos (o número de muestra)
        data_list.append(parsed)

    # Guardar la información en un CSV para posteriores análisis.
    if data_list:
        # Ordenamos las claves para que la cabecera sea consistente.
        keys = sorted(data_list[0].keys())
        with open(csv_filename, 'w', newline='') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=keys)
            writer.writeheader()
            for d in data_list:
                writer.writerow(d)
        print(f"Datos guardados en {csv_filename}")

    # Ejemplo de graficación: Temperatura de CPU en función del tiempo
    times = [d['time'] for d in data_list if 'CPU_temp' in d]
    cpu_temps = [d['CPU_temp'] for d in data_list if 'CPU_temp' in d]
    power_in = [d['POM_5V_IN_avg'] for d in data_list if 'POM_5V_IN_avg' in d]
    

    plt.figure(figsize=(8, 4))
    plt.plot(times, cpu_temps, marker='o', label='CPU Temp (°C)')
    plt.xlabel('Tiempo (s)')
    plt.ylabel('Temperatura (°C)')
    plt.title('Temperatura de CPU a lo largo del tiempo')
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.show()

if __name__ == '__main__':
    main()

```
