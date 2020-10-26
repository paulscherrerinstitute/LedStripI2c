EESchema Schematic File Version 4
LIBS:ledstrip-cache
EELAYER 26 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title "LED Strip"
Date "2020-10-13"
Rev "1.0"
Comp "PSI"
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L PCA9955TW:PCA9955TW U2
U 1 1 5F6D9E9B
P 5100 2650
F 0 "U2" V 5400 1400 50  0000 L CNN
F 1 "PCA9955TW" V 5300 1400 50  0000 L CNN
F 2 "proj_footprints:SOT1172-2" H 5100 2650 50  0001 L BNN
F 3 "" H 5100 2650 50  0001 C CNN
	1    5100 2650
	0    1    -1   0   
$EndComp
$Comp
L LED:HLCP-J100_2 BAR1
U 1 1 5F6DA79E
P 5100 1300
F 0 "BAR1" V 4700 950 50  0000 L CNN
F 1 "HLCP-J100_2" V 4800 950 50  0000 L CNN
F 2 "proj_footprints:HLCP-J100" H 5100 500 50  0001 C CNN
F 3 "https://docs.broadcom.com/docs/AV02-1798EN" H 3100 1500 50  0001 C CNN
	1    5100 1300
	0    1    1    0   
$EndComp
$Comp
L PCA9955TW:PCA9955TW U3
U 1 1 5F6DA849
P 7500 2650
F 0 "U3" V 7800 4000 50  0000 L CNN
F 1 "PCA9955TW" V 7700 4000 50  0000 L CNN
F 2 "proj_footprints:SOT1172-2" H 7500 2650 50  0001 L BNN
F 3 "" H 7500 2650 50  0001 C CNN
	1    7500 2650
	0    1    -1   0   
$EndComp
$Comp
L LED:HLCP-J100_2 BAR2
U 1 1 5F6DA8FC
P 6500 1300
F 0 "BAR2" V 6100 950 50  0000 L CNN
F 1 "HLCP-J100_2" V 6200 950 50  0000 L CNN
F 2 "proj_footprints:HLCP-J100" H 6500 500 50  0001 C CNN
F 3 "https://docs.broadcom.com/docs/AV02-1798EN" H 4500 1500 50  0001 C CNN
	1    6500 1300
	0    1    1    0   
$EndComp
$Comp
L LED:HLCP-J100_2 BAR3
U 1 1 5F6DA978
P 7900 1300
F 0 "BAR3" V 7500 950 50  0000 L CNN
F 1 "HLCP-J100_2" V 7600 950 50  0000 L CNN
F 2 "proj_footprints:HLCP-J100" H 7900 500 50  0001 C CNN
F 3 "https://docs.broadcom.com/docs/AV02-1798EN" H 5900 1500 50  0001 C CNN
	1    7900 1300
	0    1    1    0   
$EndComp
Wire Wire Line
	7400 1500 7400 2050
Wire Wire Line
	7500 1500 7500 2050
Wire Wire Line
	7600 1500 7600 2050
Wire Wire Line
	7700 1500 7700 2050
Wire Wire Line
	7800 1500 7800 2050
Wire Wire Line
	7900 1500 7900 2050
Wire Wire Line
	8000 1500 8000 2050
Wire Wire Line
	8100 1500 8100 2050
Wire Wire Line
	8200 1500 8200 2050
Wire Wire Line
	8300 1500 8300 2050
Wire Wire Line
	5500 1500 5500 2050
Wire Wire Line
	5400 1500 5400 2050
Wire Wire Line
	5300 1500 5300 2050
Wire Wire Line
	5200 1500 5200 2050
Wire Wire Line
	5100 1500 5100 2050
Wire Wire Line
	5000 1500 5000 2050
Wire Wire Line
	4900 1500 4900 2050
Wire Wire Line
	4800 1500 4800 2050
Wire Wire Line
	4700 1500 4700 2050
Wire Wire Line
	4600 1500 4600 2050
Wire Wire Line
	5600 1550 6000 1550
Wire Wire Line
	6000 1550 6000 1500
Wire Wire Line
	5600 1550 5600 2050
Wire Wire Line
	5700 1600 6100 1600
Wire Wire Line
	6100 1600 6100 1500
Wire Wire Line
	5700 1600 5700 2050
Wire Wire Line
	5800 1650 6200 1650
Wire Wire Line
	6200 1650 6200 1500
Wire Wire Line
	5800 1650 5800 2050
Wire Wire Line
	5900 2050 5900 1700
Wire Wire Line
	5900 1700 6300 1700
Wire Wire Line
	6300 1700 6300 1500
Wire Wire Line
	6900 1500 6900 1550
Wire Wire Line
	6900 1550 7300 1550
Wire Wire Line
	7300 1550 7300 2050
Wire Wire Line
	6800 1500 6800 1600
Wire Wire Line
	6800 1600 7200 1600
Wire Wire Line
	7200 1600 7200 2050
Wire Wire Line
	6700 1500 6700 1650
Wire Wire Line
	6700 1650 7100 1650
Wire Wire Line
	7100 1650 7100 2050
Wire Wire Line
	6600 1500 6600 1700
Wire Wire Line
	6600 1700 7000 1700
Wire Wire Line
	7000 1700 7000 2050
Wire Wire Line
	6500 1500 6500 1750
Wire Wire Line
	6500 1750 6900 1750
Wire Wire Line
	6900 1750 6900 2050
Wire Wire Line
	6400 1500 6400 1800
Wire Wire Line
	6400 1800 6800 1800
Wire Wire Line
	6800 1800 6800 2050
Wire Wire Line
	8300 1100 8200 1100
Connection ~ 4700 1100
Wire Wire Line
	4700 1100 4600 1100
Connection ~ 4800 1100
Wire Wire Line
	4800 1100 4700 1100
Connection ~ 4900 1100
Wire Wire Line
	4900 1100 4800 1100
Connection ~ 5000 1100
Wire Wire Line
	5000 1100 4900 1100
Connection ~ 5100 1100
Wire Wire Line
	5100 1100 5000 1100
Connection ~ 5200 1100
Wire Wire Line
	5200 1100 5100 1100
Connection ~ 5300 1100
Wire Wire Line
	5300 1100 5200 1100
Connection ~ 5400 1100
Wire Wire Line
	5400 1100 5300 1100
Connection ~ 5500 1100
Wire Wire Line
	5500 1100 5400 1100
Connection ~ 6000 1100
Wire Wire Line
	6000 1100 5500 1100
Connection ~ 6100 1100
Wire Wire Line
	6100 1100 6000 1100
Connection ~ 6200 1100
Wire Wire Line
	6200 1100 6100 1100
Connection ~ 6300 1100
Wire Wire Line
	6300 1100 6200 1100
Connection ~ 6400 1100
Wire Wire Line
	6400 1100 6300 1100
Connection ~ 6500 1100
Wire Wire Line
	6500 1100 6400 1100
Connection ~ 6600 1100
Wire Wire Line
	6600 1100 6500 1100
Connection ~ 6700 1100
Wire Wire Line
	6700 1100 6600 1100
Connection ~ 6800 1100
Wire Wire Line
	6800 1100 6700 1100
Connection ~ 6900 1100
Wire Wire Line
	6900 1100 6800 1100
Connection ~ 7400 1100
Wire Wire Line
	7400 1100 6900 1100
Connection ~ 7500 1100
Wire Wire Line
	7500 1100 7400 1100
Connection ~ 7600 1100
Wire Wire Line
	7600 1100 7500 1100
Connection ~ 7700 1100
Wire Wire Line
	7700 1100 7600 1100
Connection ~ 7800 1100
Wire Wire Line
	7800 1100 7700 1100
Connection ~ 7900 1100
Wire Wire Line
	7900 1100 7800 1100
Connection ~ 8000 1100
Wire Wire Line
	8000 1100 7900 1100
Connection ~ 8100 1100
Wire Wire Line
	8100 1100 8000 1100
Connection ~ 8200 1100
Wire Wire Line
	8200 1100 8100 1100
$Comp
L power:+5V #PWR0101
U 1 1 5F6F4CEB
P 4600 950
F 0 "#PWR0101" H 4600 800 50  0001 C CNN
F 1 "+5V" H 4615 1123 50  0000 C CNN
F 2 "" H 4600 950 50  0001 C CNN
F 3 "" H 4600 950 50  0001 C CNN
	1    4600 950 
	1    0    0    -1  
$EndComp
Wire Wire Line
	4600 950  4600 1100
Connection ~ 4600 1100
$Comp
L power:+5V #PWR0102
U 1 1 5F6F666E
P 6100 2250
F 0 "#PWR0102" H 6100 2100 50  0001 C CNN
F 1 "+5V" H 6115 2423 50  0000 C CNN
F 2 "" H 6100 2250 50  0001 C CNN
F 3 "" H 6100 2250 50  0001 C CNN
	1    6100 2250
	1    0    0    -1  
$EndComp
Wire Wire Line
	6100 2250 6100 2400
$Comp
L power:+5V #PWR0103
U 1 1 5F6F810F
P 8500 2250
F 0 "#PWR0103" H 8500 2100 50  0001 C CNN
F 1 "+5V" H 8515 2423 50  0000 C CNN
F 2 "" H 8500 2250 50  0001 C CNN
F 3 "" H 8500 2250 50  0001 C CNN
	1    8500 2250
	1    0    0    -1  
$EndComp
Wire Wire Line
	8500 2250 8500 2400
$Comp
L power:GND #PWR0104
U 1 1 5F6F9C33
P 6600 2800
F 0 "#PWR0104" H 6600 2550 50  0001 C CNN
F 1 "GND" H 6605 2627 50  0000 C CNN
F 2 "" H 6600 2800 50  0001 C CNN
F 3 "" H 6600 2800 50  0001 C CNN
	1    6600 2800
	1    0    0    -1  
$EndComp
Wire Wire Line
	6600 2650 6600 2800
$Comp
L power:GND #PWR0105
U 1 1 5F6FB7EB
P 4200 2850
F 0 "#PWR0105" H 4200 2600 50  0001 C CNN
F 1 "GND" H 4205 2677 50  0000 C CNN
F 2 "" H 4200 2850 50  0001 C CNN
F 3 "" H 4200 2850 50  0001 C CNN
	1    4200 2850
	1    0    0    -1  
$EndComp
Wire Wire Line
	4200 2650 4200 2850
$Comp
L Device:R_Small R5
U 1 1 5F6FD531
P 7500 3450
F 0 "R5" H 7559 3496 50  0000 L CNN
F 1 "R_Small" H 7559 3405 50  0000 L CNN
F 2 "Resistor_SMD:R_0603_1608Metric" H 7500 3450 50  0001 C CNN
F 3 "~" H 7500 3450 50  0001 C CNN
	1    7500 3450
	1    0    0    -1  
$EndComp
Wire Wire Line
	7500 3250 7500 3350
$Comp
L power:GND #PWR0106
U 1 1 5F6FF30B
P 7500 3550
F 0 "#PWR0106" H 7500 3300 50  0001 C CNN
F 1 "GND" H 7505 3377 50  0000 C CNN
F 2 "" H 7500 3550 50  0001 C CNN
F 3 "" H 7500 3550 50  0001 C CNN
	1    7500 3550
	1    0    0    -1  
$EndComp
$Comp
L Device:R_Small R2
U 1 1 5F701105
P 5100 3450
F 0 "R2" H 5159 3496 50  0000 L CNN
F 1 "R_Small" H 5159 3405 50  0000 L CNN
F 2 "Resistor_SMD:R_0603_1608Metric" H 5100 3450 50  0001 C CNN
F 3 "~" H 5100 3450 50  0001 C CNN
	1    5100 3450
	1    0    0    -1  
$EndComp
Wire Wire Line
	5100 3250 5100 3350
$Comp
L power:GND #PWR0107
U 1 1 5F70110D
P 5100 3550
F 0 "#PWR0107" H 5100 3300 50  0001 C CNN
F 1 "GND" H 5105 3377 50  0000 C CNN
F 2 "" H 5100 3550 50  0001 C CNN
F 3 "" H 5100 3550 50  0001 C CNN
	1    5100 3550
	1    0    0    -1  
$EndComp
$Comp
L Device:R_Small R3
U 1 1 5F702F30
P 5400 3450
F 0 "R3" H 5459 3496 50  0000 L CNN
F 1 "10k" H 5459 3405 50  0000 L CNN
F 2 "Resistor_SMD:R_0603_1608Metric" H 5400 3450 50  0001 C CNN
F 3 "~" H 5400 3450 50  0001 C CNN
	1    5400 3450
	1    0    0    -1  
$EndComp
Wire Wire Line
	5400 3250 5400 3300
Connection ~ 6100 2650
Wire Wire Line
	7800 3250 7800 3300
Wire Wire Line
	8500 3650 7800 3650
Wire Wire Line
	7800 3650 7800 3550
Connection ~ 8500 2650
Wire Wire Line
	4500 3250 4500 3500
Wire Wire Line
	4700 3250 4700 3450
Wire Wire Line
	4700 3500 4500 3500
$Comp
L power:GND #PWR0108
U 1 1 5F718BAD
P 4150 3350
F 0 "#PWR0108" H 4150 3100 50  0001 C CNN
F 1 "GND" H 4155 3177 50  0000 C CNN
F 2 "" H 4150 3350 50  0001 C CNN
F 3 "" H 4150 3350 50  0001 C CNN
	1    4150 3350
	1    0    0    -1  
$EndComp
Wire Wire Line
	4600 3250 4600 3350
Wire Wire Line
	4600 3350 4400 3350
Wire Wire Line
	4400 3250 4400 3350
Connection ~ 4400 3350
Wire Wire Line
	4400 3350 4150 3350
$Comp
L power:GND #PWR0109
U 1 1 5F71F15B
P 6650 3350
F 0 "#PWR0109" H 6650 3100 50  0001 C CNN
F 1 "GND" H 6655 3177 50  0000 C CNN
F 2 "" H 6650 3350 50  0001 C CNN
F 3 "" H 6650 3350 50  0001 C CNN
	1    6650 3350
	1    0    0    -1  
$EndComp
Wire Wire Line
	6650 3350 6800 3350
Wire Wire Line
	7000 3250 7000 3350
Wire Wire Line
	6800 3250 6800 3350
Connection ~ 6800 3350
Wire Wire Line
	6800 3350 6900 3350
$Comp
L Device:C_Small C2
U 1 1 5F729830
P 6200 2400
F 0 "C2" V 5971 2400 50  0000 C CNN
F 1 "100n" V 6062 2400 50  0000 C CNN
F 2 "Capacitor_SMD:C_0603_1608Metric" H 6200 2400 50  0001 C CNN
F 3 "~" H 6200 2400 50  0001 C CNN
	1    6200 2400
	0    1    1    0   
$EndComp
Connection ~ 6100 2400
Wire Wire Line
	6100 2400 6100 2650
$Comp
L Device:C_Small C4
U 1 1 5F729886
P 8600 2400
F 0 "C4" V 8371 2400 50  0000 C CNN
F 1 "100n" V 8462 2400 50  0000 C CNN
F 2 "Capacitor_SMD:C_0603_1608Metric" H 8600 2400 50  0001 C CNN
F 3 "~" H 8600 2400 50  0001 C CNN
	1    8600 2400
	0    1    1    0   
$EndComp
Connection ~ 8500 2400
Wire Wire Line
	8500 2400 8500 2650
$Comp
L power:GND #PWR0110
U 1 1 5F7298D4
P 6300 2400
F 0 "#PWR0110" H 6300 2150 50  0001 C CNN
F 1 "GND" H 6305 2227 50  0000 C CNN
F 2 "" H 6300 2400 50  0001 C CNN
F 3 "" H 6300 2400 50  0001 C CNN
	1    6300 2400
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0111
U 1 1 5F7298F7
P 8700 2400
F 0 "#PWR0111" H 8700 2150 50  0001 C CNN
F 1 "GND" H 8705 2227 50  0000 C CNN
F 2 "" H 8700 2400 50  0001 C CNN
F 3 "" H 8700 2400 50  0001 C CNN
	1    8700 2400
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0112
U 1 1 5F729A28
P 6300 2950
F 0 "#PWR0112" H 6300 2700 50  0001 C CNN
F 1 "GND" H 6305 2777 50  0000 C CNN
F 2 "" H 6300 2950 50  0001 C CNN
F 3 "" H 6300 2950 50  0001 C CNN
	1    6300 2950
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0113
U 1 1 5F729A4F
P 8700 2900
F 0 "#PWR0113" H 8700 2650 50  0001 C CNN
F 1 "GND" H 8705 2727 50  0000 C CNN
F 2 "" H 8700 2900 50  0001 C CNN
F 3 "" H 8700 2900 50  0001 C CNN
	1    8700 2900
	1    0    0    -1  
$EndComp
$Comp
L MCP2221A-I_SL:MCP2221A-I_SL U1
U 1 1 5F729BA6
P 3250 4950
F 0 "U1" V 3204 5680 50  0000 L CNN
F 1 "MCP2221A-I_SL" V 3295 5680 50  0000 L CNN
F 2 "snapeda:SOIC127P600X175-14N" H 3250 4950 50  0001 L BNN
F 3 "Microchip" H 3250 4950 50  0001 L BNN
F 4 "IPC7351B" H 3250 4950 50  0001 L BNN "Field4"
	1    3250 4950
	0    1    1    0   
$EndComp
Wire Wire Line
	8200 3250 8200 4050
Wire Wire Line
	5800 3250 5800 4050
Wire Wire Line
	8300 4200 8300 3250
Wire Wire Line
	5800 4050 8200 4050
$Comp
L power:GND #PWR0114
U 1 1 5F73F7D9
P 2400 3800
F 0 "#PWR0114" H 2400 3550 50  0001 C CNN
F 1 "GND" H 2405 3627 50  0000 C CNN
F 2 "" H 2400 3800 50  0001 C CNN
F 3 "" H 2400 3800 50  0001 C CNN
	1    2400 3800
	1    0    0    -1  
$EndComp
Wire Wire Line
	2400 3650 2400 3750
Wire Wire Line
	2500 3650 2500 3750
Wire Wire Line
	2500 3750 2400 3750
Connection ~ 2400 3750
Wire Wire Line
	2400 3750 2400 3800
$Comp
L power:+5V #PWR0115
U 1 1 5F7489F1
P 2800 2600
F 0 "#PWR0115" H 2800 2450 50  0001 C CNN
F 1 "+5V" H 2815 2773 50  0000 C CNN
F 2 "" H 2800 2600 50  0001 C CNN
F 3 "" H 2800 2600 50  0001 C CNN
	1    2800 2600
	1    0    0    -1  
$EndComp
Wire Wire Line
	2800 2600 2800 3050
Wire Wire Line
	2800 3350 3050 3350
Wire Wire Line
	2800 3250 2950 3250
$Comp
L Device:R_Small R1
U 1 1 5F757A3D
P 3550 3450
F 0 "R1" H 3609 3496 50  0000 L CNN
F 1 "10k" H 3609 3405 50  0000 L CNN
F 2 "Resistor_SMD:R_0603_1608Metric" H 3550 3450 50  0001 C CNN
F 3 "~" H 3550 3450 50  0001 C CNN
	1    3550 3450
	1    0    0    -1  
$EndComp
$Comp
L power:+5V #PWR0116
U 1 1 5F757ABB
P 3550 3350
F 0 "#PWR0116" H 3550 3200 50  0001 C CNN
F 1 "+5V" H 3565 3523 50  0000 C CNN
F 2 "" H 3550 3350 50  0001 C CNN
F 3 "" H 3550 3350 50  0001 C CNN
	1    3550 3350
	1    0    0    -1  
$EndComp
Connection ~ 5800 4050
Wire Wire Line
	2950 3250 2950 4350
Wire Wire Line
	3050 3350 3050 4350
Wire Wire Line
	3250 4200 3250 4350
Wire Wire Line
	3350 4050 3350 4350
Wire Wire Line
	3550 4350 3550 3550
$Comp
L power:GND #PWR0117
U 1 1 5F78A974
P 2650 5550
F 0 "#PWR0117" H 2650 5300 50  0001 C CNN
F 1 "GND" H 2655 5377 50  0000 C CNN
F 2 "" H 2650 5550 50  0001 C CNN
F 3 "" H 2650 5550 50  0001 C CNN
	1    2650 5550
	1    0    0    -1  
$EndComp
$Comp
L Device:C_Small C1
U 1 1 5F78A9A1
P 3750 6250
F 0 "C1" H 3658 6204 50  0000 R CNN
F 1 "470nT" H 3658 6295 50  0000 R CNN
F 2 "Capacitor_SMD:C_0805_2012Metric" H 3750 6250 50  0001 C CNN
F 3 "~" H 3750 6250 50  0001 C CNN
	1    3750 6250
	-1   0    0    1   
$EndComp
$Comp
L power:GND #PWR0118
U 1 1 5F78AA48
P 3750 6350
F 0 "#PWR0118" H 3750 6100 50  0001 C CNN
F 1 "GND" H 3755 6177 50  0000 C CNN
F 2 "" H 3750 6350 50  0001 C CNN
F 3 "" H 3750 6350 50  0001 C CNN
	1    3750 6350
	1    0    0    -1  
$EndComp
Wire Wire Line
	3750 5550 3750 5950
$Comp
L power:+5V #PWR0119
U 1 1 5F79093A
P 4150 5550
F 0 "#PWR0119" H 4150 5400 50  0001 C CNN
F 1 "+5V" H 4165 5723 50  0000 C CNN
F 2 "" H 4150 5550 50  0001 C CNN
F 3 "" H 4150 5550 50  0001 C CNN
	1    4150 5550
	1    0    0    -1  
$EndComp
Wire Wire Line
	4150 5550 3950 5550
Wire Wire Line
	3550 5550 3450 5550
NoConn ~ 2950 5550
NoConn ~ 3050 5550
NoConn ~ 3150 5550
NoConn ~ 3250 5550
NoConn ~ 2800 3450
$Comp
L power:PWR_FLAG #FLG0101
U 1 1 5F7C7425
P 3750 5950
F 0 "#FLG0101" H 3750 6025 50  0001 C CNN
F 1 "PWR_FLAG" V 3750 6078 50  0000 L CNN
F 2 "" H 3750 5950 50  0001 C CNN
F 3 "~" H 3750 5950 50  0001 C CNN
	1    3750 5950
	0    -1   -1   0   
$EndComp
Connection ~ 3750 5950
Wire Wire Line
	3750 5950 3750 6150
$Comp
L Device:R_Small R8
U 1 1 5F7DF6E4
P 8500 4200
F 0 "R8" V 8700 4200 50  0000 C CNN
F 1 "1k6" V 8600 4200 50  0000 C CNN
F 2 "Resistor_SMD:R_0603_1608Metric" H 8500 4200 50  0001 C CNN
F 3 "~" H 8500 4200 50  0001 C CNN
	1    8500 4200
	0    1    1    0   
$EndComp
$Comp
L Device:R_Small R7
U 1 1 5F7DF859
P 8500 4050
F 0 "R7" V 8304 4050 50  0000 C CNN
F 1 "1k6" V 8395 4050 50  0000 C CNN
F 2 "Resistor_SMD:R_0603_1608Metric" H 8500 4050 50  0001 C CNN
F 3 "~" H 8500 4050 50  0001 C CNN
	1    8500 4050
	0    1    1    0   
$EndComp
Wire Wire Line
	8200 4050 8400 4050
Connection ~ 8200 4050
Wire Wire Line
	8300 4200 8400 4200
Connection ~ 8300 4200
$Comp
L power:+5V #PWR0120
U 1 1 5F7EC0D7
P 8700 3900
F 0 "#PWR0120" H 8700 3750 50  0001 C CNN
F 1 "+5V" H 8715 4073 50  0000 C CNN
F 2 "" H 8700 3900 50  0001 C CNN
F 3 "" H 8700 3900 50  0001 C CNN
	1    8700 3900
	1    0    0    -1  
$EndComp
Wire Wire Line
	8700 3900 8700 4050
Wire Wire Line
	8700 4050 8600 4050
Wire Wire Line
	8700 4050 8700 4200
Wire Wire Line
	8700 4200 8600 4200
Connection ~ 8700 4050
$Comp
L power:+5V #PWR04
U 1 1 5F8D344D
P 5400 5050
F 0 "#PWR04" H 5400 4900 50  0001 C CNN
F 1 "+5V" H 5415 5223 50  0000 C CNN
F 2 "" H 5400 5050 50  0001 C CNN
F 3 "" H 5400 5050 50  0001 C CNN
	1    5400 5050
	1    0    0    -1  
$EndComp
Wire Wire Line
	5400 5050 5400 5100
Wire Wire Line
	5400 5100 5450 5100
$Comp
L power:GND #PWR05
U 1 1 5F8DB664
P 6550 5150
F 0 "#PWR05" H 6550 4900 50  0001 C CNN
F 1 "GND" H 6555 4977 50  0000 C CNN
F 2 "" H 6550 5150 50  0001 C CNN
F 3 "" H 6550 5150 50  0001 C CNN
	1    6550 5150
	1    0    0    -1  
$EndComp
Wire Wire Line
	6550 5100 6550 5150
Wire Wire Line
	6250 5400 6250 5450
Wire Wire Line
	6250 4750 6250 4800
$Comp
L HFBR1528:HFBR1528 D1
U 1 1 5F97EAB2
P 4500 6350
F 0 "D1" V 4900 6350 50  0000 L CNN
F 1 "HFBR1528" V 5000 6300 50  0000 L CNN
F 2 "proj_footprints:HFBR25XX" H 4500 6350 50  0001 L BNN
F 3 "HFBR-1528" H 4500 6350 50  0001 L BNN
F 4 "06F6056" H 4500 6350 50  0001 L BNN "Field4"
F 5 "1247638" H 4500 6350 50  0001 L BNN "Field5"
F 6 "AGILENT TECHNOLOGIES" H 4500 6350 50  0001 L BNN "Field6"
	1    4500 6350
	0    -1   1    0   
$EndComp
$Comp
L HFBR2528:HFBR2528 D2
U 1 1 5F97EBA3
P 5750 6350
F 0 "D2" V 5350 6200 50  0000 C CNN
F 1 "HFBR2528" V 5250 6350 50  0000 C CNN
F 2 "proj_footprints:HFBR25XX" H 5750 6350 50  0001 L BNN
F 3 "HFBR-2528" H 5750 6350 50  0001 L BNN
F 4 "06F6096" H 5750 6350 50  0001 L BNN "Field4"
F 5 "1247664" H 5750 6350 50  0001 L BNN "Field5"
F 6 "AGILENT TECHNOLOGIES" H 5750 6350 50  0001 L BNN "Field6"
	1    5750 6350
	0    1    -1   0   
$EndComp
Wire Wire Line
	5000 6250 5000 6350
Connection ~ 5000 6350
Wire Wire Line
	5000 6350 5000 6450
Connection ~ 5000 6450
Wire Wire Line
	5000 6450 5000 6550
Connection ~ 5000 6550
$Comp
L power:GND #PWR03
U 1 1 5F99FC4C
P 5000 7200
F 0 "#PWR03" H 5000 6950 50  0001 C CNN
F 1 "GND" H 5005 7027 50  0000 C CNN
F 2 "" H 5000 7200 50  0001 C CNN
F 3 "" H 5000 7200 50  0001 C CNN
	1    5000 7200
	1    0    0    -1  
$EndComp
$Comp
L Device:R_Small R9
U 1 1 5F99FD17
P 4300 5850
F 0 "R9" H 4359 5896 50  0000 L CNN
F 1 "90" H 4359 5805 50  0000 L CNN
F 2 "Resistor_SMD:R_1206_3216Metric" H 4300 5850 50  0001 C CNN
F 3 "~" H 4300 5850 50  0001 C CNN
	1    4300 5850
	1    0    0    -1  
$EndComp
Wire Wire Line
	4150 5550 4300 5550
Wire Wire Line
	4300 5550 4300 5750
Connection ~ 4150 5550
Wire Wire Line
	4300 5950 4300 6050
$Comp
L Device:R_Small R10
U 1 1 5F9C3505
P 4500 5550
F 0 "R10" V 4304 5550 50  0000 C CNN
F 1 "2k" V 4395 5550 50  0000 C CNN
F 2 "Resistor_SMD:R_0603_1608Metric" H 4500 5550 50  0001 C CNN
F 3 "~" H 4500 5550 50  0001 C CNN
	1    4500 5550
	0    1    1    0   
$EndComp
Wire Wire Line
	4300 5550 4400 5550
Connection ~ 4300 5550
Wire Wire Line
	4600 5550 4700 5550
Connection ~ 4700 5550
Wire Wire Line
	4700 5550 4700 6050
$Comp
L Device:C_Small C6
U 1 1 5F9DB5F3
P 3950 5750
F 0 "C6" H 4050 5650 50  0000 R CNN
F 1 "1u" H 4100 5850 50  0000 R CNN
F 2 "Capacitor_SMD:C_0805_2012Metric" H 3950 5750 50  0001 C CNN
F 3 "~" H 3950 5750 50  0001 C CNN
	1    3950 5750
	-1   0    0    1   
$EndComp
$Comp
L Device:C_Small C7
U 1 1 5F9DB6BF
P 4150 5750
F 0 "C7" H 4250 5650 50  0000 R CNN
F 1 "100n" H 4350 5850 50  0000 R CNN
F 2 "Capacitor_SMD:C_0603_1608Metric" H 4150 5750 50  0001 C CNN
F 3 "~" H 4150 5750 50  0001 C CNN
	1    4150 5750
	-1   0    0    1   
$EndComp
Wire Wire Line
	3950 5650 3950 5550
Connection ~ 3950 5550
Wire Wire Line
	3950 5550 3850 5550
Wire Wire Line
	4150 5650 4150 5550
$Comp
L power:GND #PWR02
U 1 1 5F9F46A7
P 4150 5850
F 0 "#PWR02" H 4150 5600 50  0001 C CNN
F 1 "GND" H 4155 5677 50  0000 C CNN
F 2 "" H 4150 5850 50  0001 C CNN
F 3 "" H 4150 5850 50  0001 C CNN
	1    4150 5850
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR01
U 1 1 5F9F46EA
P 3950 5850
F 0 "#PWR01" H 3950 5600 50  0001 C CNN
F 1 "GND" H 3955 5677 50  0000 C CNN
F 2 "" H 3950 5850 50  0001 C CNN
F 3 "" H 3950 5850 50  0001 C CNN
	1    3950 5850
	1    0    0    -1  
$EndComp
Text Notes 4200 7600 0    50   ~ 0
Reduce TMIT current!!\n
Wire Wire Line
	5250 6250 5250 6450
Connection ~ 5250 6450
Wire Wire Line
	5250 6450 5250 6550
Wire Wire Line
	5250 6550 5000 6550
Connection ~ 5250 6550
Wire Wire Line
	5750 6050 5550 6050
$Comp
L power:+5V #PWR010
U 1 1 5FA4EA2A
P 9200 4700
F 0 "#PWR010" H 9200 4550 50  0001 C CNN
F 1 "+5V" H 9215 4873 50  0000 C CNN
F 2 "" H 9200 4700 50  0001 C CNN
F 3 "" H 9200 4700 50  0001 C CNN
	1    9200 4700
	-1   0    0    -1  
$EndComp
Wire Wire Line
	9200 4700 9400 4700
$Comp
L HFBR1528:HFBR1528 D4
U 1 1 5FA4EA36
P 8850 5500
F 0 "D4" V 9250 5450 50  0000 L CNN
F 1 "HFBR1528" V 9350 5450 50  0000 L CNN
F 2 "proj_footprints:HFBR25XX" H 8850 5500 50  0001 L BNN
F 3 "HFBR-1528" H 8850 5500 50  0001 L BNN
F 4 "06F6056" H 8850 5500 50  0001 L BNN "Field4"
F 5 "1247638" H 8850 5500 50  0001 L BNN "Field5"
F 6 "AGILENT TECHNOLOGIES" H 8850 5500 50  0001 L BNN "Field6"
	1    8850 5500
	0    1    1    0   
$EndComp
$Comp
L HFBR2528:HFBR2528 D3
U 1 1 5FA4EA40
P 7600 5500
F 0 "D3" V 7150 5500 50  0000 C CNN
F 1 "HFBR2528" V 7050 5550 50  0000 C CNN
F 2 "proj_footprints:HFBR25XX" H 7600 5500 50  0001 L BNN
F 3 "HFBR-2528" H 7600 5500 50  0001 L BNN
F 4 "06F6096" H 7600 5500 50  0001 L BNN "Field4"
F 5 "1247664" H 7600 5500 50  0001 L BNN "Field5"
F 6 "AGILENT TECHNOLOGIES" H 7600 5500 50  0001 L BNN "Field6"
	1    7600 5500
	0    -1   -1   0   
$EndComp
Wire Wire Line
	8350 5400 8350 5500
Connection ~ 8350 5500
Wire Wire Line
	8350 5500 8350 5600
Connection ~ 8350 5600
Wire Wire Line
	8350 5600 8350 5700
Connection ~ 8350 5700
$Comp
L power:GND #PWR09
U 1 1 5FA4EA4E
P 8350 6300
F 0 "#PWR09" H 8350 6050 50  0001 C CNN
F 1 "GND" H 8355 6127 50  0000 C CNN
F 2 "" H 8350 6300 50  0001 C CNN
F 3 "" H 8350 6300 50  0001 C CNN
	1    8350 6300
	-1   0    0    -1  
$EndComp
$Comp
L Device:R_Small R12
U 1 1 5FA4EA54
P 9050 5000
F 0 "R12" H 9109 5046 50  0000 L CNN
F 1 "90" H 9109 4955 50  0000 L CNN
F 2 "Resistor_SMD:R_1206_3216Metric" H 9050 5000 50  0001 C CNN
F 3 "~" H 9050 5000 50  0001 C CNN
	1    9050 5000
	-1   0    0    -1  
$EndComp
Wire Wire Line
	9200 4700 9050 4700
Wire Wire Line
	9050 4700 9050 4900
Connection ~ 9200 4700
Wire Wire Line
	9050 5100 9050 5200
$Comp
L Device:R_Small R11
U 1 1 5FA4EA60
P 8850 4700
F 0 "R11" V 8654 4700 50  0000 C CNN
F 1 "2k" V 8745 4700 50  0000 C CNN
F 2 "Resistor_SMD:R_0603_1608Metric" H 8850 4700 50  0001 C CNN
F 3 "~" H 8850 4700 50  0001 C CNN
	1    8850 4700
	0    -1   1    0   
$EndComp
Wire Wire Line
	9050 4700 8950 4700
Connection ~ 9050 4700
Wire Wire Line
	8750 4700 8650 4700
Wire Wire Line
	8650 4700 8650 5200
$Comp
L Device:C_Small C11
U 1 1 5FA4EA6C
P 9400 4900
F 0 "C11" H 9550 4800 50  0000 R CNN
F 1 "1u" H 9550 5000 50  0000 R CNN
F 2 "Capacitor_SMD:C_0805_2012Metric" H 9400 4900 50  0001 C CNN
F 3 "~" H 9400 4900 50  0001 C CNN
	1    9400 4900
	1    0    0    1   
$EndComp
$Comp
L Device:C_Small C10
U 1 1 5FA4EA73
P 9200 4900
F 0 "C10" H 9350 4800 50  0000 R CNN
F 1 "100n" H 9400 5000 50  0000 R CNN
F 2 "Capacitor_SMD:C_0603_1608Metric" H 9200 4900 50  0001 C CNN
F 3 "~" H 9200 4900 50  0001 C CNN
	1    9200 4900
	1    0    0    1   
$EndComp
Wire Wire Line
	9400 4800 9400 4700
Wire Wire Line
	9200 4800 9200 4700
$Comp
L power:GND #PWR011
U 1 1 5FA4EA7E
P 9200 5000
F 0 "#PWR011" H 9200 4750 50  0001 C CNN
F 1 "GND" H 9205 4827 50  0000 C CNN
F 2 "" H 9200 5000 50  0001 C CNN
F 3 "" H 9200 5000 50  0001 C CNN
	1    9200 5000
	-1   0    0    -1  
$EndComp
$Comp
L power:GND #PWR012
U 1 1 5FA4EA84
P 9400 5000
F 0 "#PWR012" H 9400 4750 50  0001 C CNN
F 1 "GND" H 9405 4827 50  0000 C CNN
F 2 "" H 9400 5000 50  0001 C CNN
F 3 "" H 9400 5000 50  0001 C CNN
	1    9400 5000
	-1   0    0    -1  
$EndComp
Wire Wire Line
	8100 5400 8100 5600
Connection ~ 8100 5600
Wire Wire Line
	8100 5600 8100 5700
Wire Wire Line
	8100 5700 8350 5700
Connection ~ 8100 5700
Wire Wire Line
	6950 5750 6950 5200
Wire Wire Line
	6950 5200 7800 5200
Wire Wire Line
	7100 5400 7100 6100
Wire Wire Line
	7100 6250 6850 6250
$Comp
L power:+5V #PWR07
U 1 1 5FAC6739
P 7250 6100
F 0 "#PWR07" H 7250 5950 50  0001 C CNN
F 1 "+5V" H 7265 6273 50  0000 C CNN
F 2 "" H 7250 6100 50  0001 C CNN
F 3 "" H 7250 6100 50  0001 C CNN
	1    7250 6100
	1    0    0    -1  
$EndComp
$Comp
L Device:C_Small C9
U 1 1 5FAD5F35
P 6850 6450
F 0 "C9" H 7050 6350 50  0000 R CNN
F 1 "1u" H 7050 6450 50  0000 R CNN
F 2 "Capacitor_SMD:C_0805_2012Metric" H 6850 6450 50  0001 C CNN
F 3 "~" H 6850 6450 50  0001 C CNN
	1    6850 6450
	1    0    0    1   
$EndComp
$Comp
L Device:C_Small C8
U 1 1 5FAD5F3C
P 6650 6450
F 0 "C8" H 6558 6404 50  0000 R CNN
F 1 "100n" H 6558 6495 50  0000 R CNN
F 2 "Capacitor_SMD:C_0603_1608Metric" H 6650 6450 50  0001 C CNN
F 3 "~" H 6650 6450 50  0001 C CNN
	1    6650 6450
	1    0    0    1   
$EndComp
$Comp
L power:GND #PWR06
U 1 1 5FAD5F43
P 6650 6550
F 0 "#PWR06" H 6650 6300 50  0001 C CNN
F 1 "GND" H 6655 6377 50  0000 C CNN
F 2 "" H 6650 6550 50  0001 C CNN
F 3 "" H 6650 6550 50  0001 C CNN
	1    6650 6550
	-1   0    0    -1  
$EndComp
$Comp
L power:GND #PWR08
U 1 1 5FAD5F49
P 6850 6550
F 0 "#PWR08" H 6850 6300 50  0001 C CNN
F 1 "GND" H 6855 6377 50  0000 C CNN
F 2 "" H 6850 6550 50  0001 C CNN
F 3 "" H 6850 6550 50  0001 C CNN
	1    6850 6550
	-1   0    0    -1  
$EndComp
Wire Wire Line
	6850 6350 6850 6250
Connection ~ 6850 6250
Wire Wire Line
	6650 6350 6650 6250
Connection ~ 6650 6250
Wire Wire Line
	6650 6250 6350 6250
$Comp
L ledbar:SN74LS07N U4
U 1 1 5FB5B0CA
P 6050 5100
F 0 "U4" V 6300 4650 60  0000 R CNN
F 1 "SN74LS07N" V 6200 4400 60  0000 R CNN
F 2 "Package_SO:SOIC-14_3.9x8.7mm_P1.27mm" H 6250 5300 60  0001 L CNN
F 3 "http://www.ti.com/general/docs/suppproductinfo.tsp?distId=10&gotoUrl=http%3A%2F%2Fwww.ti.com%2Flit%2Fgpn%2Fsn74ls07" H 6250 5400 60  0001 L CNN
F 4 "296-1629-5-ND" H 6250 5500 60  0001 L CNN "Digi-Key_PN"
F 5 "SN74LS07N" H 6250 5600 60  0001 L CNN "MPN"
F 6 "Integrated Circuits (ICs)" H 6250 5700 60  0001 L CNN "Category"
F 7 "Logic - Gates and Inverters" H 6250 5800 60  0001 L CNN "Family"
F 8 "http://www.ti.com/general/docs/suppproductinfo.tsp?distId=10&gotoUrl=http%3A%2F%2Fwww.ti.com%2Flit%2Fgpn%2Fsn74ls04" H 6250 5900 60  0001 L CNN "DK_Datasheet_Link"
F 9 "/product-detail/en/texas-instruments/SN74LS07N/296-1629-5-ND/277275" H 6250 6000 60  0001 L CNN "DK_Detail_Page"
F 10 "IC INVERTER 6CH 6-INP 14DIP" H 6250 6100 60  0001 L CNN "Description"
F 11 "Texas Instruments" H 6250 6200 60  0001 L CNN "Manufacturer"
F 12 "Active" H 6250 6300 60  0001 L CNN "Status"
	1    6050 5100
	0    -1   -1   0   
$EndComp
$Comp
L Connector:USB_B_Mini J1
U 1 1 5F73F73F
P 2500 3250
F 0 "J1" H 2555 3717 50  0000 C CNN
F 1 "Molex USB mini B 0548190519" H 2555 3626 50  0000 C CNN
F 2 "proj_footprints:USB_Mini_B_Female_548190519" H 2650 3200 50  0001 C CNN
F 3 "~" H 2650 3200 50  0001 C CNN
	1    2500 3250
	1    0    0    -1  
$EndComp
$Comp
L PCA9617A:PCA9617A U5
U 1 1 5FBC8E46
P 1350 5400
F 0 "U5" V 1950 4950 50  0000 R CNN
F 1 "PCA9617A" V 1850 4950 50  0000 R CNN
F 2 "digikey-footprints:TSSOP-8_W3mm" H 1350 5400 50  0001 C CNN
F 3 "" H 1350 5400 50  0001 C CNN
	1    1350 5400
	0    -1   -1   0   
$EndComp
Wire Wire Line
	3250 4200 1150 4200
Wire Wire Line
	1150 4200 1150 4900
Connection ~ 3250 4200
Wire Wire Line
	3350 4050 1650 4050
Wire Wire Line
	1650 4050 1650 4900
Connection ~ 3350 4050
$Comp
L power:+5V #PWR0121
U 1 1 5FC1A94D
P 750 4700
F 0 "#PWR0121" H 750 4550 50  0001 C CNN
F 1 "+5V" H 765 4873 50  0000 C CNN
F 2 "" H 750 4700 50  0001 C CNN
F 3 "" H 750 4700 50  0001 C CNN
	1    750  4700
	1    0    0    -1  
$EndComp
Wire Wire Line
	750  4700 750  4800
Wire Wire Line
	750  4800 1450 4800
Wire Wire Line
	1450 4800 1450 4900
Connection ~ 750  4800
Wire Wire Line
	750  4800 750  5150
$Comp
L power:GND #PWR0122
U 1 1 5FC3CA8C
P 2150 5550
F 0 "#PWR0122" H 2150 5300 50  0001 C CNN
F 1 "GND" H 2155 5377 50  0000 C CNN
F 2 "" H 2150 5550 50  0001 C CNN
F 3 "" H 2150 5550 50  0001 C CNN
	1    2150 5550
	1    0    0    -1  
$EndComp
Wire Wire Line
	2150 5400 2150 5550
$Comp
L Connector_Generic:Conn_02x06_Top_Bottom J2
U 1 1 5FC858D2
P 1450 6800
F 0 "J2" V 1546 7080 50  0000 L CNN
F 1 "Conn_02x06_Top_Bottom" V 1455 7080 50  0000 L CNN
F 2 "fmc:PMOD_PinHeader_2x06_P2.54mm_Horizontal" H 1450 6800 50  0001 C CNN
F 3 "~" H 1450 6800 50  0001 C CNN
	1    1450 6800
	0    1    -1   0   
$EndComp
$Comp
L Device:C_Small C12
U 1 1 5FCBA5A5
P 700 6750
F 0 "C12" H 608 6704 50  0000 R CNN
F 1 "1u" H 608 6795 50  0000 R CNN
F 2 "Capacitor_SMD:C_0805_2012Metric" H 700 6750 50  0001 C CNN
F 3 "~" H 700 6750 50  0001 C CNN
	1    700  6750
	-1   0    0    1   
$EndComp
Wire Wire Line
	750  5650 700  5650
Wire Wire Line
	700  5650 700  6050
Wire Wire Line
	1150 6500 1150 6350
Wire Wire Line
	1150 6350 950  6350
Connection ~ 700  6350
Wire Wire Line
	700  6350 700  6650
Wire Wire Line
	950  6350 950  7000
Wire Wire Line
	950  7000 1150 7000
Connection ~ 950  6350
Wire Wire Line
	950  6350 700  6350
$Comp
L power:GND #PWR0123
U 1 1 5FD33401
P 700 7300
F 0 "#PWR0123" H 700 7050 50  0001 C CNN
F 1 "GND" H 705 7127 50  0000 C CNN
F 2 "" H 700 7300 50  0001 C CNN
F 3 "" H 700 7300 50  0001 C CNN
	1    700  7300
	1    0    0    -1  
$EndComp
Wire Wire Line
	700  6850 700  7250
Wire Wire Line
	1250 7000 1250 7250
Wire Wire Line
	1250 7250 850  7250
Connection ~ 700  7250
Wire Wire Line
	700  7250 700  7300
Wire Wire Line
	1250 6550 1250 6500
Wire Wire Line
	1250 6450 850  6450
Wire Wire Line
	850  6450 850  7250
Connection ~ 1250 6500
Wire Wire Line
	1250 6500 1250 6450
Connection ~ 850  7250
Wire Wire Line
	850  7250 700  7250
Wire Wire Line
	1750 5900 1750 6200
Wire Wire Line
	1150 5900 1550 5900
Wire Wire Line
	1550 5900 1550 6050
$Comp
L Device:R_Small R13
U 1 1 5FDC3701
P 950 6050
F 0 "R13" V 900 5900 50  0000 C CNN
F 1 "1k6" V 900 6200 50  0000 C CNN
F 2 "Resistor_SMD:R_0603_1608Metric" H 950 6050 50  0001 C CNN
F 3 "~" H 950 6050 50  0001 C CNN
	1    950  6050
	0    1    1    0   
$EndComp
$Comp
L Device:R_Small R14
U 1 1 5FDC37CB
P 950 6200
F 0 "R14" V 900 6050 50  0000 C CNN
F 1 "1k6" V 900 6350 50  0000 C CNN
F 2 "Resistor_SMD:R_0603_1608Metric" H 950 6200 50  0001 C CNN
F 3 "~" H 950 6200 50  0001 C CNN
	1    950  6200
	0    1    1    0   
$EndComp
Wire Wire Line
	1050 6050 1550 6050
Wire Wire Line
	1050 6200 1750 6200
Wire Wire Line
	850  6200 700  6200
Connection ~ 700  6200
Wire Wire Line
	700  6200 700  6350
Wire Wire Line
	850  6050 700  6050
Connection ~ 700  6050
Wire Wire Line
	700  6050 700  6200
$Comp
L power:PWR_FLAG #FLG0102
U 1 1 5FE1C9E7
P 1150 6350
F 0 "#FLG0102" H 1150 6425 50  0001 C CNN
F 1 "PWR_FLAG" V 1150 6478 50  0000 L CNN
F 2 "" H 1150 6350 50  0001 C CNN
F 3 "~" H 1150 6350 50  0001 C CNN
	1    1150 6350
	0    1    1    0   
$EndComp
Connection ~ 1150 6350
NoConn ~ 1350 6500
NoConn ~ 1450 6500
NoConn ~ 1350 7000
NoConn ~ 1450 7000
NoConn ~ 1550 7000
NoConn ~ 1650 7000
$Comp
L Device:R_Small R15
U 1 1 5FEBF060
P 6350 6050
F 0 "R15" H 6409 6096 50  0000 L CNN
F 1 "10k" H 6409 6005 50  0000 L CNN
F 2 "Resistor_SMD:R_0603_1608Metric" H 6350 6050 50  0001 C CNN
F 3 "~" H 6350 6050 50  0001 C CNN
	1    6350 6050
	1    0    0    -1  
$EndComp
$Comp
L Device:R_Small R16
U 1 1 5FEEE04D
P 6650 6050
F 0 "R16" H 6709 6096 50  0000 L CNN
F 1 "10k" H 6709 6005 50  0000 L CNN
F 2 "Resistor_SMD:R_0603_1608Metric" H 6650 6050 50  0001 C CNN
F 3 "~" H 6650 6050 50  0001 C CNN
	1    6650 6050
	1    0    0    -1  
$EndComp
Wire Wire Line
	6650 6250 6850 6250
Wire Wire Line
	7250 6100 7100 6100
Connection ~ 7100 6100
Wire Wire Line
	7100 6100 7100 6250
Wire Wire Line
	6350 5950 5750 5950
Wire Wire Line
	5750 5950 5750 6050
Wire Wire Line
	6650 5950 6650 5750
Wire Wire Line
	6650 5750 6950 5750
Wire Wire Line
	6350 6150 6350 6250
Connection ~ 6350 6250
Wire Wire Line
	6350 6250 6250 6250
Wire Wire Line
	6650 6150 6650 6250
Wire Wire Line
	8350 5700 8350 6300
Wire Wire Line
	5000 6550 5000 7200
$Comp
L Device:R_Small R6
U 1 1 5FFAE814
P 7800 3450
F 0 "R6" H 7859 3496 50  0000 L CNN
F 1 "10k" H 7859 3405 50  0000 L CNN
F 2 "Resistor_SMD:R_0603_1608Metric" H 7800 3450 50  0001 C CNN
F 3 "~" H 7800 3450 50  0001 C CNN
	1    7800 3450
	1    0    0    -1  
$EndComp
Wire Wire Line
	8500 2900 8500 3650
Wire Wire Line
	8500 2650 8500 2900
Connection ~ 8500 2900
$Comp
L Device:CP_Small C5
U 1 1 5F7299D2
P 8600 2900
F 0 "C5" V 8825 2900 50  0000 C CNN
F 1 "10u" V 8734 2900 50  0000 C CNN
F 2 "Capacitor_Tantalum_SMD:CP_EIA-3216-10_Kemet-I" H 8600 2900 50  0001 C CNN
F 3 "~" H 8600 2900 50  0001 C CNN
	1    8600 2900
	0    -1   -1   0   
$EndComp
Wire Wire Line
	6100 2950 6100 2650
Connection ~ 6100 2950
$Comp
L Device:CP_Small C3
U 1 1 5F729952
P 6200 2950
F 0 "C3" V 6425 2950 50  0000 C CNN
F 1 "10u" V 6334 2950 50  0000 C CNN
F 2 "Capacitor_Tantalum_SMD:CP_EIA-3216-10_Kemet-I" H 6200 2950 50  0001 C CNN
F 3 "~" H 6200 2950 50  0001 C CNN
	1    6200 2950
	0    -1   -1   0   
$EndComp
NoConn ~ 4500 2050
NoConn ~ 4400 2050
Wire Wire Line
	5400 3550 6100 3550
Wire Wire Line
	5400 3300 4800 3300
Wire Wire Line
	4800 3300 4800 3450
Wire Wire Line
	4800 3450 4700 3450
Connection ~ 5400 3300
Wire Wire Line
	5400 3300 5400 3350
Connection ~ 4700 3450
Wire Wire Line
	4700 3450 4700 3500
Wire Wire Line
	6100 2950 6100 3550
Connection ~ 7800 3300
Wire Wire Line
	7800 3300 7800 3350
Wire Wire Line
	6900 3250 6900 3350
Connection ~ 6900 3350
Wire Wire Line
	6900 3350 7000 3350
Wire Wire Line
	7100 3250 7100 3300
Wire Wire Line
	7100 3300 7800 3300
Wire Wire Line
	6150 5400 6150 5750
Wire Wire Line
	6150 5750 6650 5750
Connection ~ 6650 5750
Wire Wire Line
	5900 3250 5900 4200
Connection ~ 5900 4200
Wire Wire Line
	5950 4800 6000 4800
Wire Wire Line
	5950 5400 6000 5400
Wire Wire Line
	6000 5400 6000 5550
Wire Wire Line
	6000 5550 6650 5550
Wire Wire Line
	6650 5550 6650 4450
Connection ~ 6000 5400
Wire Wire Line
	6000 5400 6050 5400
Connection ~ 6650 4200
Wire Wire Line
	6650 4200 8300 4200
Wire Wire Line
	6000 4800 6000 4700
Wire Wire Line
	6000 4700 8650 4700
Connection ~ 6000 4800
Wire Wire Line
	6000 4800 6050 4800
Connection ~ 8650 4700
Wire Wire Line
	3250 4200 5900 4200
Wire Wire Line
	5300 5450 5300 4450
Connection ~ 5300 4050
Wire Wire Line
	5300 4050 3350 4050
Wire Wire Line
	5300 4050 5800 4050
Connection ~ 5300 4450
Wire Wire Line
	5300 4450 5300 4050
Wire Wire Line
	4700 4700 4700 5550
Wire Wire Line
	5750 4450 5300 4450
Wire Wire Line
	5750 4800 5750 4450
Wire Wire Line
	5850 5450 5850 5400
Connection ~ 5750 5950
Wire Wire Line
	5750 5400 5750 5950
Wire Wire Line
	5850 4700 4700 4700
Wire Wire Line
	5850 4750 5850 4700
Wire Wire Line
	5850 4800 5850 4750
Connection ~ 5850 4750
Wire Wire Line
	5850 4750 6250 4750
Wire Wire Line
	5300 5450 5850 5450
Wire Wire Line
	5900 4200 6650 4200
Wire Wire Line
	6150 4800 6150 4450
Wire Wire Line
	6150 4450 6650 4450
Wire Wire Line
	6650 4450 6650 4200
Connection ~ 6650 4450
Connection ~ 5850 5450
Wire Wire Line
	6250 5450 5850 5450
Connection ~ 1750 6200
Wire Wire Line
	1750 6200 1750 6500
Connection ~ 1550 6050
Wire Wire Line
	1550 6050 1550 6500
Wire Wire Line
	1750 6500 1650 6500
Text Notes 9250 3500 0    50   ~ 0
Power Budget [mA]:\nPCA9617  max. 3.0,  typ 1.7\n74LVC07   max. 0.01 typ 0.0\nMCP2221A max. 15.0 typ 13.0\nPCA9955B  max. 19.0 typ 15.0 (* 2)\nLEDs (10k REXT) 5.7375*30\nI2C pullups  max. 6.9, typ 6.25\nHFBR25x max. 10, typ 6.2 (*2)\nHFBF15x max. 43, typ. 37.3 (*2)
Text Notes 8850 1950 0    50   Italic 0
NOTE:\nPCA9955BTW and PCA9955TW differ!\nI2C address strapping is different!\nB:      U2 => 0x69, U3 => 0x05 \nnon-B: U2 => 0x65, U3 => 0x61
Text Notes 900  3350 0    50   ~ 0
NOTE:\nFootprint swapped!\nMount from bottom side of PCB!
$EndSCHEMATC
