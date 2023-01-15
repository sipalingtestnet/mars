## Official Links
[Website](https://marsprotocol.io/) [Twitter](https://twitter.com/mars_protocol) [Discord](https://discord.gg/marsprotocol)

## [Explorer](https://mars.explorers.guru/validators) [Explorer](https://explorer.nodestake.top/mars-testnet/staking)

# Install Node Guide Mars Protocol
### Setting up variables

Specify the name of your moniker (validator) which will be visible in the explorer
```bash
NODENAME=<YOUR_MONIKER_NAME>
```
### Save and import variables into system
```bash
MARS_PORT=33
echo "export NODENAME=$NODENAME" >> $HOME/.bash_profile
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export MARS_CHAIN_ID=ares-1" >> $HOME/.bash_profile
echo "export MARS_PORT=${MARS_PORT}" >> $HOME/.bash_profile
source $HOME/.bash_profile
```

### Update Packages and Depencies
```bash
sudo apt update && sudo apt upgrade -y
```

### Install Depencies
```bash
sudo apt install curl build-essential git wget jq make gcc tmux chrony tar htop net-tools clang pkg-config libssl-dev ncdu -y
```

### Install GO
```bash
if ! [ -x "$(command -v go)" ]; then
  ver="1.19.1"
  cd $HOME
  wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
  rm "go$ver.linux-amd64.tar.gz"
  echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
  source ~/.bash_profile
fi
```

### Download binaries
```bash
git clone https://github.com/mars-protocol/hub mars
cd mars
git checkout v1.0.0-rc7
make install
```

### Config app
```bash
marsd config chain-id $MARS_CHAIN_ID
marsd config keyring-backend test
marsd config node tcp://localhost:${MARS_PORT}657
```

## Init app
```bash
marsd init $NODENAME --chain-id $MARS_CHAIN_ID
```

### Download genesis and addrbook
```bash
wget -O ~/.mars/config/genesis.json https://raw.githubusercontent.com/mars-protocol/networks/main/ares-1/genesis.json
wget -O $HOME/.mars/config/addrbook.json "https://raw.githubusercontent.com/obajay/nodes-Guides/main/Mars/addrbook.json"
```

## Set seeds and peers
```bash
sed -i -e "s/^filter_peers *=.*/filter_peers = \"true\"/" $HOME/.mars/config/config.toml
external_address=$(wget -qO- eth0.me) 
sed -i.bak -e "s/^external_address *=.*/external_address = \"$external_address:26656\"/" $HOME/.mars/config/config.toml
peers=""
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.mars/config/config.toml
seeds="ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@testnet-seeds.polkachu.com:18556"
sed -i.bak -e "s/^seeds =.*/seeds = \"$seeds\"/" $HOME/.mars/config/config.toml
sed -i 's/max_num_inbound_peers =.*/max_num_inbound_peers = 50/g' $HOME/.mars/config/config.toml
sed -i 's/max_num_outbound_peers =.*/max_num_outbound_peers = 50/g' $HOME/.mars/config/config.toml
```

### Set minimum gas price
```bash
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0umars\"/" $HOME/.mars/config/app.toml
```

## Set custom ports
```bash
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${MARS_PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${MARS_PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${MARS_PORT}060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${MARS_PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${MARS_PORT}660\"%" $HOME/.mars/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${MARS_PORT}317\"%; s%^address = \":8080\"%address = \":${MARS_PORT}080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${MARS_PORT}090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${MARS_PORT}091\"%" $HOME/.mars/config/app.toml
sed -i.bak -e "s%^node = \"tcp://localhost:26657\"%node = \"tcp://localhost:2${MARS_PORT}7\"%" $HOME/.mars/config/client.toml
```

### Config pruning (Optional)
```bash
pruning="custom" && \
pruning_keep_recent="100" && \
pruning_keep_every="0" && \
pruning_interval="10" && \
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" ~/.mars/config/app.toml && \
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" ~/.mars/config/app.toml && \
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" ~/.mars/config/app.toml && \
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" ~/.mars/config/app.toml
```

### Indexer (Optional)
```bash
indexer="null" && \
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.mars/config/config.toml
```

### Enable prometheus
```bash
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.mars/config/config.toml
```

### Reset chain data
```bash
marsd tendermint unsafe-reset-all --home $HOME/.mars
```

### Create service
```bash
sudo tee /etc/systemd/system/marsd.service > /dev/null <<EOF
[Unit]
Description=mars
After=network-online.target

[Service]
User=$USER
ExecStart=$(which marsd) start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
```

### Register and start service
```bash
sudo systemctl daemon-reload
sudo systemctl enable marsd
sudo systemctl restart marsd && sudo journalctl -fu marsd -o cat
```

### State-Sync
```bash
SNAP_RPC=http://mars.rpc.t.stavr.tech:190
peers="b42f07453d051f65978c22b8047feb9d2e634aff@mars.peer.stavr.tech:181"
sed -i.bak -e  "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" ~/.mars/config/config.toml
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 300)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.mars/config/config.toml
marsd tendermint unsafe-reset-all --home /root/.mars --keep-addr-book
sed -i -e "s/^snapshot-interval *=.*/snapshot-interval = \"1500\"/" $HOME/.mars/config/app.toml
systemctl restart marsd && journalctl -fu marsd -o cat
```

### Create wallet
To create a new wallet, don't forget to save the mnemonics 
```bash
marsd keys add $WALLET
```

To recover existing keys use
```bash
marsd keys add $WALLET --recover
```

List of wallets
```bash
marsd keys list
```
### Save wallet info
Add wallet and valoper address into variables
```bash
MARS_WALLET_ADDRESS=$(marsd keys show $WALLET -a)
MARS_VALOPER_ADDRESS=$(marsd keys show $WALLET --bech val -a)
echo 'export MARS_WALLET_ADDRESS='${MARS_WALLET_ADDRESS} >> $HOME/.bash_profile
echo 'export MARS_VALOPER_ADDRESS='${MARS_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
```
## [Faucet](https://faucet.marsprotocol.io/)

### To check your wallet balance:
```bash
marsd query bank balances $MARS_WALLET_ADDRESS
```
### Create validator
After your node is synced, create validator
```bash
marsd tx staking create-validator \
--amount=5000000umars \
--pubkey=$(marsd tendermint show-validator) \
--moniker=$NODENAME \
--identity "" \
--website="" \
--details="" \
--chain-id=$MARS_CHAIN_ID \
--commission-rate=0.1 \
--commission-max-rate=0.20 \
--commission-max-change-rate=0.01 \
--min-self-delegation=1 \
--from=$WALLET -y
```

## Usefull commands
### Service management
Check logs
```bash
journalctl -fu marsd -o cat
```

Start service
```bash
sudo systemctl start marsd
```

Stop service
```bash
sudo systemctl stop marsd
```

Restart service
```bash
sudo systemctl restart marsd
```

### Node info
Synchronization info
```bash
marsd status 2>&1 | jq .SyncInfo
```

Validator info
```bash
marsd status 2>&1 | jq .ValidatorInfo
```

Node info
```bash
marsd status 2>&1 | jq .NodeInfo
```

Show node id
```bash
marsd tendermint show-node-id
```

### Wallet operations
List of wallets
```bash
marsd keys list
```

Recover wallet
```bash
marsd keys add $WALLET --recover
```

Delete wallet
```bash
marsd keys delete $WALLET
```

Get wallet balance
```bash
marsd query bank balances $MARS_WALLET_ADDRESS
```

Transfer funds
```bash
marsd tx bank send $MARS_WALLET_ADDRESS <TO_OLLO_WALLET_ADDRESS> 1000000umars
```

### Voting
```bash
marsd tx gov vote 1 yes --from $WALLET --chain-id=$MARS_CHAIN_ID -y
```

### Staking, Delegation and Rewards
Delegate stake
```bash
marsd tx staking delegate $MARS_VALOPER_ADDRESS 1000000umars --from=$WALLET --chain-id=$MARS_CHAIN_ID -y
```

Redelegate stake from validator to another validator
```bash
marsd tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000umars --from=$WALLET --chain-id=$MARS_CHAIN_ID -y
```

Withdraw all rewards
```bash
marsd tx distribution withdraw-all-rewards --from=$WALLET --chain-id=$MARS_CHAIN_ID -y
```

Withdraw rewards with commision
```bash
marsd tx distribution withdraw-rewards $MARS_VALOPER_ADDRESS --from=$WALLET --commission --chain-id=$MARS_CHAIN_ID -y
```

### Validator management
Edit validator
```bash
marsd tx staking edit-validator \
  --moniker=$NODENAME \
  --identity=<your_keybase_id> \
  --website="<your_website>" \
  --details="<your_validator_description>" \
  --chain-id=$MARS_CHAIN_ID \
  --from=$WALLET -y
```

Unjail validator
```bash
marsd tx slashing unjail \
  --broadcast-mode=block \
  --from=$WALLET \
  --chain-id=$MARS_CHAIN_ID -y
```

### Delete node
```bash
sudo systemctl stop marsd && \
sudo systemctl disable marsd && \
rm /etc/systemd/system/marsd.service && \
sudo systemctl daemon-reload && \
cd $HOME && \
rm -rf .mars && \
rm -rf $(which marsd)
sed -i '/MARS_/d' ~/.bash_profile
```
