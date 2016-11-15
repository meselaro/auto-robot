/*
 * Acelerometro_4.asm
 *
 *  Created: 11/10/2016 09:17:52 p.m.
 *   Author: Lucas Larroque
 */ 
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
#define F_CPU 8000000UL  //frecuencia de trabajo del ATMEGA88PA
#include "m88PAdef.inc"

.cseg

.ORG	0x0000

INICIO:
RJMP	Reset
RJMP	INT_ACCEL

;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
;Definimos los .def y .equ
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
.def	temp0			= r16		; registro auxiliar 1, colocar en 0 luego de usar
.def	temp1			= r17		; registro auxiliar 2, colocar en 0 luego de usar

.def	msk				= r18		; registro de mascara
.def	data			= r19		; registro de datos
.def	reg_address		= r20		; registro de dirección del registro a leer/escribir

.def	slaw_address	= r21		; registro de dirección del esclavo más bits de escritura
.def	slar_address	= r22		; registro de dirección del esclavo más bits de lectura

.def	a_xh			= r0		; registro de aceleración en x, parte alta
.def	a_xl			= r1		; registro de aceleración en x, parte baja
.def	a_yh			= r2		; registro de aceleración en y, parte alta
.def	a_yl			= r3		; registro de aceleración en y, parte baja
.def	a_zh			= r4		; registro de aceleración en z, parte alta
.def	a_zl			= r5		; registro de aceleración en z, parte baja

　
.equ	SLA_W = 0b11010000	; write Bit. Se asume como direccion del acelerometro b68 (AD0=0)
.equ	SLA_R = 0b11010001	; read Bit. Se asume como direccion del acelerometro b68 (AD0=0)

.equ	START = 0x08		; mascara de START
.equ	SLA_ACK_W = 0x18	; mascara de SLA+W se ha transmitido y ACK fue recibido
.equ	SLA_ACK_R = 0x40	; mascara de SLA+R se ha transmitido y ACK fue recibido
.equ	DATA_ACK = 0x28		; mascara de DATA se ha transmitido y ACK fue recibido
.equ	REPEAT_START=0x10	; mascara de START repetido
.equ	DATA_NACK = 0x58	; mascara de DATA se ha recivido y NACK fue enviado
.equ	DATA_ACK_R = 0x50	; mascara de DATA se ha recibido y ACK fue recibido

.equ	WHO_AM_I = 0x75		; dirección del registro de identidad del dispositivo
.equ	ACCEL_XOUTH = 0x3B	; dirección del registro de medición de la parte alta del eje X
.equ	ACCEL_XOUTL = 0x3C	; dirección del registro de medición de la parte baja del eje X
.equ	ACCEL_YOUTH = 0x3D	; dirección del registro de medición de la parte alta del eje Y
.equ	ACCEL_YOUTL = 0x3E	; dirección del registro de medición de la parte baja del eje Y
.equ	ACCEL_ZOUTH = 0x3F	; dirección del registro de medición de la parte alta del eje Z
.equ	ACCEL_ZOUTL = 0x40	; dirección del registro de medición de la parte baja del eje Z
.equ	TEMP_OUTL = 0x42 
.equ	PWR_MGMT_1 = 0x6B	; dirección del registro de configuracion del modo de encencido (power) y la fuente del clock;
.equ	PWR_MGMT_2 = 0X6C
.equ	INT_ENABLE = 0x38	;registro de habilitación de interrupciones		

;——————————————————————————————————————————————————————————————RESET—————————————————————————————————————————————————————————
Reset:
;————————————————————————————————————————————————————Inicializamos Stackpointer——————————————————————————————————————————————
LDI		temp0,low(RAMEND)		;Colocamos stackptr en ram end
OUT		SPL,temp0
LDI		temp0, high(RAMEND)
OUT		SPH, temp0
LDI		temp0,0

;————————————————————————————————————————————————————Configuramos los puertos C y D como salida——————————————————————————————————————————

LED_PORTC:
LDI		temp0,0xFF
OUT		DDRC,temp0

LED_PORTD:
OUT		DDRD,temp0

LDI		temp0,0

;————————————————————————————————————————————————————Inicio del bus I2C——————————————————————————————————————————————————————
;————————————————————————————————————————————————————Seteamos la velocidad de clock——————————————————————————————————————————
;SCL=400Khz=18.432MHz/(16+2*TWBR*4^TWSR)
LDI    temp0,0x00
STS    TWSR,temp0

LDI    temp0,0xC5	; Seteamos una velocidad de 92kHz aprox
STS    TWBR,temp0
LDI    temp0,0

;—————————————————————————————————————————————————————————————————PROGRAMA———————————————————————————————————————————————————
;Como este programa pretende comunicar el micro (master) con el acelerometro MPU-6050 (esclavo), la dirección del mismo se 
;setean una sola vez

LDI		slaw_address,SLA_W
LDI		slar_address,SLA_R

　
　
; En el registro de administracion de consumo de potencia deshabilitamos el modo SLEEP y el sensor de temperatura, y habilitamos
; el modo CYCLE, el cual permite que el dispositivo alterne entre modo SLEEP y encendido con una determinada frecuencia seteada
; en el registro PWR_MGMT_2. 
LDI		reg_address,PWR_MGMT_1
LDI		data,0x28
RCALL	I2C_WRITE_DATA

; Seteamos una frecuencia de CYCLE de 5 Hz.
LDI		reg_address,PWR_MGMT_2
LDI		data,0x47
RCALL	I2C_WRITE_DATA

　
; Configuramos la sensibilidad en +/- 2g. 
LDI		reg_address,0x1C
LDI		data,0x00
RCALL	I2C_WRITE_DATA

;
;LDI		reg_address,0x1F
;LDI		data,0xFF
;RCALL	I2C_WRITE_DATA

　
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
INT_ACCEL:

LDI		reg_address,ACCEL_XOUTH
LDI		data,0
RCALL	I2C_READ_DATA
MOV		a_xh,data

LDI		reg_address,ACCEL_XOUTL
LDI		data,0
RCALL	I2C_READ_DATA
MOV		a_xl,data

LDI		reg_address,ACCEL_YOUTH
LDI		data,0
RCALL	I2C_READ_DATA
MOV		a_yh,data

LDI		reg_address,ACCEL_YOUTL
LDI		data,0
RCALL	I2C_READ_DATA
MOV		a_yl,data

LDI		reg_address,ACCEL_ZOUTH
LDI		data,0
RCALL	I2C_READ_DATA
MOV		a_zh,data

LDI		reg_address,ACCEL_ZOUTL
LDI		data,0
RCALL	I2C_READ_DATA
MOV		a_zl,data

　
out portd,a_xh

　
　
LDI R27,255
DELAY:
		DEC R27
		BRNE DELAY
LDI R27,255
DELAY_1:
		DEC R27
		BRNE DELAY_1

rjmp INICIO

　
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
PROGRAM_LOOP:
;SLEEP
;RJMP	PROGRAM_LOOP

　
　
;——————————————————————————————————————Secuencia para escribir un registro del acelerometro——————————————————————————————————
;Pedimos el registro a escribir del esclavo y el dato.
I2C_WRITE_DATA:

;Enviamos la condiciòn de START y verificamos el registro de estado del bus.
RCALL	I2C_START
;LDI		msk,START
;RCALL	I2C_CHECK

　
;Cargamos en data la dirección del slave mas el bit de escritura y verificamos que ACK se haya recibido.
MOV		temp1,slaw_address
RCALL	I2C_LOAD
LDI		msk,SLA_ACK_W
RCALL	I2C_CHECK

　
;Cargamos en data la direccion del registro a escribir y verificamos que ACK se haya recibido.
MOV		temp1,reg_address		
RCALL	I2C_LOAD
LDI		msk,DATA_ACK
RCALL	I2C_CHECK

;Cargamos en TWDR el contenido del registro data y verificamos que ACK se haya recibido.
MOV		temp1,data
RCALL	I2C_LOAD
LDI		msk,DATA_ACK
RCALL	I2C_CHECK

　
　
;Enviamos la condición de STOP
RCALL	I2C_STOP

RET

;——————————————————————————————————————Secuencia para leer un registro del acelerometro——————————————————————————————————
;Pedimos el registro a leer del esclavo y se entrega el dato.
I2C_READ_DATA:

;Enviamos la condiciòn de START y verificamos el registro de estado del bus.
RCALL	I2C_START
LDI		msk,REPEAT_START
RCALL	I2C_CHECK

;Cargamos en data la dirección del slave mas el bit de escritura y verificamos que ACK se haya recibido.
MOV		temp1,slaw_address
RCALL	I2C_LOAD
LDI		msk,SLA_ACK_W
RCALL	I2C_CHECK

;Cargamos en data la direccion del registro a leer y verificamos que ACK se haya recibido.
MOV		temp1,reg_address
RCALL	I2C_LOAD
LDI		msk,DATA_ACK
RCALL	I2C_CHECK

;Renviamos la condiciòn de START y verificamos el registro de estado del bus.
RCALL	I2C_START
LDI		msk,REPEAT_START
RCALL	I2C_CHECK

;Cargamos en data la dirección del slave mas el bit de lectura y verificamos que ACK se haya recibido.
MOV		temp1,slar_address
RCALL	I2C_LOAD
LDI		msk,SLA_ACK_R
RCALL	I2C_CHECK

;Recibimos el dato y lo copiamos al registro data. Luego se verifica que el dato se haya recibido y un NACK se haya enviado.
RCALL	I2C_READ
LDI		msk,DATA_NACK
RCALL	I2C_CHECK

　
;Enviamos la condición de STOP
RCALL	I2C_STOP

RET
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

;——————————————————————————————————————————————————————————————————ERROR—————————————————————————————————————————————————————
ERROR:
RCALL	POWER_LED_PORTC
RJMP	ERROR
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————I2C_START———————————————————————————————————————————————————
;Genera la condicón de START
I2C_START:
LDI		temp0, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN)
STS		TWCR,temp0

;Espera a que la codición de START sea enviada. TWINT en uno indica que la operación de TWI ha finalizado.
WAIT_START:
LDS		temp0,TWCR
SBRS	temp0,TWINT
RJMP	WAIT_START
LDI		temp0,0
RET
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————I2C_CHECK———————————————————————————————————————————————————
;Verificamos el estado de TWSR (registro de estado del bus), TWSR se compara con la mascara (msk).
I2C_CHECK:
LDS		temp0,TWSR
ANDI	temp0,0xF8
CP		temp0,msk
BRNE	ERROR
LDI		temp0,0
RET
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————I2C_LOAD————————————————————————————————————————————————————
;Cargamos el registro data en TWDR
I2C_LOAD:
STS		TWDR,temp1
LDI     temp0,(1<<TWINT)|(1<<TWEN)
STS     TWCR,temp0

;Espera a que el dato sea enviado. TWINT en uno indica que la peración de TWI ha finalizado.
WAIT_LOAD:
LDS		temp0,TWCR
SBRS	temp0,TWINT
RJMP	WAIT_LOAD
LDI		temp0,0
LDI		temp1,0
RET
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————I2C_READ————————————————————————————————————————————————————
I2C_READ:
LDI		temp0, (1<<TWINT)|(1<<TWEN)
STS		TWCR,temp0

;Espera a que la codición de START sea enviada. TWINT en uno indica que la operación de TWI ha finalizado.
WAIT_READ:
LDS		temp0,TWCR
SBRS	temp0,TWINT
RJMP	WAIT_READ
LDS		data,TWDR
LDI		temp0,0
RET
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————I2C_STOP————————————————————————————————————————————————————
;Generamos la condición de STOP
I2C_STOP:
LDI		temp0,(1<<TWINT)|(1<<TWEN)|(1<<TWSTO)
STS		TWCR,temp0
LDI		temp0,0
RET
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

　
;—————————————————————————————————————————————————————————————POWER_LED_PORTC————————————————————————————————————————————————
POWER_LED_PORTC:
LDI		temp0,0x08; En la placa de desarrollo se deberia encender solo un LED rojo: el que se encuentra al lado de un LED verde.
OUT		PORTC,temp0
LDI		temp0,0
RET
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

;—————————————————————————————————————————————————————————————POWER_LED_PORTD————————————————————————————————————————————————
POWER_LED_PORTD:
LDI		temp0,0x00
OUT		PORTD,temp0
LDI		temp0,0
RET
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
