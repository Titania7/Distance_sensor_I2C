# Distance_sensor_I2C
I2C driver, testbench and software protocol for a Distance I2C sensor

## 0) Goal of the project
The aim of this project is to create a tutorial of how to retrieve distance via a sensor using an FPGA board and the I2C structure. In this project we will combine the software and hardware part of our hardware. 

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

The addresses of the registers and the device are given inside this file to simulate the functioning of the devices together :

![image](https://user-images.githubusercontent.com/74544161/118672580-a6043c80-b7f8-11eb-9381-4e303e6d6df6.png)


The ADDR register has the values that we want to writ and the DEVICE register has the the sensor's i2c address. As our device is read-only, we have forced the rw value to 1 so that it never get caught in the write case :

![image](https://user-images.githubusercontent.com/74544161/118672710-bddbc080-b7f8-11eb-8c63-af704addd0ad.png)

Once again the driver will have to follow a procedure :
  - s0 : Addressing for the configuration --- s0 if busy = 1 & s1 if busy = 0 ;
  - s1 : Configuration --- s1 if reg_rdy = 0 & s2 if reg_rdy = 1 ;
  - s2 : Awaiting of the measure --- s2 if val_rdy = 0 & s3 if val_rdy = 1 ;
  - s3 : Choice of the register for the measure --- s3 if busy = 1 & s4 if busy = 0 ;
  - s4 : Awaiting for the master to be ready --- s4 if reg_rdy = 0 & s5 if reg_rdy = 1 ;
  - s5 : The master reads the measure --- s5 if val_rdy = 0 & s3 if val_rdy = 1.


## 3) Arduino card - main.c

The C code is very simple. It has been adapted from a led-driven display and only takes the output of the sensor to display it on the serial output of the FPGA DEO-nano-SoC card. We initially use the h2p_lw_regout_addr pointer which has the distance information, as illustrated below :

![image](https://user-images.githubusercontent.com/74544161/118673886-a94bf800-b7f9-11eb-9bc1-eb5edfcaf0cf.png)

and then we simply send it into the serial output with a printf :

![image](https://user-images.githubusercontent.com/74544161/118674185-e2846800-b7f9-11eb-9394-e643657b3c1e.png)



## 4) Executables
The last part of the project is the executable file loaded called "Distance_sensor-Dehon-Moulin" made with "Makefile".

## 5) Demonstration video
The video available is called 'i2c_sensor_video.mp4'.

## 6) Other informations
Further information such as Testbench simulations and the like can be found in Tuto_I2C_Distance_Sensor.pdf. This document explains: How to create a driver for an I2C distance sensor matching a DEO-nano-SoC FPGA chip with Quartus.
