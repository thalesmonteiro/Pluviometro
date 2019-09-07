
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       PLUVIOMETRO                               *
;*        LMI- Laboratorio de Medidas e Instrumentação   UFPB      *
;*  Desenvolvido durante a disciplina de Microcontroladores 18.2   *
;*   VERSÃO: 1.0                           DATA: 02/05/19          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     DESCRIÇÃO DO PROJETO                        *
;*-----------------------------------------------------------------*
;*  Utilização do PIC 16F877A para monitoramento do indice         *
;* pluviometrico, guardando os valores em uma eeprom externa       *
;* e exibindo os valores em um display LCD.                        *                                         *
;*                                                                 *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*             CONFIGURAÇÕES INICIAIS PARA GRAVAÇÃO                *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

    __CONFIG _CP_OFF & _CPD_OFF & _DEBUG_OFF & _LVP_OFF & _WRT_OFF &_BODEN_OFF & _PWRTE_ON & _WDT_OFF & _HS_OSC

    
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*            DEFINIÇÃO DAS VARIÁVEIS INTERNAS DO PIC              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

#INCLUDE <p16f877A.inc>
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    DEFINIÇÃO DOS BANCOS                         *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;DEFINIÇÃO DE COMANDOS DE USUÁRIO PARA ALTERAÇÃO DA PÁGINA DE MEMÓRIA
#DEFINE	BANK0	BCF STATUS,RP0	;SELECIONA BANK0 DE MEMÓRIA
#DEFINE	BANK1	BSF STATUS,RP0	;SELECIONA BANK1 DE MEMÓRIA

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         DEFINIÇÃO DAS VARIÁVEIS                               *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DOS NOMES E ENDEREÇOS DE TODAS AS VARIÁVEIS UTILIZADAS 
; PELO SISTEMA
; ESTE BLOCO ESTÁ LOCALIZADO NO INICIO DO BANCO 0
	
	CBLOCK	0x20	        ;ENDEREÇO INICIAL DA MEMÓRIA DE USUÁRIO
		W_TEMP		;REGISTRADORES TEMPORÁRIOS PARA USO
		STATUS_TEMP	;JUNTO ÀS INTERRUPÇÕES
		GOTAS		;CONTADOR DE GOTAS
		FLAG
		TEMPO0
		TEMPO1
		AUX_TEMP
		BUFFER
		BUFFER_L          ;UTILIZADA PARA LEITURA DA EEPROM EXTERNA
		BUFFER_H          
		ENDERECO_HIGH   ;PARTE ALTA DO ENDERECO
 		ENDERECO_LOW    ;PARTE BAIXA DO ENDERECO
		DADO
		DADO_L
		DADO_H          ;UTILIZADA PARA GRAVACAO DA EEPROM EXTERNA
		ENDERECO_RTC
		DADO_RTC
		SAIDA_RTC
		DEZENA_RTC
		UNIDADE_RTC
		MINUTO
		MINUTO_ANTERIOR
		HORA
		HORA_ANTERIOR
		DIA
		DIA_ANTERIOR
		MES
		MES_ANTERIOR
		ANO
		ANO_ANTERIOR
		;VARIAVEIS UTILIZADAS NA MULTIPLICACAO
		MULTIPLO
		OPERANDO
		H_BYTE
		L_BYTE
		AUX
		BYTE1_HIGH
		BYTE1_LOW
		BYTE2_HIGH
		BYTE2_LOW
		RESULTADO_LOW
		RESULTADO_HIGH
		AUX2
		SEMANA1_HIGH
		SEMANA1_LOW
		SEMANA2_HIGH
		SEMANA2_LOW
		SEMANA3_HIGH
		SEMANA3_LOW
		SEMANA4_HIGH
		SEMANA4_LOW
		T
		R3
		R2
		R1
		AUX1_HIGH
		AUX1_LOW
		AUX2_HIGH
		AUX2_LOW
		AUX3_HIGH
		AUX3_LOW
		AUX4_HIGH
		AUX4_LOW
		INDICE_MENU
	ENDC			;FIM DO BLOCO DE MEMÓRIA
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         CONSTANTES INTERNAS                     *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODAS AS CONSTANTES UTILIZADAS PELO SISTEMA
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*              DECLARAÇÃO DOS FLAGS DE SOFTWARE                   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODAS AS FLAGS UTILIZADAS PELO SISTEMA
#DEFINE	    F_ERRO	FLAG,0
#DEFINE	    MENU_1	INDICE_MENU,0
#DEFINE	    MENU_2	INDICE_MENU,1
#DEFINE	    MENU_3	INDICE_MENU,2
#DEFINE	    MENU_4	INDICE_MENU,3

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           ENTRADAS                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS PINOS QUE SERÃO UTILIZADOS COMO ENTRADA
; RECOMENDAMOS TAMBÉM COMENTAR O SIGNIFICADO DE SEUS ESTADOS (0 E 1)
#DEFINE	   PLUV_IN  PORTA,RA0	;Define RA0 como entrada do sinal do pluviometro

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           SAÍDAS                                *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS PINOS QUE SERÃO UTILIZADOS COMO SAÍDA
; RECOMENDAMOS TAMBÉM COMENTAR O SIGNIFICADO DE SEUS ESTADOS (0 E 1)
#DEFINE    SDA       PORTC,RC4
#DEFINE	   ENABLE    PORTC,RC0
#DEFINE	   RS	     PORTC,RC1
#DEFINE    SCL       PORTC,RC3
#DEFINE	   DISPLAY   PORTD
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       VETOR DE RESET                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	ORG	0x0000			;ENDEREÇO INICIAL DE PROCESSAMENTO
	GOTO	INICIO
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    INÍCIO DA INTERRUPÇÃO                        *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; ENDEREÇO DE DESVIO DAS INTERRUPÇÕES. A PRIMEIRA TAREFA É SALVAR OS
; VALORES DE "W" E "STATUS" PARA RECUPERAÇÃO FUTURA

	ORG	0x04			;ENDEREÇO INICIAL DA INTERRUPÇÃO
	MOVWF	W_TEMP		;COPIA W PARA W_TEMP
	SWAPF	STATUS,W
	MOVWF	STATUS_TEMP	;COPIA STATUS PARA STATUS_TEMP

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    ROTINA DE INTERRUPÇÃO                        *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; AQUI SERÁ ESCRITA AS ROTINAS DE RECONHECIMENTO E TRATAMENTO DAS
; INTERRUPÇÕES
	BTFSC	PORTB,RB5
	CALL	EXIBE_MENU_OPCOES
	GOTO	SAI_INT

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                 ROTINA DE SAÍDA DA INTERRUPÇÃO                  *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; OS VALORES DE "W" E "STATUS" DEVEM SER RECUPERADOS ANTES DE 
; RETORNAR DA INTERRUPÇÃO

SAI_INT
	MOVFW	PORTB
	BCF	INTCON,RBIF
	SWAPF	STATUS_TEMP,W
	MOVWF	STATUS		;MOVE STATUS_TEMP PARA STATUS
	SWAPF	W_TEMP,F
	SWAPF	W_TEMP,W	;MOVE W_TEMP PARA W
	
	RETFIE
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;            ROTINA QUE VERIFICA SE HÁ GOTAS                      *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
CONTA_GOTA
	BANK0
	BCF	PIR1,0
	MOVLW	B'00001011'
	MOVWF	TMR1H
	MOVLW   B'11011100'
	MOVWF	TMR1L
	BSF	T1CON,TMR1ON
	;INICIA TIMER
AGUARDA
	BANK0
	BTFSC	PIR1,0
	GOTO	ESTOURO
	BANK1
	BTFSS	CMCON, C1OUT
	GOTO	AGUARDA
	BANK0
	INCF	GOTAS, F
	MOVLW	.10
	CALL	DELAY_MILE
	GOTO	AGUARDA
	
ESTOURO	
	BANK0
	BCF	PIR1,0
	DECFSZ	AUX
	GOTO	CONTA_GOTA
	RETURN

DIVIDE_POR_10
	;AUX = DEZENA
	;AUX2= UNDIADE
	CLRF	AUX	;Limpa o valor anterior
	MOVWF	BUFFER
DEZENA_T  
	BCF	STATUS,Z	
	BCF	STATUS,C	
	MOVLW	 .10		;Valor do denominador, no caso da funçâo, 10.  
	SUBWF	 BUFFER,0 ;Faz subtração de valor_10 - W, guarda resultado em W  
	BTFSS	 STATUS,Z	;Primeiro teste verifica se valor_10 = W.  
	GOTO	 DEZENA_P	;A divisão é possível.  
	INCF	 AUX,1	;valor_10=10, logo incrementa o regist dezena  
	MOVWF	 AUX2	;Completa o outro digito unidade com o valor 0  
	GOTO	 OUT    	;Divisão não é possível.  
DEZENA_P
	BTFSS	 STATUS,C	;segundo teste verifica se a divisão é possível  
	GOTO	 OUT_TEMP	;valor_10 menor que 10,divisão não é possível.  
	MOVWF	 BUFFER	;resultado da subtração passa para o regist valor_10.  
	INCF	 AUX,1	;soma 1 ao regist  
	GOTO	 DEZENA_T   ;volta ao inicio, para mais divisões... 
OUT_TEMP
	movf BUFFER,0	;resto da divisão fica no regist unidades  
	movwf AUX2	;  
OUT
	RETURN

LER_MINUTO   ;LER O MINUTO NO RTC  (0 - 59)
    BANK0
    MOVLW   0x1
    MOVWF   ENDERECO_RTC
    CALL    LEITURA_I2C_RTC
    MOVF    SAIDA_RTC, W
    CALL    BCD_TO_DEC
    MOVWF   MINUTO
 
    RETURN
    
LER_HORA   ;LER A HORA NO RTC (0 - 23)
    BANK0
    MOVLW   0x2
    MOVWF   ENDERECO_RTC
    CALL    LEITURA_I2C_RTC
    MOVF    SAIDA_RTC,W
    CALL    BCD_TO_DEC
    MOVWF   HORA
    RETURN
  
    
LER_DIA    ;LER A DATA NO RTC  (1 - 31)
    BANK0
    MOVLW   0X4
    MOVWF   ENDERECO_RTC
    CALL    LEITURA_I2C_RTC
    MOVF    SAIDA_RTC,W
    CALL    BCD_TO_DEC
    MOVWF   DIA
    RETURN
     
LER_MES     ;LER O MES  (1 - 12)
    BANK0
    MOVLW   0x5
    MOVWF   ENDERECO_RTC
    CALL    LEITURA_I2C_RTC
    MOVF    SAIDA_RTC,W
    CALL    BCD_TO_DEC
    MOVWF   MES
    RETURN
    
LER_ANO     ;LER ANO ( 00 - 99)
    BANK0
    MOVLW   0x6
    MOVWF   ENDERECO_RTC
    CALL    LEITURA_I2C_RTC
    MOVF    SAIDA_RTC,W
    CALL    BCD_TO_DEC
    MOVWF   ANO
    RETURN

;ESTA ROTINA ENVIA UM CARACTER PARA O LCD, O CARACTER DEVE ESTAR EM W 
ESCREVE
    BSF	    ENABLE
    NOP
    MOVWF   DISPLAY
    BCF	    ENABLE
    MOVLW   .100
    CALL    DELAY_MICRO
    RETURN
  
;INICIALIZAÇÃO DO LCD
INICIALIZA_DISPLAY
    MOVLW   .20
    CALL    DELAY_MILE
    
    BCF	    RS	;DEFINE O DISPLAY PARA RECEBER COMANDOS
    
    BSF	    ENABLE
    ;ENVIA COMANDO 0X30 (0011)
    MOVLW   0X30
    MOVWF   DISPLAY
    BCF	    ENABLE 
    MOVLW   .5
    CALL    DELAY_MILE
    
    ;ENVIA COMANDO 0X30
    BSF	    ENABLE ;ATIVA DISPLAY
    MOVLW   0X30
    MOVWF   DISPLAY
    BCF	    ENABLE ;DESATIVA DISPLAY
    MOVLW   .100
    CALL    DELAY_MICRO
    
    ;ENVIA COMANDO 0X30
    BSF	    ENABLE ;ATIVA DISPLAY
    MOVLW   0X30
    MOVWF   DISPLAY
    BCF	    ENABLE ;DESATIVA DISPLAY
    MOVLW   .100
    CALL    DELAY_MICRO
    
    ;ENVIA COMANDO 0X38 ESTABELECE COMUNICACAO EM 8 VIAS
    BSF	    ENABLE
    MOVLW   0X38
    MOVWF   DISPLAY
    BCF	    ENABLE
    MOVLW   .100
    CALL    DELAY_MICRO
    
    ;COMANDO QUE LIMPA O DISPLAY E POSICIONA O CURSOR NA PRIMEIRA LINHA, PRIMEIRA COLUNA
    BSF	    ENABLE
    MOVLW   0X1
    MOVWF   DISPLAY
    BCF	    ENABLE
    MOVLW   .5
    CALL    DELAY_MILE
    
   ;COMANDO PARA LIGAR O DISPLAY SEM CURSOR
    BSF	    ENABLE
    MOVLW   0XC 
    MOVWF   DISPLAY
    BCF	    ENABLE
    MOVLW   .100
    CALL    DELAY_MICRO
    
     ;COMANDO DE DESLOCAMENTO AUTOMATICO DO CURSOR PARA DIREITA
    BSF	    ENABLE
    MOVLW   0X6  
    MOVWF   DISPLAY
    MOVLW  .100
    CALL    DELAY_MICRO
    
    BSF	    RS  ;VOLTA LCD PARA RECEBER DADOS
    
    RETURN
    ;ENVIA COMANDO 0X30

    RETURN
    
LIMPA_DISPLAY
    BSF	    ENABLE
    BCF	    RS
    MOVLW   0X1
    MOVWF   DISPLAY
    BCF	    ENABLE
    RETURN

SEPARA_RTC  ;SEPARA A SAIDA DO RTC EM DUAS VARIAVEIS
    ;RETORNANDO NAS VARIAVEIS UNIDADE_RTC E DEZENA_RTC
    BANK0
    ;SEPARA OS NIBBLES DA SAIDA_RTC
    MOVWF   UNIDADE_RTC
    MOVWF   DEZENA_RTC
    SWAPF   DEZENA_RTC,F  ;INVERTE OS NIBBLES
    BCF	    UNIDADE_RTC,7
    BCF	    UNIDADE_RTC,6
    BCF	    UNIDADE_RTC,5
    BCF	    UNIDADE_RTC,4
    BCF	    DEZENA_RTC,7
    BCF	    DEZENA_RTC,6
    BCF	    DEZENA_RTC,5
    BCF	    DEZENA_RTC,4
    
    RETURN
    
ENDERECO_MINUTO
    BANK0
    ;DEFINE O ENDERECO DE GRAVAÇÃO NA EEPROM
    MOVLW   B'00000000'
    MOVWF   ENDERECO_HIGH
    
    ;SEPARA OS NIBBLES DA SAIDA_RTC E REPRESENTA O VALOR EM DECIMAL
    MOVF    MINUTO,W
    CALL    SEPARA_RTC
    MOVLW   .10
    MOVWF   MULTIPLO
    MOVF    DEZENA_RTC,W
    MOVWF   OPERANDO
    CALL    MPY_F  
    MOVF    UNIDADE_RTC,W
    ADDWF   L_BYTE,F       ;SOMA L_BYTE + UNIDADE_RTC 
    
    ;ENDERECO_LOW = MINUTO * 2
    BCF	    STATUS,C
    RLF	    L_BYTE,W
   
    MOVWF   ENDERECO_LOW
    RETURN
    
ENDERECO_HORA
    BANK0
    ;DEFINE O ENDERECO DE GRAVAÇÃO NA EEPROM
    ;SEPARA OS NIBBLES DA SAIDA_RTC E REPRESENTA O VALOR EM DECIMAL
    MOVLW   B'00000000'
    MOVWF   ENDERECO_HIGH
    
    MOVF    HORA,W
    CALL    SEPARA_RTC
    MOVLW   .10
    MOVWF   MULTIPLO
    MOVF    DEZENA_RTC,W
    MOVWF   OPERANDO
    CALL    MPY_F  
    MOVF    UNIDADE_RTC,W
    ADDWF   L_BYTE,F 
    MOVF    L_BYTE,W   
    ;ENDERECO_LOW = HORA * 2 + 120
    BCF	    STATUS,C
    RLF	    L_BYTE,F
    
    MOVLW   .120
    ADDWF   L_BYTE,W
    MOVWF   ENDERECO_LOW
    
    RETURN
    
    ;ROTINA QUE CALCULA O ENDERECO RESPECTIVO AO DIA ATUAL NA EEPROM
    ;ESSA ROTINA NECESSITA DO VALOR DO DIA E DO MES
ENDERECO_DIA  ;DIA *2 + 166 + 62(MES - 1) +732(ANO -2019)
    MOVF    DIA,W
    CALL    SEPARA_RTC
    MOVLW   .10
    MOVWF   MULTIPLO
    MOVF    DEZENA_RTC,W
    MOVWF   OPERANDO
    CALL    MPY_F
    MOVF    UNIDADE_RTC,W
    ADDWF   L_BYTE,W    ;L_BYTE GUARDA O VALOR DO DIA EM DECIMAL
    MOVWF   AUX
   
    BCF	    STATUS,C
    RLF	    AUX,F   
    MOVLW   .166
    ADDWF   AUX,F  ;AUX = DIA * 2 + 166
    
    CALL    LER_MES

    DECF    MES,F
    
    ;REALIZA OPERACAO (MES-1)*62
    MOVLW   .62
    MOVWF   MULTIPLO
    MOVF    MES,W
    MOVWF   OPERANDO
    CALL    MPY_F     
    ;H_BYTE E L_BYTE GUARDAM O RESULTADO DA MULTIPLICACAO
    MOVF    H_BYTE,W
    MOVWF   BYTE2_HIGH
    MOVF    L_BYTE,W
    MOVWF   BYTE2_LOW
    
    MOVLW   .0
    MOVWF   BYTE1_HIGH
    MOVF    AUX,W
    MOVWF   BYTE1_LOW
 
    CALL    SOMA_2BYTES
    
    MOVF    RESULTADO_HIGH,W
    MOVWF   ENDERECO_HIGH
    MOVF    RESULTADO_LOW,W
    MOVWF   ENDERECO_LOW
    
    ;PRIMEIRO TERMO DA SOMA ( DIA *2 + 166 + 62(MES - 1))
    MOVF    RESULTADO_HIGH,W
    MOVWF   BYTE1_HIGH
    MOVF    RESULTADO_LOW,W
    MOVWF   BYTE1_LOW
    
    CALL    LER_ANO
    MOVLW   .19
    SUBWF   ANO,W  ;ANO - 2019
    MOVWF   T
    
    ;COLOCA 732
    MOVLW   B'00000010'
    MOVWF   H_BYTE
    MOVLW   B'11011100'
    MOVWF   L_BYTE
    
    ;732 * T
    
    CALL    MULT16  ;RETORNA O RESULTADO EM R3,R2,R1
    
    MOVF    R2,W
    MOVWF   BYTE2_HIGH
    MOVF    R1,W
    MOVWF   BYTE2_LOW

    CALL    SOMA_2BYTES
    
    MOVF    RESULTADO_HIGH,W
    MOVWF   ENDERECO_HIGH
    MOVF    RESULTADO_LOW,W
    MOVWF   ENDERECO_LOW

    RETURN
    
GRAVA_EM_HORA
    BANK0
    MOVLW   .60
    MOVWF   AUX
    CLRF    BYTE1_LOW
    CLRF    BYTE1_HIGH
    CLRF    MINUTO
    MOVLW   B'00000000'
    MOVWF   ENDERECO_HIGH
;REALIZA SOMA DOS VALORES REGISTRADO NOS MINUTOS 0 + 1 + 2 ... + 58 + 59

SOMATORIO    
    BANK0
    ;CALCULA O ENDERECO DO MINUTO ATUAL
    BCF	    STATUS,C
    RLF	    MINUTO,W
    MOVWF   ENDERECO_LOW
    
    CALL    LEITURA_I2C_EEPROM ;LER O VALOR GUARDADO NESSA POSICAO
    ;RETORNA EM BUFFER_L E BUFFER_H
    MOVF    BUFFER_L, W
    MOVWF   BYTE2_LOW
    MOVF    BUFFER_H, W
    MOVWF   BYTE2_HIGH
    
    CALL    SOMA_2BYTES

    MOVF    RESULTADO_LOW,W
    MOVWF   BYTE1_LOW
    MOVF    RESULTADO_HIGH,W
    MOVWF   BYTE1_HIGH
    
    ;ZERA A POSICAO LIDA
    MOVLW   .0
    MOVWF   DADO_L
    MOVWF   DADO_H
    CALL    ESCRITA_I2C_EEPROM
    
    ;INCREMENTA O MINUTO
    INCF    MINUTO,F
    DECFSZ  AUX,F
    GOTO    SOMATORIO
    
    ;INICIA GRAVACAO NA HORA
    
    MOVF    HORA_ANTERIOR,W
    MOVWF   HORA
    CALL    ENDERECO_HORA
    
    MOVF    BYTE1_LOW,W
    MOVWF   DADO_L
    MOVF    BYTE1_HIGH,W
    MOVWF   DADO_H
    
    CALL    ESCRITA_I2C_EEPROM
    
    CALL    ZERA_MINUTO
    RETURN
    
GRAVA_EM_DIA
    BANK0
    MOVLW   .24   ;EXECUTA 24 VEZES
    MOVWF   AUX
    MOVLW   .0
    MOVWF   BYTE1_LOW
    MOVWF   BYTE1_HIGH
    MOVWF   HORA
  ;ENDERECO_HIGH PARA PERCORRER POSICAO DE HORAS
    MOVWF   ENDERECO_HIGH
;REALIZA SOMA DOS VALORES REGISTRADO NAS HORAS  0 + 1 + 2 ... + 22 + 23

SOMATORIO1    
    ;CALCULA O ENDERECO DA HORA ATUAL
    BCF	    STATUS,C
    RLF	    HORA,F
    MOVLW   .120
    ADDWF   HORA,W
    MOVWF   ENDERECO_LOW
    
    CALL    LEITURA_I2C_EEPROM ;LER O VALOR GUARDADO NESSA POSICAO
    ;RETORNA EM BUFFER_L E BUFFER_H
    MOVF    BUFFER_L, W
    MOVWF   BYTE2_LOW
    MOVF    BUFFER_H, W
    MOVWF   BYTE2_HIGH
    
    CALL    SOMA_2BYTES
    
    MOVF    RESULTADO_LOW,W
    MOVWF   BYTE1_LOW
    MOVF    RESULTADO_HIGH,W
    MOVWF   BYTE1_HIGH
    
    INCF    HORA,F
    
    DECFSZ  AUX,F
    GOTO    SOMATORIO1
    
    ;INICIA GRAVACAO NO DIA, CALCULA ENDERECO DO DIA 
    MOVF    BYTE1_LOW,W
    MOVWF   DADO_L
    MOVF    BYTE1_HIGH,W
    MOVWF   DADO_H
    
    MOVF    DIA_ANTERIOR,W
    MOVWF   DIA
    CALL    ENDERECO_DIA ;retorna em endereço high e endereço low
   
    
    
    CALL    ESCRITA_I2C_EEPROM
    
    RETURN
SELECAO_DIA  ; RB4 = - RB5 = OK  RB6 = +
    CLRF    INTCON ;DESLIGA A INTERRUPÇÃO
    CALL    LER_DIA
    
SELECT
    BCF	    RS		   
    MOVLW   0xF 
    CALL    ESCREVE         ; LIMPA DISPLAY
    BSF	    RS
    
    BCF	    RS
    MOVLW   0X88          ; DEFINE O CURSOR PARA LINHA 0
    CALL    ESCREVE
    BSF	    RS	
    
    MOVLW   'D'
    CALL    ESCREVE
    MOVLW   'A'
    CALL    ESCREVE
    MOVLW   'T'
    CALL    ESCREVE
    MOVLW   'A'
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0XC4          ; DEFINE O CURSOR PARA LINHA 0
    CALL    ESCREVE
    BSF	    RS	
    
    MOVLW   '<'
    CALL    ESCREVE
    
    ;ESCREVE DIA
    MOVFW   DIA
    CALL    DIVIDE_POR_10 ;RETORNA AUX = DEZENA, AUX2= UNIDADE
    MOVLW   0x30
    ADDWF   AUX,W
    CALL    ESCREVE
    
    MOVLW   0x30
    ADDWF   AUX2,W
    CALL    ESCREVE
	
    MOVLW   '/'
    CALL    ESCREVE
    
    CALL    LER_MES
    MOVFW   MES
    CALL    SEPARA_RTC 
    MOVLW   0x30
    ADDWF   DEZENA_RTC,W
    CALL    ESCREVE
    MOVLW   0x30
    ADDWF   UNIDADE_RTC,W
    CALL    ESCREVE
    
    MOVLW   '/'
    CALL    ESCREVE
    
    CALL    LER_ANO
    CALL    SEPARA_RTC 
    MOVLW   0x30
    ADDWF   DEZENA_RTC,W
    CALL    ESCREVE
    MOVLW   0x30
    ADDWF   UNIDADE_RTC,W
    CALL    ESCREVE

    BCF	    RS
    MOVLW   0XD5        
    CALL    ESCREVE
    BSF	    RS
    
    MOVLW   '-'
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0XDD        
    CALL    ESCREVE
    BSF	    RS
    
    MOVLW   'O'
    CALL    ESCREVE
    MOVLW   'K'
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0XE6       
    CALL    ESCREVE
    BSF	    RS
    
    MOVLW   '+'
    CALL    ESCREVE

CHECA_BOTAO_RB4
    BTFSS   PORTB,RB4
    GOTO    CHECA_BOTAO_RB6
    DECF    DIA,F
    MOVLW   .150
    CALL    DELAY_MILE
    GOTO    SELECT
    
CHECA_BOTAO_RB6   
    BTFSS   PORTB,RB6
    GOTO    CHECA_BOTAO_RB5
    INCF    DIA,F
    MOVLW   .150
    CALL    DELAY_MILE
    GOTO    SELECT
    
CHECA_BOTAO_RB5
    BTFSS   PORTB,RB5
    GOTO    CHECA_BOTAO_RB4
    MOVLW   .150
    CALL    DELAY_MILE
    
    RETURN
    
EXIBE_MENU  ;EXIBE MIN X
    
    BCF	    RS		   
    MOVLW   0xF 
    CALL    ESCREVE         ; LIMPA DISPLAY
    BSF	    RS
    
    BCF	    RS
    MOVLW   0X80          ; DEFINE O CURSOR PARA LINHA 0
    CALL    ESCREVE
    BSF	    RS	
    
    MOVLW   'M'
    CALL    ESCREVE
    MOVLW   'I'
    CALL    ESCREVE
    MOVLW   'N'
    CALL    ESCREVE
    MOVLW   ' '
    CALL    ESCREVE
    
    CALL    LER_MINUTO
    NOP
    MOVLW   .0
    SUBWF   MINUTO,W
    BTFSC   STATUS,Z  ; Z = 1 DEU ZERO
    GOTO    MIN_59
    DECF    MINUTO,W
    CALL    SEPARA_RTC
    
    MOVLW   0x30
    ADDWF   DEZENA_RTC,W
    CALL    ESCREVE
    
    MOVLW   0x30
    ADDWF   UNIDADE_RTC,W
    CALL    ESCREVE
 
    RETURN

EXIBE_MENU_OPCOES
    ;INDICE_MENU
    BCF	    INTCON, GIE
    BCF	    INTCON, RBIE
    
    BCF	    RS
    MOVLW   0X1
    CALL    ESCREVE
    BSF	    RS

    ;CHUVA POR DATA
    BCF	    RS
    MOVLW   0X80          
    CALL    ESCREVE
    BSF	    RS	
    
    MOVLW   .10
    CALL    DELAY_MILE
    
    MOVLW   '-'
    CALL    ESCREVE
    MOVLW   '>'
    CALL    ESCREVE
    MOVLW   'C'
    CALL    ESCREVE
    MOVLW   'H'
    CALL    ESCREVE
    MOVLW   'U'
    CALL    ESCREVE
    MOVLW   'V'
    CALL    ESCREVE
    MOVLW   'A'
    CALL    ESCREVE
    MOVLW   ' '
    CALL    ESCREVE
    MOVLW   'P'
    CALL    ESCREVE
    MOVLW   'O'
    CALL    ESCREVE
    MOVLW   'R'
    CALL    ESCREVE
    MOVLW   ' '
    CALL    ESCREVE
    MOVLW   'D'
    CALL    ESCREVE
    MOVLW   'A'
    CALL    ESCREVE
    MOVLW   'T'
    CALL    ESCREVE
    MOVLW   'A'
    CALL    ESCREVE
    
    ;VER MES
    BCF	    RS
    MOVLW   0XC0          
    CALL    ESCREVE
    BSF	    RS
    
    MOVLW   ' '
    CALL    ESCREVE
    MOVLW   ' '
    CALL    ESCREVE
    
    MOVLW   'V'
    CALL    ESCREVE
    MOVLW   'E'
    CALL    ESCREVE
    MOVLW   'R'
    CALL    ESCREVE
    MOVLW   ' '
    CALL    ESCREVE
    MOVLW   'M'
    CALL    ESCREVE
    MOVLW   'E'
    CALL    ESCREVE
    MOVLW   'S'
    CALL    ESCREVE
    
    ;VER ANO
    BCF	    RS
    MOVLW   0X94          
    CALL    ESCREVE
    BSF	    RS
    
    MOVLW   ' '
    CALL    ESCREVE
    MOVLW   ' '
    CALL    ESCREVE
    
    MOVLW   'V'
    CALL    ESCREVE
    MOVLW   'E'
    CALL    ESCREVE
    MOVLW   'R'
    CALL    ESCREVE
    MOVLW   ' '
    CALL    ESCREVE
    MOVLW   'A'
    CALL    ESCREVE
    MOVLW   'N'
    CALL    ESCREVE
    MOVLW   '0'
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0XD4
    CALL    ESCREVE
    BSF	    RS
    
    MOVLW   '-'
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0XDD
    CALL    ESCREVE
    BSF	    RS
    
    MOVLW   'O'
    CALL    ESCREVE
    MOVLW   'K'
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0XE7
    CALL    ESCREVE
    BSF	    RS
    
    MOVLW   '+'
    CALL    ESCREVE
   
    MOVLW   .50
    CALL    DELAY_MILE
ESPERA_ESCOLHA
    ;RB4 = - 
    ;RB5 = OK
    ;RB6 = +
    BTFSC   PORTB,RB4  ;SE BOTAO MENOS MARCADO, NAO FAZ NADA
    GOTO    ESPERA_ESCOLHA
    BTFSC   PORTB,RB6
    GOTO    OPCAO_MES
    BTFSC   PORTB,RB5
    GOTO    PRIMEIRO_MENU
    GOTO    ESPERA_ESCOLHA
    
OPCAO_MES
    
    BCF	    RS
    MOVLW   0X1
    CALL    ESCREVE
    BSF	    RS
    
    ;VER MES
    BCF	    RS
    MOVLW   0X80          
    CALL    ESCREVE
    BSF	    RS	
    
    MOVLW   .10
    CALL    DELAY_MILE
    MOVLW   '-'
    CALL    ESCREVE
    MOVLW   '>'
    CALL    ESCREVE
    
    MOVLW   'V'
    CALL    ESCREVE
    MOVLW   'E'
    CALL    ESCREVE
    MOVLW   'R'
    CALL    ESCREVE
    MOVLW   ' '
    CALL    ESCREVE
    MOVLW   'M'
    CALL    ESCREVE
    MOVLW   'E'
    CALL    ESCREVE
    MOVLW   'S'
    CALL    ESCREVE
    
    ;VER ANO
    BCF	    RS
    MOVLW   0XC2          
    CALL    ESCREVE
    BSF	    RS	
    
    MOVLW   'V'
    CALL    ESCREVE
    MOVLW   'E'
    CALL    ESCREVE
    MOVLW   'R'
    CALL    ESCREVE
    MOVLW   ' '
    CALL    ESCREVE
    MOVLW   'A'
    CALL    ESCREVE
    MOVLW   'N'
    CALL    ESCREVE
    MOVLW   'O'
    CALL    ESCREVE

    ;ZERAR  EEPROM
    BCF	    RS
    MOVLW   0X96          
    CALL    ESCREVE
    BSF	    RS	
    
    MOVLW   'Z'
    CALL    ESCREVE
    MOVLW   'E'
    CALL    ESCREVE
    MOVLW   'R'
    CALL    ESCREVE
    MOVLW   'A'
    CALL    ESCREVE
    MOVLW   ' '
    CALL    ESCREVE
    MOVLW   'R'
    CALL    ESCREVE
    MOVLW   'E'
    CALL    ESCREVE
    MOVLW   'G'
    CALL    ESCREVE
    MOVLW   'I'
    CALL    ESCREVE
    MOVLW   'S'
    CALL    ESCREVE
    MOVLW   'T'
    CALL    ESCREVE
    MOVLW   'R'
    CALL    ESCREVE
    MOVLW   'O'
    CALL    ESCREVE
    MOVLW   'S'
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0XD4
    CALL    ESCREVE
    BSF	    RS
    
    MOVLW   '-'
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0XDD
    CALL    ESCREVE
    BSF	    RS
    
    MOVLW   'O'
    CALL    ESCREVE
    MOVLW   'K'
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0XE7
    CALL    ESCREVE
    BSF	    RS
    
    MOVLW   '+'
    CALL    ESCREVE
    
    MOVLW   .50
    CALL    DELAY_MILE
    
ESPERA_ESCOLHA_2
    BTFSC   PORTB,RB4  
    GOTO    EXIBE_MENU_OPCOES
    BTFSC   PORTB,RB6
    GOTO    OPCAO_ANO
    BTFSC   PORTB,RB5
    GOTO    SEGUNDO_MENU
    GOTO    ESPERA_ESCOLHA_2
    
OPCAO_ANO
    BCF	    RS
    MOVLW   .1
    CALL    ESCREVE
    BSF	    RS
    
    ;VER MES
    BCF	    RS
    MOVLW   0X80          
    CALL    ESCREVE
    BSF	    RS	
    
    MOVLW   ' '
    CALL    ESCREVE
    MOVLW   ' '
    CALL    ESCREVE
    
    MOVLW   'V'
    CALL    ESCREVE
    MOVLW   'E'
    CALL    ESCREVE
    MOVLW   'R'
    CALL    ESCREVE
    MOVLW   ' '
    CALL    ESCREVE
    MOVLW   'M'
    CALL    ESCREVE
    MOVLW   'E'
    CALL    ESCREVE
    MOVLW   'S'
    CALL    ESCREVE
    
    ;VER ANO
    BCF	    RS
    MOVLW   0XC0          
    CALL    ESCREVE
    BSF	    RS	
    
    MOVLW   '-'
    CALL    ESCREVE
    MOVLW   '>'
    CALL    ESCREVE
    MOVLW   'V'
    CALL    ESCREVE
    MOVLW   'E'
    CALL    ESCREVE
    MOVLW   'R'
    CALL    ESCREVE
    MOVLW   ' '
    CALL    ESCREVE
    MOVLW   'A'
    CALL    ESCREVE
    MOVLW   'N'
    CALL    ESCREVE
    MOVLW   'O'
    CALL    ESCREVE

    ;ZERAR  EEPROM
    BCF	    RS
    MOVLW   0X96          
    CALL    ESCREVE
    BSF	    RS	
    
    MOVLW   'Z'
    CALL    ESCREVE
    MOVLW   'E'
    CALL    ESCREVE
    MOVLW   'R'
    CALL    ESCREVE
    MOVLW   'A'
    CALL    ESCREVE
    MOVLW   ' '
    CALL    ESCREVE
    MOVLW   'R'
    CALL    ESCREVE
    MOVLW   'E'
    CALL    ESCREVE
    MOVLW   'G'
    CALL    ESCREVE
    MOVLW   'I'
    CALL    ESCREVE
    MOVLW   'S'
    CALL    ESCREVE
    MOVLW   'T'
    CALL    ESCREVE
    MOVLW   'R'
    CALL    ESCREVE
    MOVLW   'O'
    CALL    ESCREVE
    MOVLW   'S'
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0XD4
    CALL    ESCREVE
    BSF	    RS
    
    MOVLW   '-'
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0XDD
    CALL    ESCREVE
    BSF	    RS
    
    MOVLW   'O'
    CALL    ESCREVE
    MOVLW   'K'
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0XE7
    CALL    ESCREVE
    BSF	    RS
    
    MOVLW   '+'
    CALL    ESCREVE
    
    MOVLW   .50
    CALL    DELAY_MILE
    
ESPERA_ESCOLHA_3
    BTFSC   PORTB,RB4  
    GOTO    OPCAO_MES
    BTFSC   PORTB,RB6
    GOTO    OPCAO_EEPROM
    BTFSC   PORTB,RB5
    GOTO    TERCEIRO_MENU
    GOTO    ESPERA_ESCOLHA_3

OPCAO_EEPROM
    
    BCF	    RS
    MOVLW   .1
    CALL    ESCREVE
    BSF	    RS
   
    ;VER MES
    BCF	    RS
    MOVLW   0X80          
    CALL    ESCREVE
    BSF	    RS	
    
    MOVLW   ' '
    CALL    ESCREVE
    MOVLW   ' '
    CALL    ESCREVE
    
    MOVLW   'V'
    CALL    ESCREVE
    MOVLW   'E'
    CALL    ESCREVE
    MOVLW   'R'
    CALL    ESCREVE
    MOVLW   ' '
    CALL    ESCREVE
    MOVLW   'M'
    CALL    ESCREVE
    MOVLW   'E'
    CALL    ESCREVE
    MOVLW   'S'
    CALL    ESCREVE
    
    ;VER ANO
    BCF	    RS
    MOVLW   0XC0          
    CALL    ESCREVE
    BSF	    RS	
    
    MOVLW   ' '
    CALL    ESCREVE
    MOVLW   ' '
    CALL    ESCREVE
    MOVLW   'V'
    CALL    ESCREVE
    MOVLW   'E'
    CALL    ESCREVE
    MOVLW   'R'
    CALL    ESCREVE
    MOVLW   ' '
    CALL    ESCREVE
    MOVLW   'A'
    CALL    ESCREVE
    MOVLW   'N'
    CALL    ESCREVE
    MOVLW   'O'
    CALL    ESCREVE

    ;ZERAR  EEPROM
    BCF	    RS
    MOVLW   0X94          
    CALL    ESCREVE
    BSF	    RS	
    
    MOVLW   '-'
    CALL    ESCREVE
    MOVLW   '>'
    CALL    ESCREVE
    MOVLW   'Z'
    CALL    ESCREVE
    MOVLW   'E'
    CALL    ESCREVE
    MOVLW   'R'
    CALL    ESCREVE
    MOVLW   'A'
    CALL    ESCREVE
    MOVLW   ' '
    CALL    ESCREVE
    MOVLW   'R'
    CALL    ESCREVE
    MOVLW   'E'
    CALL    ESCREVE
    MOVLW   'G'
    CALL    ESCREVE
    MOVLW   'I'
    CALL    ESCREVE
    MOVLW   'S'
    CALL    ESCREVE
    MOVLW   'T'
    CALL    ESCREVE
    MOVLW   'R'
    CALL    ESCREVE
    MOVLW   'O'
    CALL    ESCREVE
    MOVLW   'S'
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0XD4
    CALL    ESCREVE
    BSF	    RS
    
    MOVLW   '-'
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0XDD
    CALL    ESCREVE
    BSF	    RS
    
    MOVLW   'O'
    CALL    ESCREVE
    MOVLW   'K'
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0XE7
    CALL    ESCREVE
    BSF	    RS
    
    MOVLW   '+'
    CALL    ESCREVE
    
    MOVLW   .50
    CALL    DELAY_MILE
    
ESPERA_ESCOLHA_4
    BTFSC   PORTB,RB4  
    GOTO    OPCAO_ANO
    BTFSC   PORTB,RB6
    GOTO    ESPERA_ESCOLHA_4
    BTFSC   PORTB,RB5
    GOTO    QUARTO_MENU
    GOTO    ESPERA_ESCOLHA_4
    
    
PRIMEIRO_MENU
    BSF	    MENU_1
    RETURN
    
SEGUNDO_MENU
    BSF	    MENU_2
    RETURN
TERCEIRO_MENU
    BSF	    MENU_3
    RETURN
QUARTO_MENU
    BSF	    MENU_4
    RETURN
    
MENU_MES
    RETURN
    
MENU_ANO
    RETURN
    
ZERA_EEPROM
    RETURN
    
    
    

  
;*********************************************************
;EXIBE TELA INICIAL DO SISTEMA, COM O INDICE DE CHUVA NO DIA TODO ATE O MOMENTO E O INDICE 
; DAS ULTIMAS SEIS HORAS
; 23/08: 7mm   15:33
; 0-6 : 2mm    12-18: 1mm
; 6-12: 4mm    18-23: 0mm
EXIBE_MENU_HOME  
    BCF	    RS		   
    MOVLW   0xF 
    CALL    ESCREVE         ; LIMPA DISPLAY
    BSF	    RS
    
    BCF	    RS
    MOVLW   0X80          ; DEFINE O CURSOR PARA LINHA 0
    CALL    ESCREVE
    BSF	    RS	
 
    CALL    LER_DIA
    CALL    DIVIDE_POR_10
    MOVLW   0x30
    ADDWF   AUX,W
    CALL    ESCREVE
    MOVLW   0x30
    ADDWF   AUX2,W
    CALL    ESCREVE
   
    MOVLW   '/'
    CALL    ESCREVE
    
    CALL    LER_MES
    CALL    DIVIDE_POR_10 
    MOVLW   0x30
    ADDWF   AUX,W
    CALL    ESCREVE
    MOVLW   0x30
    ADDWF   AUX2,W
    CALL    ESCREVE
    

    BCF	    RS
    MOVLW   0X8F        
    CALL    ESCREVE
    BSF	    RS	
    
    CALL    LER_HORA
    CALL    DIVIDE_POR_10
    MOVLW   0X30
    ADDWF   AUX,W
    CALL    ESCREVE
    MOVLW   0X30
    ADDWF   AUX2,W
    CALL    ESCREVE

    MOVLW   ':'
    CALL    ESCREVE
    
    CALL    LER_MINUTO
    CALL    DIVIDE_POR_10
    MOVLW   0X30
    ADDWF   AUX,W
    CALL    ESCREVE
    MOVLW   0X30
    ADDWF   AUX2,W
    CALL    ESCREVE
    
    CALL    CHUVA_HOJE
    
    BCF	    RS
    MOVLW   0X85        
    CALL    ESCREVE
    BSF	    RS	
    
    MOVLW   ':'
    CALL    ESCREVE
    MOVF    RESULTADO_HIGH,W
    MOVWF   BUFFER_H
    MOVF    RESULTADO_LOW,W
    MOVWF   BUFFER_L
    CALL    CONVERTE_ASCII_LCD
    
    BCF	    RS
    MOVLW   0XC0          
    CALL    ESCREVE
    BSF	    RS	
    
    MOVLW   '0'
    CALL    ESCREVE
    MOVLW   '-'
    CALL    ESCREVE
    MOVLW   '6'
    CALL    ESCREVE
    MOVLW   ' '
    CALL    ESCREVE
    MOVLW   ':'
    CALL    ESCREVE
    
    MOVF    AUX1_LOW,W
    MOVWF   BUFFER_L
    MOVF    AUX1_HIGH,W
    MOVWF   BUFFER_H
    CALL    CONVERTE_ASCII_LCD
    
    BCF	    RS
    MOVLW   0X94         ; DEFINE O CURSOR PARA LINHA 0
    CALL    ESCREVE
    BSF	    RS	
    
    MOVLW   '6'
    CALL    ESCREVE
    MOVLW   '-'
    CALL    ESCREVE
    MOVLW   '1'
    CALL    ESCREVE
    MOVLW   '2'
    CALL    ESCREVE
    MOVLW   ':'
    CALL    ESCREVE
    
    MOVF    AUX2_LOW,W
    MOVWF   BUFFER_L
    MOVF    AUX2_HIGH,W
    MOVWF   BUFFER_H
    CALL    CONVERTE_ASCII_LCD
    
    
    BCF	    RS
    MOVLW   0XCA         ; DEFINE O CURSOR PARA LINHA 0
    CALL    ESCREVE
    BSF	    RS	
    
    MOVLW   '1'
    CALL    ESCREVE
    MOVLW   '2'
    CALL    ESCREVE
    MOVLW   '-'
    CALL    ESCREVE
    MOVLW   '1'
    CALL    ESCREVE
    MOVLW   '8'
    CALL    ESCREVE
    MOVLW   ':'
    CALL    ESCREVE
    
    MOVF    AUX3_LOW,W
    MOVWF   BUFFER_L
    MOVF    AUX3_HIGH,W
    MOVWF   BUFFER_H
    CALL    CONVERTE_ASCII_LCD
    
    BCF	    RS
    MOVLW   0X9E         ; DEFINE O CURSOR PARA LINHA 0
    CALL    ESCREVE
    BSF	    RS	
    
    MOVLW   '1'
    CALL    ESCREVE
    MOVLW   '8'
    CALL    ESCREVE
    MOVLW   '-'
    CALL    ESCREVE
    MOVLW   '2'
    CALL    ESCREVE
    MOVLW   '3'
    CALL    ESCREVE
    MOVLW   ':'
    CALL    ESCREVE
    
    MOVF    AUX4_LOW,W
    MOVWF   BUFFER_L
    MOVF    AUX4_HIGH,W
    MOVWF   BUFFER_H
    CALL    CONVERTE_ASCII_LCD

    BCF	    RS
    MOVLW   0XDC        ; DEFINE O CURSOR PARA LINHA 0
    CALL    ESCREVE
    BSF	    RS	
    
    MOVLW   'M'
    CALL    ESCREVE
    MOVLW   'E'
    CALL    ESCREVE
    MOVLW   'N'
    CALL    ESCREVE
    MOVLW   'U'
    CALL    ESCREVE
    
    RETURN
 
CHUVA_HOJE
    MOVLW   .0
    MOVWF   HORA
    MOVWF   AUX1_LOW
    MOVWF   AUX2_LOW
    MOVWF   AUX3_LOW
    MOVWF   AUX4_LOW
    MOVWF   AUX1_HIGH
    MOVWF   AUX2_HIGH
    MOVWF   AUX3_HIGH
    MOVWF   AUX4_HIGH
    
PRIMEIRO
    MOVLW   .6
    SUBWF   HORA,W
    BTFSC   STATUS,C
    GOTO    SEGUNDO
    
    CALL    ENDERECO_HORA
    CALL    LEITURA_I2C_EEPROM   ;LEITURA DE UM ENDERECO QUALQUER, RETORNA OS 2 BYTES EM BUFFER_L E BUFFER_H
   
    MOVF    AUX1_LOW,W
    MOVWF   BYTE1_LOW
    MOVF    AUX1_HIGH,W
    MOVWF   BYTE1_HIGH
    
    MOVF    BUFFER_L,W
    MOVWF   BYTE2_LOW
    MOVF    BUFFER_H,W
    MOVWF   BYTE2_HIGH
    
    CALL    SOMA_2BYTES
    
    MOVF    RESULTADO_LOW,W
    MOVWF   AUX1_LOW
    MOVF    RESULTADO_HIGH,W
    MOVWF   AUX1_HIGH
    
    INCF    HORA,F
    GOTO    PRIMEIRO
    
SEGUNDO
    MOVLW   .12
    SUBWF   HORA,W
    BTFSC   STATUS,C
    GOTO    TERCEIRO
    
    CALL    ENDERECO_HORA
    CALL    LEITURA_I2C_EEPROM   ;LEITURA DE UM ENDERECO QUALQUER, RETORNA OS 2 BYTES EM BUFFER_L E BUFFER_H
   
    MOVF    AUX2_LOW,W
    MOVWF   BYTE1_LOW
    MOVF    AUX2_HIGH,W
    MOVWF   BYTE1_HIGH
    
    MOVF    BUFFER_L,W
    MOVWF   BYTE2_LOW
    MOVF    BUFFER_H,W
    MOVWF   BYTE2_HIGH
    
    CALL    SOMA_2BYTES
    
    MOVF    RESULTADO_LOW,W
    MOVWF   AUX2_LOW
    MOVF    RESULTADO_HIGH,W
    MOVWF   AUX2_HIGH
    
    INCF    HORA,F
    GOTO    SEGUNDO
    
TERCEIRO
    MOVLW   .18
    SUBWF   HORA,W
    BTFSC   STATUS,C
    GOTO    QUARTO
    
    CALL    ENDERECO_HORA
    CALL    LEITURA_I2C_EEPROM   ;LEITURA DE UM ENDERECO QUALQUER, RETORNA OS 2 BYTES EM BUFFER_L E BUFFER_H
   
    MOVF    AUX3_LOW,W
    MOVWF   BYTE1_LOW
    MOVF    AUX3_HIGH,W
    MOVWF   BYTE1_HIGH
    
    MOVF    BUFFER_L,W
    MOVWF   BYTE2_LOW
    MOVF    BUFFER_H,W
    MOVWF   BYTE2_HIGH
    
    CALL    SOMA_2BYTES
    
    MOVF    RESULTADO_LOW,W
    MOVWF   AUX3_LOW
    MOVF    RESULTADO_HIGH,W
    MOVWF   AUX3_HIGH
    
    INCF    HORA,F
    GOTO    TERCEIRO
    
    
QUARTO
    MOVLW   .24
    SUBWF   HORA,W
    BTFSC   STATUS,C
    GOTO    FINAL_TUDO
    
    CALL    ENDERECO_HORA
    CALL    LEITURA_I2C_EEPROM   ;LEITURA DE UM ENDERECO QUALQUER, RETORNA OS 2 BYTES EM BUFFER_L E BUFFER_H
   
    MOVF    AUX4_LOW,W
    MOVWF   BYTE1_LOW
    MOVF    AUX4_HIGH,W
    MOVWF   BYTE1_HIGH
    
    MOVF    BUFFER_L,W
    MOVWF   BYTE2_LOW
    MOVF    BUFFER_H,W
    MOVWF   BYTE2_HIGH
    
    CALL    SOMA_2BYTES
    
    MOVF    RESULTADO_LOW,W
    MOVWF   AUX4_LOW
    MOVF    RESULTADO_HIGH,W
    MOVWF   AUX4_HIGH
    
    INCF    HORA,F
    GOTO    QUARTO
    
FINAL_TUDO
    
    MOVF    AUX1_LOW,W
    MOVWF   BYTE1_LOW
    MOVF    AUX1_HIGH,W
    MOVWF   BYTE1_HIGH
    
    MOVF    AUX2_LOW,W
    MOVWF   BYTE2_LOW
    MOVF    AUX2_HIGH,W
    MOVWF   BYTE2_HIGH
    
    CALL    SOMA_2BYTES
    
    MOVF    RESULTADO_LOW,W
    MOVWF   BYTE1_LOW
    MOVF    RESULTADO_HIGH,W
    MOVWF   BYTE1_HIGH
    
    MOVF    AUX3_LOW,W
    MOVWF   BYTE2_LOW
    MOVF    AUX3_HIGH,W
    MOVWF   BYTE2_HIGH
    
    CALL    SOMA_2BYTES
    
    MOVF    RESULTADO_LOW,W
    MOVWF   BYTE1_LOW
    MOVF    RESULTADO_HIGH,W
    MOVWF   BYTE1_HIGH
   
    MOVF    AUX4_LOW,W
    MOVWF   BYTE2_LOW
    MOVF    AUX4_HIGH,W
    MOVWF   BYTE2_HIGH
    
    CALL    SOMA_2BYTES
    
    RETURN
    
    
BCD_TO_DEC ;ESPERA QUE VALOR A SER CONVERTIDO ESTEJA NO WORK E RETORNA NO W
    MOVWF   AUX2
    RRF	    AUX2, W 
    ANDLW   B'01111000'  ;W = tens*8 
    MOVWF   AUX
    BCF	    STATUS,C
    RRF	    AUX,F
    RRF	    AUX,F
    SUBWF   AUX2,W
    ADDWF   AUX,W
    
    RETURN 
    

ENDERECO_DIA_MES  ;DIA *2 + 166 + 62(MES - 1) + 732(ANO - 2019)
    MOVF    DIA,W
    CALL    SEPARA_RTC
    MOVLW   .10
    MOVWF   MULTIPLO
    MOVF    DEZENA_RTC,W
    MOVWF   OPERANDO
    CALL    MPY_F
    MOVF    UNIDADE_RTC,W
    ADDWF   L_BYTE,W    ;L_BYTE GUARDA O VALOR DO DIA EM DECIMAL
    MOVWF   AUX
   
    BCF	    STATUS,C
    RLF	    AUX,F   
    MOVLW   .166
    ADDWF   AUX,F  ;AUX = DIA * 2 + 166
   
    DECF    MES,F
    
    ;REALIZA OPERACAO (MES-1)*62
    MOVLW   .62
    MOVWF   MULTIPLO
    MOVF    MES,W
    MOVWF   OPERANDO
    CALL    MPY_F     
    ;H_BYTE E L_BYTE GUARDAM O RESULTADO DA MULTIPLICACAO
    MOVF    H_BYTE,W
    MOVWF   BYTE2_HIGH
    MOVF    L_BYTE,W
    MOVWF   BYTE2_LOW
    
    MOVLW   .0
    MOVWF   BYTE1_HIGH
    MOVF    AUX,W
    MOVWF   BYTE1_LOW
    
    CALL    SOMA_2BYTES
    
    MOVF    RESULTADO_HIGH,W
    MOVWF   ENDERECO_HIGH
    MOVF    RESULTADO_LOW,W
    MOVWF   ENDERECO_LOW
    
    RETURN
    
EXIBE_MENU_MESES ;EXIBE A QUANTIDADE DE GOTAS POR SEMANA EM CADA MES DO CORRENTE ANO
    BCF	    RS		   
    MOVLW   0xF 
    CALL    ESCREVE         ; LIMPA DISPLAY
    BSF	    RS
    
    BCF	    RS
    MOVLW   0X87          ; MOVE O CURSOR
    CALL    ESCREVE
    BSF	    RS	  
    
    MOVLW   'M'
    CALL    ESCREVE
    MOVLW   'E'
    CALL    ESCREVE
    MOVLW   'S'
    CALL    ESCREVE
    MOVLW   ' '
    CALL    ESCREVE
    CALL    LER_MES
    CALL    SEPARA_RTC 
    MOVLW   0x30
    ADDWF   DEZENA_RTC,W
    CALL    ESCREVE
    MOVLW   0x30
    ADDWF   UNIDADE_RTC,W
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0XC0          ; MOVE O CURSOR
    CALL    ESCREVE
    BSF	    RS
    
    CALL    LER_INDICE_SEMANAL
    
    ;EXIBE A QUANTIDADE DE CHUVA NA PRIMEIRA SEMANA DO MES 
    MOVLW   '1'
    CALL    ESCREVE
    MOVLW   ':'
    CALL    ESCREVE
    
    MOVF    SEMANA1_LOW,W
    MOVWF   BUFFER_L
    MOVF    SEMANA1_HIGH,W
    MOVWF   BUFFER_H
    CALL    CONVERTE_ASCII_LCD
    MOVLW   0X00
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0X94          ; MOVE O CURSOR
    CALL    ESCREVE
    BSF	    RS
    
    
    ;EXIBE A QUANTIDADE DE CHUVA NA SEGUNDA SEMANA DO MES 
    MOVLW   '2'
    CALL    ESCREVE
    MOVLW   ':'
    CALL    ESCREVE
    
    MOVF    SEMANA2_LOW,W
    MOVWF   BUFFER_L
    MOVF    SEMANA2_HIGH,W
    MOVWF   BUFFER_H
    CALL    CONVERTE_ASCII_LCD
    MOVLW   0X00
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0XCD          ; MOVE O CURSOR
    CALL    ESCREVE
    BSF	    RS
    
    ;EXIBE A QUANTIDADE DE CHUVA NA TERCEIRA SEMANA DO MES 
    MOVLW   '3'
    CALL    ESCREVE
    MOVLW   ':'
    CALL    ESCREVE
    
    MOVF    SEMANA3_LOW,W
    MOVWF   BUFFER_L
    MOVF    SEMANA3_HIGH,W
    MOVWF   BUFFER_H
    CALL    CONVERTE_ASCII_LCD
    MOVLW   0X00
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0XA1         ; MOVE O CURSOR
    CALL    ESCREVE
    BSF	    RS
    
    
    ;EXIBE A QUANTIDADE DE CHUVA NA SEGUNDA SEMANA DO MES 
    MOVLW   '4'
    CALL    ESCREVE
    MOVLW   ':'
    CALL    ESCREVE
    
    MOVF    SEMANA4_LOW,W
    MOVWF   BUFFER_L
    MOVF    SEMANA4_HIGH,W
    MOVWF   BUFFER_H
    CALL    CONVERTE_ASCII_LCD
    MOVLW   0X00
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0XD4          ; MOVE O CURSOR
    CALL    ESCREVE
    BSF	    RS
    MOVLW   '<'
    CALL    ESCREVE
    MOVLW   '-'
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0XDC          ; MOVE O CURSOR
    CALL    ESCREVE
    BSF	    RS
    MOVLW   'H'
    CALL    ESCREVE
    MOVLW   'O'
    CALL    ESCREVE
    MOVLW   'M'
    CALL    ESCREVE
    MOVLW   'E'
    CALL    ESCREVE
    
    BCF	    RS
    MOVLW   0XE6          ; MOVE O CURSOR
    CALL    ESCREVE
    BSF	    RS
    
    MOVLW   '-'
    CALL    ESCREVE
    MOVLW   '>'
    CALL    ESCREVE
    
    RETURN

LER_INDICE_SEMANAL ; ESPERA QUE O MES DESEJADO ESTEJA EM MES, RETORNA A QUANTIDADE DE GOTAS NAS VARIAVEIS SEMANA1
;SEMANA2,SEMANA3,SEMANA4
    ;INICIANDO LEITURA DOS VALORES DA PRIMEIRA SEMANA DO MES DESEJADO
    MOVLW   .0
    MOVWF   BYTE1_LOW
    MOVWF   BYTE1_HIGH

    MOVLW   .7
    MOVWF   DIA
    
LACO
    CALL    ENDERECO_DIA_MES ;CALCULA O ENDERECO DO DIA NO MES DESEJADO E RETORNA EM ENDERECO_HIGH ENDERECO_LOW
    CALL    LEITURA_I2C_EEPROM

    MOVF    BUFFER_L, W
    MOVWF   BYTE2_LOW
    MOVF    BUFFER_H, W
    MOVWF   BYTE2_HIGH
    
    CALL    SOMA_2BYTES

    MOVF    RESULTADO_LOW,W
    MOVWF   BYTE1_LOW
    MOVF    RESULTADO_HIGH,W
    MOVWF   BYTE1_HIGH
    
    DECFSZ  DIA,F
    GOTO    LACO
    MOVF    BYTE1_LOW,W
    MOVWF   SEMANA1_LOW
    MOVF    BYTE1_HIGH,W
    MOVWF   SEMANA1_HIGH
    
    ;INICIO DA SEMANA2
    
    MOVLW   .0
    MOVWF   BYTE1_LOW
    MOVWF   BYTE1_HIGH

    MOVLW   .14
    MOVWF   DIA
    
LACO2
    CALL    ENDERECO_DIA_MES ;CALCULA O ENDERECO DO DIA NO MES DESEJADO E RETORNA EM ENDERECO_HIGH ENDERECO_LOW
    CALL    LEITURA_I2C_EEPROM

    MOVF    BUFFER_L, W
    MOVWF   BYTE2_LOW
    MOVF    BUFFER_H, W
    MOVWF   BYTE2_HIGH
    
    CALL    SOMA_2BYTES

    MOVF    RESULTADO_LOW,W
    MOVWF   BYTE1_LOW
    MOVF    RESULTADO_HIGH,W
    MOVWF   BYTE1_HIGH
    
    DECF    DIA,F
    MOVLW   .7
    SUBWF   DIA,W   ;DIA - 7
    BTFSS   STATUS,Z
    GOTO    LACO2
    MOVF    BYTE1_LOW,W
    MOVWF   SEMANA2_LOW
    MOVF    BYTE1_HIGH,W
    MOVWF   SEMANA2_HIGH
    
    ;INICIO SEMANA 3
    MOVLW   .0
    MOVWF   BYTE1_LOW
    MOVWF   BYTE1_HIGH

    MOVLW   .21
    MOVWF   DIA
    
LACO3
    CALL    ENDERECO_DIA_MES ;CALCULA O ENDERECO DO DIA NO MES DESEJADO E RETORNA EM ENDERECO_HIGH ENDERECO_LOW
    CALL    LEITURA_I2C_EEPROM

    MOVF    BUFFER_L, W
    MOVWF   BYTE2_LOW
    MOVF    BUFFER_H, W
    MOVWF   BYTE2_HIGH
    
    CALL    SOMA_2BYTES

    MOVF    RESULTADO_LOW,W
    MOVWF   BYTE1_LOW
    MOVF    RESULTADO_HIGH,W
    MOVWF   BYTE1_HIGH
    
    DECF    DIA,F
    MOVLW   .14
    SUBWF   DIA,W   ;DIA - 14
    BTFSS   STATUS,Z
    GOTO    LACO3
    MOVF    BYTE1_LOW,W
    MOVWF   SEMANA3_LOW
    MOVF    BYTE1_HIGH,W
    MOVWF   SEMANA3_HIGH
    
    ;INICIO SEMANA 4
    MOVLW   .0
    MOVWF   BYTE1_LOW
    MOVWF   BYTE1_HIGH

    ;VERICANDO SE O MES DESEJADO É DE 30, 31 OU 28 DIAS
    
    MOVLW   .31
    MOVWF   DIA
    BCF	    STATUS,C
    RRF	    MES,W ;DIVIDE O DIA POR 2
    BTFSC   STATUS,C 
    CALL    DIA_30
    
    ;CHECA SE É FEVEREIRO
    MOVF    MES,W
    SUBLW   .2
    BTFSC   STATUS,Z
    CALL    DIA_29
    
LACO4
    CALL    ENDERECO_DIA_MES ;CALCULA O ENDERECO DO DIA NO MES DESEJADO E RETORNA EM ENDERECO_HIGH ENDERECO_LOW
    CALL    LEITURA_I2C_EEPROM

    MOVF    BUFFER_L, W
    MOVWF   BYTE2_LOW
    MOVF    BUFFER_H, W
    MOVWF   BYTE2_HIGH
    
    CALL    SOMA_2BYTES

    MOVF    RESULTADO_LOW,W
    MOVWF   BYTE1_LOW
    MOVF    RESULTADO_HIGH,W
    MOVWF   BYTE1_HIGH
    
    DECF    DIA,F
    MOVLW   .21
    SUBWF   DIA,W   ;DIA - 14
    BTFSS   STATUS,Z
    GOTO    LACO4
    MOVF    BYTE1_LOW,W
    MOVWF   SEMANA4_LOW
    MOVF    BYTE1_HIGH,W
    MOVWF   SEMANA4_HIGH
    
    RETURN
    
DIA_29
    MOVLW   .29
    MOVWF   DIA
    RETURN
    
DIA_30
    MOVLW   .30
    MOVWF   DIA
    RETURN
    
    
MIN_59   ;COMO É EXIBIDO O MINUTO ANTERIOR PRECISAMOS EXIBIR 59 QUANDO FOR LIDO 00
    MOVLW   '5'
    CALL    ESCREVE
    MOVLW   '9'
    CALL    ESCREVE
    
    RETURN

EXIBE_DIA
    CALL    LER_DIA
    CALL    ENDERECO_DIA
    
EXIBE_MINUTO
    	CALL	LER_MINUTO
	MOVF	MINUTO,W
	MOVLW	.0
	SUBWF	MINUTO,W
	BTFSC	STATUS,Z
	GOTO	MINUTO_59
	DECF	MINUTO_ANTERIOR,F
	MOVF	MINUTO_ANTERIOR,W
	MOVWF	MINUTO
SALTO
	CALL	ENDERECO_MINUTO
	CALL	LEITURA_I2C_EEPROM
	;SEPARA PARTE HIGH
	MOVF	BUFFER_H,W
	MOVWF   UNIDADE_RTC
	MOVWF   DEZENA_RTC
	SWAPF   DEZENA_RTC,F  ;INVERTE OS NIBBLES
	BCF	UNIDADE_RTC,7
	BCF     UNIDADE_RTC,6
	BCF     UNIDADE_RTC,5
	BCF     UNIDADE_RTC,4
	BCF     DEZENA_RTC,7
	BCF	DEZENA_RTC,6
	BCF     DEZENA_RTC,5
	BCF     DEZENA_RTC,4
	
	MOVF	DEZENA_RTC,W
	MOVWF	AUX
	MOVLW	.10
	SUBWF	AUX,W  ; AUX - 10
	BTFSC	STATUS, C   ; C = 0 NEGATIVO
	CALL	MAIOR_QUE
	BTFSS	STATUS, C
	CALL	MENOR_QUE
	
	MOVF	UNIDADE_RTC,W
	MOVWF	AUX
	MOVLW	.10
	SUBWF	AUX,W  ; AUX - 10
	BTFSC	STATUS, C   ; C = 0 NEGATIVO
	CALL	MAIOR_QUE
	BTFSS	STATUS, C
	CALL	MENOR_QUE
	
	
	;SEPARA PARTE BAIXA
	MOVF	BUFFER_L,W
	MOVWF   UNIDADE_RTC
	MOVWF   DEZENA_RTC
	SWAPF   DEZENA_RTC,F  ;INVERTE OS NIBBLES
	BCF	UNIDADE_RTC,7
	BCF     UNIDADE_RTC,6
	BCF     UNIDADE_RTC,5
	BCF     UNIDADE_RTC,4
	BCF     DEZENA_RTC,7
	BCF	DEZENA_RTC,6
	BCF     DEZENA_RTC,5
	BCF     DEZENA_RTC,4
	
	MOVF	DEZENA_RTC,W
	MOVWF	AUX
	MOVLW	.10
	SUBWF	AUX,W  ; AUX - 10
	BTFSC	STATUS, C   ; C = 0 NEGATIVO
	CALL	MAIOR_QUE
	BTFSS	STATUS, C
	CALL	MENOR_QUE
	
	MOVF	UNIDADE_RTC,W
	MOVWF	AUX
	MOVLW	.10
	SUBWF	AUX,W  ; DEZENA - 10
	BTFSC	STATUS, C   ; C = 0 NEGATIVO
	CALL	MAIOR_QUE
	BTFSS	STATUS, C
	CALL	MENOR_QUE
	
	RETURN
MINUTO_59
	MOVLW	B'01011001'
	MOVWF	MINUTO
	
	GOTO	SALTO

CONVERTE_ASCII_LCD  ;CONVERTE OS VALORES DE BUFFER_H e BUFFER_L PARA EXIBIÇÃO NO LCD
	MOVF	BUFFER_H,W
	MOVWF   UNIDADE_RTC
	MOVWF   DEZENA_RTC
	SWAPF   DEZENA_RTC,F  ;INVERTE OS NIBBLES
	BCF	UNIDADE_RTC,7
	BCF     UNIDADE_RTC,6
	BCF     UNIDADE_RTC,5
	BCF     UNIDADE_RTC,4
	BCF     DEZENA_RTC,7
	BCF	DEZENA_RTC,6
	BCF     DEZENA_RTC,5
	BCF     DEZENA_RTC,4
	
	MOVF	DEZENA_RTC,W
	MOVWF	AUX
	MOVLW	.10
	SUBWF	AUX,W  ; AUX - 10
	BTFSC	STATUS, C   ; C = 0 NEGATIVO
	CALL	MAIOR_QUE
	BTFSS	STATUS, C
	CALL	MENOR_QUE
	
	MOVF	UNIDADE_RTC,W
	MOVWF	AUX
	MOVLW	.10
	SUBWF	AUX,W  ; AUX - 10
	BTFSC	STATUS, C   ; C = 0 NEGATIVO
	CALL	MAIOR_QUE
	BTFSS	STATUS, C
	CALL	MENOR_QUE
	
	;SEPARA PARTE BAIXA
	MOVF	BUFFER_L,W
	MOVWF   UNIDADE_RTC
	MOVWF   DEZENA_RTC
	SWAPF   DEZENA_RTC,F  ;INVERTE OS NIBBLES
	BCF	UNIDADE_RTC,7
	BCF     UNIDADE_RTC,6
	BCF     UNIDADE_RTC,5
	BCF     UNIDADE_RTC,4
	BCF     DEZENA_RTC,7
	BCF	DEZENA_RTC,6
	BCF     DEZENA_RTC,5
	BCF     DEZENA_RTC,4
	
	MOVF	DEZENA_RTC,W
	MOVWF	AUX
	MOVLW	.10
	SUBWF	AUX,W  ; AUX - 10
	BTFSC	STATUS, C   ; C = 0 NEGATIVO
	CALL	MAIOR_QUE
	BTFSS	STATUS, C
	CALL	MENOR_QUE
	
	MOVF	UNIDADE_RTC,W
	MOVWF	AUX
	MOVLW	.10
	SUBWF	AUX,W  ; DEZENA - 10
	BTFSC	STATUS, C   ; C = 0 NEGATIVO
	CALL	MAIOR_QUE
	BTFSS	STATUS, C
	CALL	MENOR_QUE
	
	RETURN
	
MENOR_QUE   ;SOMAR 0X30 CASO O NUMERO SEJA MENOR QUE 10
	MOVLW	0X30
	ADDWF	AUX,W
	CALL	ESCREVE
	RETURN

MAIOR_QUE  ; SOMA OX37 CASO O NUMERO SEJA MAIOR	
	MOVLW	.55
	ADDWF	AUX,W
	CALL	ESCREVE
	BSF	STATUS,C
	RETURN
	
ZERA_MINUTO     ;ZERA AS 60 POSICOES REFERENTES AO MINUTO
	BANK0
	MOVLW	B'00000000'
	MOVWF	ENDERECO_HIGH
	MOVWF	ENDERECO_LOW
	
LOOP1
	MOVLW	.118
	SUBWF	ENDERECO_LOW,W
	BTFSC	STATUS,Z
	RETURN
	
	MOVLW	.0
	MOVWF	DADO_L
	MOVWF	DADO_H
	CALL	ESCRITA_I2C_EEPROM
	MOVLW	.1
	CALL	DELAY_MILE
	INCF	ENDERECO_LOW,F
	GOTO	LOOP1
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIO DO PROGRAMA                          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
INICIO
	BANK1		        ;ALTERA PARA O BANCO 1
	MOVLW	B'00000001'     ;CONFIGURA TODAS AS PORTAS DO TRISA (PINOS)
	MOVWF	TRISA	
	MOVLW	B'11111110'     ;CONFIGURA TODAS AS PORTAS DO TRISB (PINOS)
	MOVWF	TRISB	
	MOVLW	B'00011000'     ;CONFIGURA TODAS AS PORTAS DO TRISC (PINOS)
	MOVWF	TRISC
	MOVLW	B'00000000'     ;CONFIGURA TODAS AS PORTAS DO TRISD (PINOS)
	MOVWF	TRISD
	MOVLW	B'00000000'     ;CONFIGURA TODAS AS PORTAS DO TRISE (PINOS)
	MOVWF	TRISE
	MOVLW	B'10000000'
	MOVWF	OPTION_REG	;DEFINE OPÇÕES DE OPERAÇÃO
	MOVLW	B'10001000'
	MOVWF	INTCON		;DEFINE OPÇÕES DE INTERRUPÇÕES
					;RETORNA PARA O BANCO
	MOVLW	B'00010110'
	MOVWF	CMCON		;DEFINE O MODO DE OPERAÇÃO DO COMPARADOR ANALÓGICO
	MOVLW	B'11101001'    ;INICIA VRCON COM 9, TENSAO DE 1.85 V 
	MOVWF	CVRCON
	
	MOVLW	B'00110001'    ; VALOR 49 PRO SSPADD DEFINE VELOCIDADE DE 100 KHZ PARA COMUNICACAO I2C
	MOVWF	SSPADD	                                                                                        
	MOVLW	B'00000000'   
	MOVWF	SSPSTAT

	BSF	SCL
	CLRF	SSPCON2

	BANK0
	MOVLW	B'00101000'   ;Inicia I2C COMO MASTER
	MOVWF	SSPCON
	
	MOVLW	B'00110000'
	MOVWF	T1CON
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIALIZAÇÃO DAS VARIÁVEIS                 *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ROTINA PRINCIPAL                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
MAIN 
	;CALL	ZERA_EEPROM
	CALL    INICIALIZA_DISPLAY
	;CALL	CARACTER_GOTA
	CALL	EXIBE_MENU_HOME
	;CALL	SELECAO_DIA
	
	
	;CALL	EXIBE_MENU_MESES
	GOTO	FIM
START   
	;LEITURA INICIAL DO RTC
	CALL	LER_MINUTO
	MOVF	MINUTO,W
	MOVWF	MINUTO_ANTERIOR
	
	CALL	LER_HORA
	MOVF	HORA,W
	MOVWF	HORA_ANTERIOR
	
	CALL	LER_DIA
	MOVF	DIA,W
	MOVWF	DIA_ANTERIOR

	CALL	LER_MES
	MOVF	MES,W
	MOVWF	MES_ANTERIOR 
	
	MOVLW	.10
	MOVWF	AUX
	CALL	CONTA_GOTA   ;CONTA O NUMERO DE GOTAS DURANTE AUX*0.5s
	
	;VERIFICA SE O MINUTO ATUAL É IGUAL AO MINUTO LIDO ANTERIORMENTE
	CALL	LER_MINUTO
	MOVF	MINUTO,W
	SUBWF	MINUTO_ANTERIOR,W
	BTFSC	STATUS,Z          ; Z = 1 MINUTOS IGUAIS
	GOTO	MIN_ANTERIOR   ;GRAVA O VALOR DE GOTAS NO MINUTO ANTERIOR
	GOTO	MIN_ATUAL
MIN_ANTERIOR	;FAZ O MINUTO ATUAL SER O MINUTO ANTERIOR
	MOVF	MINUTO_ANTERIOR,W
	MOVWF	MINUTO
MIN_ATUAL
	;GRAVACAO NO MINUTO ATUAL
	CALL	ENDERECO_MINUTO     ;CALCULO DO ENDERECO DA EEPROM REFERENTE AO MINUTO 
	CALL	LEITURA_I2C_EEPROM  ;LENDO OS DADOS DA EEPROM NA POSICAO REFERENTE AO MINUTO
	;RETORNA EM BUFFER_L E BUFFER_H
	MOVF	BUFFER_H,W
	MOVWF	BYTE1_HIGH
	MOVF	BUFFER_L,W
	MOVWF	BYTE1_LOW
	MOVLW	.0
	MOVWF	BYTE2_HIGH
	MOVF	GOTAS,W
	MOVWF   BYTE2_LOW
	
	CALL	SOMA_2BYTES  ;RETORNA EM RESULTADO_LOW E RESULTADO_HIGH
	
	MOVF	RESULTADO_HIGH,W
	MOVWF	DADO_H
	MOVF	RESULTADO_LOW,W
	MOVWF	DADO_L
	
	CALL	ENDERECO_MINUTO
	;ESCREVE NA POSICAO DE MEMORIA CALCULADA ANTERIORMENTE OS VALORES DE DADO_H E DADO_L
	CALL	ESCRITA_I2C_EEPROM 
	
	MOVLW	.2
	CALL	DELAY_MILE
	
	;ATUALIZA VALOR EM HORAS SE HOUVE MUDANCA DE HORA
	CALL	LER_HORA
	MOVF	HORA,W
	SUBWF	HORA_ANTERIOR,W
	BTFSS	STATUS,Z          ; Z = 1 HORAS IGUAIS
	CALL	GRAVA_EM_HORA   ;GRAVA O VALOR DE GOTAS NA HORA ANTERIOR
	
	;ATUALIZA VALOR EM DIAS SE HOUVE MUDANCA DE DIA
	MOVLW	.3
	MOVWF	DIA_ANTERIOR
	CALL	LER_DIA
	MOVF	DIA,W
	SUBWF	DIA_ANTERIOR,W
	BTFSS	STATUS,Z
	CALL	GRAVA_EM_DIA
	
	
	;ATUALIZA O VALOR NO LCD
	
	CALL	EXIBE_MENU
	
	BCF	RS
	MOVLW   0XC1           ; DEFINE O CURSOR PARA LINHA 1
	CALL    ESCREVE
	BSF	RS
	
	CALL	EXIBE_MINUTO
	
	GOTO	START
	
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       FIM DO PROGRAMA                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
FIM
	
	;GARANTE QUE AS POSICOES DA EEPROM EXTERNA SEJAM ZERADAS PELA PRIMEIRA VEZ
	;POSICAO 0X7FFE DA EEPROM FOI UTILIZADA COMO INDICADOR
	;MOVLW	B'01111111'
	;MOVWF	ENDERECO_HIGH
	;MOVLW	B'11111110'
	;MOVWF	ENDERECO_LOW
	;CALL	LEITURA_I2C_EEPROM
	;MOVF	BUFFER_L,W
	
	;SUBLW	.255
	;BTFSS	STATUS,Z  ;VERIFICA SE HÁ FF NA POSICAO 0X7FFE
	;GOTO	START	  
	;CALL	ZERA_EEPROM  ;SE HÁ FF, LIMPA A EEPROM
	;CALL	DELAY_1SEGUNDO
	
	;GRAVA ZERO NA POSICAO 0X7FFE
	;MOVLW	B'01111111'
	;MOVWF	ENDERECO_HIGH
	;MOVLW	B'11111110'
	;MOVWF	ENDERECO_LOW
	;MOVLW	.0
	;MOVWF	DADO_H
	;MOVWF	DADO_L
	;CALL	ESCRITA_I2C_EEPROM
	;NOP
	
	
	GOTO	FIM
	
	;FUNCOES PRONTAS
CARACTER_GOTA
    ;DESENHANDO UM CARACTER NO LCD
    ;MANDAR COMANDO 01000000 PARA ACESSAR A CGRAM
    BCF	    RS
    MOVLW   B'01000000'
    CALL    ESCREVE
    BSF	    RS	
    
    ;MANDA BYTES REFERENTES AO DESENHO
    MOVLW   B'00000100'
    CALL    ESCREVE
    MOVLW   B'00001110'
    CALL    ESCREVE
    MOVLW   B'00001110'
    CALL    ESCREVE
    MOVLW   B'00011111'
    CALL    ESCREVE
    MOVLW   B'00011101'
    CALL    ESCREVE
    MOVLW   B'00011011'
    CALL    ESCREVE
    MOVLW   B'00001110'
    CALL    ESCREVE
    
    RETURN
 

    
LOOP  
    ;VERIFICA CONDICAO DE SAIDA, ZERA ATE 3FF
    MOVLW   .4
    SUBWF   ENDERECO_HIGH,W
    BTFSC   STATUS,Z
    RETURN
    MOVLW   .0
    MOVWF   DADO_L
    MOVWF   DADO_H
    CALL    ESCRITA_I2C_EEPROM
    BANK0
    MOVLW   .1
    CALL    DELAY_MILE
    
    MOVLW   .1
    BSF	    STATUS,C
    ADDWF   ENDERECO_LOW,F
    BTFSS   STATUS,C ;VERIFICA SE HOUVE ESTOURO
    GOTO    LOOP
    INCF    ENDERECO_HIGH,F
    GOTO    LOOP
    RETURN
    
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;            ROTINAS REFERENTES AO PROTOCOLO I2C                  *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *	
AGUARDA_I2C  ;ESPERA O BARRAMENTO FICAR LIVRE
	BANK1
	BTFSC	SSPSTAT, R_W
	GOTO	$-1
	MOVF	SSPCON2, W
	ANDLW	B'00011111'  ;VERIFICA SE A AND DA MASCARA COM SSPCON2 DEU ZERO
	BTFSS	STATUS, Z
	GOTO	$-3
        RETURN

VERIFICA_ACK
	BANK1
	BTFSC	SSPCON2, ACKSTAT
	GOTO	NAO_ACK   ;NÃO FOI RECEBIDO O ACK
	BANK0
	BCF	F_ERRO    ;FOI RECEBIDO, FLAG DE ERRO É LIMPA
	RETURN
	
NAO_ACK
	BANK0
	BSF	F_ERRO ; INDICA ERRO POR NAO RECEBIMENTO DO ACK
	RETURN

STOP_BIT	;INICIA STOP BIT
	BANK1
	BSF	SSPCON2, PEN
	RETURN
	
START_BIT
	BANK1
	CALL	AGUARDA_I2C
	BSF	SSPCON2, SEN    ; INICIA START BIT
	RETURN
	
I2C_ERRO
	BANK1
	BSF	SSPCON2,PEN
	BANK0
	BSF	PORTB, RB4  ;ACENDE LED PARA INDICAR ERRO
	RETURN
	
NACK_OUT
	BANK1
	BSF	SSPCON2, ACKDT
	BSF	SSPCON2, ACKEN
	RETURN
;ESCREVE NO ENDERECO PASSADO E NO SUBSEQUENTE
ESCRITA_I2C_EEPROM  ;ESCREVE NA EEPROM
	CALL	START_BIT
	CALL	AGUARDA_I2C
	BANK0   ; VARIAVEIS ESTÃO NO BANK0
	MOVLW	B'10100000' ;ENDEREÇO DA EEPROM EXTERNA + COMANDO DE ESCRITA
	MOVWF	SSPBUF
	CALL	AGUARDA_I2C
	CALL	VERIFICA_ACK
	BTFSC	F_ERRO
	GOTO	I2C_ERRO
	
	BANK0  ;ENVIO DA PARTE ALTA DO ENDERECO DE MEMORIA A SER ESCRITO
	MOVF	ENDERECO_HIGH,W
	MOVWF	SSPBUF
	CALL	AGUARDA_I2C
	CALL	VERIFICA_ACK
	BTFSC	F_ERRO
	GOTO	I2C_ERRO
	
	BANK0  ;ENVIA A PARTE BAIXA DO ENDERECO
	MOVF	ENDERECO_LOW,W
	MOVWF	SSPBUF
	CALL	AGUARDA_I2C
	CALL	VERIFICA_ACK
	BTFSC	F_ERRO
	GOTO	I2C_ERRO
	
	BANK0   ;ENVIA O DADO_H A SER GRAVADO
	MOVF	DADO_H,W
	MOVWF	SSPBUF
	CALL	AGUARDA_I2C
	CALL	VERIFICA_ACK
	BTFSC	F_ERRO
	GOTO	I2C_ERRO
	
	BANK0   ;ENVIA O DADO_L A SER GRAVADO
	MOVF	DADO_L,W
	MOVWF	SSPBUF
	CALL	AGUARDA_I2C
	CALL	VERIFICA_ACK
	BTFSC	F_ERRO
	GOTO	I2C_ERRO
	
	CALL	STOP_BIT
	
	BANK0
	RETURN

;LER O ENDERECO PASSADO E O SUBSEQUENTE
LEITURA_I2C_EEPROM   ;LEITURA DE UM ENDERECO QUALQUER, RETORNA OS 2 BYTES EM BUFFER_L E BUFFER_H
	CALL	START_BIT
	CALL	AGUARDA_I2C
	BANK0
	MOVLW	B'10100000' ;ENVIA O ENDERECO DE CONTROLE DA EEPROM + COMANDO DE ESCRITA
	MOVWF	SSPBUF
	CALL	AGUARDA_I2C
	CALL	VERIFICA_ACK
	BTFSC	F_ERRO
	GOTO	I2C_ERRO
	
	BANK0   ;ENVIA ENDERECO HIGH
	MOVF	ENDERECO_HIGH,W
	MOVWF	SSPBUF
	CALL	AGUARDA_I2C
	CALL	VERIFICA_ACK
	BTFSC	F_ERRO
	GOTO	I2C_ERRO
	
	BANK0   ;ENVIA ENDERECO LOW
	MOVF	ENDERECO_LOW,W
	MOVWF	SSPBUF
	CALL	AGUARDA_I2C
	CALL	VERIFICA_ACK
	BTFSC	F_ERRO
	GOTO	I2C_ERRO
	
	BANK1  ;ENVIA RESTART BIT
	BSF	SSPCON2, RSEN
	CALL	AGUARDA_I2C
	
	BANK0  ; ENVIA BYTE DE CONTROLE + COMANDO DE LEITURA
	MOVLW	B'10100001'
	MOVWF	SSPBUF
	CALL	AGUARDA_I2C
	CALL	VERIFICA_ACK
	BTFSC	F_ERRO
	GOTO	I2C_ERRO
	
	BANK1  ;INICIA LEITURA DO BYTE
	BSF	SSPCON2, RCEN
	CALL	AGUARDA_I2C
	BANK0
	MOVF	SSPBUF,W
	MOVWF	BUFFER_H
	
	CALL	NACK_OUT
	CALL	AGUARDA_I2C
	CALL	STOP_BIT
	CALL	AGUARDA_I2C
	BANK0
    
	;LER O QUE TIVER NO ENDERECO ATUAL
	CALL	START_BIT
	CALL	AGUARDA_I2C
	BANK0  ; ENVIA BYTE DE CONTROLE + COMANDO DE LEITURA
	MOVLW	B'10100001'
	MOVWF	SSPBUF
	CALL	AGUARDA_I2C
	CALL	VERIFICA_ACK
	BTFSC	F_ERRO
	GOTO	I2C_ERRO
	
	BANK1  ;INICIA LEITURA DO BYTE
	BSF	SSPCON2, RCEN
	CALL	AGUARDA_I2C
	BANK0
	MOVF	SSPBUF,W
	MOVWF	BUFFER_L
	
	CALL	NACK_OUT
	CALL	AGUARDA_I2C
	CALL	STOP_BIT
	CALL	AGUARDA_I2C
	BANK0
	
	RETURN
	
ESCRITA_I2C_RTC  ;GRAVA NO RTC
	CALL	START_BIT   ;INICIA COMUNICACAO
	CALL	AGUARDA_I2C
	MOVLW	B'11010000'  ;PASSA O ENDERECO DO RTC (1101000) + COMANDO DE ESCRITA
	MOVWF	SSPBUF
	CALL	AGUARDA_I2C
	CALL	VERIFICA_ACK
	BTFSC	F_ERRO
	GOTO	I2C_ERRO
	
	BANK0	;ENVIO ENDERECO A SER ESCRITO
	MOVF	ENDERECO_RTC,W
	MOVWF	SSPBUF
	CALL	AGUARDA_I2C
	CALL	VERIFICA_ACK
	BTFSC	F_ERRO
	GOTO	I2C_ERRO
	
	BANK0	;ENVIA DADO EM BCD A SER GRAVADO
	MOVF	DADO_RTC,W
	MOVWF	SSPBUF
	CALL	AGUARDA_I2C
	CALL	VERIFICA_ACK
	BTFSC	F_ERRO
	GOTO	I2C_ERRO
	CALL	STOP_BIT
	BANK0
	RETURN

LEITURA_I2C_RTC ;LER O RTC
	CALL	START_BIT   ;INICIA COMUNICACAO
	CALL	AGUARDA_I2C
	BANK0
	MOVLW	B'11010000' ;PASSA O ENDERECO DO RTC + COMANDO ESCRITA
	MOVWF	SSPBUF
	CALL	AGUARDA_I2C ;AGUARDA E VERIFICA SE A COMUNICAO OCORREU SEM ERRO
	CALL	VERIFICA_ACK
	BTFSC	F_ERRO
	GOTO	I2C_ERRO
	
	BANK0   ;ENVIA ENDERECO DE LEITURA
	MOVF	ENDERECO_RTC,W ; ENDERECO ENTRE 0X0 E 0X7
	MOVWF	SSPBUF
	CALL	AGUARDA_I2C
	CALL	VERIFICA_ACK
	BTFSC	F_ERRO
	GOTO	I2C_ERRO
	
	BANK1   ;ENVIA RE STARTBIT
	BSF	SSPCON2, RSEN
	CALL	AGUARDA_I2C
	
	BANK0	;ENVIA ENDERECO DO RTC + COMANDO DE LEITURA
	MOVLW	B'11010001'
	MOVWF	SSPBUF
	CALL	AGUARDA_I2C
	CALL	VERIFICA_ACK
	BTFSC	F_ERRO
	GOTO	I2C_ERRO
	
	BANK1	;INICIA LEITURA DO DADO
	BSF	SSPCON2, RCEN
	CALL	AGUARDA_I2C
	BANK0
	MOVF	SSPBUF,W
	MOVWF	SAIDA_RTC
	CALL	NACK_OUT
	CALL	AGUARDA_I2C
	CALL	STOP_BIT
	CALL	AGUARDA_I2C
	
	BANK0
	
	RETURN
	
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;	ROTINA DE DELAY_MILE    (1 ~ 256)MILESSEGUNDOS)    	  *
;       ROTINA DE DELAY_MICRO   (1 ~ 256)MICROSSEGUNDOS)          *
;       ROTINA DE DELAY_1SEGUNDO(1)      SEGUNDO                  *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;VALOR PASSADO EM WORK(W) DEFINE O DELAY            			  ;
    
DELAY_MILE
    MOVWF   TEMPO1		    ; CARREGA EM TEMPO_1 ATE AONDE VAI ESPERAR
VOLTA
    MOVLW   .5
    MOVWF   AUX_TEMP        ; TEMPORIZADOR AUXILIAR PARA COMPENSAÇÃO DO OCILADOR
    MOVLW   .250		    
    MOVWF   TEMPO0		    ; CARREGA EM TEMPO_0 1MS
    NOP
    DECFSZ  TEMPO0,F		; SE PASSOU 1MS?
    GOTO    $-2			    ; NÃO, VOLTA
    DECFSZ  AUX_TEMP,F
    GOTO    $-6
    DECFSZ  TEMPO1,F		; SE PASSOU O TEMPO DESEJADO?
    GOTO    VOLTA		    ; NÃO, ESPERA POR MAIS 1MS
    RETURN
    
DELAY_MICRO
    MOVWF   TEMPO0		    ; CARREGA EM TEMPO_1 ATE AONDE VAI ESPERAR
    NOP
    NOP
    DECFSZ  TEMPO0,F		; SE PASSOU O TEMPO?
    GOTO    $-3 			; NÃO, VOLTA
    RETURN

DELAY_1SEGUNDO
    MOVLW   .240
    CALL    DELAY_MILE
    MOVLW   .240
    CALL    DELAY_MILE
    MOVLW   .240
    CALL    DELAY_MILE
    MOVLW   .240
    CALL    DELAY_MILE
    RETURN
    
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;                      ROTINA DE MULTIPLICAÇÃO                 	  *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;                     8x8 SOFTWARE MULTIPLIER                     *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;       OS 16 BITS DE RESULTADO, SÃO ARMAZENADOS EM 2 BYTES       *
;ANTES DE CHAMAR A SUB-ROTINA "mpy", DEVEMOS CARREGAR LOCALMENTE  *
;"mulplr", E O MULTIPLICADOR EM "mulcnd" . O RESULTADO EM 16 BITS,*
;SERA ARMAZENADO EM H_byte E l_byte.                              *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DA MACRO DE ADIÇÃO E SHIFT                            *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
MULT    MACRO   BIT                            ;INICIO DA MACRO
    
    BTFSC   MULTIPLO,BIT                          ;MAPEIA O MULTIPLICADOR
    ADDWF   H_BYTE,F
    RRF     H_BYTE,F
    RRF     L_BYTE,F
    
    ENDM                                        ;FIM DA MACRO
    
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; INICIO DA SUBROTINA DE MULTIPLICAÇÃO                            *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
MPY_F
    CLRF    H_BYTE
    CLRF    L_BYTE
    MOVFW   OPERANDO                                ; MOVE O MULTIPLICA PARA W
    BCF     STATUS,C                              ; LIMPA O CARRY
    
    MULT    0
    MULT    1
    MULT    2
    MULT    3
    MULT    4
    MULT    5
    MULT    6
    MULT    7
    
    RETURN
    

    
OVERFLOW   ;VERIFICA SE HOUVE OVERFLOW NA SOMA
    MOVLW   .1
    ADDWF   ENDERECO_HIGH,F
    RETURN

SOMA_2BYTES  ;REALIZA A SOMA DE 2 OPERANDOS DE 2 BYTES
    MOVF    BYTE1_LOW,W
    ADDWF   BYTE2_LOW,W  ; BYTE1_LOW + BYTE2_LOW = RESULTADO_LOW
    MOVWF   RESULTADO_LOW
    BTFSS   STATUS,C ; C = 1 HOUVE ESTOURO
    GOTO    SOMA
    MOVF    BYTE1_HIGH,W
    ADDWF   BYTE2_HIGH,W
    MOVWF   RESULTADO_HIGH
    INCF    RESULTADO_HIGH,F
    RETURN
    
SOMA
    MOVF    BYTE1_HIGH,W
    ADDWF   BYTE2_HIGH,W
    MOVWF   RESULTADO_HIGH
    RETURN
   
MULT16
	CLRF	R3
	CLRF	R2
	CLRF	R1
	MOVWF	T		; optionally comment out
	BSF	R1,7
M1
	RRF	T,F
	SKPC
	GOTO	M2
	MOVFW	L_BYTE
	ADDWF	R2,F
	MOVFW	H_BYTE
	SKPNC
	INCFSZ	H_BYTE,W
	ADDWF	R3,F
M2
	RRF	R3,F
	RRF	R2,F
	RRF	R1,F
	SKPC
	GOTO	M1
	
	RETURN

    END