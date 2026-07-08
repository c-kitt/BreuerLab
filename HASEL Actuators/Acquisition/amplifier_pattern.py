# %%
# amplifier_pattern.py
# Drives the Artimus HASEL amplifier channels with sinusoidal patterns.
# Frequency, amplitude, and phases are passed in from MATLAB via environment
# variables (see run_trials_NI_Artimus_fun.m). Run standalone, it falls back
# to the default values below.
import os
import ardi

psu = ardi.autoconnect()          # connect to the power supply
ch1 = psu.ch(1)                   # channel 1
ch2 = psu.ch(2)                   # channel 2
ch3 = psu.ch(3)                   # channel 3 (unused in 2-actuator tests)
ch4 = psu.ch(4)                   # channel 4 (unused in 2-actuator tests)

rail = psu.channels['rail']       # rail voltage channel
# %%
# Input frequency, voltage, and phases (overridable from MATLAB via env vars).
# In the standard two-actuator bench tests only ch1/ch2 are driven, so
# phi_3 and phi_4 stay at 0.
f_in  = float(os.environ.get("F_IN", 0.5))   # excitation frequency (Hz)
A_in  = float(os.environ.get("A_IN", 4000))  # excitation amplitude (V)
phi_2 = float(os.environ.get("PHI_2", 0))    # phase offset, ch2 (deg)
phi_3 = float(os.environ.get("PHI_3", 0))    # phase offset, ch3 (deg)
phi_4 = float(os.environ.get("PHI_4", 0))    # phase offset, ch4 (deg)

# Expected oscilloscope reading: the amplifier outputs ~10000 V for every 3 V
# seen on the scope, so scope voltage = commanded amplitude / (10000/3).
scope_A = A_in / (10000 / 3)
print(f"Expected oscilloscope measured voltage: {scope_A} V")
print(f"f_in={f_in} Hz, A_in={A_in} V, phi_2={phi_2}, phi_3={phi_3}, phi_4={phi_4}")
# %%
# Output a unipolar sinusoid on each of the four channels, with independent
# phase offsets on channels B, C, and D relative to channel A.
def pattern(psu, chA, chB, chC, chD, freq, amp, phase2, phase3, phase4):
    chA.sin(freq, amp)
    chB.sin(freq, amp, phase2)
    chC.sin(freq, amp, phase3)
    chD.sin(freq, amp, phase4)
# %% run the pattern on all four channels
pattern(psu, ch1, ch2, ch3, ch4, f_in, A_in, phi_2, phi_3, phi_4)
