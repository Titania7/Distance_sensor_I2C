# Distance_sensor_I2C
I2C driver, testbench and software protocol for a Distance I2C sensor

## 1) I2C driver - I2C_M.vhd
This file takes into account the major parts of the components we will use in this project.
The sensor entity (which is an I2C type) is exposed with its important features like its input clock, its bus clock, enable pin, rw variable etc...
The important data we will use are the following, extracted from the general I2C master state diagram figure below :
  - **clk** : the clock of the device shall be connected to the one of the DEO-nano-SoC card controlling it ;
  - **ena** : '1' to enable the device ;
  - **addr** : the address of target slave = the distance sensor ;
  - **rw** : the read/write data variable : we will force it to zero since our sensor is read-only type ;
  - **busy** : to allow the state machine to end its task before beginning another one ;
  - **sda** : serial data output of the I2C_M bus ;
  - **scl** : serial clock output of the I2C_M bus.
 This part of the code works exactly the way it is described on the figure below.
 
 ![I2C_master_state_diagram](https://user-images.githubusercontent.com/74544161/118660105-2e311480-b7ee-11eb-8cf9-5206a2bdc8a2.png)


## 2) I2C distance sensor (VHDL coding for the testbench simuation) - I2C_M_TB.vhd
The role of this file is to simulate the working of the device by checking all the states it should encounter in a real practical case.



## 3) Arduino card - main.c

## 4) Executables
The last part of the project is the executable file loaded called "Distance_sensor-Dehon-Moulin" made with "Makefile".
