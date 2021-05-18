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
It simulates the I2C sensor (which will be a slave one) and the driver (a master) together, by plugging their respective entries together as illustrated in the figure below :

![image](https://user-images.githubusercontent.com/74544161/118664017-6c7c0300-b7f1-11eb-9c33-bd7ca719481b.png)

Once again the driver will have to follow a procedure :
  - s0 : Addressing for the configuration --- s0 if busy = 1 & s1 if busy = 0 ;
  - s1 : Configuration --- s1 if reg_rdy = 0 & s2 if reg_rdy = 1 ;
  - s2 : Awaiting of the measure --- s2 if val_rdy = 0 & s3 if val_rdy = 1 ;
  - s3 : Choice of the register for the measure --- s3 if busy = 1 & s4 if busy = 0 ;
  - s4 : Awaiting for the master to be ready --- s4 if reg_rdy = 0 & s5 if reg_rdy = 1 ;
  - s5 : The master reads the measure --- s5 if val_rdy = 0 & s3 if val_rdy = 1.
test


## 3) Arduino card - main.c

## 4) Executables
The last part of the project is the executable file loaded called "Distance_sensor-Dehon-Moulin" made with "Makefile".
