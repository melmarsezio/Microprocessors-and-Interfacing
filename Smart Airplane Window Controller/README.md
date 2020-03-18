# Smart Airplane Window Controller
#### Courseword project for Microprocessors & Interfacing
![](https://github.com/melmarsezio/Microprocessors-and-Interfacing/blob/master/Smart%20Airplane%20Window%20Controller/Project.png)
## Specification
In regards to project description, details are explained in [*`Project.pdf`*](https://github.com/melmarsezio/Microprocessors-and-Interfacing/blob/master/Smart%20Airplane%20Window%20Controller/Project.pdf)  

The assembly program file of this project is [*`Project.asm`*](https://github.com/melmarsezio/Microprocessors-and-Interfacing/blob/master/Smart%20Airplane%20Window%20Controller/Project.asm), and all I/O register names, I/O register bit names, X/Y/Z data pointers, highest RAM addresses for Internal SRAM are predefined in [*`m2560def.inc`*](https://github.com/melmarsezio/Microprocessors-and-Interfacing/blob/master/Smart%20Airplane%20Window%20Controller/m2560def.inc) by AVR  

A project instruction manual is also provided: [*`Project Instruction Manual.pdf`*](https://github.com/melmarsezio/Microprocessors-and-Interfacing/blob/master/Smart%20Airplane%20Window%20Controller/Project%20Instruction%20Manual.pdf)  

Generally, we have Push bottom, Keypads to control the opaque level of plane windows by emergency/ central pilot/ passanger.  
The opaque level is represented by the LED brightness (fully on -> fully opaque, fully off -> transparent) simulated by using PWM concept.  
Each window of different passangers are independent, they are only synchronized when emergency happens or pilot indicates to do so (either fully opaque or fully clear depend on the situation).  
Windows might set to clear when preparing for landing, and set to dark when passangers are resting.
