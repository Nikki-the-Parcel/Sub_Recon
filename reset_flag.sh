#!/bin/bash
# How to Use? 
# This script will delete the Check flag so the main script could run a test again. 
# Removing one of the tools will help us see whether the visual loading bar is working as intended.

rm ./.sub-recon_ran_already
sudo apt remove sublist3r -y
