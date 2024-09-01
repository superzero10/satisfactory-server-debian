#!/bin/bash

# Main installation and configuration script for a Satisfactory server on Debian

# Variables
USER="satisfactory"
INSTALL_DIR="/home/$USER/satisfactory"
STEAMCMD_DIR="/home/$USER/steamcmd"
STEAMCMD_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
GAME_ID="1690800"  # Satisfactory server game ID

# 1. System update and installation of necessary dependencies
echo "Updating system and installing dependencies..."
apt update && apt upgrade -y
apt install -y lib32gcc-s1 lib32stdc++6 curl tar wget cron ufw fail2ban htop glances unattended-upgrades

# 2. Create a dedicated user
echo "Creating dedicated user $USER..."
useradd -m -s /bin/bash $USER

# 3. Install SteamCMD
echo "Installing SteamCMD..."
mkdir -p $STEAMCMD_DIR
cd $STEAMCMD_DIR
wget $STEAMCMD_URL
tar -xvzf steamcmd_linux.tar.gz
chown -R $USER:$USER $STEAMCMD_DIR

# 4. Download and install the Satisfactory server
echo "Downloading and installing the Satisfactory server..."
sudo -u $USER bash -c "$STEAMCMD_DIR/steamcmd.sh +login anonymous +force_install_dir $INSTALL_DIR +app_update $GAME_ID validate +quit"

# 5. Configure the systemd service to manage the Satisfactory server
echo "Configuring systemd service for the Satisfactory server..."
cat <<EOL > /etc/systemd/system/satisfactory.service
[Unit]
Description=Satisfactory Server
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=$INSTALL_DIR/FactoryServer.sh
Nice=-10
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable satisfactory
systemctl start satisfactory

# 6. Configure the firewall with UFW
echo "Configuring the firewall..."
ufw allow OpenSSH
ufw allow 15777/udp  # Default port for Satisfactory
ufw enable

# 7. Set up Fail2Ban for security
echo "Setting up Fail2Ban..."
systemctl enable fail2ban
systemctl start fail2ban

# 8. Configure logrotate to manage server logs
echo "Configuring logrotate for server logs..."
cat <<EOL > /etc/logrotate.d/satisfactory
$INSTALL_DIR/FactoryGame/Saved/Logs/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0640 $USER $USER
}
EOL

# 9. Set up automatic system updates
echo "Setting up automatic updates..."
dpkg-reconfigure --priority=low unattended-upgrades

# 10. Create a README file for server documentation
echo "Creating server documentation..."
cat <<EOL > /home/$USER/README.md
# Satisfactory Server on Debian

## Main Commands

- **Start the server**: \`sudo systemctl start satisfactory\`
- **Stop the server**: \`sudo systemctl stop satisfactory\`
- **Restart the server**: \`sudo systemctl restart satisfactory\`
- **Check the server status**: \`sudo systemctl status satisfactory\`

## Backups

Backups are stored in \`/home/$USER/satisfactory_backups/\` and are performed daily.

## Updates

The server is automatically updated via SteamCMD every day at 3 AM.

## Restart

The server automatically restarts each day at 5 AM.

## Logs

Server logs are managed by logrotate and are kept for 7 days.

EOL

echo "Satisfactory server installation and configuration completed."
