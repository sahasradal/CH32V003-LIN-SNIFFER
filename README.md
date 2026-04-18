# CH32V003-LIN-SNIFFER
under development
PD5 = USART TX , PD6 = USART RX , TJA1020 LIN TRANSRECEIVER. 
TJA1 <--> PD6 with PU , TJA4 <--> PD5 , TJA6 <--> LIN BUS (1k + diode to 12v if master) , TJA5 <--> GND , TJA7 <--> 12V, TJA2 <--> +5/3.3V ( 0-->1 while TX is 1 is wakeup, 1--->0 while TX is 1 is sleep)
