#!/bin/bash

echo -e "Super Mario 64 Steam Deck builder - script by Linux Gaming Central\n"

US_ROM=baserom.us.z64
JP_ROM=baserom.jp.z64
EU_ROM=baserom.eu.z64

# If a password was set by the program, this will run when the program closes
temp_pass_cleanup() {
  echo $PASS | sudo -S -k passwd -d deck
}

# Removes unhelpful GTK warnings
zen_nospam() {
  zenity 2> >(grep -v 'Gtk' >&2) "$@"
}

get_build_tools() {
	# Disable the filesystem until we're done
	echo -e "Disabling read-only mode...\n"
	sudo steamos-readonly disable

	# Get pacman keys
	echo -e "Getting pacman keys...\n"
	sudo pacman-key --init
	sudo pacman-key --populate archlinux holo

	echo -e "Installing essential build tools...\n"
	sudo pacman -S --needed --noconfirm base-devel "$(cat /usr/lib/modules/$(uname -r)/pkgbase)-headers"
}

# Check if GitHub is reachable
if ! curl -Is https://github.com | head -1 | grep 200 > /dev/null
then
    echo "GitHub appears to be unreachable, you may not be connected to the Internet."
    exit 1
fi

# If the script is not root yet, get the password and re-run as root
if (( $EUID != 0 )); then
    PASS_STATUS=$(passwd -S deck 2> /dev/null)
    if [ "$PASS_STATUS" = "" ]; then
        echo "Warning: Deck user not found!"
    fi

    if [ "${PASS_STATUS:5:2}" = "NP" ]; then # if no password is set, set up a temporary password to Smash!
        if ( zen_nospam --title="Super Mario 64 Steam Deck Builder" --width=300 --height=200 --question --text="You appear to have not set an admin password.\nSuper Mario 64 Steam Deck Builder can still install by temporarily setting your password to 'Smash!' and continuing, then removing it when the installer finishes\nAre you okay with that?" ); then
            yes "Smash!" | passwd deck # set password to Smash!
            trap temp_pass_cleanup EXIT # make sure that password is removed when application closes
            PASS="Smash!"
        else exit 1; fi
    else
        # get password
        FINISHED="false"
        while [ "$FINISHED" != "true" ]; do
            PASS=$(zen_nospam --title="Super Mario 64 Steam Deck Builder" --width=300 --height=100 --entry --hide-text --text="Enter your sudo/admin password")
            if [[ $? -eq 1 ]] || [[ $? -eq 5 ]]; then
                exit 1
            fi
            if ( echo "$PASS" | sudo -S -k true ); then
                FINISHED="true"
            else
                zen_nospam --title="Super Mario 64 Steam Deck Builder" --width=150 --height=40 --info --text "Incorrect password!"
            fi
        done
    fi

    if ! [ $USER = "deck" ]; then # check if the user is on Deck. If not, provide a warning.
        zen_nospam --title="Super Mario 64 Steam Deck Builder" --width=300 --height=100 --warning --text "Error: you're likely not using a Steam Deck. Please note this installer may not work on other devices."
    fi
    
    echo "$PASS" | sudo -S -k bash "$0" "$@" # rerun script as root
    exit 1
fi

while true; do
Choice=$(zenity --width 1000 --height 550 --list --radiolist --multiple --title "Super Mario 64 Steam Deck Builder"\
	--column "Select One" \
	--column "Option" \
	--column="Description"\
	FALSE SM64 "The original SM64 PC port"\
	FALSE PLAY_SM64 "Play SM64"
	#FALSE SM64+ "SM64 with improved camera, controls, expanded moveset, 60 FPS support, etc."\
	#FALSE SM64EX "SM64 with button remapping, support for custom texture packs, analog camera, etc."\
	#FALSE SM64EX_ALO "SM64EX with even more QoL improvements"
	#FALSE RENDER96EX "SM64 with HD models and textures"
	TRUE EXIT "Exit this script")

if [ $? -eq 1 ] || [ "$Choice" == "EXIT" ]; then
	echo Goodbye!
	
	# restore the read-only FS
	sudo steamos-readonly enable
	
	exit

elif [ "$Choice" == "SM64" ]; then
	get_build_tools
	
	cd $HOME
	
	echo -e "Cloning repo...\n"
	git clone https://github.com/sm64-port/sm64-port.git
	cd sm64-port
	
	zenity --info --title "Super Mario 64 Steam Deck Builder" --text "Place the SM64 ROM inside of the sm64-port folder, name it to $US_ROM (or $JP_ROM or $EU_ROM, depending on the ROM's region), then click/tap OK to continue." --width 400 --height 75
	
	# check to see if ROM exists. Discontinue if it's not detected
	if [ -f "$HOME/sm64-port/$US_ROM" ] || [ -f "$HOME/sm64-port/$JP_ROM" ] || [ -f "$HOME/sm64-port/$EU_ROM" ]; then
		echo -e "Compiling...\n"
		make -j4
		echo -e "Finished compiling\n"
		zenity --info --title "Super Mario 64 Steam Deck Builder" --text "Installation complete!" --width 400 --height 75
	else
		zenity --error --title "Super Mario 64 Steam Deck Builder" --text "ROM file not found." --width 400 --height 75
	fi

elif [ "$Choice" == "PLAY_SM64" ]; then
	# check to see if ROM exists. Discontinue if it's not detected
	if [ -f "$HOME/sm64-port/$US_ROM" ]; then
		./$HOME/sm64-port/build/us_pc/sm64.us.f3dex2e
	elif [ -f "$HOME/sm64-port/$JP_ROM" ]; then
		./$HOME/sm64-port/build/jp_pc/sm64.jp.f3dex2e		
	elif [ -f "$HOME/sm64-port/$EU_ROM" ]; then
		./$HOME/sm64-port/build/eu_pc/sm64.eu.f3dex2e
	else
		zenity --error --title "Super Mario 64 Steam Deck Builder" --text "ROM file not found." --width 400 --height 75
	fi
fi
done
