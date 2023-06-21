#include <firmware_apis.h> // include required APIs
void main(){
    // use managment gpio for communication between firmware and gpio
    ManagmentGpio_write(0);
    ManagmentGpio_outputEnable();
    User_enableIF(); // enable communication user interface 
    // start timer from time 3:33 by writing to register 1
    USER_writeWord(0x333,1);
    ManagmentGpio_write(1);
}