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

