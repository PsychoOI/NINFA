# NINFA


 
A Matlab Framework for running Custom Neurofeedback Protocols via Lab Streaming Layer (LSL) Streams

## Requirements
* [liblsl-Matlab](https://github.com/labstreaminglayer/liblsl-Matlab/) -> Installation guide is available here.
* Matlab 2023b

## Starting

1. Open this folder in Matlab
2. Open and start `main.m` in Matlab

## Configuration

1. Select your device
2. [Optional] Adjust `TYPE` of LSL input stream
3. Click `OPEN` to connect with LSL input stream
4. Configure `SETTINGS`, `ID` and `EPOCHS`
5. Click `START` to run a session

![ninfa](https://github.com/user-attachments/assets/7f8ba7ad-ea09-4d08-8384-57f182961430)

### DEVICE
 
* Select your device type and model from the available options.
* Add a device by creating a `.json` file for it in subfolder `devices`
  * Take a look at the existing `nirs_nirx_nirsport2_26.json`
  * The most important part is defining the LSL channels sent by the device

### LSL STREAM

| Setting       | Description                                                  |
|---------------|--------------------------------------------------------------|
| `TYPE`        | LSL `type` of input stream to open. This is device specific. |
| `CHANNELS`    | Number of channels found in LSL stream                       | 
| `SAMPLE RATE` | Measured Samplerate / Reported Samplerate by Device          |

> [!IMPORTANT]  
> The measured samplerate should (almost) equal the reported samplerate.</br>
> Otherwise this turns from green to red and you're likely suffering </br>
> from packet loss (e.g. due to bad or overloaded wifi).

### SETTINGS

| Setting              | Description                                                                                    |
|----------------------|------------------------------------------------------------------------------------------------|
| `PROTOCOL`           | The Matlab file from folder `protocols` with algorithm executed on each window.                |
| `CHANNELS`           | Select LSL channels to use in the selected protocol                                            |
| `WINDOW SIZE (S)`    | Size of the sliding window in seconds. The window always contains last n seconds of samples.   |
| `SESSION LENGTH (S)` | The session will automatically stop after this time.                                           |

### ID

| Setting    | Description        |
|------------|--------------------|
| `STUDY`    | Name of Study      |
| `SUBJECT`  | Number of Subject  |
| `RUN`      | Number of Run      |

The session will be automatically saved in subfolder `sessions` with name `STUDY-SUBJECT-RUN.mat`

### EPOCHS

An epoch is a configurable timespan within a session.

| Setting     | Description                                            |
|-------------|--------------------------------------------------------|
| `START (S)` | Start of Epoch (in seconds)                            |
| `END (S)`   | End of Epoch (in seconds)                              |
| `MARKER`    | Marker Value (`1-99`) of Epoch (also sent on LSL)      | 
| `VISIBLE`   | Visibility of Bar in Feedback Window during Epoch      |
| `COLOR`     | Background Color in Feedback Window during Epoch       |

* Add epoch by clicking `+`
* Remove last or selected epoch(s) by clicking `-`
* Chose background color of selected epoch(s) by clicking `COLOR`

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

* A protocol calculates a feedback value from an input window
* To add a protocol put the Matlab file in subfolder `protocols`
* The `MovAvg_SS.m` example requires a NIRS device that sends at least one `HbO` channel with `μmol/L` unit and one short channel selected.
* The `RecordOnly.m` works with any device type and model and just records data
* The `BanPass.m` example requires a NIRS device that sends at least one `HbO` channel with `μmol/L` unit without short channels selection.
* The `MovAvg.m` example requires a NIRS device that sends at least one `HbO` channel with `μmol/L` unit without short channels selection.

## Delay and Execution Times

* `DELAY` shows current offset in playback schedule (`where we are` vs. `where we should be`)
* It typically occurs if the average runtime of your protocol is larger than `1s/samplerate`

## Feedback Window

Shows a centered bar with feedback values `<= 0.5` visualized in blue and values `> 0.5` visualized in red.

![ukt-nf-feedback](https://github.com/cyberjunk/ukt-nf/assets/780159/05b6cb15-8979-4106-8c4d-77c790c9f4a8)
