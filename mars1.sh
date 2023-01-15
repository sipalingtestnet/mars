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
echo -e '\e[33mNama Project =\e[55m' MARS CHAIN 
echo -e '\e[33mKomunitas Kami =\e[55m' Sipaling Testnet
echo -e '\e[33mChannel Telegram =\e[55m' https://t.me/ssipalingtestnet
echo -e '\e[33mGroup Telegram =\e[55m' https://t.me/diskusisipalingairdrop
echo -e "\e[0m"

sleep 2

sleep 2

# Menu

PS3='Select an action: '
options=(
"Install"
"Create Wallet"
"Create Validator"
"Exit")
select opt in "${options[@]}"
do
case $opt in

"Install")
echo "============================================================"
echo "Install start"
echo "============================================================"

# set vars
if [ ! $NODENAME ]; then
	read -p "Enter node name: " NODENAME
	echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
fi
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export MARS_CHAIN_ID=ares-1" >> $HOME/.bash_profile
source $HOME/.bash_profile

# update
sudo apt update && sudo apt upgrade -y

# packages
sudo apt install curl build-essential git wget jq make gcc tmux chrony -y

# install go
if ! [ -x "$(command -v go)" ]; then
  ver="1.19.4"
  cd $HOME
wget -O go1.19.4.linux-amd64.tar.gz https://golang.org/dl/go1.19.4.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.19.4.linux-amd64.tar.gz && sudo rm go1.19.4.linux-amd64.tar.gz
echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
echo 'export GO111MODULE=on' >> $HOME/.bash_profile
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile
fi

# download binary
cd $HOME
rm -rf hub
git clone https://github.com/mars-protocol/hub
cd hub
git checkout v1.0.0-rc7
make install

# config
marsd config chain-id $MARS_CHAIN_ID
marsd config keyring-backend test

# init
marsd init $NODENAME --chain-id $MARS_CHAIN_ID

# download genesis and addrbook
marsd init $MONIKER --chain-id ares-1
	wget -O $HOME/.mars/config/addrbook.json "https://raw.githubusercontent.com/elangrr/testnet_guide/main/mars/addrbook.json"
	wget -O $HOME/.mars/config/genesis.json "https://raw.githubusercontent.com/elangrr/testnet_guide/main/mars/genesis.json"

# Set custom ports 20
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:20658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:20657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:20060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:20656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":20660\"%" $HOME/.mars/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:20317\"%; s%^address = \":8080\"%address = \":20080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:20090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:20091\"%; s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:20545\"%; s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:20546\"%" $HOME/.mars/config/app.toml

# set minimum gas price
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0umars\"/" $HOME/.mars/config/app.toml

# set peers and seeds
peers="14ba3b19424301a6bb58c27663a0323a81866d5d@134.122.82.186:26656,6c855909a8bf1c12ef34baca059f5c0cdf82bc36@65.108.255.124:36656,9847d03c789d9c87e84611ebc3d6df0e6123c0cc@91.194.30.203:10656,cec7501f438e2700573cdd9d45e7fb5116ba74b9@176.9.51.55:10256,e12bc490096d1b5f4026980f05a118c82e81df2a@85.17.6.142:26656,7342199e80976b052d8506cc5a56d1f9a1cbb486@65.21.89.54:26653,7226c00dd90cf182ca9ec9aa513f518965e7e1a4@167.235.7.34:43656,846ee4df536ddba9739d3f5eebd0139b0a9e5169@159.148.146.132:27225,719cf7e8f7640a48c782599475d4866b401f2d34@51.254.197.170:26656,fe8d614aa5899a97c11d0601ef50c3e7ce17d57b@65.108.233.109:18556"
sed -i -e "s|^seeds *=.*|seeds = \"3f472746f46493309650e5a033076689996c8881@mars-testnet.rpc.kjnodes.com:45659\"|" $HOME/.mars/config/config.toml
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.mars/config/config.toml
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0umars\"|" $HOME/.mars/config/app.toml

# Set pruning
	sed -i -e "s|^pruning *=.*|pruning = \"custom\"|" $HOME/.mars/config/app.toml
	sed -i -e "s|^pruning-keep-recent *=.*|pruning-keep-recent = \"100\"|" $HOME/.mars/config/app.toml
	sed -i -e "s|^pruning-keep-every *=.*|pruning-keep-every = \"0\"|" $HOME/.mars/config/app.toml
	sed -i -e "s|^pruning-interval *=.*|pruning-interval = \"19\"|" $HOME/.mars/config/app.toml

	# Set Indexer
	indexer="null" && \
	sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.mars/config/config.toml


# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.mars/config/config.toml

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

marsd tendermint unsafe-reset-all



#set state sync
   echo " If you have state sync enabled please turn it off first"
   sleep 3
   sudo apt update
   sudo apt install snapd -y
   sudo snap install lz4
   
   sudo systemctl stop marsd
	cp $HOME/.mars/data/priv_validator_state.json $HOME/.mars/priv_validator_state.json.backup
	rm -rf $HOME/.mars/data

	curl -L https://snapshot.mars.indonode.net/mars-snapshot-2023-01-14.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.mars
	mv $HOME/.mars/priv_validator_state.json.backup $HOME/.mars/data/priv_validator_state.json

	sudo systemctl restart marsd && journalctl -u marsd -f --no-hostname -o cat
	

	# start service
sudo systemctl daemon-reload
sudo systemctl enable marsd
sudo systemctl start marsd
break
;;

"Create Wallet")
marsd keys add $WALLET
echo "============================================================"
echo "Save address and mnemonic"
echo "============================================================"
MARS_WALLET_ADDRESS=$(marsd keys show $WALLET -a)
MARS_VALOPER_ADDRESS=$(marsd keys show $WALLET --bech val -a)
echo 'export MARS_WALLET_ADDRESS='${MARS_WALLET_ADDRESS} >> $HOME/.bash_profile
echo 'export MARS_VALOPER_ADDRESS='${MARS_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile

break
;;

"Create Validator")
marsd tx staking create-validator \
  --amount 1000000umars \
  --from wallet \
  --commission-max-change-rate "0.1" \
  --commission-max-rate "0.2" \
  --commission-rate "0.1" \
  --min-self-delegation "1" \
  --pubkey  $(marsd tendermint show-validator) \
  --moniker $NODENAME \
  --chain-id ares-1 \
  -y
  
break
;;

"Exit")
exit
;;
*) echo "invalid option $REPLY";;
esac
done
done
