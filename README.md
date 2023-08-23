# SNN-Accelerator
A three-layer LIF neuron SNN accelerator. 
The first layer is the input layer and has 784 neurons, that receive the encoded spikes. The second layer is the hidden layer and has 100 neurons; the last layer is the output layer with 10 neurons.

## Design Spec
The following figure is my block diagram. It takes one image as input at a time, and by modifying the IMAGE in the testbench, different images can be used to obtain test results. There are several registers in the top module, which differ from those provided by the teaching assistant.
![Designspec](https://github.com/hsieh672/SNN-Accelerator/blob/main/image/design%20spec.jpg)
#### (1) en_compute_FC1
The input trigger is used to start computing FC1. When en_compute_FC1 = 1, start to compute the output spike in the hidden layer.
#### (2) en_compute_FC1_finish
The output trigger is used to start checking the answer of FC1. When en_compute_FC1_finish = 1, start to check the answer of the output spike in the hidden layer.
#### (3) en_compute_FC2
The input trigger is used to start computing FC2. When en_compute_FC2 = 1, start to compute the output spike in the output layer.
#### (4) en_compute_FC2_finish
The output trigger is used to start checking the answer of FC2. When en_compute_FC2_finish = 1, start to check the answer of the output spike in the output layer.

## FSM
The following figure is the FSM of the whole system. The inside controllers of FC1/FC2 are the same. The timestep of each image is the most important part of the whole system. Because we need to use the membranes of the previous timestep, so we need to save them for each timestep. I used several counters to count the timesteps and the address of SRAM A and SRAM B.
![FSM](https://github.com/hsieh672/SNN-Accelerator/blob/main/image/FSM.jpg)
#### (1) count_en_spike / count_en_spike_l2: 
The trigger is used to determine whether generates a spike in FC1 and FC2.
#### (2) count_pastmem / count_pastmem_l2: 
The trigger is used to count the membranes of the previous timestep in FC1 (0-99) and FC2 (0-9).
#### (3) count_timestep / count_timestep_l2:
The counter is used to count 0 to 34 timesteps of each layer.
#### (4) count_addr_A / count_addr_B: 
The counter is used to count the address of SRAM A (0-3499) and SRAM B (0-349).
#### (5) count_addr_A_for_B:
The counter is used to count the address of SRAM A which used to be the input spike of FC2.
#### (6) count_addr_A_check_ans / count_addr_A_check_ans: 
The counter is used to count the address of SRAM A (0-3499) and SRAM B (0-349) which is used to check the answers in the testbench.
