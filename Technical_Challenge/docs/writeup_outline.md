# LFM Matched Filter -- Design & Performance

Arye Mindell 4/24/2026

---

## 1. Overview
This project delivers a LFM Matched Filter system for isolating radar chirps in in-phase and quadrature components. The output of the system is one isolated IQ chirp per pulse repetition interveal (PRI).

The system was designed to maximize precision and robustness under the conditions of an offline MATLAB simulation, with recognition that different tradeoffs would be made on a production device with tighter resource constraints. 

The system achieved a 

- **P_d = 90% SNR point:** ___
- **SOF RMS at that point:** ___
- **Delta-f tolerance:** +/- ___ kHz
- **P_fa observed:** ___  (target 1e-4 per PRI)
---

## 2. Spec & Objective

The objective was to optimize the matched filter system for robustness to a range of SNRs, and frequency offsets, while maintaining efficiency, preformance, and readable code. The system was designed to the following specifications:
| Parameter    | Value                                   |
| ------------ | --------------------------------------- |
| Sample rate  | 100 MHz                                 |
| Sweep        | alternates up/down between pulses       |
| PW           | 100 us (up), 200 us (down)              |
| Sweep range  | 30->60 kHz (up), 60->30 kHz (down)      |
| PRF          | 1 kHz                                   |
| Constraints  | no toolbox code                         |

---

## 3. Architecture

```
wave generator -> channel (noise + freq offset) -> decimator -> dual MF -> detector -> arbitration -> output
```

- **Generator:** produces complex-baseband LFM chirps (up: 30->60 kHz over 100 us; down: 60->30 kHz over 200 us) at a configurable sample rate, used for both waveform synthesis and MF template construction.
- **Channel:** adds complex AWGN at a specified SNR and applies a bulk frequency offset Delta-f to model carrier mismatch between transmitter and receiver.
- **Decimator:** Hamming-windowed sinc LPF (passband 100 kHz, stopband at fs_dec/2 = 250 kHz) followed by D = 200 downsampling, taking 100 MSps to 500 kHz.
- **Dual MF:** two parallel banks (one per chirp direction), each bank containing 9 templates tiled across Delta-f bins from -10 kHz to +10 kHz in 2.5 kHz steps; per-sample output is the max |corr|^2 over the bank.
- **Detector:** per-bank threshold |corr|^2 > K * sigma_hat^2, with K set to meet the 1e-4 per-PRI false-alarm budget (Bonferroni-corrected across samples and doppler bins); noise variance estimated from the median of |corr|^2.
- **Arbitration:** within a window of max(N_up, N_down) samples, drops the weaker detection when the stronger peak exceeds it by a ratio of >=2, resolving cross-template leakage between up/down banks.
- **Output:** pulse IQ, metadata, debug stream

---

## 4. Design Notes

### 4.1 Decimation
Decimation is handled by a single-stage FIR that drops the 100 MSps ADC rate to 500 kHz (D = 200). 500 kHz strikes a balance between sitting comfortably above the Nyquist rate of the 30-60 kHz chirp band and substantially reducing resource usage. The anti-alias filter is a Hamming-windowed sinc with passband 100 kHz and stopband at fs_dec/2 = 250 kHz; tap count follows the standard transition-width rule N = 2*round(1.65*fs/df) + 1, giving ~2201 taps. A single stage was used rather than a cascaded chain for simplicity under time constraints at the cost of compute.

### 4.2 MF Implementation
The matched filter is a direct-form FIR operating at the decimated 500 kHz rate, with 50 taps for the up-chirp and 100 taps for the down-chirp; direct-FIR was preferred over FFT-based correlation because at this tap count it is nearly as fast and considerably simpler to observe and debug. To cover Delta-f tolerance, each chirp direction is realized as a bank of 9 templates tiled across Delta-f bins from -10 kHz to +10 kHz in 2.5 kHz steps, with the per-sample MF output taken as the maximum |corr|^2 across the bank. The two banks run as independent parallel filters, a simple approach but sufficient under time constraints; their outputs are reconciled by a post-correlation arbitration rule: within a window of max(N_up, N_down) samples, the weaker peak is suppressed whenever the stronger exceeds it by a ratio of >=2. No taper is applied to the templates, trading SLL for precision; a windowed variant was evaluated but offered no net benefit.

### 4.3 Detection
Detection runs on |corr|^2 with a runtime-normalized threshold |corr|^2 > K * sigma_hat^2. The per-sample statistic is the max over K_bins = 9 doppler filters, so under H0 its CDF is (1 - exp(-x/sigma^2))^K_bins, whose tail approximates to K_bins * exp(-K) in the regime of interest. Budgeting the 1e-4 per-PRI false-alarm target across the ~500 samples per PRI and the 9 bins gives a per-sample-per-bin budget of ~2.2e-8, hence K = -ln(P_fa / (N_samp * K_bins)) = -ln(1e-4 / (500 * 9)) ~ 17.6 — a Bonferroni correction across both samples and bins. The noise variance is estimated at runtime as sigma_hat^2 = median(|corr|^2) / (-ln(1 - 2^(-1/K_bins))), inverting the median of the max-of-K_bins exponential CDF; this reduces to the familiar median/ln(2) when K_bins = 1 and grows with K_bins to remove the upward bias introduced by the max. The median is preferred to the mean because it remains robust when signal samples are present in the estimation window. Above-threshold runs separated by less than PRI/2 samples are merged into a single detection, exploiting the spec guarantee of at most one pulse per PRI to suppress shoulder-driven double-counts.

### 4.4 Peak Refinement
Sub-sample peak location is recovered by parabolic interpolation on the three |corr|^2 samples straddling the coarse peak, offset = 0.5 * (y[-1] - y[+1]) / (y[-1] - 2*y[0] + y[+1]), clipped to [-0.5, +0.5] to guard against noise.

---

## 5. Performance Results

> `[code]` load results_primary.mat, results_surface.mat  (guard with exist())

### 5.1 P_d / P_fa vs. SNR @ Delta-f = 0
`[fig]` -- caption: ___

### 5.2 SOF RMS vs. SNR with CRLB overlay
`[fig]` -- caption: ___

### 5.3 SNR x Delta-f surface
`[fig]` P_d surface | `[fig]` SOF RMS surface -- caption: ___

### 5.4 Up/Down bias cancellation
`[fig]` three curves (up, down, averaged) vs. Delta-f -- caption: ___

### 5.5 Windowed vs. unwindowed single-pulse response
`[fig]` -- caption: ___

### 5.6 Score vs. Decision-10 robustness definition

| Criterion | Target            | Observed | Pass/Fail |
| --------- | ----------------- | -------- | --------- |
| P_d       | >= 90% @ ___ dB   | ___      | ___       |
| P_fa      | <= 1e-4 / PRI     | ___      | ___       |
| SOF RMS   | < 2 us            | ___      | ___       |

---

## 6. Production Considerations

Moving this design to a production radar would be dominated by compute, numeric, and scene-realism concerns. The 100 MSps single-stage front end is wasteful in mul/s and would be replaced by a multi-stage polyphase decimator to cut arithmetic by an order of magnitude; the parallel dual-MF is convenient for acquisition but would shift to ping-pong once PRF is locked to halve MAC load. The floating-point simulation would need a fixed-point port with explicit bit-growth budgeting (e.g. ~31-bit accumulator for 100 taps at 12b/12b, truncated to 16b out) to fit real silicon. Finally, the AWGN-only detector would break on real scenes, so CA-/OS-CFAR would replace the static-noise estimator, and a Doppler filter bank would be added for velocity estimation and to cover chirp-rate mismatch from moving targets.

---

## 7. Source Map

| Module file              | Role                                                                 | Specified in     |
| ------------------------ | -------------------------------------------------------------------- | ---------------- |
| testbench.m              | Top-level driver: runs single trial, MC repeat, SNR/offset sweeps, and plots | Section 5       |
| cfg_spec.m               | Hardware spec constants; LFM chirp waveform generator                | Section 2, 3     |
| sim/cfg_sim.m            | Channel simulation config (SNR, Delta-f, schedule length)            | Section 3        |
| test/cfg_tests.m         | Test tolerances and matching config                                  | Section 5        |
| module/cfg_dut.m         | DUT configuration: LPF, decimator, MF bank, detector, arbitration    | Section 3, 4     |
| module/run_dut.m         | DUT pipeline: decimate -> dual MF -> detect -> arbitrate -> extract  | Section 3, 4.1-4.4 |
| test/generate_wave.m     | Builds PRI schedule, applies Delta-f and AWGN, LPF-gain-scaled noise | Section 3        |
| test/trial_run.m         | Single-trial driver (generate -> DUT -> metrics)                     | Section 5        |
| test/trial_repeat.m      | Monte Carlo repeat of a trial                                        | Section 5        |
| test/trial_sweep.m       | Parameter sweep wrapper                                              | Section 5        |
| test/compute_errors.m    | Detection matching, miss rate, FA rate, SOF RMS                      | Section 5        |
| test/run_mc.m            | Monte Carlo driver                                                   | Section 5        |
| test/set_nested.m        | Utility for nested-struct field assignment                           | --               |
