# UKT - Neurofeedback

Matlab Framework for running Custom Neurofeedback Protocols on LSL Streams

## Requirements

* Windows 10/11
* Matlab 2020a

## How-To

1. Open this folder in Matlab
2. Open and start `main.m` in Matlab

Then:
1. Adjust `TYPE` of LSL input stream (default is for NIRS device) [Optional]
2. Click `OPEN` to connect with the LSL stream
3. Configure `SETTINGS`, `ID` and `EPOCHS`
4. Click `START` to run a session

## Configuration

### Settings

| Setting              | Description                                                                                    |
|----------------------|------------------------------------------------------------------------------------------------|
| `SELECTED CHANNELS`  | Comma separated list of LSL input channel numbers to use (others are ignored).                 |
| `WINDOW SIZE (S)`    | Size of the sliding window in seconds. The window always contains this last n seconds of data. |
| `SESSION LENGTH (S)` | The session will automatically stop after this time.                                           |
| `PROTOCOL`           | The Matlab file from folder `protocols` with algorithm executed on each window.                |

### ID

| Setting    | Description        |
|------------|--------------------|
| `STUDY`    | Name of Study      |
| `SUBJECT`  | Number of Subject  |
| `RUN`      | Number of Run      |

The session will be automatically saved in subfolder `sessions` with name `STUDYNAME-SUBJECTNUM-RUNNUM.mat`

### Epochs

An epoch is a special timespan within a session.

| Setting     | Description                                            |
|-------------|--------------------------------------------------------|
| `START (S)` | Start of Epoch (in seconds)                            |
| `END (S)`   | End of Epoch (in seconds)                              |
| `MARKER`    | Marker Value (`1-99`) of Epoch (also sent on LSL)      | 
| `VISIBLE`   | Visibility of Bar in Feedback Window during Epoch      |
| `COLOR`     | Background Color in Feedback Window during Epoch       |

* Add epoch by clicking `+`
* Remove last or selected epoch(s) by clicking `-`
* Chose color of selected epoch(s) by clicking `COLOR`

## LSL Output

### Trigger

* Sends triggers on LSL with stream type and name set to `Trigger`
* Sends trigger with value `100` on session start
* Sends trigger with value `101` on session end
* Sends trigger with custom value from column `MARKER` on each epoch start

### Marker

* Sends markers on LSL with stream type and name set to `Marker`
* Sends markers with same samplerate as LSL input (one marker for each LSL input sample)
* Default value is `0` (if no active epoch)

## Protocols

* A protocol calculates a feedback value from a window
* To add a protocol put the Matlab file in subfolder `protocols`
* See `example1.m` (returns a random feedback value)

## Drift and Execution Times

TODO
