# Ecko: A Keyword Spotting Accelerator for Caravel SoC

Ecko is an open-source hardware accelerator designed specifically for efficient and accurate Keyword Spotting (KWS) on edge devices. Leveraging the power of the "Hello Edge" CNN model and optimized through the Gemmini platform, Ecko seamlessly integrates with the Caravel System-on-Chip to provide real-time speech recognition capabilities.

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

### Convolutional Neural Networks (CNNs)

Convolutional Neural Networks (CNNs) are central to the Ecko project, providing the backbone for our efficient and accurate Keyword Spotting (KWS) system. The CNN-KWS model, specifically tailored for KWS tasks, was introduced in the influential paper "Hello Edge: Keyword Spotting on Microcontrollers" by Zhang et al. (2017). This model has proven to be highly effective in recognizing keywords from audio inputs with minimal computational resources, making it ideal for edge devices like those powered by the Caravel SoC.

The adoption of the CNN-KWS model in Ecko leverages its compact architecture to maximize performance while maintaining low power consumption. This architecture aligns with our project's goals to create a KWS system that not only operates efficiently in real-time on edge devices but also minimizes energy usage and space requirements. The CNN-KWS model's ability to achieve high accuracy with a relatively small footprint makes it the ideal choice for embedding sophisticated AI capabilities directly onto microcontrollers and SoCs, where space and power are at a premium.

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
To design the input stage for the KWS accelerator, which involves extracting Mel-frequency cepstral coefficients (MFCC) features from the audio signal, we'll implement the MFCC feature extraction algorithm  several steps, including pre-emphasis, framing, windowing, Fourier transform, mel-filterbank, logarithm, and discrete cosine transform (DCT).

Here's a high-level overview of the components (Verilog Modules) for the MFCC feature extraction:

1. Audio input interface:
   - Design an interface to receive the audio samples from an external source, such as an analog-to-digital converter (ADC) or a digital audio interface (e.g., I2S).
   - Implement the necessary control signals and data registers to capture and store the audio samples.

2. Pre-emphasis filter:
   - Apply a high-pass filter to the audio samples to emphasize higher frequencies and improve signal-to-noise ratio.
   - Implement the pre-emphasis filter using a simple first-order finite impulse response (FIR) filter in Verilog.

3. Framing and windowing:
   - Divide the audio samples into overlapping frames of fixed size (e.g., 25ms) with a certain stride (e.g., 10ms).
   - Apply a window function (e.g., Hamming window) to each frame to reduce spectral leakage.
   - Implement the framing and windowing operations using shift registers and multipliers in Verilog.

4. Fourier transform:
   - Compute the Fourier transform of each windowed frame to convert the time-domain signal into the frequency domain.
   - Implement the Fast Fourier Transform (FFT) algorithm in Verilog, using a combination of butterfly operations and twiddle factor multiplications.

5. Mel-filterbank:
   - Apply a set of triangular mel-scale filters to the frequency spectrum to extract the mel-frequency components.
   - Implement the mel-filterbank using a bank of triangular filters, each centered at a specific mel-frequency, and accumulate the energy in each filter using multipliers and adders in Verilog.

6. Logarithm:
   - Take the logarithm of the mel-filterbank energies to compress the dynamic range and mimic human perception of loudness.
   - Implement the logarithm operation using a lookup table (LUT) or an approximation algorithm (e.g., Taylor series) in Verilog.

7. Discrete Cosine Transform (DCT):
   - Apply DCT to the log mel-filterbank energies to decorrelate the features and obtain the final MFCC coefficients.
   - Implement the DCT algorithm in Verilog using a combination of butterfly operations and cosine factor multiplications.

8. Output interface:
   - Design an interface to output the computed MFCC features to the subsequent stages of the KWS accelerator, such as the CNN model.
   - Implement the necessary control signals and data registers to transfer the MFCC features.

#### MFCC feature extraction optimization

1. Fixed-point arithmetic: Use fixed-point representation for the audio samples and intermediate calculations to reduce hardware complexity and resource utilization.

2. Pipelining: Divide the MFCC algorithm into multiple pipeline stages to improve throughput and enable parallel processing of audio frames.

3. Resource sharing: Share hardware resources, such as multipliers and adders, across different stages of the MFCC algorithm to minimize area and power consumption.

4. Approximations: Explore approximations for complex operations like logarithm and DCT to simplify hardware implementation while maintaining acceptable accuracy.



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

