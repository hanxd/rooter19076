# rooter19076

The official repository for the ROOter build system using OpenWrt 19.07.6

To create a ROOter 19.07.6 build system in a folder named 'rooter19076' 
run the following :

git clone https://github.com/ofmodemsandmen/rooter19076 rooter19076
cd rooter19076
./scripts/feeds update -a
./scripts/feeds install -a

Use 'make menuconfig' to select the Target and router model you want and
then run 'make V=s' to build the image.
