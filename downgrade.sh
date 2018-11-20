#! /bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

KernelList="$(dpkg -l |grep 'linux-image' |awk '{print $2}')"
[ -z "$(echo $KernelList |grep -o linux-image-3.16.0-4-amd64)" ] && echo "Install error." && exit 1
for KernelTMP in `echo "$KernelList"`
 do
  [ "$KernelTMP" != "linux-image-3.16.0-4-amd64" ] && echo -ne "Uninstall Old Kernel\n\t$KernelTMP\n" && apt-get purge "$KernelTMP" -y >/dev/null 2>&1
done

for KernelTMP in `echo "$KernelList"`
 do
  [ "$KernelTMP" != "linux-image-3.16.0-4-amd64" ] && echo -ne "Uninstall Old Kernel\n\t$KernelTMP\n" && apt-get purge "$KernelTMP" -y >/dev/null 2>&1
done

apt purge linux-headers* -y
apt install linux-headers-3.16.0-4-amd64 -y

apt-mark hold linux-image-3.16.0-4-amd64

update-grub && update-grub2

reboot
