# UKT - Neurofeedback

Matlab Framework for Running Custom Neurofeedback Protocols on LSL Streams

## Requirements

* Windows 10/11
* Matlab 2020a

## How-To

1. Open folder in Matlab
2. Open and run main.m
3. Optional: Adjust TYPE of LSL STREAM (default is for NIRS device)
4. Press OPEN
5. Configure SETTINGS, ID and EPOCHS
6. Press START

## Settings

TODO

## Epochs

TODO

## LSL Trigger Output

* Sends triggers on LSL with stream type and name set to Trigger
* Sends trigger with value 100 on session start
* Sends trigger with value 101 on session end
* Sends trigger with custom value from column MARKER on each epoch start

## LSL Marker Output

* Sends markers on LSL with stream type and name set to Marker
* Sends markers with same samplerate as LSL input (one marker for each LSL input sample)
* Sends 

## Protocols

TODO
