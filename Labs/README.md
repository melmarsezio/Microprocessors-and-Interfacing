# Labs
## All labs for Microprocessors & Interfacing
### Lab 1a  
[*`lab_1a.asm`*](https://github.com/melmarsezio/Microprocessors-and-Interfacing/blob/master/Labs/lab_1a.asm): This program code reads two char as ascii code, and translates them into binary digital number.  
Two ways of interpretation: decimal or hexadecimal, and we use 1st bit (1 or 0) as indication of hexadecimal or decimal.  
e.g. : `'1 0x37 0x38'` interpretes as `'0x78'` (hexadecimal number) and `'0b0111 1000'` in binary form.  
&emsp;&emsp;&emsp;`'0 0x37 0x38'` interpretes as `'78'` (decimal number) and `'0b0100 1110'` in binary form.  
### Lab 1b  
[*`lab_1b.asm`*](https://github.com/melmarsezio/Microprocessors-and-Interfacing/blob/master/Labs/lab_1b.asm): This program code reads two 2-bytes unsigned integers (0~65535), and calculates their greatest common divisor.  
e.g. : `72 & 40` gives `8`, `12 & 18` gives `6`.  
### Lab 2a  
[*`lab_2a.asm`*](https://github.com/melmarsezio/Microprocessors-and-Interfacing/blob/master/Labs/lab_2a.asm): Similar to Lab_1b, instead, this program code implements it within a function (so it can be called multiple times).
### Lab 2b  
[*`lab_2b.asm`*](https://github.com/melmarsezio/Microprocessors-and-Interfacing/blob/master/Labs/lab_2b.asm): This program code makes the AVR Microcontroller Board repeatedly display 3 patterns through LED. LED halt when PB0 is pressed, and resume when PB1 is released. There are 0.5s deleys between two adjacent patterns.
### Lab 3  
[*`lab_3.asm`*](https://github.com/melmarsezio/Microprocessors-and-Interfacing/blob/master/Labs/lab_3.asm): This program code gets two number from keypad and display the multiplication of them on LCD. Use the "\*" key for "x" and the "#" key for "=".  
e.g. : To calculate `12X9`, we press: `'1','2','*','9','#'`. This multiplicative calculator can only handle unsigned 1-byte integers (for inputs and output), so LED flashes 3 times when result overflows.
### Lab 4  
[*`lab_4.asm`*](https://github.com/melmarsezio/Microprocessors-and-Interfacing/blob/master/Labs/lab_4.asm): This program code measures the speed of the motor (based on the number of holes that are detected by the shaft encoder) and displays the speed on LCD. The motor speed can be adjusted by the POT (potentiometer).
