# ECG Signal Processing using IIR Filters

## 📋 Project Overview
This project focuses on the design and implementation of Infinite Impulse Response (IIR) digital filters to process and denoise raw Electrocardiogram (ECG) signals. The primary objective is to remove common noise sources such as baseline wander, high-frequency interference, and power line noise to extract a clean ECG signal for analysis.

## 🛠 Features & Filter Specifications
This project utilizes a combination of **Elliptic** and **Notch** filters to achieve optimal noise suppression with minimal filter order.

### 1. High Pass Filter (HPF)
* **Filter Type:** **Elliptic**
* **Purpose:** Removes low-frequency noise, specifically **baseline wander** caused by respiration or patient movement.
* **Characteristics:** The Elliptic design is chosen for its sharp transition band, allowing effective removal of low frequencies without attenuating the QRS complex.

### 2. Low Pass Filter (LPF)
* **Filter Type:** **Elliptic**
* **Purpose:** Eliminates high-frequency noise, such as electromyographic (EMG) interference and other sensor noise.
* **Characteristics:** Provides a steep rolloff to efficiently cut off high frequencies while maintaining a lower filter order compared to Butterworth or Chebyshev approximations.

### 3. Notch Filter
* **Filter Type:** **IIR Notch**
* **Center Frequency:** **50 Hz**
* **Purpose:** Specifically designed to reject **Power Line Interference (PLI)** at 50 Hz, which is a common artifact in biomedical signal acquisition.

## 💻 Technologies & Tools
* **Language:** MATLAB, Verilog
* **Toolbox:** HDL Coder

## 📊 Results
* **Raw Signal:** Contains visible baseline drift and 50Hz superposed noise.
* **Filtered Signal:**
    * Baseline wander is stabilized using the Elliptic HPF.
    * High-frequency artifacts are smoothed out by the Elliptic LPF.
    * The 50Hz interference is effectively suppressed by the Notch filter, revealing distinct P, Q, R, S, and T waves.
