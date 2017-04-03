#!/bin/bash

IMG="/home/fragmede/iso/2017-03-02-raspbian-jessie-lite.img"
MNTDIR="./mnt"

function setup {
	sudo losetup /dev/loop0 "${IMG}"
	sudo kpartx -a /dev/loop0 
	sudo mount -o loop /dev/mapper/loop0p2 "${MNTDIR}"
	sudo mount -o loop /dev/mapper/loop0p1 "${MNTDIR}/boot"
}

function enable_ssh {
	sudo touch "${MNTDIR}"/boot/ssh
}

function modify_config_txt {
	grep "dtoverlay=dwc2" "${MNTDIR}/boot/config.txt"
	if [[ $? -ne 0 ]]; then
		echo "dtoverlay=dwc2" | sudo tee -a "${MNTDIR}/boot/config.txt" >/dev/null
	fi;
	echo "tail -2 of new config.txt:"
	tail -2 "${MNTDIR}"/boot/config.txt
}

function modify_cmdline_txt {
	if [[ ! -e "${MNTDIR}/boot/cmdline.txt.orig" ]]; then
		echo backing up cmdline.txt
		sudo cp "${MNTDIR}/boot/cmdline.txt" "${MNTDIR}/boot/cmdline.txt.orig"
	fi;
	cmdline=`cat "${MNTDIR}/boot/cmdline.txt" | tr -d '\n'`
	echo "$cmdline modules-load=dwc2,g_ether" | sudo tee "${MNTDIR}/boot/cmdline.txt" >/dev/null
	
	echo "new cmdline.txt"
	cat "${MNTDIR}/boot/cmdline.txt"
}

function setup_usb0_static {
# edit /etc/network/interfaces to be static
	cp ./usb0 "${MNTDIR}/etc/network/interfaces.d/"
}

function config_dnsmasq {
# install dnsmasq and configure
	# somehow dpkg/apt-get -i dnsmasq
	cp ./usb0-dhcp "${MNTDIR}/etc/dnsmasq.d/usb0-dhcp"
}

function save_and_cleanup {
	sudo umount "${MNTDIR}/boot"
	sudo umount "${MNTDIR}"
	sudo losetup -d /dev/loop0
}

setup
enable_ssh
modify_config_txt
modify_cmdline_txt
setup_usb0_static
#TODO
# enable overlay mode
#   not systemd compat? https://hallard.me/raspberry-pi-read-only/
save_and_cleanup
