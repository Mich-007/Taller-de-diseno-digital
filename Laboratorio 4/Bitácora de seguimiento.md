# Instituto Tecnológico de Costa Rica  
## Escuela de Ingeniería Electrónica  
### Laboratorio 4 — Microcontrolador RISC-V  
---

## **Integrantes**
- **Lesly Mariana Álvarez Álvarez**
- **Laura Elena Brenes Espinoza**
- **Ana Laura Cartín Ruiz**
- **Michelle Gutiérrez Araya**
- **Brayan Ariel Vargas Rojas**

---

## **Curso:**  
IE-0523 — Arquitectura de Computadores

## **Profesor:**  
Luis Carlos Rosales 

## **Fecha de Entrega:**  
05/12/2025

---

# 📘 **Bitácora de Desarrollo del Laboratorio 4**

---

## **Día 1 — Revisión del documento y comprensión del objetivo general**
**Fecha:** 7/11/2025  

**Actividades realizadas:**  
- Lectura completa del enunciado del laboratorio para comprender el alcance: implementación de un microcontrolador RV32I uniciclo en FPGA, capaz de ejecutar un programa bare-metal para leer temperatura del ADC integrado.  
- Revisión del mapa de memoria y periféricos mapeados en memoria (MMIO): LEDs, switches, display 7 segmentos, timer y módulo TMP.  
- Estudio preliminar de la estructura del procesador uniciclo basada en las referencias proporcionadas (Harris & Harris).  

**Hallazgos relevantes:**  
- Confirmamos que la arquitectura utilizada es **RISC-V RV32I**, por lo que el procesador debe soportar instrucciones básicas de load/store, operaciones AL, inmediatos y branching.  
- Identificamos la necesidad de compilar ensamblador a `.hex` para inicializar la ROM del IP Core en Vivado.  

**Conclusiones del día:**  
- Se estableció el flujo del laboratorio: investigación → escritura de respuestas → preparación del código ensamblador → integración con la FPGA.

---

## **Día 2 — Investigación técnica y desarrollo del cuestionario previo**
**Fecha:** 10/11/2025  

**Actividades realizadas:**  
- Investigación sobre la ISA RISC-V, en particular el subconjunto **RV32I**, enfocándose en registros, formatos de instrucción y flujo básico del procesador.  
- Desarrollo de las respuestas para:  
  - Diferencias entre C y ensamblador.  
  - Concepto de programación bare-metal.  
  - Endianness en memoria.  
  - Periféricos mapeados en memoria.  
  - Uso de IP-Cores para RAM, ROM y ADC XADC.  
- Integración de explicaciones técnicas en lenguaje formal y orientado al laboratorio.  

**Hallazgos / Problemas encontrados:**  
- Fue necesario estudiar el funcionamiento del **XADC** para comprender cómo el módulo TMP obtiene valores analógicos.  
- Se revisó documentación adicional de Digilent para confirmar la disponibilidad del sensor ADT7420 integrado en la Nexys4.  

**Conclusiones del día:**  
- El cuestionario previo quedó redactado con base técnica sólida y alineado con la arquitectura de la FPGA.

---

## **Día 3 — Análisis del diagrama del procesador RISC-V y unidad de control**
**Fecha:** 22/11/2025  y 25/11/2025

**Actividades realizadas:**  
- Revisión detallada de los diagramas del procesador uniciclo, en particular ALU, banco de registros, unidad de control y generador de inmediatos.  
- Análisis de señales clave: `Branch`, `MemWrite`, `ALUSrc`, `ImmSrc`, `RegWrite`, y cómo dependen del opcode.  
- Repaso de las tablas de decodificación, incluyendo la extensión de ALU para operaciones como `xor`, `sll`, `srl` y `sra`.  

**Hallazgos relevantes:**  
- Se determinó que para este laboratorio es necesario comprender cómo la señal `ALUControl` se deriva de `funct3`, `funct7` y `ALUOp`.  
- La descripción del comportamiento de cada instrucción debe correlacionarse con la implementación del pipeline uniciclo.  

**Notas de los día:**  
- Se avanzó en conectar teoría de arquitectura con las funciones reales que tendrá el ensamblador para controlar periféricos en memoria.

---

## **Día 4 — Mapa de memoria, periféricos y definición de funcionamiento**
**Fecha:** 1/12/2025  y 4/12/2025

**Actividades realizadas:**  
- Estudio del mapa de memoria del laboratorio, incluyendo posiciones para:  
  - Switches (0x2000)  
  - LEDs (0x2004)  
  - Display 7 segmentos (0x2008)  
  - Timer (0x2018 y 0x201C)  
  - Sensor TMP (0x2030 y 0x2034)  
- Comprensión de cómo leer y escribir en cada periférico con instrucciones `lw` y `sw`.  
- Análisis del mecanismo para seleccionar el periodo de muestreo en función de los switches (1 s, 2 s, 5 s, 10 s).  

**Hallazgos:**  
- La FPGA opera como un sistema abierto basado en un microprocesador, donde el acceso a periféricos depende totalmente del direccionamiento mapeado.  
- El código ensamblador debe iniciar conversiones del sensor TMP escribiendo un bit en el registro de control y luego esperar el `NEW_DATA_FLAG`.  

**Conclusiones del día:**  
- Quedó clara la estructura total del sistema y la interacción entre software (ensamblador) y hardware (microcontrolador uniciclo).
- Todo esta claro, pero estamos al borde de la locura con la FPGA y su funcionamiento.
- Alguien por favor SALVENOSSSSS 

---

