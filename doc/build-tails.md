# PrivcyCoin in Tails persistent volume

[Tails](https://tails.boum.org) is an amnesic live operating system that aims to preserve your privacy and anonymity. It is a Linux Debian distribution configured to follow several security measures including sending all internet traffic through the Tor network. The following tutorial documents how to build PrivcyCoin in Tails, create an AppImage, configure the amnesic system to whitelist the PrivcyCoin application, as well as creating a bash script to automate this configuration in Live sessions.

To install the PrivcyCoin QT wallet in Tails you will need a [persistent volume](https://tails.boum.org/doc/first_steps/persistence/index.en.html) configured with Personal Data and GnuPG enabled. You can build PrivcyCoin in Tails and create an AppImage or [download the image](https://PrivcyCoin.org/community/threads/tutorial-packaging-PrivcyCoin-qt-wallet-with-appimage.29042/) and configure Tails to use it instead. This process has been tested with PrivcyCoin 1.5.5 in Tails 3.5, it may not work for newer versions.

*Please read: [Warnings about persistence](https://tails.boum.org/doc/first_steps/persistence/warnings/index.en.html) before continuing. Downloading and executing the PrivcyCoin pacakaged image is at your own risk, as is configuring the firewall from the default [Tails configuration](https://tails.boum.org/contribute/design/Tor_enforcement/Network_filter/)*.

## Building from source into persistent volume

Follow the slightly modified version of [unix build](https://github.com/PrivcyCoin/PrivcyCoin/blob/master/doc/build-unix.txt) instructions. You can otherwise follow the generic build instructions and make the PrivcyCoin AppImage in a more convenient Linux environment to use with Tails, which has also been tested.

These instructions are tailored for a Debian Stretch/Sid distribution with dependencies acquired through the Tor Network by using [torsocks](https://github.com/dgoulet/torsocks) and it's frontend torify to connect via local proxy, as is a requirement in Tails.

1. Access your persistent volume with admin password enabled and install dependencies:

```
sudo apt update && sudo apt upgrade -y
sudo apt install build-essential libtool autotools-dev autoconf automake pkg-config libboost-all-dev bsdmainutils libqrencode-dev libminiupnpc-dev libevent-dev libcap-dev libseccomp-dev git software-properties-common libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler
```

2. Configure additional APT repositories for installing in Stretch/Sid:

```
sudo nano /etc/apt/sources.list
```

3. Include Bitcoin/Xenial and Jessie/Backports to that list:

```
deb tor+http://ppa.launchpad.net/bitcoin/bitcoin/ubuntu xenial main
deb tor+http://ftp.de.debian.org/debian jessie-backports main
```

4. Copy and save the [Bitcoin repository key](https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xD46F45428842CE5E) ([ref](https://launchpad.net/~bitcoin/+archive/ubuntu/bitcoin)) as Bitcoin.gpg in Downloads, add to keyring and update:

```
sudo apt-key add Downloads/Bitcoin.gpg
sudo apt update
```

5. Install additional dependencies Berkeley 4.8++ and OpenSSL 1.0

```
sudo apt install libdb4.8-dev libdb4.8++-dev libssl1.0 libssl1.0-dev
```

6. Clone PrivcyCoin repository to persistent volume, as you would normally:

```
cd /home/amnesia/Persistent
git clone --recursive https://github.com/privcycoin/privcy.git
```

7. Build with autotools into the persistent volume:

```
cd PrivcyCoin
./autogen.sh
./configure --with-gui=qt5
make
```

## Creating AppImage in the persistent volume

We then follow the instructions for packaging PrivcyCoin, but again using torsocks where necessary and within the persistent volume. To get an insight about these steps, read PrivcyCoin's [AppImage tutorial](https://github.com/PrivcyCoin/PrivcyCoin/blob/master/doc/build-appimage.md).

> In this way, we obtain a file named PrivcyCoin_wallet-x86_64.AppImage, that can be distributed without worrying about dependencies; the only step needed to get it running is making it executable.

```
shell
$ mkdir -p dist/usr/bin
$ cd dist
$ cp ../src/qt/PrivcyCoin-qt usr/bin/
$ nano PrivcyCoin-qt.desktop
 — — — — — — — — — — — — — —
[Desktop Entry]
Version=1.0
Type=Application
Name=PrivcyCoin wallet
Exec=AppRun %F
Icon=PrivcyCoin
Categories=Network;
 — — — — — — — — — — — — — —
$ torify wget https://raw.githubusercontent.com/PrivcyCoin/PrivcyCoin/master/src/qt/res/icons/PrivcyCoin.png
$ torify wget https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage
$ chmod a+x linuxdeployqt-continuous-x86_64.AppImage
$ sudo apt install qt5-default qt5-qmake
$ ./linuxdeployqt-continuous-x86_64.AppImage usr/bin/PrivcyCoin-qt -appimage -bundle-non-qt-libs -verbose=2
```

## Configuring firewall and data directory

If you have downloaded the AppImage or produced it in another system then create the directory PrivcyCoin/dist in the persistent volume and copy the image to this folder before proceeding with configuration instructions.

> [Ferm](http://ferm.foo-projects.org/download/2.1/ferm.html) is a tool to maintain complex firewalls, without having the trouble to rewrite the complex rules over and over again. ferm allows the entire firewall rule set to be stored in a separate file, and to be loaded with one command. The firewall configuration resembles structured programming-like language, which can contain levels and lists.

1. Access ferm firewall configuration that manages whitelisted application connections in Tails:

```
sudo nano /etc/ferm/ferm.conf
```

2. Enter the following lines to the list to enable SOCKS5 listening port 9081:

```
# White-list access to PrivcyCoin
daddr 127.0.0.1 proto tcp syn dport 9081 {
mod owner uid-owner $amnesia_uid ACCEPT;
}
```

3. Restart ferm's firewall configuration to register update:

```
sudo ferm /etc/ferm/ferm.conf
```

4. Create the data directory .PrivcyCoin in persistent volume:

```
mkdir -p /home/amnesia/Persistent/.PrivcyCoin
```

5. Launch with torsocks and data target option:

```
cd ~/Persistent/PrivcyCoin/dist
torsocks ./PrivcyCoin_wallet-x86_64.AppImage -datadir=/home/amnesia/Persistent/.PrivcyCoin
```

*Note: You will additionally need a [PrivcyCoin.conf](https://PrivcyCoin.org/PrivcyCoin.conf.php?action=download) file to place in the .PrivcyCoin directory.*

## Creating bash script for auto-configuring executable

The bash script, as before, will overwrite the amnesic firewall configuration to enable the socks listening port then launch PrivcyCoin with torsocks wrapping to authorize the connection to the Tor network.

1. Copy the config file from the amnesic file system to persistent volume:

```
sudo mkdir -p /home/amnesia/Persistent/.PrivcyCoin/ferm
sudo cp /etc/ferm/ferm.conf /home/amnesia/Persistent/.PrivcyCoin/ferm/ferm.conf
```

2. Create new file in /PrivcyCoin directory named PrivcyCoin-Tails and input this data:

```
#!/bin/bash
sudo cp /home/amnesia/Persistent/.PrivcyCoin/ferm/ferm.conf /etc/ferm/ferm.conf
sudo ferm /etc/ferm/ferm.conf
cd /home/amnesia/Persistent/PrivcyCoin/dist/
torsocks ./PrivcyCoin_wallet-x86_64.AppImage -datadir=/home/amnesia/Persistent/.PrivcyCoin
```

3. Make file executeable and launch PrivcyCoin-Tails:

```
cd ../
chmod +x PrivcyCoin-Tails
./PrivcyCoin-Tails
```

## Launching PrivcyCoin in Tails Live

On rebooting Tails will return to it's default live state with the blockchain and wallet data saved in the persistent volume. Thanks to the dependencies included in the AppImage, that have been wiped from the amnesic system after shutting down, we can now execute PrivcyCoin in Tail's native environment without further installation.

To launch PrivcyCoin we unlock our persistent volume and run the PrivcyCoin-Tails executable:

```
./Persistent/PrivcyCoin/PrivcyCoin-Tails
```
*Note: You will be prompted for your admin password in order for the executable to configure the firewall configuration. PrivcyCoin is otherwise launched from the amnesic user. Do not execute PrivcyCoin-Tails with root privileges.*
