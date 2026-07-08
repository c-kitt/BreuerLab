# HASEL Actuators — Bench Characterization

This folder contains everything used to run the HASEL actuator bench tests
and analyze the resulting data.

The goal of these tests: drive two HASEL actuators with a sine wave at
different frequencies, voltages, and applied weights, and record both the
input voltage and the sensing signal from each actuator. This lets us see
how the sensing signal responds to load.

---

## Folder structure

    HASEL Actuators/
    ├── Acquisition/     code that RUNS the experiment and records data
    ├── Analysis/        code that READS the data and makes graphs
    └── README.md        this file

---

## Experiment conditions

Each test sweeps three variables:

  - Frequency:  0.5, 0.75, 1.0 Hz
  - Voltage:    4000, 5000 V
  - Weight:     0, 50, 100 g

Two actuators are recorded at once (Ch1 and Ch2). For each actuator we
record two signals:

  - V = input voltage (the drive signal sent to the actuator)
  - S = sensing signal (what the actuator reads back)

Each recording is 25 drive cycles, sampled at 1000 Hz.

---

## Data files

Each trial is saved as its own .mat file. The file name stores the
conditions, for example:

    Ch1-2_Hasel5-4_f0.50_Amp4000_Phi000_Weight100_trial1.mat

  - Ch1-2      -> amplifier channels 1 and 2
  - Hasel5-4   -> actuator serial numbers 5 and 4
  - f0.50      -> frequency 0.50 Hz
  - Amp4000    -> amplitude 4000 V
  - Phi000     -> phase 0 degrees
  - Weight100  -> 100 g weight
  - trial1     -> trial number 1

Inside each file is a 50000x4 timetable called "data" with columns:
Ch1_V, Ch1_S, Ch2_V, Ch2_S.

---

## Acquisition/  (running the experiment)

Run on the lab PC that is connected to the Artimus power supply and the
NI USB-6341 DAQ.

  - amplifier_pattern.py
        Tells the power supply to drive the actuators with a sine wave at
        the chosen frequency and voltage. MATLAB launches this file; it is
        not run by hand. Needs the "ardi" Python library installed.

  - hasel_acquire.m
        The main data-collection function. Loops over every frequency and
        voltage, runs the Python pattern, records the four signals from the
        DAQ, and saves one .mat file per trial. Weight is set by hand (you
        physically place the weight, then run for that weight).

  - run_hasel_acquire.m
        The simple script you actually run. Set the weight and lists at the
        top, then run it — it calls hasel_acquire. Repeat for each weight.

### To collect data
  1. Make sure the "ardi" Python library is installed (see note below).
  2. Open run_hasel_acquire.m and set the weight to match the physical
     weight on the actuator.
  3. Check the paths inside hasel_acquire.m match this machine (Python path,
     script path, output folder).
  4. Run run_hasel_acquire.m. Place the weight and arm the PTU when prompted.
  5. Change the weight and repeat for each weight level.

### Note on the "ardi" library
The Python code needs the Artimus "ardi" package. Install it by downloading
the tarball from the Artimus Robotics ardi GitHub releases page and running:

    pip install ardi_py-<version>.tar.gz

Test it worked with:  python -i -m ardi
(It will say "no device found" if the power supply is off — that is fine,
it still confirms the install.)

---

## Analysis/  (reading the data and making graphs)

Run on any computer with MATLAB and access to the .mat files.

  - hasel_load.m
        Reads every .mat file in a folder, pulls the frequency, voltage,
        weight, and trial out of each file name, and puts everything into
        one table called "T". Set the data folder at the top before running.

  - hasel_9plots.m
        Makes 9 graphs — one for each frequency/weight combination — with
        both voltages drawn on each graph. Each graph shows input voltage on
        top and sensing signal on the bottom. Run hasel_load.m first.

### To analyze data
  1. Open hasel_load.m, set the data folder to where the .mat files are.
  2. Run hasel_load.m. This creates the table "T".
  3. Run hasel_9plots.m to make the graphs.

---

## Quick start

Collect data (lab PC):
    run_hasel_acquire.m      (set weight, run, repeat per weight)

Analyze data (any PC with MATLAB):
    hasel_load.m             (creates table T)
    hasel_9plots.m           (makes the 9 graphs)

---

## People
Pedro Ormonde, Dipan Deb & Casey Kittredge
