# Distance_sensor_I2C
I2C driver, testbench and software protocol for a Distance I2C sensor

## 1) I2C driver - I2C_M.vhd
This file takes into account the major parts of the components we will use in this project.
The sensor entity (which is an I2C type) is expossed with its important features like its input clock, its bus clock, enable pin, rw variable etc...
The important data we will use are the following :

## 2) I2C distance sensor (VHDL coding for the testbench simuation) - I2C_M_TB.vhd

## 3) Arduino card - main.c

## 4) Executables
The last part of the project is the executable file loaded called "Distance_sensor-Dehon-Moulin" made with "Makefile".
