## Building on *Nix

### Dependencies

```
apt-get update
apt-get upgrade
apt-get install autotools-dev autoconf automake bsdmainutils build-essential git
apt-get install libtool libssl-dev libboost-all-dev pkg-config 
apt-get install libqrencode-dev libminiupnpc-dev libevent-dev libcap-dev libseccomp-dev 
```
```
apt-get install software-properties-common
add-apt-repository ppa:bitcoin/bitcoin
apt-get update
apt-get install libdb4.8-dev libdb4.8++-dev
```
#### Clone Source

Clone file source:

`git clone --recursive https://github.com/privcycoin/privcy.git`

#### Building Daemon

Build non-GUI

    cd privcy
    ./autogen.sh
    ./configure --without-gui
    make


#### Building GUI Version

```
apt-get install libqt5gui5 libqt5core5a libqt5dbus5 libprotobuf-dev protobuf-compiler qttools5-dev qttools5-dev-tools
```

    cd privcy
    ./autogen.sh
    ./configure --with-gui=qt5 
    make