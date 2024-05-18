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

