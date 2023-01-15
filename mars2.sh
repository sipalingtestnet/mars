#!/bin/bash
clear
echo -e "\033[0;33m"
echo "================================"
echo " ███████ ██████  ████████     ";
echo " ██      ██   ██    ██        ";
echo " ███████ ██████     ██        ";
echo "      ██ ██         ██        ";
echo " ███████ ██         ██    	 ";
echo "================================"
echo -e "\e[0m"
echo -e '\e[33mNama Project =\e[55m' MARS CHAIN 1
echo -e '\e[33mKomunitas Kami =\e[55m' Sipaling Testnet
echo -e '\e[33mChannel Telegram =\e[55m' https://t.me/ssipalingtestnet
echo -e '\e[33mGroup Telegram =\e[55m' https://t.me/diskusisipalingairdrop
echo -e "\e[0m"

read -r -p "Enter node moniker: " MONIKER

#Install dependencies
#Update system and install build tools
sudo apt -q update
sudo apt -qy install curl git jq lz4 build-essential
sudo apt -qy upgrade

#Install Go
sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.19.4.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)

#Download and build binaries
# Clone project repository
cd $HOME
rm -rf hub
git clone https://github.com/mars-protocol/hub.git
cd hub
git checkout v1.0.0-rc7

# Build binaries
make build

# Prepare binaries for Cosmovisor
mkdir -p $HOME/.mars/cosmovisor/genesis/bin
mv build/marsd $HOME/.mars/cosmovisor/genesis/bin/
rm -rf build

# Create application symlinks
ln -s $HOME/.mars/cosmovisor/genesis $HOME/.mars/cosmovisor/current
sudo ln -s $HOME/.mars/cosmovisor/current/bin/marsd /usr/local/bin/marsd

#Install Cosmovisor and create a service
# Download and install Cosmovisor
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.4.0

# Create service
sudo tee /etc/systemd/system/marsd.service > /dev/null << EOF
[Unit]
Description=mars-testnet node service
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.mars"
Environment="DAEMON_NAME=marsd"
Environment="UNSAFE_SKIP_BACKUP=true"

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable marsd

#Initialize the node
# Set node configuration
marsd config chain-id ares-1
marsd config keyring-backend test

# Initialize the node
marsd init $MONIKER --chain-id ares-1

# Download genesis and addrbook
wget -O $HOME/.mars/config/addrbook.json "https://raw.githubusercontent.com/elangrr/testnet_guide/main/mars/addrbook.json"
wget -O $HOME/.mars/config/genesis.json "https://raw.githubusercontent.com/elangrr/testnet_guide/main/mars/genesis.json"

# Add seeds
sed -i -e "s|^seeds *=.*|seeds = \"3f472746f46493309650e5a033076689996c8881@mars-testnet.rpc.kjnodes.com:45659\"|" $HOME/.mars/config/config.toml

# Set minimum gas price
	sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0umars\"|" $HOME/.mars/config/app.toml

	sed -i -e "s/^filter_peers *=.*/filter_peers = \"true\"/" $HOME/.mars/config/config.toml
	external_address=$(wget -qO- eth0.me) 
	sed -i 's/max_num_inbound_peers =.*/max_num_inbound_peers = 50/g' $HOME/.mars/config/config.toml
	sed -i 's/max_num_outbound_peers =.*/max_num_outbound_peers = 50/g' $HOME/.mars/config/config.toml

# Set pruning
	sed -i -e "s|^pruning *=.*|pruning = \"custom\"|" $HOME/.mars/config/app.toml
	sed -i -e "s|^pruning-keep-recent *=.*|pruning-keep-recent = \"100\"|" $HOME/.mars/config/app.toml
	sed -i -e "s|^pruning-keep-every *=.*|pruning-keep-every = \"0\"|" $HOME/.mars/config/app.toml
	sed -i -e "s|^pruning-interval *=.*|pruning-interval = \"19\"|" $HOME/.mars/config/app.toml
# Set Indexer
	indexer="null" && \
	sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.mars/config/config.toml

	# Set custom ports 20
	sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:20658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:20657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:20060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:20656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":20660\"%" $HOME/.mars/config/config.toml
	sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:20317\"%; s%^address = \":8080\"%address = \":20080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:20090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:20091\"%; s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:20545\"%; s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:20546\"%" $HOME/.mars/config/app.toml


#Download latest chain snapshot
curl -L https://snapshots.kjnodes.com/mars-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.mars
[[ -f $HOME/.mars/data/upgrade-info.json ]] && cp $HOME/.mars/data/upgrade-info.json $HOME/.mars/cosmovisor/genesis/upgrade-info.json

#Start service and check the logs
sudo systemctl start marsd && sudo journalctl -u marsd -f --no-hostname -o cat

