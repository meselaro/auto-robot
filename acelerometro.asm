# auto-robot
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
#define F_CPU 8000000UL  //frecuencia de trabajo del ATMEGA88PA
#include "m88PAdef.inc"

.cseg

.ORG	0x0000
RJMP	Reset
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
;Definimos los .def y .equ
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
.def	temp	= r16		; registro de trabajo
.def	data	= r17		; registro de datos
.def	msk		= r18		; registro de mascara

.equ	START = 0x08		; mascara de START
.equ	SLA_W = 0b11010000	; write Bit. Se asume como direccion del acelerometro b68 (AD0=0)
.equ	SLA_R = 0b11010001	; read Bit. Se asume como direccion del acelerometro b68 (AD0=0)

.equ	SLA_ACK_W = 0x18	; mascara de SLA+W se ha transmitido y ACK fue recibido
.equ	SLA_ACK_R = 0x40	; mascara de SLA+R se ha transmitido y ACK fue recibido
.equ	DATA_ACK = 0x28		; mascara de DATA se ha transmitido y ACK fue recibido
.equ	REPEAT_START=0x10	; mascara de START repetido
.equ	DATA_NACK = 0x58	; mascara de DATA se ha recivido y NACK fue enviado
.equ	DATA_ACK_R = 0x50	; mascara de DATA se ha recibido y ACK fue recibido

.equ	WHO_AM_I = 0x75		; dirección del registro de identidad del dispositivo
.equ	ACCEL_XOUTH = 0x3B	; dirección del registro de medición de la parte alta del eje X
.equ	ACCEL_XOUTL = 0x3C	; dirección del registro de medición de la parte baja del eje X
.equ	TEMP_OUTL = 0x42 
.equ	PWR_MGMT_1 = 0x6B	; dirección del registro de configuracion del modo de encencido (power) y la fuente del clock;
;——————————————————————————————————————————————————————————————RESET—————————————————————————————————————————————————————————
Reset:
;————————————————————————————————————————————————————Inicializamos Stackpointer——————————————————————————————————————————————
LDI		temp,low(RAMEND)		;Colocamos stackptr en ram end
OUT		SPL,temp
LDI		temp, high(RAMEND)
OUT		SPH, temp

;————————————————————————————————————————————————————Configuramos los puertos C y D como salida——————————————————————————————————————————

LED_PORTC:
LDI		r19,0xFF
OUT		DDRC,r19

LED_PORTD:
OUT		DDRD,r19

;————————————————————————————————————————————————————Inicio del bus I2C——————————————————————————————————————————————————————
;————————————————————————————————————————————————————Seteamos la velocidad de clock——————————————————————————————————————————
;SCL=400Khz=18.432MHz/(16+2*TWBR*4^TWSR)
LDI    temp,0x00
STS    TWSR,temp

LDI    temp,0xC5	; Seteamos una velocidad de 92kHz aprox
STS    TWBR,temp
LDI    temp,0

　
　
;—————————————————————————————————————————————————————————————————PROGRAMA———————————————————————————————————————————————————

;——————————————————————————————————————Secuencia para escribir un registro del acelerometro——————————————————————————————————
I2C_WRITE_DATA:

;Enviamos la condiciòn de START y verificamos el registro de estado del bus.
RCALL	I2C_START
LDI		msk,START
RCALL	I2C_CHECK

;Cargamos en data la dirección del slave mas el bit de escritura y verificamos que ACK se haya recibido.
LDI		data,SLA_W
RCALL	I2C_LOAD
LDI		msk,SLA_ACK_W
RCALL	I2C_CHECK

;Cargamos en data la direccion del registro a escribir y verificamos que ACK se haya recibido.
LDI		data,PWR_MGMT_1		
RCALL	I2C_LOAD
LDI		msk,DATA_ACK
RCALL	I2C_CHECK

;Cargamos en data el dato a escribir en el registro y verificamos que ACK se haya recibido.
LDI		data,0x00		; Seteamos en 0 el registro para sacar al acelerometro del modo sleep.
RCALL	I2C_LOAD
LDI		msk,DATA_ACK
RCALL	I2C_CHECK

;Enviamos la condición de STOP
RCALL	I2C_STOP

;——————————————————————————————————————Secuencia para leer un registro del acelerometro——————————————————————————————————

I2C_READ_DATA:

;Enviamos la condiciòn de START y verificamos el registro de estado del bus.
RCALL	I2C_START
LDI		msk,REPEAT_START
RCALL	I2C_CHECK

;Cargamos en data la dirección del slave mas el bit de escritura y verificamos que ACK se haya recibido.
LDI		data,SLA_W
RCALL	I2C_LOAD
LDI		msk,SLA_ACK_W
RCALL	I2C_CHECK

;Cargamos en data la direccion del registro a leer y verificamos que ACK se haya recibido.
LDI		data,ACCEL_XOUTL
RCALL	I2C_LOAD
LDI		msk,DATA_ACK
RCALL	I2C_CHECK

;Renviamos la condiciòn de START y verificamos el registro de estado del bus.
RCALL	I2C_START
LDI		msk,REPEAT_START
RCALL	I2C_CHECK

;Cargamos en data la dirección del slave mas el bit de lectura y verificamos que ACK se haya recibido.
LDI		data,SLA_R
RCALL	I2C_LOAD
LDI		msk,SLA_ACK_R
RCALL	I2C_CHECK

;Recibimos el dato y lo copiamos al registro 'r17 = data'. Luego se verifica que el dato se haya recibido y un NACK se haya enviado.
RCALL	I2C_READ
LDI		msk,DATA_NACK
RCALL	I2C_CHECK

　
;Enviamos la condición de STOP
RCALL	I2C_STOP

　
　
ok:

out	PORTD,data
rjmp Reset

　
　
RCALL	POWER_LED_PORTD

RJMP	I2C_LOOP
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

;——————————————————————————————————————————————————————————————————ERROR—————————————————————————————————————————————————————
ERROR:
RCALL	POWER_LED_PORTC
RJMP	ERROR
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————I2C_START———————————————————————————————————————————————————
;Genera la condicón de START
I2C_START:
LDI		temp, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN)
STS		TWCR,temp

;Espera a que la codición de START sea enviada. TWINT en uno indica que la operación de TWI ha finalizado.
WAIT_START:
LDS		temp,TWCR
SBRS	temp,TWINT
RJMP	WAIT_START
LDI		temp,0
RET
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————I2C_CHECK———————————————————————————————————————————————————
;Verificamos el estado de TWSR (registro de estado del bus), TWSR se compara con la mascara (msk).
I2C_CHECK:
LDS		temp,TWSR
ANDI	temp,0xF8
CP		temp,msk
BRNE	ERROR
LDI		temp,0
RET
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————I2C_LOAD————————————————————————————————————————————————————
;Cargamos el registro data en TWDR
I2C_LOAD:
STS		TWDR,data
LDI     temp,(1<<TWINT)|(1<<TWEN)
STS     TWCR,temp

;Espera a que el dato sea enviado. TWINT en uno indica que la peración de TWI ha finalizado.
WAIT_LOAD:
LDS		temp,TWCR
SBRS	temp,TWINT
RJMP	WAIT_LOAD
LDI		temp,0
LDI		data,0
RET
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————I2C_READ————————————————————————————————————————————————————
I2C_READ:
LDI		temp, (1<<TWINT)|(1<<TWEN)
STS		TWCR,temp

;Espera a que la codición de START sea enviada. TWINT en uno indica que la operación de TWI ha finalizado.
WAIT_READ:
LDS		temp,TWCR
SBRS	temp,TWINT
RJMP	WAIT_READ
LDS		data,TWDR
LDI		temp,0
RET
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————I2C_STOP————————————————————————————————————————————————————
;Generamos la condición de STOP
I2C_STOP:
LDI		temp,(1<<TWINT)|(1<<TWEN)|(1<<TWSTO)
STS		TWCR,temp
RET
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

　
;—————————————————————————————————————————————————————————————POWER_LED_PORTC————————————————————————————————————————————————
POWER_LED_PORTC:
LDI		r19,0x08; En la placa de desarrollo se deberia encender solo un LED rojo: el que se encuentra al lado de un LED verde.
OUT		PORTC,r19
RET
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

;—————————————————————————————————————————————————————————————POWER_LED_PORTD————————————————————————————————————————————————
POWER_LED_PORTD:
LDI		r19,0x00
OUT		PORTD,r19
RET
;————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
