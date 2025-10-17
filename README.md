# **NINFA: Non-commercial interface for neuro-feedback acquisitions**

NINFA is a MATLAB framework for running custom neurofeedback protocols via Lab Streaming Layer (LSL) streams. Its flexible and reusable software design enables real-time data acquisition across brain regions and neuroimaging techniques. While initially developed for fNIRS, it is also compatible with EEG and other modalities.

By providing a unified and adaptable framework, NINFA allows researchers, students, and engineers to design and run neurofeedback experiments without reinventing the wheel.

## Requirements

- Operating System: Windows 10 or 11 (macOS and Linux support coming soon)
- MATLAB Version: 2023b

## Getting Started

The first step is to clone the repository using the following command:

```markdown
# SSH
git clone git@github.com:PsychoOI/NINFA.git

# Or HTTPS (if SSH keys aren’t set up)
git clone https://github.com/PsychoOI/NINFA.git
```

### Device Model Configuration

The next step is to prepare your JSON configuration file. This file defines the experiment setup, including:

1. Model name and type. Having a descriptive name for your measurement configuration is a good practice. (e.g., impulsivity_protocol.json )
2. LSL stream type (e.g., NIRS, EEG) and expected channels
3. Channel map (long and short channels defined from the probe set)
4. Metadata for blinded experiments

The `channels` parameter should match the complete set of sources and detectors in your probe set. Channels can be organized (though not always required) into five blocks:

- Block 1: Counter (devch 0)
- Block 2 & 3: Wavelength measurements (devch 1 … N for both blocks, where N is the number of channels in the probe set)
- Block 4 & 5: HbO and HbR measurements (devch 1 … N)

Ensure this structure is set correctly and matches, so the mapping between dev channels and LSL ones works smoothly and yields correct values. 

The `channel_map` parameter maps the probe set channels configuration by identifying the long and short channels used in the experiment. NINFA detects whether this is real or sham feedback and acts accordingly. 

Finally, the `modes` parameter is used for blinded experiments. Here, you can define different experiment modes, where the operator assigns labels for real and sham conditions and selects which algorithm to use. During runtime, the experimenter only chooses between Condition A and B without knowing which one corresponds to the real feedback.

```json
// A pseudo-JSON for illustration
{
  "name": "your_model_name",
  "type": "NIRS", // Assuming you have an fNIRS device
  "lsl": {
    "type": "NIRS", // Assuming you have an fNIRS device
     "channels": [
      // Counter devch 0
      { "devch":  0, "type": "COUNTER", "unit": "" },
      
      // Dev channels with wavelength = 760NM (1 -> N)
      { "devch":  1, "type": "WL760NM", "unit": "V" },
      '''' 
      { "devch": N, "type": "WL760NM", "unit": "V" },
      
      // Dev channels with wavelength = 850NM (1 -> N)
      { "devch":  1, "type": "WL850NM", "unit": "V" },
      ''''
      { "devch": N, "type": "WL850NM", "unit": "V" },
      
      // HbO channels (1 -> N)
      { "devch":  1, "type": "HbO",     "unit": "μmol/L" },
      ''''   
      { "devch": N, "type": "HbO",     "unit": "μmol/L" },	  
      
      // HbR channels (1 -> N)
      { "devch":  1, "type": "HbR",     "unit": "μmol/L" },
      ''''
      { "devch": N, "type": "HbR",     "unit": "μmol/L" }
    ]
  },
	  // Neurofeedback and short separation channels
    "channel_map": {
        "long_channels": { "HbO":  [7, 11, 17], "HbR": []},
        "short_channels": { "HbO": [4, 10, 19], "HbR": []}
    },
    // Real and sham neurofeedback in a blinded mode
    "modes": {
        "A": { "label": "Condition A", "role": "real", "protocol": "MovAvg_SS"},
        "B": { "label": "Condition B", "role": "sham", "protocol": "BandPass"}
    },
    
    // Enabling the blind_role in the UI  -> Otherwise you choose manually in the UI
    "ui": {"blind_role": true},
    "default_mode": "A",
    "randomize": false
}
```

Finally, consider formatting the reference file name as code: `your_experiment_model.json` (and double-check the casing/extension).

After creating your JSON file, save it under the `devices` directory.

To start NINFA, please run `main.m` inside the repository in MATLAB.

NINFA can run in two modes

1. Blinded (You choose condition A or B without knowing which is which)
2. Unblinded (You manually choose a real or sham experiment and which algorithm to use)

![Blinded_NINFA](https://github.com/user-attachments/assets/c6763768-57e5-4933-8843-53c227bce00b)

![Unblinded_NINFA](https://github.com/user-attachments/assets/4d067e46-8068-48cd-a4b8-d9730f5bae03)

Left → A Blinded NINFA, Right → Unblinded NINFA

Automatically, it starts in a blinded mode where the experimenter only has to choose condition A or B. You shouldn’t be able to select protocol and role in a blinded version, as you can in the unblinded version.

## Configuration

1. Select your device
2. [Optional] Adjust the `TYPE` of the LSL input stream to match the type in your neuroimaging device
3. Click `OPEN` to connect with the LSL input stream.
4. Configure your `EPOCHS` (i.e., block design) section using the + sign.
    
    ![EPOCHS](https://github.com/user-attachments/assets/d19d1c6d-1a4a-4963-a356-2a6cd22a1def)
    
5. Click `FILE` and then `SAVE`; you can use this setting in the future.
6. Click `START` to run a session.

### Bad Channels

![BAD_Channels](https://github.com/user-attachments/assets/01d07e52-cb2b-451b-8eba-783f0eb8d54a)

An example of deselecting channels that are of bad quality on your device.

### Device

| Setting | Description |
| --- | --- |
| `TYPE` | Device `type` whether NIRS of EEG. |
| `MODEL` | Which device model are you using? A model is a blueprint representing your device configuration. Check the Device Model Configuration for more details. |
| `CONDITION` | The conditions or modes in the JSON file represent whether sham or real neurofeedback is used and which protocol to use. |

### SETTINGS

| Setting | Description |
| --- | --- |
| `PROTOCOL` | The Matlab file from the folder `protocols` with the algorithm executed on each window. |
| `ROLE` | Real or Sham Neurofeedback |
| `CHANNELS` | Select LSL channels to use in the selected protocol. They should be preselected in the JSON file, but can be edited here. |
| `BAD CHANNELS`  | The channels might have bad signal quality, and must be deselected here. |
| `WINDOW SIZE (S)` | Size of the sliding window in seconds. It is used for feedback signal calculation. The window always contains the last n seconds of samples. |
| `SESSION LENGTH (S)` | The session will automatically stop after this time. |

### ID

| Setting | Description |
| --- | --- |
| `STUDY` | Name of Study |
| `SUBJECT` | Number of Subject |
| `RUN` | Number of Run |

The session will be automatically saved in the subfolder `sessions` with the name `STUDY-SUBJECT-RUN.mat`

### EPOCHS

An epoch is a configurable timespan within a session.

| Setting | Description |
| --- | --- |
| `START (S)` | Start of Epoch (in seconds) |
| `END (S)` | End of Epoch (in seconds) |
| `MARKER` | Marker Value (`1-99`) of Epoch (also sent on LSL) |
| `VISIBLE` | Visibility of Bar in Feedback Window during Epoch |
| `COLOR` | Background Color in Feedback Window during Epoch |
- Add epoch by clicking `+`
- Remove last or selected epoch(s) by clicking `-`
- Chose background color of selected epoch(s) by clicking `COLOR`

## LSL Output

### Trigger

- Sends triggers on LSL with stream type and name set to `Trigger`
- Sends trigger with value `100` on session start
- Sends trigger with value `101` on session end
- Sends trigger with custom value from column `MARKER` on each epoch start

### Marker

- Sends markers on LSL with stream type and name set to `Marker`
- Sends markers with the same sample rate as LSL input (one marker for each LSL input sample)
- Default value is `0` (if no active epoch)

## Protocols

- A protocol calculates a feedback value from an input window
- To add a protocol, please put the Matlab file in the subfolder `protocols`
- The `MovAvg_SS.m` example requires a NIRS device that sends at least one `HbO` channel with a `μmol/L` unit and one short channel selected.
- The `RecordOnly.m` works with any device type and model and just records data
- The `BandPass.m` example requires a NIRS device that sends at least one `HbO` channel with a `μmol/L` unit without short channel selection.
- The `MovAvg.m` example requires a NIRS device that sends at least one `HbO` channel with `μmol/L` unit without short channel selection.

## Delay and Execution Times

- `DELAY` shows the current offset in the playback schedule (`where we are` vs `where we should be`)
- It typically occurs if the average runtime of your protocol is larger than `1s/samplerate`
- A longer delay can be noticed when the `DELAY`  value turns red.

## Feedback Window

Shows a centered bar with feedback values `<= 0.5` visualized in blue and values `> 0.5` visualized in red.

![ukt-nf-feedback](https://github.com/cyberjunk/ukt-nf/assets/780159/05b6cb15-8979-4106-8c4d-77c790c9f4a8)

## Created by:

- Ahmed Eldably
- Costanza Iester
- Clint Banzhaf
- Beatrix Barth
