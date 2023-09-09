# SNN-Accelerator
A three-layer LIF neuron SNN accelerator. 
The first layer is the input layer, with 784 neurons that receive the encoded spikes. The second layer is the hidden layer with 100 neurons; the last layer is the output layer with ten neurons.

## Design Spec
The following figure is my block diagram. It takes one image as input at a time, and by modifying the IMAGE in the testbench, different images can be used to obtain test results. There are several registers in the top module, which differ from those provided by the teaching assistant.
![Designspec](https://github.com/hsieh672/SNN-Accelerator/blob/main/image/design%20spec.jpg)
#### (1) en_compute_FC1
The input trigger is used to start computing FC1. When en_compute_FC1 = 1, add the output spike in the hidden layer.
#### (2) en_compute_FC1_finish
The output trigger is used to start checking the answer of FC1. When en_compute_FC1_finish = 1, study the response of the output spike in the hidden layer.
#### (3) en_compute_FC2
The input trigger is used to start computing FC2. When en_compute_FC2 = 1, add the output spike in the output layer.
#### (4) en_compute_FC2_finish
The output trigger is used to start checking the answer of FC2. When en_compute_FC2_finish = 1, study the response of the output spike in the output layer.

## FSM
The following figure is the FSM of the whole system. The inside controllers of FC1/FC2 are the same. The timestep of each image is the most essential part of the system. Because we need to use the membranes of the previous timestep, we need to save them for each. I used several counters to count the timesteps and the addresses of SRAM A and SRAM B.
![FSM](https://github.com/hsieh672/SNN-Accelerator/blob/main/image/FSM.jpg) 

## Membranes Potential
![timestep](https://github.com/hsieh672/SNN-Accelerator/blob/main/image/timestep.jpg) 
  
The total timesteps I chose is 35. First, divide the timesteps into 0 and 1-34. In the software simulation, in the first layer, Vth = 68 in the second layer, Vth = 91. I use the following formula to calculate mem:
![timestep0](https://github.com/hsieh672/SNN-Accelerator/blob/main/image/timestep0.jpg)  
  
In timestep 1 to 34, I need to use the membranes after resetting from the previous timestep. So, in timestep 0, I first output and record the reset membranes in the top module. When I reach timestep 1, I then input these values.
![timestep1to34](https://github.com/hsieh672/SNN-Accelerator/blob/main/image/timestep1to34.jpg)
