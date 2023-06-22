#include <firmware_apis.h> // include required APIs
void user_isr(void);
void main(){
    // use managment gpio for communication between firmware and gpio
    ManagmentGpio_write(0);
    ManagmentGpio_outputEnable();
    User_enableIF(); // enable communication user interface 
    IRQ_enableUser0(1);
    // start timer from time 1:45 by writing to register 1
    USER_writeWord(0x145,0);
    while (1)
        if (flag == 1)
            user_isr();
}

void user_isr(void){
    ManagmentGpio_write(1);
    // clear irq 
    flag = 0;
    USER_writeWord(0x1,2);
    IRQ_enableUser0(0);
    IRQ_enableUser0(1);
    // user_irq_0_ev_pending_i0_write(1); // to clear the interrupt
    // write new alarm value
    USER_writeWord(0x300,0);

    ManagmentGpio_write(0);

}