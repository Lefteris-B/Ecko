<p align="center">
  <img src="./images/ecko.png" />
</p>

# Ecko: A Keyword Spotting Accelerator for Caravel SoC

Ecko *(greek ἠχώ)* is an open-source hardware accelerator designed specifically for efficient and accurate Keyword Spotting (KWS) on edge devices. Leveraging the power of the "Hello Edge" CNN model and optimized for the caravel platform.
Ecko seamlessly integrates with the Caravel System-on-Chip to provide real-time speech recognition capabilities.


## Table of Contents
- [Introduction](#introduction)
  - [Features](#features)
- [Prompt Methodology](#prompt-methodology)
  - [Prompt Engineering](#prompt-engineering)
  - [Prompting Patterns](#prompting-patterns)
- [CNN KWS - Keyword Spotting using Convolutional Neural Networks](#cnn-kws---keyword-spotting-using-convolutional-neural-networks)
  - [Architecture Optimizations](#architecture-optimizations)
  - [Number Representation](#number-representation)
  - [Dataflows in AI Accelerators](#dataflows-in-ai-accelerators)
  - [Look Up Tables (LUTs)](#look-up-tables-luts)
  - [Dimensions](#dimensions)
  - [Pipelining](#pipelining)
  - [Quantization](#quantization)
  - [Pruning](#pruning)
- [Mel-frequency Cepstral Coefficients (MFCC) Implementation](#mel-frequency-cepstral-coefficients-mfcc-implementation)
  - [MFCC Implementation Computational Optimizations](#mfcc-implementation-computational-optimizations)
  - [MFCC Pipeline](#mfcc-pipeline)
- [Keyword Spotting (KWS)](#keyword-spotting-kws)
  - [KWS Dataflow](#kws-dataflow)
  - [KWS RAM Address Map](#kws-ram-address-map)
  - [CNN-KWS Model Architecture](#cnn-kws-model-architecture)
  - [CNN-KWS Layers](#cnn-kws-layers)
  - [Computational Optimizations](#computational-optimizations)
- [Testing](#testing)
- [Verification](#verification)
- [License](#license)
- [Efabless Repository and Files](#efabless-repository-and-files)




## Introduction
Ecko aims to push the boundaries of what's possible with AI accelerators on the Caravel SoC, focusing on minimal power consumption and maximal efficiency for Keyword Spotting applications.

### Features
- **Efficient Keyword Spotting**: Utilizes a compact, optimized CNN model for fast and accurate speech recognition.
- **Low Power Consumption**: Designed with energy efficiency in mind, ideal for battery-operated devices.
- **Seamless Integration**: Fully compatible with the Caravel SoC environment, making it easy to adopt in existing projects.
- **Parameterizable**: The project is designed to be highly parameterizable, allowing for easy adjustment of key parameters such as frame size, fixed-point precision, and zero-padding size, enabling flexible adaptation to various application requirements and resource constraints.


[↟Back to Top](#ecko-a-keyword-spotting-accelerator-for-caravel-soc)


## Prompt Methodology
The Prompt Methodology is a central aspect of our approach to leveraging generative AI within the hardware design process. We use advanced prompt engineering techniques to facilitate complex reasoning and context-aware responses from the AI models, tailored specifically for digital design tasks.

### Prompt Engineering
Digital design is a really complex task that requires complex reasoning and produces context-aware responses. These tasks (like creating an FSM) require multiple intermediate reasoning steps. We utilized generative AI to develop the keyword spotting (KWS) design by employing advanced prompt patterns [(paper: https://doi.org/10.48550/arXiv.2302.11382)](https://doi.org/10.48550/arXiv.2302.11382) and prompt engineering techiques [(paper: https://doi.org/10.48550/arXiv.2402.07927)](https://doi.org/10.48550/arXiv.2402.07927):

1. [Chain of thought](https://doi.org/10.48550/arXiv.2201.11903) for context-aware responses

Using chain of thought in prompting large language models (LLMs) helps to generate context-aware responses by breaking down complex tasks into smaller, logical steps. This method ensures coherence and accuracy in the AI's reasoning process.

![Chain of Thought in Prompt Engineering](/images/prompt_eng.png)


2. [Visualization-of-Thought](https://doi.org/10.48550/arXiv.2404.03622) for Spatial Reasoning.

Visualization-of-Thought for spatial reasoning is crucial when prompting LLMs as it aids in understanding and communicating complex spatial relationships and structures. It transforms abstract concepts into concrete visuals, enhancing comprehension and facilitating more effective problem-solving. This is a novel technique used in LLMs in order to facilitate a comprehensive understanding of the relationships and intricacies of data and their connection to multidimensional inputs, weights, and biases, ultimately resulting in enhancing the design's clarity and effectiveness.

![CVisualization-of-Thought](/images/vot.png)


### Prompting Patterns
To refine the process of interacting with LLMs, we employed two specific prompting patterns [(paper: https://doi.org/10.48550/arXiv.2302.11382)](https://doi.org/10.48550/arXiv.2302.11382): e

**Recipe**: The recipe prompt pattern works by providing a structured, step-by-step framework for generating responses, akin to following a recipe. Each step includes specific instructions or questions, guiding the AI through a logical progression. This method ensures thoroughness and consistency, improving the clarity and quality of the generated content.

![Recipe](/images/recipe.png)

**Persona**: We then used the Persona prompt pattern to:

- Provide the LLM with intent (for example, “Act as a digital engineer”) and conceptualize context (refactor the code, provide Verilog files).
- Give the LLM motivation to achieve a certain task (for example, “refactor the code to provide extended functionality”).
- Structure fundamental contextual statements around key ideas (for example, “Provide code that a digital designer would create”).
- Provide example code for the LLM to follow along using the Chain of Thought prompt engineering technique (for example, “This part of code ‘X’ from my codebase needs new features.”).


These approaches enabled the LLMs to provide detailed, step-by-step explanations and maintain coherence throughout complex tasks.

[↟Back to Top](#ecko-a-keyword-spotting-accelerator-for-caravel-soc)

## CNN KWS - Keyword Spotting using Convolutional Neural Networks 

Convolutional Neural Networks (CNNs) are central to the Ecko project, providing the backbone for our efficient and accurate Keyword Spotting (KWS) system. The CNN-KWS model, specifically tailored for KWS tasks, was introduced in the influential paper ["Hello Edge: Keyword Spotting on Microcontrollers"](https://doi.org/10.48550/arXiv.1711.07128) by Zhang et al. (2017). This model has proven to be highly effective in recognizing keywords from audio inputs with minimal computational resources, making it ideal for edge devices like those powered by the Caravel SoC.

We used the paper ["Integer-Only Approximated MFCC for Ultra-Low Power Audio NN Processing on Multi-Core MCUs" - https://doi.org/10.1109/AICAS51828.2021.9458491](https://doi.org/10.1109/AICAS51828.2021.9458491) with LP16 to develop the MFCC, as it provides a methodology for implementing efficient MFCC extraction using integer arithmetic. This approach is well-suited for ultra-low power audio processing on resource-constrained devices, ensuring energy efficiency and performance optimization.

The adoption of these models in Ecko leverages its compact architecture to maximize performance while maintaining low power consumption. This architecture aligns with our project's goals to create a KWS system that not only operates efficiently in real-time on edge devices but also minimizes energy usage and space requirements. The CNN-KWS model's ability to achieve high accuracy with a relatively small footprint makes it the ideal choice for embedding sophisticated AI capabilities directly onto microcontrollers and SoCs, where space and power are at a premium.

### Architecture optimizations 

### Number Representation 
Choosing the appropriate number representation is pivotal in influencing the accuracy, area, and energy cost of hardware accelerators. Common number systems include integers, floats, and brain floats (bfloats). Integers are typically used for quantized models, offering lower energy cost and area but at a potential loss of accuracy. Floats, including the standard IEEE 754 and bfloat16, provide a wider dynamic range, which is beneficial for maintaining the precision of calculations. Bfloats are a compromise, providing enough precision for deep learning while reducing complexity. The selection of number representation is a critical design decision that impacts the trade-offs between accuracy, computational area, and energy efficiency.


![Number Representation Impact](/images/number_representation.png)

![Energy Cost of Different Number Representations](/images/number_energy_cost.png)

We chose integers as the number representation in our design to enhance computational efficiency and reduce power consumption. Integer arithmetic is less demanding on hardware resources compared to floating-point operations, making it ideal for ultra-low power and real-time processing applications on resource-constrained devices.


### Dataflows in AI Accelerators
Dataflows in AI accelerators define how data moves through various processing elements, influencing the efficiency and performance of neural network computations. Common dataflows include weight stationary, output stationary, and row stationary, each optimizing different aspects of memory and computation by strategically managing the reuse of weights, activations, or partial sums.

#### Why We Used "Weight Stationary" Dataflow
We used the "Weight Stationary" dataflow in our design to maximize the reuse of weights by keeping them stationary in the local memory of processing elements. This approach minimizes the costly data movement of weights, reduces memory access latency, and optimizes power efficiency, making it ideal for our resource-constrained, low-power AI accelerator.

![Dataflow Optimizations ](/images/dataflow.png)

### Look Up Tables (LUTs)

Usage of LUTs for Computational Optimizations in Our Modules
In our modules, Look-Up Tables (LUTs) are employed to enhance computational efficiency by precomputing and storing frequently used values. This approach eliminates the need for repeated complex calculations, significantly speeding up operations. For instance, in the logarithm module, LUTs store precomputed values of 
log
⁡
(
2
)
log(2) and other constants, enabling rapid access during runtime. Similarly, in the Mel filter and windowing operations, LUTs provide precomputed filter coefficients and window functions, facilitating quick dot product computations and windowing processes. By leveraging LUTs, we reduce the computational burden, lower power consumption, and achieve real-time performance in our signal processing tasks. Notably, all LUT results were calculated using Python scripts generated by large language models (LLMs) and are included in the /scripts folder of our repository.

### Dimensions
The dimensions of the hardware and software components significantly influence the system's overall capabilities. The size of the hardware components, such as memory size, directly correlates with the computational power and throughput. Complexity arises from the integration of multiple components and the need for precise timing and control logic. Scalability is a key design feature, allowing the system to adapt to different KWS models and workloads, ensuring that our accelerator can meet both current and future demands without requiring complete redesigns.

### Pipelining
Pipelining is a crucial feature that enhances the execution of matrix multiplication operations, a common task in deep learning models. By effectively using pipelining, we can overlap the execution of multiple instructions, which helps to utilize the hardware more efficiently and increase the throughput. Specifically, we leveraged external memories by using a pseudo-ram interface that holds the same data across different pipeline stages to improve energy consumption. This approach reduces the need for repeated memory accesses for the same data, thus saving power,time and space. Pipelining is particularly effective in deep neural network computations where such data reusability is common. 

### Quantization
We implemented integer-only quantization, reducing the precision of weights and activations to int8. This optimization significantly lowered memory usage and enhanced computational speed, fitting our low-power design requirements.

### Pruning
Our design involved pruning less significant weights and neurons from the neural network, resulting in a smaller and more efficient model. This optimization reduced the model size and sped up inference without compromising accuracy.

[↟Back to Top](#ecko-a-keyword-spotting-accelerator-for-caravel-soc)

## Mel-frequency Cepstral Coefficients (MFCC) implementation

[Mel Frequency Cepstral Coefficients (MFCC) - (https://doi.org/10.1016/B978-0-323-91776-6.00016-6)](https://doi.org/10.1016/B978-0-323-91776-6.00016-6) are features used in audio processing, particularly in speech and audio recognition tasks. MFCCs represent the short-term power spectrum of a sound signal, using a nonlinear Mel scale to approximate human ear perception. The process involves transforming the audio signal into the frequency domain using the Fast Fourier Transform (FFT), applying a Mel filter bank to emphasize perceptually important frequencies, taking the logarithm to compress the dynamic range, and finally applying the Discrete Cosine Transform (DCT) to decorrelate the features, producing a compact representation that captures the essential characteristics of the audio signal.
Bellow is a visual representation of the mfcc module using a **SysML** BDD diagram.

```
audio_sample 
    |
    v
+------------------------------+
|   Pre-Emphasis               |
| Input: audio_sample          |
| Output: pre_emphasized_sample|
+------------------------------+
    |
    v
+------------------------------------------------------------------------------+
|      Framing                                                                 |
| Input: pre_emphasized_sample                                                 |
| Output: frames                                                               |
| Params: frame_length, frame_step                                             |
| Calculation: frames = frame(pre_emphasized_sample, frame_length, frame_step) |
+------------------------------------------------------------------------------+
    |
    v
+----------------------------------------------------------------+
|     Windowing                                                  |
| Input: frames                                                  |
| Output: windowed_frames                                        |
| Params: window_function                                        |
| Calculation: windowed_frames = window(frames, window_function) |
+----------------------------------------------------------------+
    |
    v
+--------------------------------------------------------+
|       FFT                                              |
| Input: windowed_frames                                 |
| Output: magnitude_spectrum                             |
| Calculation: magnitude_spectrum = fft(windowed_frames) |
+--------------------------------------------------------+
    |
    v
+-----------------------------------------------------------------------------+
|   Mel Filter Bank                                                           |
| Input: magnitude_spectrum                                                   |
| Output: mel_spectrum                                                        |
| Params: num_mel_filters                                                     |
| Calculation: mel_spectrum = mel_filter(magnitude_spectrum, num_mel_filters) |
+-----------------------------------------------------------------------------+
    |
    v
+---------------------------------------------------+
|     Logarithm                                     |
| Input: mel_spectrum                               |
| Output: log_mel_spectrum                          |
| Calculation: log_mel_spectrum = log(mel_spectrum) |
+---------------------------------------------------+
    |
    v
+---------------------------------------------------------------------------+
|       DCT                                                                 |
| Input: log_mel_spectrum                                                   |
| Output: mfcc_features                                                     |
| Params: num_mfcc_coefficients                                             |
| Calculation: mfcc_features = dct(log_mel_spectrum, num_mfcc_coefficients) |
+---------------------------------------------------------------------------+
    |
    v
mfcc_features

```
The MFCC pipeline processes audio samples by first applying pre-emphasis to amplify high frequencies, then segmenting the signal into overlapping frames. Each frame is windowed to reduce spectral leakage before performing an FFT to obtain the magnitude spectrum. The spectrum is then filtered using a Mel filter bank, followed by logarithmic scaling, and finally, a Discrete Cosine Transform (DCT) is applied to produce the MFCC features. This pipeline efficiently extracts critical audio features for further processing in the KWS application.

![mfcc pipeline ](/images/mfcc.png)

### MFCC Implementation Computational Optimizations

1. Framing Filter
- In the framing module, computational efficiency is achieved by using fixed-point arithmetic to handle overlapping frames, minimizing the computational overhead compared to floating-point operations. The Hanning window module applies a precomputed window function to each frame, utilizing efficient memory access patterns and minimizing redundant calculations. Window functions are applied to each frame of the signal to mitigate spectral leakage, which can distort the frequency representation. 
- The Hanning window is commonly used for this purpose due to its smooth tapering characteristics that reduce the amplitude of the discontinuities at the boundaries of each frame. This window effectively minimizes side lobes in the periodogram, resulting in a cleaner and more accurate power spectral density estimate. By applying the Hanning window, we ensure that the computed periodogram faithfully represents the signal's frequency components, crucial for accurate audio feature extraction.
By leveraging symmetry properties of the Hanning window and using integer-only operations, the overall computational load is reduced, enhancing performance and power efficiency in resource-constrained environments. These optimizations ensure real-time processing capabilities essential for audio applications.

2. FFT
- In our FFT modules, computational optimizations were achieved by using the squared module of complex values, known as the periodogram, to calculate the power spectrum. This approach avoids the highly expensive square root function required in traditional complex module computations. By focusing on the squared values, we significantly reduced the computational complexity and improved the efficiency of the FFT process, making it more suitable for real-time audio processing on low-power devices. 
- This optimization ensures faster execution while maintaining the accuracy needed for subsequent audio feature extraction steps. By applying shift operations prior to the the sum, the two additions and two multiplications that make up the Radix-2 FFT's basic computation match the scaling factors of the fixed-point operands. Multiplying and shifting the fixed point values and the int16 twiddles (fixed-point Q15) yields the FFT products. 

3. MEL Filters
- In the Mel filter module, we optimized computations by leveraging the dot product between the periodogram power spectrum and a set of precomputed triangular filter banks. This approach efficiently aggregates spectral energy into Mel frequency bands by performing simple multiplications and additions, eliminating the need for more complex operations. 
- By using integer arithmetic for these dot products, we further reduce computational overhead, ensuring faster processing and lower power consumption. These optimizations make the Mel filtering step both efficient and effective for real-time audio feature extraction on resource-constrained hardware.
In order to calculate the Mel energies, we perform a dot-product operation between the int32 data, specifically the Periodogram, and the non-zero elements of the sparse Mel filter banks. In order to minimize memory use, we keep only the initial and final indices of the non-zero items in the triangle filters.

4. Logarithm calculation
- In the logarithm module for fixed-point data, we exploit the intrinsic properties of the logarithm operator to optimize computations. The logarithm of each value is computed as 
log
⁡
(
𝑥
[
𝑖
]
)
=
log
⁡
(
𝑋
[
𝑖
]
⋅
2
−
𝑄
[
𝑖
]
)
=
log
⁡
(
𝑋
[
𝑖
]
)
−
𝑄
[
𝑖
]
⋅
log
⁡
(
2
)
log(x[i])=log(X[i]⋅2 
−Q[i]
 )=log(X[i])−Q[i]⋅log(2), where 
log
⁡
(
2
)
log(2) is stored as a fixed-point constant. The term 
log
⁡
(
𝑋
[
𝑖
]
)
log(X[i]) is approximated using a 3rd order Taylor series, relying solely on integer operations. This approach ensures efficient computation without floating-point arithmetic. The resulting fixed-point int16 elements produced by the logarithm operator share a consistent scaling factor 
𝑄
Q. Subsequently, the DCT operation involves a dot product between the log outputs and the int16 DCT coefficient matrix in Q15 format. Through empirical analysis, we found that using a Q11 format for the log outputs and a Q4 format for the DCT outputs provides an optimal balance between dynamic range and precision for real-valued numbers, enhancing the overall efficiency and accuracy of the processing pipeline.

5. Usage of LUTs for Computational Optimizations in Our Modules.
- In our modules, Look-Up Tables (LUTs) are employed to enhance computational efficiency by precomputing and storing frequently used values. This approach eliminates the need for repeated complex calculations, **significantly** speeding up operations. For instance, in the logarithm module, LUTs store precomputed values of 
log
⁡
(
2
)
log(2) and other constants, enabling rapid access during runtime. Similarly, in the Mel filter and windowing operations, LUTs provide precomputed filter coefficients and window functions, facilitating quick dot product computations and windowing processes. By leveraging LUTs, we reduce the computational burden, lower power consumption, and achieve real-time performance in our signal processing tasks.
- Notably, all LUT results were calculated using Python scripts generated by large language models (LLMs) and are included in the /scripts folder of our repository.

### MFCC Pipeline


```
+------------+    +-------------+    +---------+    +---------+    +--------+    +--------+    +----------+    
|  Hanning   | -> | Periodogram | -> |   Pow   | -> |   Log   | -> |  Mel   | -> |  DCT   | -> | MFCC_out |
|  Windowing |    +-------------+    +---------+    +---------+    +--------+    +--------+    +----------+    
+------------+
```

The MFCC (Mel Frequency Cepstral Coefficients) dataflow in the cnn_kws_accel module starts with the audio_sample input, which is fed into the mfcc_accel module. The mfcc_accel module processes the raw audio signal to extract MFCC features, which are a compact representation of the power spectrum of the audio signal. This is achieved by applying a series of transformations: pre-emphasis, framing, windowing, fast Fourier transform (FFT), Mel filter bank processing, and discrete cosine transform (DCT). The resulting mfcc_feature output is a set of coefficients that capture the essential characteristics of the audio signal, making it suitable for further processing in the subsequent stages of the CNN-based keyword spotting accelerator.

The implementation utilizes a Verilog-based approach and incorporates various optimizations for resource-constrained environments.

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



[↟Back to Top](#ecko-a-keyword-spotting-accelerator-for-caravel-soc)


## Keyword Spoting (KWS)

Keyword spotting (KWS) is a specialized task in speech recognition that focuses on detecting specific keywords or phrases within an audio stream. Unlike full speech recognition systems that transcribe entire utterances, keyword spotting systems are designed to recognize predefined words or commands, making them ideal for applications such as voice-activated assistants, command-and-control interfaces, and wake-word detection (e.g., "Hey Siri" or "OK Google").

### KWS Dataflow 

```
mfcc_accel-> conv2d_psram (conv1) -> conv2d_psram (conv2) -> fully_connected_psram (fc1) -> fully_connected_psram (fc2) -maxpool2d_sram -> softmax_psram
```

The dataflow in the cnn_kws_accel module begins in the IDLE state, waiting for a start signal. Once triggered, it transitions to the MFCC (Mel Frequency Cepstral Coefficients) extraction stage, where audio features are computed. The data then flows to the first convolutional layer (conv2d_psram (conv1)) for initial feature extraction, followed by a second convolutional layer (conv2d_psram (conv2)) for further processing. The output is passed to the first fully connected layer (fully_connected_psram (fc1)) to integrate the features, then to a second fully connected layer (fully_connected_psram (fc2)) for deeper integration. Subsequently, the data is processed by the max pooling layer (maxpool2d_sram) to downsample the features and reduce dimensionality. Finally, the data reaches the softmax layer (softmax_psram), where probabilities are computed for classification. The completion of this stage indicates the end of the processing sequence.

### KWS RAM address map

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


### CNN-KWS model architecture

1. Input: Mel-frequency cepstral coefficients (MFCC) features extracted from the audio signal.
2. Convolutional layers: Two or three convolutional layers with small kernel sizes (e.g., 3x3) and a small number of filters (e.g., 32 or 64) to learn local patterns in the MFCC features.
3. Pooling layers: Max pooling layers to reduce the spatial dimensions and provide translation invariance.
4. Fully connected layers: One or two fully connected layers to learn high-level representations and perform classification.
5. Output layer: A softmax layer to produce the probability distribution over the keyword classes.

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
### CNN-KWS Layers 

Layer Details:
Input Layer MFCC
Signal Width: 40 bits
Convolution Layer 1

Dimensions: 128x128x16
Kernel Size: 3x3
Stride: 1
Signal Width: 16 bits
Pooling Layer 1

Dimensions: 64x64x16
Pool Size: 2x2
Stride: 2
Signal Width: 16 bits
Convolution Layer 2

Dimensions: 32x32x32
Kernel Size: 3x3
Stride: 1
Signal Width: 32 bits
Pooling Layer 2

Dimensions: 16x16x32
Pool Size: 2x2
Stride: 2
Signal Width: 32 bits
Fully Connected Layer

Dimensions: 128
Signal Width: 32 bits
Output Layer

Dimensions: 10
Signal Width: 32 bits

### Computational Optimizations 

The cnn_kws_accel module employs several computational optimizations to enhance performance and efficiency in keyword spotting applications:
1.It utilizes parameterizable layers, allowing for tailored configurations that balance accuracy and resource usage according to specific application requirements. Convolution operations are optimized by leveraging parallel processing techniques, which significantly reduce the computational latency. 
2. The module also implements efficient memory management strategies, such as input and output buffering, to minimize data transfer overhead. By applying fixed-point arithmetic rather than floating-point, the design achieves lower power consumption and faster execution, which is critical for real-time processing in embedded systems. 
3. The use of smaller kernel sizes and stride adjustments in convolution and pooling layers reduces the amount of data processed, further enhancing the speed and efficiency of the model. 

These optimizations collectively enable the cnn_kws_accel to perform rapid and accurate keyword detection while maintaining a low power footprint, making it suitable for deployment in resource-constrained environments like mobile and IoT devices.


[↟Back to Top](#ecko-a-keyword-spotting-accelerator-for-caravel-soc)

## Testing
Each model was tested using SystemVerilog assertions. That involves writing testbenches that not only apply test cases but also include assertions to verify that the modules behave as expected. 

[↟Back to Top](#ecko-a-keyword-spotting-accelerator-for-caravel-soc)

## Verification
Formal verification is a powerful technique that uses mathematical methods to prove the correctness of a design. We verified the KWS accelerator pipeline using the SymbiYosys (sby) front-end and the Yosys open synthesis suite.

[↟Back to Top](#ecko-a-keyword-spotting-accelerator-for-caravel-soc)


## License

Ecko is open source and freely available to the community under the Apache License 2.0. This licensing choice supports our commitment to open innovation and collaboration. 

For more detailed information, please refer to the LICENSE file located in the root directory of this repository.

[↟Back to Top](#ecko-a-keyword-spotting-accelerator-for-caravel-soc)

## Efabless repo\GDS files\lef-def-spef files
[https://github.com/Lefteris-B/ecko_efabless](https://github.com/Lefteris-B/ecko_efabless)


