# TFM-Raman-Noise

This repository contains the MATLAB code developed for the Master's Thesis (called "Ruido Raman en redes híbridas clásico-cuánticas") focused on the experimental characterization and theoretical analysis of Raman noise in optical fiber communication systems.

The study investigates the coexistence of classical and quantum optical channels over a common fiber link and analyzes the generation and propagation
of Raman noise under different transmission conditions. 

## Experimental scenarios

Four experimental scenarios were considered, combining the two Raman regimes of interest, Stokes and anti-Stokes, with the presence or absence of an Internet connection:

- **Anti-Stokes without Internet connection**
- **Anti-Stokes with Internet connection**
- **Stokes without Internet connection**
- **Stokes with Internet connection**

For the scenarios without an Internet connection, four different classical transmission powers were considered. In contrast, for the scenarios with an Internet connection, the transmission power was fixed by the equipment used in the Ethernet link, either by the 1310 nm Ethernet transceiver or by the corresponding SFP modules.

Each scenario was evaluated for four different fiber lengths. One of these conditions corresponds to the reference case of $0$ km and is treated as a critical point in the analysis, since the measured Raman contribution can be comparable to the detector background. This condition therefore requires a more careful statistical treatment, for which a bootstrap-based analysis was implemented.

## Experimental characterization

Several optical and electronic components involved in the experimental setups were characterized prior to the Raman measurements. In particular, the MUX and DEMUX devices were experimentally evaluated through their isolation measurements, from which their spectral response at the wavelengths of interest was estimated.

The two optical light sources employed throughout the experiments were also characterized in order to determine their relevant operating parameters and verify their behavior under the different experimental conditions.

The repository therefore includes MATLAB routines associated with the characterization of the optical components and sources, as well as the subsequent processing and analysis of the experimental measurements.

## Raman noise model

The theoretical propagation and generation model for Raman noise presented in the work by Chapuran et al. was evaluated using the experimental conditions of the study. The model was used to describe the expected Raman contribution as a function of the relevant transmission parameters and fiber length.

The theoretical predictions were then compared with the experimentally obtained Raman detection rates in order to evaluate the agreement between the model and the measurements and to estimate the corresponding Raman parameter $\beta$ for the different experimental configurations.

## Data analysis

The measured photon-counting data were processed to account for the main effects associated with the detection system, including detector dead time and dark counts. The resulting Raman contribution was subsequently used to obtain the relevant quantities employed in the analysis.

Special attention was given to the $0$ km reference condition. Since this point can lie close to the detector background, a bootstrap procedure was implemented to determine the confidence interval of the difference between the Raman measurements and the dark-count measurements. This allows the presence of a positive Raman contribution to be statistically evaluated rather than inferred solely from the difference between the corresponding mean values.

## MATLAB code

The repository contains the MATLAB routines used for:

- characterization of the MUX and DEMUX spectral response;
- characterization of the optical sources;
- Raman noise analysis for the four experimental scenarios;
- evaluation of the theoretical Raman propagation model;
- estimation of the Raman parameter $\beta$;
- power-budget calculations;
- bootstrap analysis of the $0$ km critical point; and
- generation of complementary statistical plots, including histograms and boxplots.

The code is organized according to the different stages of the experimental and data-analysis workflow.

## Author 

Pablo Díez Tascón.

## Studies

Master's degree in Telecommunications Engineering.

## University

Escuela Técnica Superior de Ingenieros de Telecomunicación (ETSIT), Universidad de Valladolid (Uva).

## Bibliographic references

T. E. Chapuran et al., “Optical networking for quantum key distribution and quantum communications,” New Journal of Physics, vol. 11, no. 10, Art. no. 105001, 2009.
