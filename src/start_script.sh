#!/bin/bash
set -e

git clone https://github.com/Shadoxity/comfyui-wan.git /comfyui-wan
cp /comfyui-wan/src/start.sh /start.sh
chmod +x /start.sh
bash /start.sh
