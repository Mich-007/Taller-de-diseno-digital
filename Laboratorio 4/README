#Laboratorio 4: Microcontrolado
Profesor: Luis C. Rosales
Estudiantes: Lesly Mariana Alvarez Alvarez, Laura Elena Brenes Espinoza, Ana Laura Cartín Ruiz, Michelle Gutierrez Araya, Brayan Ariel Vargas Rojas

 El laboratorio 4 constituye el proyecto final del curso y por ello es una actividad integradora que requiere de trabajo en equipo para diseñar e implementar un sistema digital complejo.
 El proyecto tiene como parte principal el diseño de un microcontrolador, donde la implementación del mismo debe basarse en la arquitectura del set de instrucciones rv32i. Un programa, 
 que se ejecutará en dicho microcontrolador, deberá orquestar diferentes módulos que controlan entradas de un ADC, botones y switches, salidas hacia LEDs y display de 7 segmentos.
 La complejidad del sistema a implementar solo es manejable con disciplina de implementación: cada módulo debe tener las pruebas (testbenches) necesarias para asegurar su 
 funcionamiento correcto a nivel de pre-síntesis, post-síntesis y post-implementación en FPGA. Esto es relevante, en particular, para el microcontrolador a implementar pues de otra 
 forma no se podrá asegurar que el programa implementado esté ejecutándose de manera correcta.


##Objetivos
 1. Utilizar las herramientas del diseño digital para construir un sistema basado en un microcontrolador, lo que incluye un componente de software 
(programa que corre el microcontrolador) que deberá ser desarrollado en lenguaje ensamblador.
 2. Diseñar la implementación de hardware en forma modular, separando tareas de control del procesamiento de los datos.
 3. Diseñar e interconectar periféricos mapeados en memoria en un sistema de procesamiento básico.
 4. Comprender cómo utilizar IP-Cores como parte de un diseño digital complejo.
 5. Profundizar sobre el enlace e interacción entre software y hardware digital.
 6. Plantear una estrategia de trabajo en equipo adecuada para diseñar un sistema complejo e implementarlo con restricciones de tiempo existentes.


##Investigación previa

1. Investigue sobre la arquitectura RISC-V. Preste especial atención a las instrucciones que forman parte del conjunto básico de instrucciones para números enteros de 32 bits, rv32i.
RISC-V es una arquitectura de conjunto de instrucciones (ISA) abierta, modular y load/store, diseñada para ofrecer simplicidad en la implementación de hardware mientras mantiene la 
completitud necesaria para el targeting de compiladores. El subconjunto RV32I es la base de 32 bits y define el núcleo mínimo de la máquina.

El procesador, en su implementación RV32I, dispone de:
 - 32 registros enteros (x0–x31) de 32 bits: “x0” está cableado a cero y el resto son de propósito general (GPRs). Esta cantidad facilita el diseño del datapath y la unidad de control al 
  requerir un campo de registro de solo 5 bits en las instrucciones.
 - Un Contador de Programa (PC) de 32 bits.
 - Instrucciones de longitud fija de 32 bits: Utilizan formatos bien definidos (R, I, S, B, U, J) que, gracias a su ortogonalidad, simplifican enormemente la lógica de decodificación 
  y el diseño del hardware del pipeline.

El subconjunto utilizado en este proyecto (cargas/almacenamientos, operaciones A-L, inmediatos, comparaciones, y control de flujo) es suficiente para implementar el código bare-metal 
y gestionar la lógica de aplicación, la gestión de memoria y la interacción con periféricos mediante el paradigma load/store.


2. Investigue sobre las diferencias entre un lenguaje de programación como C y ensamblador. Explique que es bare-metal programming. 
La distinción entre C y ensamblador radica en el nivel de abstracción y el control directo sobre el hardware:

 Lenguaje C
   - Nivel: Alto ya que es estructurado y portable.
   - Control: Abstrae la gestión de registros y la pila.
   - Compilador: Esta genera la secuencia óptima de instrucciones máquina (por ejemplo, decide si usar addi o lw/add/sw).
   - Uso Tipico: La lógica de aplicación principal, funciones complejas.

 Lenguaje Ensamblador
   - Nivel: Bajo ya que es simbólico, porque es casi 1:1 con instrucciones binarias.
   - Control: Tiene un control explícito sobre cada registro, en la dirección de memoria y timing.
   - Compilador: El programador decide la secuencia de instrucciones.
   - Uso Tipico: Sus rutinas de arranque (Reset Vector), handlers de interrupción, secciones ultra-optimizadas o acceso directo a hardware específico.

Programación Bare-metal se refiere a la ejecución de código directamente sobre el hardware (el "metal desnudo"), sin la mediación de un sistema operativo (OS). 
En este contexto, nuestro programa es el SO: debe realizar la inicialización completa del sistema (configurar el reloj, la memoria, la interfaz de interrupciones, y los periféricos). 
Para el microcontrolador RISC-V del laboratorio, el código en la ROM se ejecuta inmediatamente después del reset, controlando directamente el flujo del programa y el mapa de memoria 
para atender la aplicación de monitoreo de temperatura.


3. Investigue sobre cómo se almacenan los datos en una memoria. ¿Qué es little-endian y big-endian? 
El endianness define el orden en que los bytes de una palabra multi-byte (ej. 32 bits) se almacenan en la memoria. RISC-V, por defecto, implementa el orden little-endian, 
lo cual es una característica obligatoria de la ISA unprivileged (RV32I).

  - Little-endian (LSB primero): El byte menos significativo (LSB) de la palabra se almacena en la dirección más baja de la memoria, seguido por los bytes más significativos en 
    direcciones crecientes.
  - Ejemplo (0x12345678 en dirección A): A almacena 78, A+1 almacena 56, A+2 almacena 34, A+3 almacena 12.

Esta convención es crucial para nuestro proyecto, ya que tanto el procesador como los periféricos mapeados en memoria (como el registro de datos del ADC) deben adherirse a esta misma 
convención para que las instrucciones lw y sw puedan extraer o depositar correctamente las palabras de 32 bits sin errores de inversión de bytes.


4. Explique el concepto de periféricos mapeados en memoria. ¿Cuál es el método utilizado para leer o escribir datos/instrucciones a un periférico? 
Los Periféricos Mapeados en Memoria (MMIO) implementan un espacio de direcciones unificado, donde los registros de control, estado y datos de los dispositivos de E/S (como LEDs, 
temporizador, o el sensor TMP) ocupan direcciones específicas dentro del mismo espacio de direcciones utilizado por la RAM y la ROM.
El acceso se realiza mediante las mismas instrucciones de carga y almacenamiento (lw, sw, etc.) usadas para acceder a la memoria de datos.

- Implementación en Hardware: Una pieza clave del diseño es la Lógica de Interconexión/Arbitraje. Este módulo decodifica la dirección colocada en el bus de direcciones (DataAddress_o).
   - Si la dirección cae en el rango de RAM (ej. 0x1000–0x1FFF), la operación se enruta al módulo RAM.
   - Si la dirección coincide con una dirección de periférico (ej. 0x2034 para el registro de temperatura), la operación se enruta al módulo periférico correspondiente.

Ventaja principal: Elimina la necesidad de instrucciones de E/S dedicadas (como en arquitecturas port-mapped I/O), simplificando el diseño de la Unidad de Control del RISC-V y 
la generación de código por parte del compilador o programador de ensamblador.

5. Investigue sobre el uso de los IP-Cores en Vivado para memorias RAM y ROM, así como el ADC para entradas analógicas.
Un IP-Core (Intellectual Property Core) en el entorno Vivado es un bloque de hardware pre-verificado que encapsula una funcionalidad compleja, facilitando su integración en el diseño 
HDL sin necesidad de escribir el código subyacente. Su uso es esencial para la eficiencia y la correcta implementación en FPGA:

    a) Memorias RAM y ROM (Block Memory Generator)

Este IP permite instanciar memorias utilizando los recursos dedicados de Block RAM (BRAM) de la FPGA (que son mucho más rápidos y eficientes que la lógica implementada en look-up tables).
    - ROM de Programa: Se configura como memoria de solo lectura (ROM) y se inicializa con un archivo .mem (contiene el programa RISC-V compilado). Mapeada típicamente desde 0x0000.
    - RAM de Datos: Se configura como memoria de lectura/escritura de uno o dos puertos para almacenar datos temporales de la aplicación y la pila. Mapeada típicamente desde 0x1000.

    b) ADC para Entradas Analógicas (XADC)

El XADC es un IP que proporciona acceso a un convertidor analógico-digital (ADC) interno y dedicado que poseen muchas FPGAs de AMD/Xilinx.
   - En el laboratorio, el módulo del sensor de temperatura (TMP) debe utilizar el XADC para digitalizar la señal analógica del sensor externo (ej. TMP36).
   - El XADC gestiona la conversión y coloca el resultado digital en un registro. Desde el punto de vista del microcontrolador, la lectura de temperatura se reduce a una única 
     instrucción lw dirigida a la dirección mapeada en memoria (ej. 0x2034) asociada a ese registro. Esto abstrae la complejidad del muestreo y conversión, simplificando el código 
     bare-metal.

