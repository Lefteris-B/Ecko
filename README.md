# Ecko: A Keyword Spotting Accelerator for Caravel SoC

Ecko *(greek ἠχώ)* is an open-source hardware accelerator designed specifically for efficient and accurate Keyword Spotting (KWS) on edge devices. Leveraging the power of the "Hello Edge" CNN model and optimized for the caravel platform.
Ecko seamlessly integrates with the Caravel System-on-Chip to provide real-time speech recognition capabilities.

## Table of Contents
- [Introduction](#introduction)
- [Convolutional Neural Networks (CNNs)](#convolutional-neural-networks-cnn)
- [Mel-frequency Cepstral Coefficients (MFCC)](#mel-frequency-cepstral-coefficients-mfcc)
- [Features](#features)
- [Layers](#layers)
- [Verification](#verification)
- [License](#license)


### Introduction
Ecko aims to push the boundaries of what's possible with AI accelerators on the Caravel SoC, focusing on minimal power consumption and maximal efficiency for Keyword Spotting applications.

[Back to Top](#ecko-a-keyword-spotting-accelerator-for-caravel-soc)


### CNN KWS - Keyword Spotting using Convolutional Neural Networks 

Convolutional Neural Networks (CNNs) are central to the Ecko project, providing the backbone for our efficient and accurate Keyword Spotting (KWS) system. The CNN-KWS model, specifically tailored for KWS tasks, was introduced in the influential paper ["Hello Edge: Keyword Spotting on Microcontrollers"](https://doi.org/10.48550/arXiv.1711.07128) by Zhang et al. (2017). This model has proven to be highly effective in recognizing keywords from audio inputs with minimal computational resources, making it ideal for edge devices like those powered by the Caravel SoC.

The adoption of the CNN-KWS model in Ecko leverages its compact architecture to maximize performance while maintaining low power consumption. This architecture aligns with our project's goals to create a KWS system that not only operates efficiently in real-time on edge devices but also minimizes energy usage and space requirements. The CNN-KWS model's ability to achieve high accuracy with a relatively small footprint makes it the ideal choice for embedding sophisticated AI capabilities directly onto microcontrollers and SoCs, where space and power are at a premium.

## KWS Dataflow 

```
mfcc_accel-> conv2d_psram (conv1) -> conv2d_psram (conv2) -> fully_connected_psram (fc1) -> fully_connected_psram (fc2) -maxpool2d_sram -> softmax_psram
```

The dataflow in the cnn_kws_accel module begins in the IDLE state, waiting for a start signal. Once triggered, it transitions to the MFCC (Mel Frequency Cepstral Coefficients) extraction stage, where audio features are computed. The data then flows to the first convolutional layer (conv2d_psram (conv1)) for initial feature extraction, followed by a second convolutional layer (conv2d_psram (conv2)) for further processing. The output is passed to the first fully connected layer (fully_connected_psram (fc1)) to integrate the features, then to a second fully connected layer (fully_connected_psram (fc2)) for deeper integration. Subsequently, the data is processed by the max pooling layer (maxpool2d_sram) to downsample the features and reduce dimensionality. Finally, the data reaches the softmax layer (softmax_psram), where probabilities are computed for classification. The completion of this stage indicates the end of the processing sequence.

## KWS RAM address map

In the our imlementation, pseudo-static RAM (PSRAM) plays a crucial role in managing the temporary storage and retrieval of intermediate data between various processing stages. During the execution of convolutional layers, fully connected layers, and other operations, large amounts of data are generated and need to be efficiently stored and accessed. PSRAM provides a high-density, cost-effective memory solution that balances the speed of SRAM with the density of DRAM, making it suitable for embedded applications like keyword spotting (KWS). By leveraging PSRAM, the accelerator can handle the memory demands of complex neural network computations without incurring the higher costs and power consumption associated with traditional memory solutions, thereby enabling real-time processing and improving overall system performance.

Address Map Explanation: 

1. Convolution Layer 1: 
- conv1_weight_base_addr: 0x000000 
- conv1_bias_base_addr: 0x000100 

2. Convolution Layer 2: 
- conv2_weight_base_addr: 0x000200 
- conv2_bias_base_addr: 0x000300 

3. Fully Connected Layer 1: 
- fc1_weight_base_addr: 0x000400 
- fc1_bias_base_addr: 0x000500 

4. Fully Connected Layer 2: 
- fc2_weight_base_addr: 0x000600 
- fc2_bias_base_addr: 0x000700 

5. Max Pooling Layer: 
- maxpool_input_addr: 0x000800 
- maxpool_output_addr: 0x000900 

6. Softmax Layer: 
- softmax_input_addr: 0x000A00 
- softmax_output_addr: 0x000B00 

This address map helps visualize how the different weights, biases, and data for each layer are 
organized in memory. Each module's base address is separated by 0x100 to ensure no overlap and 
allow easy access to the data stored for each layer. 


**Topdown visualization using SysML BDD Diagram**
```
audio_sample 
    |
    v
mfcc_accel
    |
    v
mfcc_feature
    |
    v
+--------------+                                +--------------------------+
| conv2d_psram | <------------------------------| conv1_weight_base_addr   |
|    (conv1)   |                                | 24'h000000               |
|              | <------------------------------| conv1_bias_base_addr     |
|              |                                | 24'h000300               |
|              |                                +--------------------------+
| Params:      |
| INPUT_WIDTH  |                                  Calculation:
| 40           |                                  conv1_data_out = conv2d(mfcc_feature, weights, biases)
| INPUT_HEIGHT | 
| 1            |
| INPUT_CHANNELS|
| 1            |
| KERNEL_SIZE  |
| 3            |
| NUM_FILTERS  |
| 8            |
| PADDING      |
| 1            |
| ACTIV_BITS   |
| 16           |
+--------------+
    |
    v
conv1_data_out
    |
    v
+--------------+                                +--------------------------+
| conv2d_psram | <------------------------------| conv2_weight_base_addr   |
|    (conv2)   |                                | 24'h000600               |
|              | <------------------------------| conv2_bias_base_addr     |
|              |                                | 24'h000900               |
|              |                                +--------------------------+
| Params:      |
| INPUT_WIDTH  |                                  Calculation:
| 40           |                                  conv2_data_out = conv2d(conv1_data_out, weights, biases)
| INPUT_HEIGHT |
| 1            |
| INPUT_CHANNELS|
| 8            |
| KERNEL_SIZE  |
| 3            |
| NUM_FILTERS  |
| 16           |
| PADDING      |
| 1            |
| ACTIV_BITS   |
| 16           |
+--------------+
    |
    v
conv2_data_out
    |
    v
+----------------------+                       +--------------------------+
| fully_connected_psram| <---------------------| fc1_weight_base_addr     |
|        (fc1)         |                       | 24'h000C00               |
|                      | <---------------------| fc1_bias_base_addr       |
|                      |                       | 24'h001400               |
|                      |                       +--------------------------+
| Params:              |
| INPUT_SIZE           |                         Calculation:
| 640                  |                         fc1_data_out = fully_connected(conv2_data_out, weights, biases)
| OUTPUT_SIZE          |
| 64                   |
| ACTIV_BITS           |
| 16                   |
+----------------------+
    |
    v
fc1_data_out
    |
    v
+----------------------+                       +--------------------------+
| fully_connected_psram| <---------------------| fc2_weight_base_addr     |
|        (fc2)         |                       | 24'h001600               |
|                      | <---------------------| fc2_bias_base_addr       |
|                      |                       | 24'h001800               |
|                      |                       +--------------------------+
| Params:              |
| INPUT_SIZE           |                         Calculation:
| 64                   |                         fc2_data_out = fully_connected(fc1_data_out, weights, biases)
| OUTPUT_SIZE          |
| 32                   |
| ACTIV_BITS           |
| 16                   |
+----------------------+
    |
    v
fc2_data_out
    |
    v
+----------------------+                       
| maxpool2d_sram       |
|                      |
| Params:              |
| INPUT_WIDTH          |                         Calculation:
| 40                   |                         maxpool_data_out = maxpool(fc2_data_out)
| INPUT_HEIGHT         |
| 1                    |
| INPUT_CHANNELS       |
| 16                   |
| KERNEL_SIZE          |
| 2                    |
| STRIDE               |
| 2                    |
| ACTIV_BITS           |
| 16                   |
| ADDR_WIDTH           |
| 24                   |
+----------------------+
    |
    v
maxpool_data_out
    |
    v
+----------------------+                       
| softmax_psram        |
|                      |
| Params:              |                         Calculation:
| INPUT_SIZE           |                         softmax_data_out = softmax(maxpool_data_out)
| 10                   |
| ACTIV_BITS           |
| 8                    |
| ADDR_WIDTH           |
| 24                   |
+----------------------+
    |
    v
softmax_data_out
```




## The MFCC
```
audio_sample -> mfcc_accel -> mfcc_feature
```

The MFCC (Mel Frequency Cepstral Coefficients) dataflow in the cnn_kws_accel module starts with the audio_sample input, which is fed into the mfcc_accel module. The mfcc_accel module processes the raw audio signal to extract MFCC features, which are a compact representation of the power spectrum of the audio signal. This is achieved by applying a series of transformations: pre-emphasis, framing, windowing, fast Fourier transform (FFT), Mel filter bank processing, and discrete cosine transform (DCT). The resulting mfcc_feature output is a set of coefficients that capture the essential characteristics of the audio signal, making it suitable for further processing in the subsequent stages of the CNN-based keyword spotting accelerator.

#### Advantages

1. Compact architecture: The model consists of a few convolutional layers followed by fully connected layers, making it relatively lightweight and suitable for resource-constrained hardware.

2. High accuracy: Despite its compact size, the CNN-KWS model achieves high accuracy in keyword spotting tasks, with reported accuracies of over 90% on popular KWS datasets like the Google Speech Commands dataset.

3. Compatibility with hardware: The convolutional and fully connected layers in the CNN-KWS model can be efficiently mapped to hardware resources like multiply-accumulate (MAC) units and memory buffers, enabling parallel and pipelined execution.

4. Energy efficiency: The compact size and hardware-friendly architecture of the CNN-KWS model make it energy-efficient, which is crucial for battery-powered devices and edge computing scenarios.

#### CNN-KWS model architecture

1. Input: Mel-frequency cepstral coefficients (MFCC) features extracted from the audio signal.
2. Convolutional layers: Two or three convolutional layers with small kernel sizes (e.g., 3x3) and a small number of filters (e.g., 32 or 64) to learn local patterns in the MFCC features.
3. Pooling layers: Max pooling layers to reduce the spatial dimensions and provide translation invariance.
4. Fully connected layers: One or two fully connected layers to learn high-level representations and perform classification.
5. Output layer: A softmax layer to produce the probability distribution over the keyword classes.

[Back to Top](#ecko-a-keyword-spotting-accelerator-for-caravel-soc)


### Mel-frequency Cepstral Coefficients (MFCC)

Audio Features Extractor
This repository contains an implementation of an audio features extractor, focusing on efficiency and low power consumption. The project is inspired by the paper "Integer-Only Approximated MFCC for Ultra-Low Power Audio NN Processing on Multi-Core MCUs". The implementation utilizes a Verilog-based approach and incorporates various optimizations for resource-constrained environments.

Methodology
The implementation follows an optimized processing pipeline, incorporating the following steps:

1. Hamming Windowing: The input audio samples are processed using the Hamming window function to reduce spectral leakage and improve frequency estimation accuracy.

2. Periodogram Calculation: Instead of using the traditional Fast Fourier Transform (FFT), a Periodogram module is employed to compute the squared magnitude of complex values. This avoids the expensive square root operation and reduces computational complexity.

3. Power Computation: A power module is introduced after the Periodogram stage to compute the power of the signal. This involves appropriate scaling to prevent overflow and maintain accuracy.

4. Mel Filtering: Mel filtering is implemented as a sparse matrix multiply operation, with Mel filter coefficients stored in ROM. This step is crucial for capturing human auditory perception characteristics.

5. Logarithmic Compression: A logarithmic operation is applied to the output of the Mel filtering stage to compress the dynamic range of the features.

6. Discrete Cosine Transform (DCT): Finally, a fixed-point INT16 DCT is performed to transform the logarithmic features into a compact representation suitable for further processing or analysis.
Implementation Details

Top-Level Module: The Verilog implementation includes a top-level module with INT16 input and output ports for audio samples and MFCC features, respectively. Control signals are provided to manage the processing stages.

Sub-Modules: Each processing stage is instantiated as a sub-module within the top-level design. These modules are designed to efficiently handle the specified operations while maintaining low resource utilization.

Optimizations: Various optimizations are applied at each stage, including the use of fixed-point arithmetic, lookup tables, and ROM storage for coefficients and intermediate results.



[Back to Top](#ecko-a-keyword-spotting-accelerator-for-caravel-soc)

### Features
- **Efficient Keyword Spotting**: Utilizes a compact, optimized CNN model for fast and accurate speech recognition.
- **Low Power Consumption**: Designed with energy efficiency in mind, ideal for battery-operated devices.
- **Seamless Integration**: Fully compatible with the Caravel SoC environment, making it easy to adopt in existing projects.

[Back to Top](#ecko-a-keyword-spotting-accelerator-for-caravel-soc)

### Layers

1. Input: Mel-frequency cepstral coefficients (MFCC) features extracted from the audio signal.
2. Convolutional layers: Two or three convolutional layers with small kernel sizes (e.g., 3x3) and a small number of filters (e.g., 32 or 64) to learn local patterns in the MFCC features.
3. Pooling layers: Max pooling layers to reduce the spatial dimensions and provide translation invariance.
4. Fully connected layers: One or two fully connected layers to learn high-level representations and perform classification.
5. Output layer: A softmax layer to produce the probability distribution over the keyword classes.

[Back to Top](#ecko-a-keyword-spotting-accelerator-for-caravel-soc)

### Verification

Verification of the Ecko accelerator is a critical step in ensuring its functionality, performance, and compatibility with the Caravel SoC. We employ a rigorous verification strategy that includes both simulation and hardware-based testing. Initially, the design is verified through extensive simulation using standard EDA tools to simulate the CNN-KWS model's behavior and to ensure that it meets the predefined specifications for accuracy and performance.

Additionally, we can leverage the Caravel SoC's built-in testing and debugging features to monitor the performance of the Ecko accelerator. This includes tracking power consumption, processing speed, and memory usage, which are crucial for assessing the system's efficiency. The results from these tests could help us to fine-tune the design, optimize performance, and ensure seamless integration with the Caravel environment.

[Back to Top](#ecko-a-keyword-spotting-accelerator-for-caravel-soc)


### License

Ecko is open source and freely available to the community under the Apache License 2.0. This licensing choice supports our commitment to open innovation and collaboration. 

For more detailed information, please refer to the LICENSE file located in the root directory of this repository.

[Back to Top](#ecko-a-keyword-spotting-accelerator-for-caravel-soc)


[Back to Top](#ecko-a-keyword-spotting-accelerator-for-caravel-soc)

