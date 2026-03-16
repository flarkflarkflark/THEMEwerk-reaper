# Testing THEMEwerk-reaper v0.1

Follow these steps to test the local theme browser prototype in REAPER.

## Prerequisites

1.  REAPER v6.0 or later.
2.  Your REAPER installation must have some themes in the `ColorThemes` directory.

## Installation

1.  Clone or download this repository.
2.  In REAPER, open the Action List (`?` key).
3.  Click `New Action...` -> `Load ReaScript...`.
4.  Navigate to the `scripts/` directory inside this repository and select `THEMEwerk.lua`.
5.  The script is now installed.

## Running the Script

1.  In the Action List, find the action named `Script: THEMEwerk.lua`.
2.  Select it and click `Run`.
3.  The THEMEwerk-reaper window should appear.

## What to Test

-   Does the script find and list all your locally installed themes?
-   Does applying a theme from the list work correctly?
-   Does the script handle the case where the `ColorThemes` directory is empty?
-   Does the script run without errors on Windows, macOS, and Linux?
