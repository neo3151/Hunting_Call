# Audio Asset Normalization Workflow

New animal calls are added to the reference library frequently. It is highly disruptive to the user if a user swaps from a quiet turkey purr to a blaring elk bugle unexpectedly. 

## The Problem
Raw WAV and MP3 files provided by different hunters or stock libraries possess wildly varying:
- RMS amplitudes
- Peak decibels
- Sample rates (44.1kHz vs 48kHz)
- Bit depths

## The Solution: Workflow Automation
All incoming assets must pass through an automated normalization step before being ingested into the `ReferenceDatabase`.

### 1. Slash Command Workflow
The OUTCALL development environment is configured with a custom workspace workflow: `/update-assets`.

This workflow performs the following:
1. Downloads the target audio assets.
2. Runs batch processing to normalize peak amplitude to a target `-3.0 dBFS`.
3. Standardizes sample rates to `44100 Hz` (optimal for our `AnalyzeAudioUseCase` FFT processing constraint length of 1024).

### 2. Goal
This guarantees that the UI feels premium: switching between reference tracks maintains a consistent volume, and the recording graph does not suffer scale mismatch issues when comparing user attempts.
