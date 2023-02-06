#!/bin/bash
sudo apt update -y
sudo apt install apache2 -y
sudo ufw allow 'Apache'
sudo systemctl status apache2
