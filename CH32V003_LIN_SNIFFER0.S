#riscv32-unknown-elf-as -g CH32V003_LIN_SNIFFER0.S -o CH32V003_LIN_SNIFFER0.O
#riscv32-unknown-elf-ld -T CH32V003.ld -Map=final.map CH32V003_LIN_SNIFFER0.O
#riscv32-unknown-elf-objcopy -O ihex a.out CH32V003_LIN_SNIFFER0.hex

# new linker version
#.\riscv32-unknown-elf-as -g CH32V003_LIN_SNIFFER0.S -o CH32V003_LIN_SNIFFER0.O
#.\riscv32-unknown-elf-ld -T CH32V003.ld --Map final.map CH32V003_LIN_SNIFFER0.O
#.\riscv32-unknown-elf-objcopy -O ihex a.out CH32V003_LIN_SNIFFER0.hex



#USARTDIV= (AHB_clk/(16 x baud))  , USARTDIV  goes into BRR register
#for 9600 baud , (8000000/(16 x 9600)) = 52.0833
#Mantissa (Bits [15:4]): Fraction (Bits [3:0]) of USARTDIV in BRR
#52 is mantissa, 1 as fraction rounded 0.0833 x 16 =1.33



#Here are the register values for standard baud rates assuming a 
# of 8 MHz.
#Baud Rate	USARTDIV (Dec)	Mantissa (Hex)	Fraction (Hex)	USART_BRR	Error %
#2400		208.333	 	0xD0	 	0x5		0x0D05		0.01%
#4800		104.166		0x68	 	0x3		0x0683		0.04%
#9600		52.083		0x34	 	0x1		0x0341		0.04%
#10417		47.998		0x30		0x0		0x0300		0.003%
#19200		26.041		0x1A	 	0x1		0x01A1		0.16%
#38400		13.020		0x0D	 	0x0		0x00D0		0.16%
#57600		8.680		0x08	 	0xB		0x008B		0.08%
#115200		4.340		0x04	 	0x5		0x0045		0.16%

#Waits for hardware LIN Break (LBD flag)
#Reads Sync (0x55), PID, data bytes, and checksum
#Calculates Enhanced checksum (LIN 2.x)
#Prints the result (raw ID, data, [OK] or [ERROR])
#You only need to copy-paste these snippets into your .s file.

.equ SRAM_start, 0x20000000
.equ SRAM_end,  0x20000800
.equ STACK, 0x20000800 

.equ TIM2_BASE, 0x40000000
.equ W_WDG_BASE, 0x40002C00
.equ I_WDG_BASE, 0x40003000
.equ I2C_BASE, 0x40005400
.equ PWR_BASE, 0x40007000
.equ AFIO_BASE, 0x40010000
.equ EXTI_BASE, 0x40010400
.equ PORTA_BASE, 0x40010800
.equ PORTC_BASE, 0x40011000
.equ PORTD_BASE, 0x40011400
.equ ADC_BASE, 0x40012400
.equ TIM1_BASE, 0x40012C00
.equ SPI_BASE, 0x40013000
.equ USART_BASE, 0x40013800
.equ DMA_BASE, 0x40020000
.equ RCC_BASE, 0x40021000
.equ FLASH_INTERFACE_BASE, 0x40022000
.equ EXTENDED_MEM_BASE, 0x40023800
.equ CORE_PRIVATE_BASE, 0xE0000000
.equ FLASH_BASE, 0x08000000


.equ R32_PWR_CTLR, 0x40007000 		#Power control register
.equ R32_PWR_CSR, 0x40007004 		#Power control/status register
.equ R32_PWR_AWUCSR, 0x40007008 	#Auto-wakeup control/status register
.equ R32_PWR_AWUWR, 0x4000700C		#Auto-wakeup window comparison value register
.equ R32_PWR_AWUPSC, 0x40007010 	#Auto-wakeup crossover factor register
.equ R32_RCC_CTLR, 0x40021000 		#Clock control register 0x0000xx83
.equ R32_RCC_CFGR0, 0x40021004 		#Clock configuration register 0 0x00000000
.equ R32_RCC_INTR, 0x40021008 		#Clock interrupt register 0x00000000
.equ R32_RCC_APB2PRSTR, 0x4002100C 	#APB2 peripheral reset register 0x00000000
.equ R32_RCC_APB1PRSTR, 0x40021010 	# APB1 peripheral reset register 0x00000000
.equ R32_RCC_AHBPCENR, 0x40021014 	#AHB peripheral clock enable register 0x00000014
.equ R32_RCC_APB2PCENR, 0x40021018 	#APB2 peripheral clock enable register 0x00000000
.equ R32_RCC_APB1PCENR, 0x4002101C 	#APB1 peripheral clock enable register 0x00000000
.equ R32_RCC_RSTSCKR, 0x40021024   	#Control/status register

.equ R16_IWDG_CTLR, 0x40003000 		#Control register 0x0000
.equ R16_IWDG_PSCR, 0x40003004		#Prescaler register 0x0000
.equ R16_IWDG_RLDR, 0x40003008 		#Reload register 0x0FFF
.equ R16_IWDG_STATR, 0x4000300C 	#Status register

.equ R16_WWDG_CTLR, 0x40002C00 		#Control register 0x007F
.equ R16_WWDG_CFGR, 0x40002C04 		#Configuration Register 0x007F
.equ R16_WWDG_STATR, 0x40002C08 	#Status Register

.equ R32_EXTI_INTENR, 0x40010400 	#Interrupt enable register 0x00000000
.equ R32_EXTI_EVENR,  0x40010404 	#Event enable register 0x00000000
.equ R32_EXTI_RTENR, 0x40010408 	#Rising edge trigger enable register 0x00000000
.equ R32_EXTI_FTENR, 0x4001040C 	#Falling edge trigger enable register 0x00000000
.equ R32_EXTI_SWIEVR, 0x40010410 	#Soft interrupt event register 0x00000000
.equ R32_EXTI_INTFR, 0x40010414 	#Interrupt flag register

.equ R32_PFIC_ISR1, 0xE000E000 		#PFIC interrupt enable status register 1
.equ R32_PFIC_ISR2, 0xE000E004 		#PFIC interrupt enable status register 2 
.equ R32_PFIC_IPR1, 0xE000E020 		#PFIC interrupt pending status register 1 
.equ R32_PFIC_IPR2, 0xE000E024 		#PFIC interrupt pending status register 2 
.equ R32_PFIC_ITHRESDR, 0xE000E040 	#PFIC interrupt priority threshold configuration register
.equ R32_PFIC_CFGR, 0xE000E048 		#PFIC interrupt configuration register
.equ R32_PFIC_GISR, 0xE000E04C 		#PFIC interrupt global status register 
.equ R32_PFIC_VTFIDR, 0xE000E050 	#PFIC VTF interrupt ID configuration register
.equ R32_PFIC_VTFADDRR0, 0xE000E060 	#PFIC VTF interrupt 0 offset address register
.equ R32_PFIC_VTFADDRR1, 0xE000E064 	#PFIC VTF interrupt 1 offset address register
.equ R32_PFIC_IENR1, 0xE000E100		#PFIC interrupt enable setting register 1 
.equ R32_PFIC_IENR2, 0xE000E104 	#PFIC interrupt enable setting register 2 
.equ R32_PFIC_IRER1, 0xE000E180 	#PFIC interrupt enable clear register 1 
.equ R32_PFIC_IRER2, 0xE000E184 	#PFIC interrupt enable clear register 2 
.equ R32_PFIC_IPSR1, 0xE000E200 	#PFIC interrupt pending setting register 1 
.equ R32_PFIC_IPSR2, 0xE000E204 	#PFIC interrupt pending setting register 2 
.equ R32_PFIC_IPRR1, 0xE000E280 	#PFIC interrupt hang clear register 1 
.equ R32_PFIC_IPRR2, 0xE000E284 	#PFIC interrupt hang clear register 2 
.equ R32_PFIC_IACTR1, 0xE000E300 	#PFIC interrupt activation status register1
.equ R32_PFIC_IACTR2, 0xE000E304 	#PFIC interrupt activation status register2
.equ R32_PFIC_IPRIOR1, 0xE000E400 	#PFIC interrupt priority configuration register
.equ R32_PFIC_IPRIOR2, 0xE000E401 	#PFIC interrupt priority configuration register
.equ R32_PFIC_SCTLR, 0xE000ED10 	#PFIC system control register

.equ INTSYSCR, 0x804 			#Interrupt System Control Register
.equ MTVEC, 0x305 			#Exception Entry Base Address Register
.equ DBGMCU_CR, 0x7C0  			#Debug MCU Configuration Register (CSR)
 
.equ R32_STK_CTLR, 0xE000F000 		#System count control register 
.equ R32_STK_SR, 0xE000F004 		#System count status register 
.equ R32_STK_CNTR, 0xE000F008		# System counter low register 
.equ R32_STK_CMPR, 0xE000F010 		#Counting comparison low register


.equ R32_GPIOA_CFGLR, 0x40010800 	#PA port configuration register low 0x44444444
.equ R32_GPIOC_CFGLR, 0x40011000 	#PC port configuration register low 0x44444444
.equ R32_GPIOD_CFGLR, 0x40011400 	#PD port configuration register low 0x44444444
.equ R32_GPIOA_INDR, 0x40010808 	#PA port input data register 0x0000XXXX
.equ R32_GPIOC_INDR, 0x40011008 	#PC port input data register 0x0000XXXX
.equ R32_GPIOD_INDR, 0x40011408 	#PD port input data register 0x0000XXXX
.equ R32_GPIOA_OUTDR, 0x4001080C 	#PA port output data register 0x00000000
.equ R32_GPIOC_OUTDR, 0x4001100C 	#PC port output data register 0x00000000
.equ R32_GPIOD_OUTDR, 0x4001140C 	#PD port output data register 0x00000000
.equ R32_GPIOA_BSHR, 0x40010810 	#PA port set/reset register 0x00000000
.equ R32_GPIOC_BSHR, 0x40011010 	#PC port set/reset register 0x00000000
.equ R32_GPIOD_BSHR, 0x40011410 	#PD port set/reset register 0x00000000
.equ R32_GPIOA_BCR, 0x40010814 		#PA port reset register 0x00000000
.equ R32_GPIOC_BCR, 0x40011014 		#PC port reset register
.equ R32_GPIOD_BCR, 0x40011414 		#PD port reset register 0x00000000
.equ R32_GPIOA_LCKR, 0x40010818 	#PA port configuration lock register 0x00000000
.equ R32_GPIOC_LCKR, 0x40011018 	#PC port configuration lock register 0x00000000
.equ R32_GPIOD_LCKR, 0x40011418 	#PD port configuration lock register 
.equ R32_AFIO_PCFR1, 0x40010004		#AFIO Remap Register 1
.equ R32_AFIO_EXTICR, 0x40010008 	#External interrupt configuration register 1

.equ R32_DMA_INTFR, 0x40020000 		#DMA interrupt status register 0x00000000
.equ R32_DMA_INTFCR, 0x40020004 	#DMA interrupt flag clear register 0x00000000
.equ R32_DMA_CFGR1, 0x40020008 		#DMA channel 1 configuration register 0x00000000
.equ R32_DMA_CNTR1, 0x4002000C 		#DMA channel 1 number of data register
.equ R32_DMA_PADDR1, 0x40020010 	#DMA channel 1 peripheral address register 0x00000000
.equ R32_DMA_MADDR1, 0x40020014 	#DMA channel 1 memory address register 0x00000000
.equ R32_DMA_CFGR2, 0x4002001C 		#DMA channel 2 configuration register 0x00000000
.equ R32_DMA_CNTR2, 0x40020020 		#DMA channel 2 number of data register 0x00000000
.equ R32_DMA_PADDR2, 0x40020024 	#DMA channel 2 peripheral address register 0x00000000
.equ R32_DMA_MADDR2, 0x40020028 	#DMA channel 2 memory address register 0x00000000
.equ R32_DMA_CFGR3, 0x40020030 		#DMA channel 3 configuration register 0x00000000
.equ R32_DMA_CNTR3, 0x40020034 		#DMA channel 3 number of data register 0x00000000
.equ R32_DMA_PADDR3, 0x40020038 	#DMA channel 3 peripheral address register 0x00000000
.equ R32_DMA_MADDR3, 0x4002003C 	#DMA channel 3 memory address register 0x00000000
.equ R32_DMA_CFGR4, 0x40020044 		#DMA channel 4 configuration register 0x00000000
.equ R32_DMA_CNTR4, 0x40020048 		#DMA channel 4 number of data register 0x00000000
.equ R32_DMA_PADDR4, 0x4002004C 	#DMA channel 4 peripheral address register 0x00000000
.equ R32_DMA_MADDR4, 0x40020050 	#DMA channel 4 memory address register 0x00000000
.equ R32_DMA_CFGR5, 0x40020058		#DMA channel 5 configuration register 0x00000000
.equ R32_DMA_CNTR5, 0x4002005C 		#DMA channel 5 number of data register 0x00000000
.equ R32_DMA_PADDR5, 0x40020060 	#DMA channel 5 peripheral address register 0x00000000
.equ R32_DMA_MADDR5, 0x40020064 	#DMA channel 5 memory address register 0x00000000
.equ R32_DMA_CFGR6, 0x4002006C 		#DMA channel 6 configuration register 0x00000000
.equ R32_DMA_CNTR6, 0x40020070 		#DMA channel 6 number of data register 0x00000000
.equ R32_DMA_PADDR6, 0x40020074 	#DMA channel 6 peripheral address register 0x00000000
.equ R32_DMA_MADDR6, 0x40020078 	#DMA channel 6 memory address register 0x00000000
.equ R32_DMA_CFGR7, 0x40020080 		#DMA channel 7 configuration register 0x00000000
.equ R32_DMA_CNTR7, 0x40020084 		#DMA channel 7 number of data register 0x00000000
.equ R32_DMA_PADDR7, 0x40020088 	#DMA channel 7 peripheral address register 0x00000000
.equ R32_DMA_MADDR7, 0x4002008C 	#DMA channel 7 memory address register


.equ R32_ADC_STATR, 0x40012400 		#ADC status register 0x00000000
.equ R32_ADC_CTLR1, 0x40012404 		#ADC control register 1 0x00000000
.equ R32_ADC_CTLR2, 0x40012408 		#ADC control register 2 0x00000000
.equ R32_ADC_SAMPTR1, 0x4001240C 	#ADC sample time register 1 0x00000000
.equ R32_ADC_SAMPTR2, 0x40012410 	#ADC sample time register 2 0x00000000
.equ R32_ADC_IOFR1, 0x40012414 		#ADC injected channel data offset register 1 0x00000000
.equ R32_ADC_IOFR2, 0x40012418 		#ADC injected channel data offset register 2 0x00000000
.equ R32_ADC_IOFR3, 0x4001241C 		#ADC injected channel data offset register 3 0x00000000
.equ R32_ADC_IOFR4, 0x40012420 		#ADC injected channel data offset register 4 0x00000000
.equ R32_ADC_WDHTR, 0x40012424 		#ADC watchdog high threshold register 0x00000000
.equ R32_ADC_WDLTR, 0x40012428 		#ADC watchdog low threshold register 0x00000000
.equ R32_ADC_RSQR1, 0x4001242C 		#ADC regular sequence register 1 0x00000000
.equ R32_ADC_RSQR2, 0x40012430 		#ADC regular sequence register 2 0x00000000
.equ R32_ADC_RSQR3, 0x40012434 		#ADC regular sequence register 3 0x00000000
.equ R32_ADC_ISQR, 0x40012438 		#ADC injected sequence register 0x00000000
.equ R32_ADC_IDATAR1, 0x4001243C 	#ADC injected data register 1 0x00000000
.equ R32_ADC_IDATAR2, 0x40012440 	#ADC injected data register 2 0x00000000
.equ R32_ADC_IDATAR3, 0x40012444 	#ADC injected data register 3 0x00000000
.equ R32_ADC_IDATAR4, 0x40012448 	#ADC injected data register 4 0x00000000
.equ R32_ADC_RDATAR, 0x4001244C 	#ADC regular data register 0x00000000
.equ R32_ADC_DLYR, 0x40012450 		#ADC delayed data register


.equ R16_TIM1_CTLR1, 0x40012C00 	#Control register 1 0x0000
.equ R16_TIM1_CTLR2, 0x40012C04 	#Control register 2 0x0000
.equ R16_TIM1_SMCFGR, 0x40012C08 	#Slave mode control register 0x0000
.equ R16_TIM1_DMAINTENR, 0x40012C0C 	#DMA/interrupt enable register 0x0000
.equ R16_TIM1_INTFR, 0x40012C10 	#Interrupt status register 0x0000
.equ R16_TIM1_SWEVGR, 0x40012C14 	#Event generation register 0x0000
.equ R16_TIM1_CHCTLR1, 0x40012C18 	#Compare/capture control register 1 0x0000
.equ R16_TIM1_CHCTLR2, 0x40012C1C 	#Compare/capture control register 2 0x0000
.equ R16_TIM1_CCER, 0x40012C20 		#Compare/capture enable register 0x0000
.equ R16_TIM1_CNT, 0x40012C24 		#Counters 0x0000
.equ R16_TIM1_PSC, 0x40012C28 		#Counting clock prescaler 0x0000
.equ R16_TIM1_ATRLR, 0x40012C2C 	#Auto-reload value register 0x0000
.equ R16_TIM1_RPTCR, 0x40012C30 	#Recurring count value register 0x0000
.equ R16_TIM1_CH1CVR, 0x40012C34 	#Compare/capture register 1 0x0000
.equ R16_TIM1_CH2CVR, 0x40012C38 	#Compare/capture register 2 0x0000
.equ R16_TIM1_CH3CVR, 0x40012C3C 	#Compare/capture register 3 0x0000
.equ R16_TIM1_CH4CVR, 0x40012C40 	#Compare/capture register 4 0x0000
.equ R16_TIM1_BDTR, 0x40012C44 		#Brake and deadband registers 0x0000
.equ R16_TIM1_DMACFGR, 0x40012C48 	#DMA control register 0x0000
.equ R16_TIM1_DMAADR, 0x40012C4C 	#DMA address register for continuous mode


.equ R16_TIM2_CTLR1, 0x40000000 	#TIM2 control register1 0x0000
.equ R16_TIM2_CTLR2, 0x40000004 	#TIM2 control register2 0x0000
.equ R16_TIM2_SMCFGR, 0x40000008 	#TIM2 Slave mode control register 0x0000
.equ R16_TIM2_DMAINTENR, 0x4000000C 	#TIM2 DMA/interrupt enable register
.equ R16_TIM2_INTFR, 0x40000010 	#TIM2 interrupt status register 0x0000
.equ R16_TIM2_SWEVGR, 0x40000014 	#TIM2 event generation register 0x0000
.equ R16_TIM2_CHCTLR1, 0x40000018 	#TIM2 compare/capture control register1 0x0000
.equ R16_TIM2_CHCTLR2, 0x4000001C 	#TIM2 compare/capture control register2 0x0000
.equ R16_TIM2_CCER, 0x40000020 		#TIM2 compare/capture enable register 0x0000
.equ R16_TIM2_CNT, 0x40000024 		#TIM2 counter 0x0000
.equ R16_TIM2_PSC, 0x40000028 		#TIM2 count clock prescaler 0x0000
.equ R16_TIM2_ATRLR, 0x4000002C 	#TIM2 auto-reload register 0x0000
.equ R16_TIM2_CH1CVR, 0x40000034 	#TIM2 compare/capture register1 0x0000
.equ R16_TIM2_CH2CVR, 0x40000038 	#TIM2 compare/capture register2 0x0000
.equ R16_TIM2_CH3CVR, 0x4000003C 	#TIM2 compare/capture register3 0x0000
.equ R16_TIM2_CH4CVR, 0x40000040 	#TIM2 compare/capture register4 0x0000
.equ R16_TIM2_DMACFGR, 0x40000048 	#TIM2 DMA control register 0x0000
.equ R16_TIM2_DMAADR, 0x4000004C 	#TIM2 DMA address register in continuous mode
  

.equ R32_USART_STATR, 0x40013800 	#UASRT status register 0x000000C0
.equ R32_USART_DATAR, 0x40013804 	#UASRT data register 0x000000XX
.equ R32_USART_BRR, 0x40013808 		#UASRT baud rate register 0x00000000
.equ R32_USART_CTLR1, 0x4001380C 	#UASRT control register 1 0x00000000
.equ R32_USART_CTLR2, 0x40013810 	#UASRT control register 2 0x00000000
.equ R32_USART_CTLR3, 0x40013814 	#UASRT control register 3 0x00000000
.equ R32_USART_GPR, 0x40013818 		#UASRT protection time and prescaler register


.equ R16_I2C_CTLR1, 0x40005400 		#I2C control register 1 0x0000
.equ R16_I2C_CTLR2, 0x40005404 		#I2C control register 2 0x0000
.equ R16_I2C_OADDR1, 0x40005408 	#I2C address register 1 0x0000
.equ R16_I2C_OADDR2, 0x4000540C 	#I2C address register 2 0x0000
.equ R16_I2C_DATAR,  0x40005410 	#I2C data register 0x0000
.equ R16_I2C_STAR1,  0x40005414 	#I2C status register 1 0x0000
.equ R16_I2C_STAR2,  0x40005418 	#I2C status register 2 0x0000
.equ R16_I2C_CKCFGR, 0x4000541C 	#I2C clock register

.equ R16_SPI_CTLR1, 0x40013000 		#SPI Control register1 0x0000
.equ R16_SPI_CTLR2, 0x40013004 		#SPI Control register2 0x0000
.equ R16_SPI_STATR, 0x40013008 		#SPI Status register 0x0002
.equ R16_SPI_DATAR, 0x4001300C 		#SPI Data register 0x0000
.equ R16_SPI_CRCR,  0x40013010 		#SPI Polynomial register 0x0007
.equ R16_SPI_RCRCR, 0x40013014 		#SPI Receive CRC register 0x0000
.equ R16_SPI_TCRCR, 0x40013018 		#SPI Transmit CRC register 0x0000
.equ R16_SPI_HSCR,  0x40013024 		#SPI High-speed control register

.equ R16_ESIG_FLACAP, 0x1FFFF7E0 	#Flash capacity register 0xXXXX
.equ R32_ESIG_UNIID1, 0x1FFFF7E8 	#UID register 1 0xXXXXXXXX
.equ R32_ESIG_UNIID2, 0x1FFFF7EC 	#UID register 2 0xXXXXXXXX
.equ R32_ESIG_UNIID3,  0x1FFFF7F0 	#UID register 3 

.equ R32_FLASH_ACTLR, 0x40022000 	#Control register
.equ R32_FLASH_KEYR,  0x40022004 	#FPEC key register X
.equ R32_FLASH_OBKEYR, 0x40022008 	#OBKEY register X
.equ R32_FLASH_STATR, 0x4002200C 	#Status register 0x00008000
.equ R32_FLASH_CTLR,  0x40022010 	#Configuration register 0x00008080
.equ R32_FLASH_ADDR, 0x40022014 	#Address register X
.equ R32_FLASH_OBR,  0x4002201C 	#Select word register 0x03FFFFFE
.equ R32_FLASH_WPR,  0x40022020 	#Write protection register 0xFFFFFFF
.equ R32_FLASH_MODEKEYR,  0x40022024 	#Extended key register X
.equ R32_FLASH_BOOT_MODEKEYR,  0x40022028 #Unlock BOOT key register

.equ R32_EXTEN_CTR, 0x40023800 		#Configure extended control registers

.equ PFIC_KEY1, 0xFA050000
.equ PFIC_KEY2, 0xBCAF0000
.equ PFIC_KEY3, 0xBEEF0000
.equ mstatus, 0x300
.equ mtvec, 0x305
.equ intsyscr, 0x804
.equ mepc, 0x341

.equ  SYSTICK_SR_CNTIF, (1<<0)
.equ  SYSTICK_CTLR_STE , (1<<0)
.equ  SYSTICK_CTLR_STIE, (1<<1)
.equ  SYSTICK_CTLR_STCLK, (1<<2)
.equ  SYSTICK_CTLR_STRE,  (1<<3)
.equ  SYSTICK_CTLR_SWIE, (1<<31) 

.equ data_command2 , 0x0d               #0b00001101# data control nibble , 1101  = 0x0D   - EN goes hi=1
.equ data_command3 , 0xf9		#0b00001001# data control nibble , 1011  = 0x0B   - EN goes low=0
.equ inst_command2 , 0x0C               #0b00001100# instruction control nibble ,  led on,EN hi , rs/RW 0    = 1100   = 0x0C
.equ inst_command3 , 0xf8		#0b00001000# instruction control nibble  , led on, EN lo ,rs/rw 0    = 1000   = 0x08
.equ LCDWAD , 0x4E 			# 1602 LCD address
.equ buffer,   0x20000004
.equ buffer1,  0x20000008
.equ state , 0x2000000C
.equ input_count,  0x20000010
.equ kd_gain,  0x20000014
.equ fraction,  0x20000018		# stores 1 second measure window overflow for slow signals
.equ fraction2,  0x2000001C
.equ result_lo,  0x20000020
.equ result_hi,  0x20000024
.equ modulo ,  0x20000028 
.equ scratch,  0x2000002C
.equ result1,  0x20000030		# 10 bytes used by print function from 0(mem)
.equ result2,  0x20000034		# till 9(mem) , 2 bytes in mem1
.equ dividend , 0x20000038
.equ divisor, 0x2000003C
.equ scratchpad, 0x20000040
.equ last_error, 0x20000044
.equ kd_gain,	0x20000048
.equ ki_gain, 0x2000004C
.equ kp_gain,0x20000058
.equ i_accum,0x2000005C
.equ frame_buffer,0x20000060:           # Sync + PID + 8 data + checksum

# Bits

.equ LBD,           0x100    		# Bit 8  - LIN Break Detected (write 1 to clear)

.equ RXNE,          0x20     		# Bit 5  - Receive Data Register Not Empty

.macro push val
  addi sp, sp, -4
  sw \val, 0(sp)
.endm

.macro pop val
  lw \val, 0(sp)
  addi sp, sp, 4
.endm

.macro pos x y
  addi sp,sp,-8
  sw x6,0(sp)
  sw x7,4(sp)
  li x6,\y
  li x7,\x
  call posi
  lw x7,4(sp)
  lw x6,0(sp)
  addi sp,sp,8
.endm

.macro string address
  addi sp,sp,-4
  sw a2,0(sp)
  la a2,\address
  call string_reader
  lw a2,0(sp)
  addi sp,sp,4
.endm

.macro micros val
  addi sp,sp,-4
  sw t1,0(sp)
  li t1,\val
  call delayus
  lw t1,0(sp)
  addi sp,sp,4
.endm

.macro debug tp
  addi sp,sp,-8
  sw a5,0(sp)
  sw gp,4(sp)
  la a5, result_lo
  mv gp,\tp
  sw gp, 0(a5)
  call convert_to_decimal_signed
  pos 0,0
  call displayresult2			# display value in LCD
  call delay1S				# delay 1 second
  lw gp,4(sp)
  lw a5,0(sp)
  addi sp,sp,8
.endm


.align 9
vtable:
  j start		#  
.align 2
  .word   0x00000000 # RESERVED 1
  .word   NMI_IRQhandler
  .word   HardFault_IRQhandler
  .word   0x00000000 # RESERVED 4
  .word   0x00000000 # RESERVED 5
  .word   0x00000000 # RESERVED 6
  .word   0x00000000 # RESERVED 7
  .word   0x00000000 # RESERVED 8
  .word   0x00000000 # RESERVED 9
  .word   0x00000000 # RESERVED 10
  .word   0x00000000 # RESERVED 11
  .word   SysTick_IRQhandler		# 	
  .word   0x00000000 # RESERVED 13
  .word   SW_Software_IRQhandler
  .word   0x00000000 # RESERVED 15
  .word   WWDG_IRQhandler
  .word   PVD_IRQhandler
  .word   FLASH_IRQhandler
  .word   RCC_IRQhandler
  .word   EXTI7_0_IRQhandler
  .word   AWU_IRQhandler
  .word   DMA1_CH1_IRQhandler
  .word   DMA1_CH2_IRQhandler
  .word   DMA1_CH3_IRQhandler
  .word   DMA1_CH4_IRQhandler
  .word   DMA1_CH5_IRQhandler
  .word   DMA1_CH6_IRQhandler
  .word   DMA1_CH7_IRQhandler
  .word  ADC1_IRQhandler			# ADC1 interrupt vector
  .word  I2C1_EV_IRQhandler
  .word  I2C1_ER_IRQhandler
  .word  USART1_IRQhandler
  .word  SPI1_IRQhandler
  .word  TIM1BRK_IRQhandler
  .word  TIM1UP_IRQhandler
  .word  TIM1TRG_COM_IRQhandler
  .word  TIM1CC_IRQhandler
  .word  TIM2_IRQhandler



.text
.section .isr_vectors
  .weak   NMI_IRQhandler
  .weak   HardFault_IRQhandler
  .weak   SysTick_IRQhandler		
  .weak   SW_Software_IRQhandler
  .weak   WWDG_IRQhandler
  .weak   PVD_IRQhandler
  .weak   FLASH_IRQhandler
  .weak   RCC_IRQhandler
  .weak   EXTI7_0_IRQhandler
  .weak   AWU_IRQhandler
  .weak   DMA1_CH1_IRQhandler
  .weak   DMA1_CH2_IRQhandler
  .weak   DMA1_CH3_IRQhandler
  .weak   DMA1_CH4_IRQhandler
  .weak   DMA1_CH5_IRQhandler
  .weak   DMA1_CH6_IRQhandler
  .weak   DMA1_CH7_IRQhandler
  .weak  ADC1_IRQhandler			# ADC1 interrupt vector
  .weak  I2C1_EV_IRQhandler
  .weak  I2C1_ER_IRQhandler
  .weak  USART1_IRQhandler
  .weak  SPI1_IRQhandler
  .weak  TIM1BRK_IRQhandler
  .weak  TIM1UP_IRQhandler
  .weak  TIM1TRG_COM_IRQhandler
  .weak  TIM1CC_IRQhandler
  .weak  TIM2_IRQhandler


.align 2
.text
.global start
start:

    	li sp, STACK			# load stack pointer with stack end address
	 
    	la t0, vtable			#BASEADDR[31:2],The interrupt vector table base address,which needs to be 1KB aligned
    	ori t0, t0, 3			#BASEADDR[31:2],1: Identify by absolute address,1: Address offset based on interrupt number *4
    	csrrw zero, mtvec,t0		# write t0 mtvec
   	la t0,main
	csrw	mepc,t0
          				#csrw	mepc,t0 :mepc updated with address of main
	mret

  
.align 4

main:        

#enable periphrel clocks
	la x10,R32_RCC_APB2PCENR	# load address of APB2PCENR register to x10 ,for enabling GPIO A,D,C peripherals
	lw x11,0(x10)			# load contents from peripheral register R32_RCC_APB2PCENR pointed by x10
	li x7,((1<<2)|(1<<4)|(1<<5)|(1<<0)|(1<<14)|(1<<9)|(1<<11))	# 1<<IOPA_EN,1<<IOPC_EN,1<<IOPD_EN,1<<AFIOEN,1<<USART ,1<<ADC enable port A,C,D and AFIO functions,1<<TIM1
	or x11,x11,x7			# or values 
	sw x11,0(x10)			# store modified enable values in R32_RCC_APB2PCENR

#configure GPIO 
	la x10,R32_GPIOD_CFGLR		# load pointer x10 with address of R32_GPIOD_CFGLR , GPIO configuration register
	lw x11,0(x10)			# load contents from register pointed by x10
	li x7,~((0xf<<20)|(0xf<<24)|(0xf<<16))	#clear pd4,pd5,pd6. we need to setup PD5 & PD6 for usart tx and rx and pd4 for led
	and x11,x11,x7			# clear pd4,pd5,pd6 mode and cnf bits for selected pin D4,D5,D6
	li x7,((0x8<<24)|(0xB<<20)|(0x3<<16))	# pd6 = input with PU/PD,pd5= multiplex pushpull output 50mhz,pd4= normal pushpull output 50hz
	or x11,x11,x7			# OR value to register
	sw x11,0(x10)			# store in R32_GPIOD_CFGLR

#enable pull up for input	
	la x10,R32_GPIOD_OUTDR		# enable pullup resistor by setting OUTDR register
	lw x11,0(x10)			# this setting of GPIO_OUTDR for pullup resistor effects if corresonding pin is selected as input
	li x7,(1<<6)			#when PD6 is input with resistor selected 1= pullup and 0 = pulldown
	or x11,x11,x7
	sw x11,0(x10)

#configure USART baud
	la x10,R32_USART_BRR		# USART BAUD setting
	lw x11,0(x10)			# copy R32_USART_BRR to x11
	li x7,0x300			# baud 10417,Mantissa 0x30, Fraction 0
	or x11,x11,x7			# or registers
	sw x11,0(x10)			# store in R32_USART_BRR
#enable LIN
	la x10, R32_USART_CTLR2
	li x7, (1<<14)          	# LINEN
	sw x7, 0(x10)


#setup UART control and enable	
	la x10,R32_USART_CTLR1		# load x10 with R32_USART_CTLR1 address
	lw x11,0(x10)			# load to x11 contents
	li x7,(1<<13)|(1<<3)|(1<<2)	# enable USART UE, TX,RX bits		# UE 
	or x11,x11,x7
	sw x11,0(x10)			# store back new values







	la x10,name			# load address of label "name" to x10, string to be transmitted
string_loop:
	lb x8,0(x10)			# load 1 byte from 0 offset of "name"
	beqz x8,finish			# if byte in x8 null branch to label "finish"
	call USART_TX			# call subroutine USART_TX to transmit byte
	addi x10,x10,1			# increase pointer by 1 byte
	j string_loop			# jump back to label string_loop until null is encountered
finish:
	call delay			# some delay
	


    # 1. Wait for LIN Break
wait_break:
    	la t0, R32_USART_STATR
    	lw t1, 0(t0)
    	andi t1, t1, 0x100          # LBD flag (bit 8)
    	beqz t1, wait_break
    
    	# Clear LBD flag by writing 0 to it (Standard USART behavior)
   	la t0, R32_USART_STATR
    	lw t1, 0(t0)
    	li t2, ~0x100               # Bitmask to clear bit 8
	and t1,t1,t2
    	sw t1, 0(t0)

    	# 2. Read Sync (0x55) and PID
    	la a4, frame_buffer         # a4 = buffer pointer (x14)
    	call read_byte              # Result in a0
    	sb a0, 0(a4)                # Store Sync
    	addi a4, a4, 1
    
    	call read_byte              # Read PID
    	sb a0, 0(a4)                # Store PID
    	mv a5, a0                   # a5 = Protected PID (x15)
    	addi a4, a4, 1

    	# 3. Flexible Data Loop (Capped at 8)
    	li a3, 8                    # a3 = counter (x13)
data_loop:
    	call read_byte
    	sb a0, 0(a4)
    	addi a4, a4, 1
    	addi a3, a3, -1
    	bnez a3, data_loop

    	# 4. Read Received Checksum
    	call read_byte
    	mv tp, a0                   # tp = rx_checksum (x12)

    	# 5. Calculate and Compare
    	mv a0, a5                   # a0 = PID for checksum
    	la a1, frame_buffer         # a1 = data pointer
	addi a1,a1,2		    # frame_buffer + 2 = sync, pid, data starts at 3rd byte 
    	li a2, 8                    # a2 = length
    	call lin_checksum           # Returns calculated in a0
        	
    	beq a0, tp, checksum_ok     # Assuming tp held rx_checksum temporarily
    	j wait_break

checksum_ok:
    	call display_frame 
    	j wait_break


###########################################################################################################
#3. LIN Checksum (Enhanced) – pure assembly
# Input:a0 = PID (full 8-bit Protected ID),a1 = pointer to data buffer,a2 = number of data bytes (usually 8)
# Output:   a0 = calculated checksum
############################################################################################################

lin_checksum:
	addi sp,sp,-24
	sw ra,0(sp)
	sw a1,4(sp)
	sw t0,8(sp)
	sw t1,12(sp)
	sw t2,16(sp)			
	sw tp,20(sp)			# received CS pushed to stack

	mv      t0, a0                 # sum = PID
	li      t1, 0                  # i = 0
step1:  beq     t1, a2, step2          # if i == len, done
        lbu     t2, 0(a1)              # t2 = data[i]
    	add     t0, t0, t2
    	li      tp, 256
    	blt     t0, tp, step3
    	addi    t0, t0, -255           # carry handling
step3:  addi    a1, a1, 1
    	addi    t1, t1, 1
    	j       step1
step2:  not     t0, t0                 # invert
    	andi    a0, t0, 0xFF           # return lower 8 bits

	lw tp,20(sp)			# received CS popped from stack
	lw t2,16(sp)
	lw t1,12(sp)
	lw t0,8(sp)
	lw a1,4(sp)
	lw ra,0(sp)
    	ret

###################################################################
	
USART_TX:
	addi sp,sp,-16			# add space in stack
	sw ra,0(sp)			# push ra
	sw x7,4(sp)			# push x7
	sw x10,8(sp)			# push x10
	sw x11,12(sp)			# push x11
TX_loop:
	la x10,R32_USART_STATR		# load address of usart status register
	lw x11,0(x10)			# load contents of status register in x11
	andi x11,x11,(1<<7)		# mask out 7th bit, transmit buffer empty flag
	beqz x11,TX_loop		# if 0 transmit buffer full, wait until bit is set
	#li x8,0x30
	mv x7,x8			# move byte in x8(s0) to x7(t2) ( call USART_TX with byte in x8)
	la x10,R32_USART_DATAR		# x10 has the address of data register
	sb x7,0(x10)			# store byte in x7 to data register
TC_check:
	la x10,R32_USART_STATR		# get contents of status register again
	lw x11,0(x10)
	andi x11,x11,(1<<6)		# check transmit complete bit
	beqz x11,TC_check		# wait if bit is 0 , when transmit complete = 1
		
	lw x11,12(sp)			# pop x11
	lw x10,8(sp)			# pop x10
	lw x7,4(sp)			# pop x7
	lw ra,0(sp)			# pop ra
	addi sp,sp,16			# set SP back 16 bytes
	ret				# return to caller

 
################################################################################
#Helper: Read one byte from UART (polling)

read_byte:
	addi sp,sp,-8
	sw ra,0(sp)
	sw a1,4(sp)
rb_loop:
	la a0,R32_USART_STATR
	lw a1,0(a0)
	andi a1,a1, RXNE		# RXNE=0x20
	beqz a1,rb_loop       		# Wait until RXNE == 1
	la a0,R32_USART_DATAR  		# Read the byte into a0
	lw a1,4(sp)
	lw ra,0(sp)
	addi sp,sp,8
	ret
###################################################################################
display_frame:
	addi sp,sp,-16
	sw ra,0(sp)
	sw s1,4(sp)
	sw a0,8(sp)
	sw s0,12(sp)

	li s1,11			# total number of bytes to transmit -sync,pid,data(8),CS
	la x10,frame_buffer		# load address of label "name" to x10, string to be transmitted
frame_loop:
	lbu x8,0(x10)			# 
	call print_hex_byte
	li x8, 0x20             	# Load space character " "
	call USART_TX			# call subroutine USART_TX to transmit byte
	addi x10,x10,1			# 
	addi s1,s1,-1			#
	beqz s1,frame_end		# 
	j frame_loop			# 
frame_end:
	# Print New Line at end of frame
    	li x8, 0x0D             	# \r
    	call USART_TX
    	li x8, 0x0A             	# \n
    	call USART_TX
	lw s0,12(sp)
	lw a0,8(sp)
	lw s1,4(sp)
	lw ra,0(sp)
	addi sp,sp,16
	ret
######################################################################################
# Input: x8 = Byte to print as Hex
# Uses: x7, x8, x9
print_hex_byte:
    	addi sp, sp, -16
    	sw ra, 0(sp)
    	sw x8, 4(sp)            # Save original byte
    	sw x7, 8(sp)
    	sw x9,12(sp)

   	 mv x9, x8               # Copy to x9
    
    	# Process High Nibble
    	srli x8, x9, 4          # Shift right 4 bits
    	call nibble_to_ascii
    	call USART_TX
    
    	# Process Low Nibble
    	andi x8, x9, 0x0F       # Mask lower 4 bits
    	call nibble_to_ascii
    	call USART_TX

    	lw x9,12(sp)
    	lw x7, 8(sp)
    	lw x8, 4(sp)            # Restore x8
    	lw ra, 0(sp)
    	addi sp, sp, 16
    	ret

nibble_to_ascii:
    	addi sp, sp, -12
    	sw ra, 0(sp)
	sw x7,4(sp)
	sw x8,8(sp)
    	li x7, 10
    	blt x8, x7, is_digit
    	addi x8, x8, 7          # Offset for A-F
is_digit:
    	addi x8, x8, 48         # Add ASCII '0'
	lw x8,8(sp)
	lw x7,4(sp)
    	lw ra, 0(sp)
    	addi sp, sp, 12
    	ret

#==========================================
delay10S: 
	addi sp,sp,-8 			# push RA
	sw ra,0(sp) 			# push RA
	sw t1,4(sp)
	li t1,20100101 			# load an arbitarary value 20000000 to t1 register 
loop10S:
	addi t1,t1,-1 			# subtract 1 from t1
	bne t1,zero,loop10S 		# if t1 not equal to 0 branch to label loop
	lw t1,4(sp)
	lw ra,0(sp) 			# POP RA
	addi sp,sp,8 			# pop RA
	ret 

delay1S: 
	addi sp,sp,-8 			# push RA
	sw ra,0(sp) 			# push RA
	sw t1,4(sp)
	li t1,2010010 			# load an arbitarary value 20000000 to t1 register 
loop1s:
	addi t1,t1,-1 			# subtract 1 from t1
	bne t1,zero,loop1s 		# if t1 not equal to 0 branch to label loop
	lw t1,4(sp)
	lw ra,0(sp) 			# POP RA
	addi sp,sp,8 			# pop RA
	ret 

delay1ms:
	addi sp,sp,-8 			# push RA
	sw ra,0(sp) 			# push RA
	sw t1,4(sp) 
	li t1,2010 			# load an arbitarary value 20000000 to t1 register 
loop1ms:
	addi t1,t1,-1 			# subtract 1 from t1
	bne t1,zero,loop1ms 		# if t1 not equal to 0 branch to label loop
	lw t1,4(sp)
	lw ra,0(sp) 			# POP RA
	addi sp,sp,8 			# pop RA 
	ret 

delay10ms:
	addi sp,sp,-8 			# push RA
	sw ra,0(sp) 			# push RA
	sw t1,4(sp) 
	li t1,20100 			# load an arbitarary value 20000000 to t1 register 
loop10ms:
	addi t1,t1,-1 			# subtract 1 from t1
	bne t1,zero,loop10ms 		# if t1 not equal to 0 branch to label loop
	lw t1,4(sp)
	lw ra,0(sp) 			# POP RA
	addi sp,sp,8 			# pop RA
	ret

delay50ms:
	addi sp,sp,-8 			# push RA
	sw ra,0(sp) 			# push RA
	sw t1,4(sp) 
	li t1,100500 			# load an arbitrary value 20000000 to t1 register 
loop50ms:
	addi t1,t1,-1 			# subtract 1 from t1
	bne t1,zero,loop50ms 		# if t1 not equal to 0 branch to label loop
	lw t1,4(sp)
	lw ra,0(sp) 			# POP RA
	addi sp,sp,8 			# pop RA
	ret 

delay10us:
	addi sp,sp,-8 			# push RA
	sw ra,0(sp) 			# push RA
	sw t1,4(sp) 
	li t1,105			# load an arbitrary value 20000000 to t1 register 
loop10us:
	addi t1,t1,-1 			# subtract 1 from t1
	bne t1,zero,loop10us 		# if t1 not equal to 0 branch to label loop
	lw t1,4(sp)
	lw ra,0(sp) 			# POP RA
	addi sp,sp,8 			# pop RA
	ret 

delayus:
	addi sp,sp,-4 			# push RA
	sw ra,0(sp) 			# push RA
loopus:
	addi t1,t1,-1 			# subtract 1 from t1
	bne t1,zero,loopus 		# if t1 not equal to 0 branch to label loop
	lw ra,0(sp) 			# POP RA
	addi sp,sp,4 			# pop RA
	ret 



###################################################################
##################################################################################
.align 4
.section .rodata
.global message

message1: .asciz "CH32V003 LIN SNIFFER "


