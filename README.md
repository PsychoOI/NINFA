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
2. [Optional] Adjust the `TYPE` of the LSL input stream
3. Click `OPEN` to connect with the LSL input stream
4. Configure `SETTINGS`, `ID` and `EPOCHS`
5. Click `FILE` and then `SAVE`; then, you can use this setting in the future.
6. Click `START` to run a session

![Image](https://github.com/user-attachments/assets/22cf33bc-c605-4228-8822-c8f9a9878e3b)

### DEVICE
 
* Select your device type and model from the available options.
* Add a device by creating a `.json` file for it in the subfolder `devices`
  * Take a look at the existing `nirs_nirx_nirsport2_26.json`
  * The most important part is defining the LSL channels sent by the device

### LSL STREAM

| Setting       | Description                                                  |
|---------------|--------------------------------------------------------------|
| `TYPE`        | LSL `type` of the input stream to open. This is device-specific. |
| `CHANNELS`    | Number of channels found in LSL stream                       | 
| `SAMPLE RATE` | Measured Samplerate / Reported Samplerate by Device          |

> [!IMPORTANT]  
> The measured sample rate should (almost) equal the reported sample rate.</br>
> Otherwise, this turns from green to red, and you're likely suffering </br>
> from packet loss (e.g. due to bad or overloaded wifi).

### SETTINGS

| Setting              | Description                                                                                    |
|----------------------|------------------------------------------------------------------------------------------------|
| `PROTOCOL`           | The Matlab file from folder `protocols` with the algorithm executed on each window.                |
| `CHANNELS`           | Select LSL channels to use in the selected protocol                                            |
| `WINDOW SIZE (S)`    | Size of the sliding window in seconds. The window always contains the last n seconds of samples.   |
| `SESSION LENGTH (S)` | The session will automatically stop after this time.                                           |

### ID

| Setting    | Description        |
|------------|--------------------|
| `STUDY`    | Name of Study      |
| `SUBJECT`  | Number of Subject  |
| `RUN`      | Number of Run      |

The session will be automatically saved in the subfolder `sessions` with the name `STUDY-SUBJECT-RUN.mat`

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
* Sends markers with the same sample rate as LSL input (one marker for each LSL input sample)
* Default value is `0` (if no active epoch)

## Protocols

* A protocol calculates a feedback value from an input window
* To add a protocol,l put the Matlab file in the subfolder `protocols`
* The `MovAvg_SS.m` example requires a NIRS device that sends at least one `HbO` channel with a `μmol/L` unit and one short channel selected.
* The `RecordOnly.m` works with any device type and model and just records data
* The `BandPass.m` example requires a NIRS device that sends at least one `HbO` channel with a `μmol/L` unit without short channel selection.
* The `MovAvg.m` example requires a NIRS device that sends at least one `HbO` channel with `μmol/L` unit without short channel selection.

## Delay and Execution Times

* `DELAY` shows the current offset in the playback schedule (`where we are` vs `where we should be`)
* It typically occurs if the average runtime of your protocol is larger than `1s/samplerate`

## Feedback Window

Shows a centered bar with feedback values `<= 0.5` visualized in blue and values `> 0.5` visualized in red.

![ukt-nf-feedback](https://github.com/cyberjunk/ukt-nf/assets/780159/05b6cb15-8979-4106-8c4d-77c790c9f4a8)

## Created by:
- Dr. rer. nat. Beatrix Barth  
- Dipl.-Inf. Clint Banzhaf  
- M.Sc. Costanza Iester  
- B.Sc. Ahmed Eldably  
