#!/bin/bash
# Sets my jabra device as default audio device in pulse.
pactl set-default-source alsa_input.usb-GN_Netcom_A_S_Jabra_EVOLVE_LINK_MS_00023B7ED69E07-00.analog-mono
pactl set-default-sink alsa_output.usb-GN_Netcom_A_S_Jabra_EVOLVE_LINK_MS_00023B7ED69E07-00.analog-stereo
