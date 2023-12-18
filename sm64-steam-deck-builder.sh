#!/bin/bash

echo -e "Super Mario 64 Steam Deck builder - script by Linux Gaming Central\n"

# Removes unhelpful GTK warnings
zen_nospam() {
  zenity 2> >(grep -v 'Gtk' >&2) "$@"
}

# Check if GitHub is reachable
if ! curl -Is https://github.com | head -1 | grep 200 > /dev/null
then
    echo "GitHub appears to be unreachable, you may not be connected to the Internet."
    exit 1
fi

# check if the user is on Deck. If not, provide a warning.
if ! [ $USER = "deck" ]; then
	zen_nospam --title="Super Mario 64 Steam Deck Builder" --width=300 --height=100 --warning --text "Warning: you're likely not using a Steam Deck. Please note this installer may not work on other devices."
fi

US_ROM=baserom.us.z64
JP_ROM=baserom.jp.z64
EU_ROM=baserom.eu.z64

# check for ROM in home. If it doesn't exist, close the program
if ! [[ -f "$HOME/$US_ROM" ]] && ! [[ -f "$HOME/$JP_ROM" ]] && ! [[ -f "$HOME/$EU_ROM" ]]; then
	zen_nospam --title="Super Mario 64 Steam Deck Builder" --width=500 --height=100 --error --text "Error: ROM not found. Place your legally-dumped SM64 ROM in $HOME and name it to $US_ROM, $JP_ROM, or $EU_ROM, depending on the region of the ROM."
	exit
fi

# assign the appropriate region ROM to a new variable
if [ -f "$HOME/$US_ROM" ]; then
	ROM=$US_ROM
elif [ -f "$HOME/$JP_ROM" ]; then
	ROM=$JP_ROM
elif [ -f "$HOME/$EU_ROM" ]; then
	ROM=$EU_ROM
fi

echo -e "ROM is $ROM"

# extract the region name from the ROM
REGION=$(cut -c 9-10 <<< $ROM)
echo -e "Region is $REGION\n"

PC=_pc

SM64=sm64-port
SM64EX=sm64ex
SM64EX_ALO=sm64ex-alo
SM64PLUS=sm64plus
RENDER96=Render96ex

# Main menu
while true; do
Choice=$(zen_nospam --width 1000 --height 400 --list --radiolist --multiple --title "Super Mario 64 Steam Deck Builder and Launcher"\
	--column "Select a Fork" \
	--column "Option" \
	--column="Description"\
	FALSE SM64 "The original SM64 PC port."\
	FALSE SM64EX "SM64 with new options menu, support for texture packs, analog camera, etc."\
	FALSE SM64EX_ALO "Fork of $SM64EX with newer camera, QoL fixes and features, etc."\
	FALSE SM64PLUS "SM64 with more responsive controls/camera, 60 FPS support, and can continue the level after getting a star."\
	FALSE RENDER96 "Fork of $SM64EX with HD character models and textures."\
	FALSE OPTIONS "Download and install needed dependencies, back up save files, download hi-res textures, etc."\
	TRUE EXIT "Exit this script.")

if [ $? -eq 1 ] || [ "$Choice" == "EXIT" ]; then
	echo Goodbye!
	exit

elif [ "$Choice" == "SM64" ]; then
	# sub menu
	while true; do
	Choice=$(zen_nospam --width 800 --height 300 --list --radiolist --multiple --title "Super Mario 64 Steam Deck Builder and Launcher"\
		--column "Select One" \
		--column "Option" \
		--column="Description"\
		FALSE INSTALL_SM64 "Install $SM64"\
		FALSE UPDATE_SM64 "Update $SM64"\
		FALSE PLAY_SM64 "Play $SM64"\
		FALSE EDIT_SM64 "Adjust options for $SM64"\
		FALSE UNINSTALL_SM64 "Uninstall $SM64 (warning: save data will be lost! Back it up first!)"\
		TRUE EXIT "Exit this menu.")

	if [ $? -eq 1 ] || [ "$Choice" == "EXIT" ]; then
		echo -e "\nUser selected EXIT, going back to main menu.\n"
		break

	elif [ "$Choice" == "INSTALL_SM64" ]; then
		cd $HOME

		# check if cloned repo exists. If it does, exit
		if [ -d "$HOME/$SM64" ]; then
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "$SM64 already exists. Please run UPDATE_SM64 if you wish to update $SM64." --width 400 --height 75
		else
			(
			echo -e "Cloning repo...\n"
			git clone https://github.com/$SM64/$SM64.git
			echo 25; sleep 1

			echo -e "Copying ROM...\n"
			cp $HOME/$ROM $HOME/$SM64/
			cd $SM64
			echo 50; sleep 1

			echo -e "Compiling...\n"
			make -j$(nproc)
			echo -e "Finished compiling!\n"
			) | zen_nospam --title "Super Mario 64 Steam Deck Builder" --text "Installing. This will take a minute or two." --progress --percentage=0 --auto-close --auto-kill --width=300 --height=100
			echo 100; sleep 1

			if [ "$?" != 0 ]; then
				echo -e "\nInstallation canceled.\n"
			else
				zen_nospam --info --title "Super Mario 64 Steam Deck Builder" --text "Installation complete!" --width 400 --height 75
			fi
		fi

	elif [ "$Choice" == "UPDATE_SM64" ]; then
		cd $HOME

		# check if sm64-port directory exists. If it doesn't, exit this option
		if ! [ -d "$HOME/$SM64" ]; then
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "$SM64 doesn't exist. Please run INSTALL_SM64 before running this option." --width 400 --height 75
		else
			(
			cd $SM64

			echo -e "Updating repository...\n"
			git pull
			echo 50; sleep 1

			echo -e "Re-compiling...\n"
			make -j$(nproc)
			echo -e "Finished compiling!\n"
			) | zen_nospam --title "Super Mario 64 Steam Deck Builder" --text "Updating. This shouldn't take long." --progress --percentage=0 --auto-close --auto-kill --width=300 --height=100
			echo 100; sleep 1

			if [ "$?" != 0 ]; then
				echo -e "\nUpdate canceled.\n"
			else
				zen_nospam --info --title "Super Mario 64 Steam Deck Builder" --text "Update complete!" --width 400 --height 75
			fi
		fi

	elif [ "$Choice" == "PLAY_SM64" ]; then
		# check to see if executable exists. Discontinue if it's not detected
		if [ -f "$HOME/$SM64/build/$REGION${PC}/sm64.$REGION" ]; then
			cd $HOME/$SM64/build/$REGION${PC}/
			./sm64.$REGION
		else
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "Executable file not found." --width 400 --height 75
		fi

	elif [ "$Choice" == "EDIT_SM64" ]; then
		config_file="$HOME/$SM64/build/$REGION${PC}/sm64config.txt"

		if ! [ -f $config_file ]; then
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "$config_file file not found." --width 400 --height 75
		else
			kate $config_file
		fi

	elif [ "$Choice" == "UNINSTALL_SM64" ]; then
		if ! [ -d $HOME/$SM64 ]; then
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "$SM64 folder not found." --width 400 --height 75
		else
			if ( zen_nospam --title="Super Mario 64 Steam Deck Builder" --width=300 height=200 --question --text="WARNING: please back up your save file from the Options menu, otherwise it will be deleted! Select Yes to continue, or No to stop." ); then
					yes |
						rm -rf $HOME/$SM64
						zen_nospam --info --title "Super Mario 64 Steam Deck Builder" --text "Uninstall complete." --width 400 --height 75
					else
						echo -e "\nUser selected no, continuing...\n"
			fi
		fi
	fi
	done

elif [ "$Choice" == "SM64EX" ]; then
	# sub menu
	while true; do
	Choice=$(zen_nospam --width 800 --height 300 --list --radiolist --multiple --title "Super Mario 64 Steam Deck Builder and Launcher"\
		--column "Select One" \
		--column "Option" \
		--column="Description"\
		FALSE INSTALL_SM64EX "Install $SM64EX"\
		FALSE UPDATE_SM64EX "Update $SM64EX"\
		FALSE PLAY_SM64EX "Play $SM64EX"\
		FALSE EDIT_SM64EX "Adjust options for $SM64EX"\
		FALSE UNINSTALL_SM64EX "Uninstall $SM64EX"\
		TRUE EXIT "Exit this menu.")

	if [ $? -eq 1 ] || [ "$Choice" == "EXIT" ]; then
		echo -e "\nUser selected EXIT, going back to main menu.\n"
		break

	elif [ "$Choice" == "INSTALL_SM64EX" ]; then
		cd $HOME

		# check if cloned repo exists. If it does, exit
		if [ -d "$HOME/$SM64EX" ]; then
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "$SM64EX already exists. Please run UPDATE_SM64EX if you wish to update $SM64EX." --width 400 --height 75
		else
			(
			echo -e "Cloning repo...\n"
			git clone https://github.com/sm64pc/$SM64EX.git
			cd $SM64EX
			echo 25; sleep 1

			echo -e "Copying ROM...\n"
			cp $HOME/$ROM $HOME/$SM64EX/
			echo 50; sleep 1

			echo -e "Compiling...\n"
			make BETTERCAMERA=1 NODRAWINGDISTANCE=1 TEXTURE_FIX=1 EXTERNAL_DATA=1 -j$(nproc)
			echo -e "Finished compiling\n"
			) | zen_nospam --title "Super Mario 64 Steam Deck Builder" --text "Installing. This will take a minute or two." --progress --percentage=0 --auto-close --auto-kill --width=300 --height=100
			echo 100; sleep 1

			if [ "$?" != 0 ]; then
				echo -e "\nInstallation canceled.\n"
			else
				zen_nospam --info --title "Super Mario 64 Steam Deck Builder" --text "Installation complete!" --width 400 --height 75
			fi
		fi

	elif [ "$Choice" == "UPDATE_SM64EX" ]; then
		cd $HOME

		# check if sm64ex directory exists. If it doesn't, exit this option
		if ! [ -d "$HOME/$SM64EX" ]; then
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "$SM64EX doesn't exist. Please run INSTALL_SM64EX before running this option." --width 400 --height 75
		else
			(
			cd $SM64EX
			echo -e "Updating repository...\n"
			git pull
			echo 50; sleep 1

			echo -e "Re-compiling...\n"
			make -j$(nproc)
			echo -e "Finished compiling!\n"
			) | zen_nospam --title "Super Mario 64 Steam Deck Builder" --text "Updating. This shouldn't take long." --progress --percentage=0 --auto-close --auto-kill --width=300 --height=100
			echo 100; sleep 1

			if [ "$?" != 0 ]; then
				echo -e "\nUpdate canceled.\n"
			else
				zen_nospam --info --title "Super Mario 64 Steam Deck Builder" --text "Update complete!" --width 400 --height 75
			fi
		fi

	elif [ "$Choice" == "PLAY_SM64EX" ]; then
		# check to see if executable exists. Discontinue if it's not detected
		if [ -f "$HOME/$SM64EX/build/$REGION${PC}/sm64.$REGION.f3dex2e" ]; then
			cd $HOME/$SM64EX/build/$REGION${PC}/
			./sm64.$REGION.f3dex2e gfx/ --skip-intro
		else
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "Executable file not found." --width 400 --height 75
		fi

	elif [ "$Choice" == "EDIT_SM64EX" ]; then
		config_file="$HOME/.local/share/$SM64EX/sm64config.txt"

		if ! [ -f $config_file ]; then
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "$config_file file not found." --width 400 --height 75
		else
			kate $config_file
		fi

	elif [ "$Choice" == "UNINSTALL_SM64EX" ]; then
		if ! [ -d $HOME/$SM64EX ]; then
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "$SM64EX folder not found." --width 400 --height 75
		else
			rm -rf $HOME/$SM64EX
			zen_nospam --info --title "Super Mario 64 Steam Deck Builder" --text "Uninstall complete." --width 400 --height 75
		fi
	fi
	done

elif [ "$Choice" == "SM64EX_ALO" ]; then
	# sub menu
	while true; do
	Choice=$(zen_nospam --width 800 --height 300 --list --radiolist --multiple --title "Super Mario 64 Steam Deck Builder and Launcher"\
		--column "Select One" \
		--column "Option" \
		--column="Description"\
		FALSE INSTALL_SM64EX_ALO "Install $SM64EX_ALO"\
		FALSE UPDATE_SM64EX_ALO "Update $SM64EX_ALO"\
		FALSE PLAY_SM64EX_ALO "Play $SM64EX_ALO"\
		FALSE EDIT_SM64EX_ALO "Adjust options for $SM64EX_ALO"\
		FALSE UNINSTALL_SM64EX_ALO "Uninstall $SM64EX_ALO"\
		TRUE EXIT "Exit this menu.")

	if [ $? -eq 1 ] || [ "$Choice" == "EXIT" ]; then
		echo -e "\nUser selected EXIT, going back to main menu.\n"
		break

	elif [ "$Choice" == "INSTALL_SM64EX_ALO" ]; then
		cd $HOME

		# check if cloned repo exists. If it does, exit
		if [ -d "$HOME/$SM64EX_ALO" ]; then
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "$SM64EX_ALO already exists. Please run UPDATE_SM64EX_ALO if you wish to update $SM64EX_ALO." --width 400 --height 75
		else
			(
			echo -e "Cloning repo...\n"
			git clone https://github.com/AloUltraExt/$SM64EX_ALO.git
			cd $SM64EX_ALO
			echo 25; sleep 1

			echo -e "Copying ROM...\n"
			cp $HOME/$ROM $HOME/$SM64EX_ALO/
			echo 50; sleep 1

			echo -e "Compiling...\n"
			make BETTERCAMERA=1 NODRAWINGDISTANCE=1 TEXTURE_FIX=1 EXTERNAL_DATA=1 -j$(nproc)
			echo -e "Finished compiling\n"
			) | zen_nospam --title "Super Mario 64 Steam Deck Builder" --text "Installing. This will take a minute or two." --progress --percentage=0 --auto-close --auto-kill --width=300 --height=100
			echo 100; sleep 1

			if [ "$?" != 0 ]; then
				echo -e "\nInstallation canceled.\n"
			else
				zen_nospam --info --title "Super Mario 64 Steam Deck Builder" --text "Installation complete!" --width 400 --height 75
			fi
		fi

	elif [ "$Choice" == "UPDATE_SM64EX_ALO" ]; then
		cd $HOME

		# check if directory exists. If it doesn't, exit this option
		if ! [ -d "$HOME/$SM64EX_ALO" ]; then
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "$SM64EX_ALO doesn't exist. Please run INSTALL_SM64EX_ALO before running this option." --width 400 --height 75
		else
			(
			cd $SM64EX_ALO
			echo -e "Updating repository...\n"
			git pull
			echo 50; sleep 1

			echo -e "Re-compiling...\n"
			make -j$(nproc)
			echo -e "Finished compiling!\n"
			) | zen_nospam --title "Super Mario 64 Steam Deck Builder" --text "Updating. This shouldn't take long." --progress --percentage=0 --auto-close --auto-kill --width=300 --height=100
			echo 100; sleep 1

			if [ "$?" != 0 ]; then
				echo -e "\nUpdate canceled.\n"
			else
				zen_nospam --info --title "Super Mario 64 Steam Deck Builder" --text "Update complete!" --width 400 --height 75
			fi
		fi

	elif [ "$Choice" == "PLAY_SM64EX_ALO" ]; then
		# check to see if executable exists. Discontinue if it's not detected
		if [ -f "$HOME/$SM64EX_ALO/build/$REGION${PC}/sm64.$REGION.f3dex2e" ]; then
			cd $HOME/$SM64EX_ALO/build/$REGION${PC}/
			./sm64.$REGION.f3dex2e gfx/ --skip-intro
		else
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "Executable file not found." --width 400 --height 75
		fi

	elif [ "$Choice" == "EDIT_SM64EX_ALO" ]; then
		config_file="$HOME/.local/share/$SM64EX/sm64config.txt"

		if ! [ -f $config_file ]; then
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "$config_file file not found." --width 400 --height 75
		else
			kate $config_file
		fi

	elif [ "$Choice" == "UNINSTALL_SM64EX_ALO" ]; then
		if ! [ -d $HOME/$SM64EX_ALO ]; then
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "$SM64EX_ALO folder not found." --width 400 --height 75
		else
			rm -rf $HOME/$SM64EX_ALO
			zen_nospam --info --title "Super Mario 64 Steam Deck Builder" --text "Uninstall complete." --width 400 --height 75
		fi
	fi
	done

elif [ "$Choice" == "SM64PLUS" ]; then
	# sub menu
	while true; do
	Choice=$(zen_nospam --width 800 --height 300 --list --radiolist --multiple --title "Super Mario 64 Steam Deck Builder and Launcher"\
		--column "Select One" \
		--column "Option" \
		--column="Description"\
		FALSE INSTALL_SM64PLUS "Install $SM64PLUS"\
		FALSE UPDATE_SM64PLUS "Update $SM64PLUS"\
		FALSE PLAY_SM64PLUS "Play $SM64PLUS"\
		FALSE EDIT_SM64PLUS "Adjust options for $SM64PLUS"\
		FALSE UNINSTALL_SM64PLUS "Uninstall $SM64PLUS (warning: save data will be lost! Back up save before proceeding!)"\
		TRUE EXIT "Exit this menu")

	if [ $? -eq 1 ] || [ "$Choice" == "EXIT" ]; then
		echo -e "\nUser selected EXIT, going back to main menu.\n"
		break

	elif [ "$Choice" == "INSTALL_SM64PLUS" ]; then
		cd $HOME

		# check if cloned repo exists. If it does, exit
		if [ -d "$HOME/$SM64PLUS" ]; then
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "$SM64PLUS already exists. Please run UPDATE_SM64PLUS if you wish to update $SM64PLUS." --width 400 --height 75
		else
			(
			echo -e "Cloning repo...\n"
			git clone https://github.com/MorsGames/$SM64PLUS.git
			echo 25; sleep 1

			echo -e "Copying ROM...\n"
			cp $HOME/$ROM $HOME/$SM64PLUS/
			cd $SM64PLUS
			echo 50; sleep 1

			echo -e "Compiling...\n"
			make -j$(nproc)
			echo -e "Finished compiling!\n"
			) | zen_nospam --title "Super Mario 64 Steam Deck Builder" --text "Installing. This will take a minute or two." --progress --percentage=0 --auto-close --auto-kill --width=300 --height=100
			echo 100; sleep 1

			if [ "$?" != 0 ]; then
				echo -e "\nInstallation canceled.\n"
			else
				zen_nospam --info --title "Super Mario 64 Steam Deck Builder" --text "Installation complete!" --width 400 --height 75
			fi
		fi

	elif [ "$Choice" == "UPDATE_SM64PLUS" ]; then
		cd $HOME

		# check if directory exists. If it doesn't, exit this option
		if ! [ -d "$HOME/$SM64PLUS" ]; then
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "$SM64PLUS doesn't exist. Please run INSTALL_SM64PLUS before running this option." --width 400 --height 75
		else
			(
			cd $SM64PLUS
			echo -e "Updating repository...\n"
			git pull
			echo 50; sleep 1

			echo -e "Re-compiling...\n"
			make -j$(nproc)
			echo -e "Finished compiling!\n"
			) | zen_nospam --title "Super Mario 64 Steam Deck Builder" --text "Updating. This shouldn't take long." --progress --percentage=0 --auto-close --auto-kill --width=300 --height=100
			echo 100; sleep 1

			if [ "$?" != 0 ]; then
				echo -e "\nUpdate canceled.\n"
			else
				zen_nospam --info --title "Super Mario 64 Steam Deck Builder" --text "Update complete!" --width 400 --height 75
			fi
		fi

	elif [ "$Choice" == "PLAY_SM64PLUS" ]; then
		# check to see if executable exists. Discontinue if it's not detected
		if [ -f "$HOME/$SM64PLUS/build/$REGION${PC}/sm64.$REGION" ]; then
			cd $HOME/$SM64PLUS/build/$REGION${PC}/
			./sm64.$REGION gfx/
		else
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "Executable file not found." --width 400 --height 75
		fi

	elif [ "$Choice" == "EDIT_SM64PLUS" ]; then
		config_file="$HOME/$SM64PLUS/build/$REGION${PC}/settings.ini"

		if ! [ -f $config_file ]; then
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "$config_file file not found." --width 400 --height 75
		else
			kate $config_file
		fi

	elif [ "$Choice" == "UNINSTALL_SM64PLUS" ]; then
		if ! [ -d $HOME/$SM64PLUS ]; then
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "$SM64PLUS folder not found." --width 400 --height 75
		else
			if ( zen_nospam --title="Super Mario 64 Steam Deck Builder" --width=300 height=200 --question --text="WARNING: please back up your save file from the Options menu, otherwise it will be deleted! Select Yes to continue, or No to stop." ); then
					yes |
						rm -rf $HOME/$SM64PLUS
						zen_nospam --info --title "Super Mario 64 Steam Deck Builder" --text "Uninstall complete." --width 400 --height 75
					else
						echo -e "\nUser selected no, continuing...\n"
			fi
		fi
	fi
	done

elif [ "$Choice" == "RENDER96" ]; then
	# sub menu
	while true; do
	Choice=$(zen_nospam --width 800 --height 350 --list --radiolist --multiple --title "Super Mario 64 Steam Deck Builder and Launcher"\
		--column "Select One" \
		--column "Option" \
		--column="Description"\
		FALSE INSTALL_RENDER96 "Install $RENDER96"\
		FALSE INSTALL_TEXTURE_PACKS "Install model/texture packs for $RENDER96 (downloading texture pack will take a while)"\
		FALSE UPDATE_RENDER96 "Update $RENDER96"\
		FALSE PLAY_RENDER96 "Play $RENDER96"\
		FALSE EDIT_RENDER96 "Adjust options for $RENDER96"\
		FALSE UNINSTALL_RENDER96 "Uninstall $RENDER96"\
		TRUE EXIT "Exit this menu.")

	if [ $? -eq 1 ] || [ "$Choice" == "EXIT" ]; then
		echo -e "\nUser selected EXIT, going back to main menu.\n"
		break

	elif [ "$Choice" == "INSTALL_RENDER96" ]; then
		cd $HOME

		# check if cloned repo exists. If it does, exit
		if [ -d "$HOME/$RENDER96" ]; then
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "$RENDER96 already exists. Please run UPDATE_RENDER96 if you wish to update $RENDER96." --width 400 --height 75
		else
			(
			echo -e "Cloning repo...\n"
			git clone https://github.com/Render96/$RENDER96.git
			cd $RENDER96
			echo 25; sleep 1

			echo -e "Copying ROM...\n"
			cp $HOME/$ROM $HOME/$RENDER96/
			echo 50; sleep 1

			echo -e "Compiling...\n"
			make -j4

			# sometimes the command needs to be run twice...
			echo -e "Compiling a second time...\n"
			make -j4
			echo -e "Finished compiling.\n"
			echo 70; sleep 1

			) | zen_nospam --title "Super Mario 64 Steam Deck Builder" --text "Installing. This will take a minute or two." --progress --percentage=0 --auto-close --auto-kill --width=300 --height=100
			echo 100; sleep 1

			if [ "$?" != 0 ]; then
				echo -e "\nInstallation canceled.\n"
			else
				zen_nospam --info --title "Super Mario 64 Steam Deck Builder" --text "Installation complete!" --width 400 --height 75
			fi
		fi

	elif [ "$Choice" == "INSTALL_TEXTURE_PACKS" ]; then
		if [ -d $HOME/$RENDER96/build/$REGION${PC}/dynos/packs ] || [ -d $HOME/$RENDER96/build/$REGION${PC}/res/gfx ]; then
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "$RENDER96 texture/model pack already exists." --width 400 --height 75
		else
			echo -e "Downloading model pack...\n"
			cd $HOME
			curl -L $(curl -s https://api.github.com/repos/Render96/ModelPack/releases/latest | grep "browser_download_url" | cut -d '"' -f 4) -o $HOME/Render96_DynOs.7z
			echo -e "Extracting model pack...\n"
			7za x Render96_DynOs.7z -o/$HOME/$RENDER96/build/$REGION${PC}/dynos/packs
			rm Render96_DynOs.7z

			echo -e "Downloading texture pack...\n"
			cd $HOME
			git clone https://github.com/pokeheadroom/RENDER96-HD-TEXTURE-PACK.git -b master
			echo -e "Copying...\n"
			cd RENDER96-HD-TEXTURE-PACK
			mkdir $HOME/$RENDER96/build/$REGION${PC}/res
			cp gfx/ -r $HOME/$RENDER96/build/$REGION${PC}/res/gfx
			cd $HOME
			rm -rf RENDER96-HD-TEXTURE-PACK
			echo -e "Done.\n"

			zen_nospam --info --title "Super Mario 64 Steam Deck Builder" --text "Install complete. Note that you will need to enable the HD models via the in-game options menu in order to use them." --width 400 --height 75
		fi

	elif [ "$Choice" == "UPDATE_RENDER96" ]; then
		cd $HOME

		# check if directory exists. If it doesn't, exit this option
		if ! [ -d "$HOME/$RENDER96" ]; then
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "$RENDER96 doesn't exist. Please run INSTALL_RENDER96 before running this option." --width 400 --height 75
		else
			(
			cd $RENDER96
			echo -e "Updating repository...\n"
			git pull
			echo 50; sleep 1

			echo -e "Re-compiling...\n"
			make -j$(nproc)
			echo -e "Finished compiling!\n"
			) | zen_nospam --title "Super Mario 64 Steam Deck Builder" --text "Updating. This shouldn't take long." --progress --percentage=0 --auto-close --auto-kill --width=300 --height=100
			echo 100; sleep 1

			if [ "$?" != 0 ]; then
				echo -e "\nUpdate canceled.\n"
			else
				zen_nospam --info --title "Super Mario 64 Steam Deck Builder" --text "Update complete!" --width 400 --height 75
			fi
		fi

	elif [ "$Choice" == "PLAY_RENDER96" ]; then
		# check to see if executable exists. Discontinue if it's not detected
		if [ -f "$HOME/$RENDER96/build/$REGION${PC}/sm64.$REGION.f3dex2e" ]; then
			cd $HOME/$RENDER96/build/$REGION${PC}/
			./sm64.$REGION.f3dex2e --skip-intro
		else
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "Executable file not found." --width 400 --height 75
		fi

	elif [ "$Choice" == "EDIT_RENDER96" ]; then
		config_file="$HOME/.local/share/$SM64EX/sm64config.txt"

		if ! [ -f $config_file ]; then
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "$config_file file not found." --width 400 --height 75
		else
			kate $config_file
		fi

	elif [ "$Choice" == "UNINSTALL_RENDER96" ]; then
		if ! [ -d $HOME/$RENDER96 ]; then
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "$RENDER96 folder not found." --width 400 --height 75
		else
			rm -rf $HOME/$RENDER96
			zen_nospam --info --title "Super Mario 64 Steam Deck Builder" --text "Uninstall complete." --width 400 --height 75
		fi
	fi
	done

elif [ "$Choice" == "OPTIONS" ]; then
	# sub menu
	while true; do
	Choice=$(zen_nospam --width 800 --height 300 --list --radiolist --multiple --title "Super Mario 64 Steam Deck Builder and Launcher"\
		--column "Select One" \
		--column "Option" \
		--column="Description"\
		FALSE DEPENDENCIES "Install build dependencies. (Root password required.)"\
		FALSE BACKUP "Backup save files"\
		FALSE INSTALL_SM64_RELOADED "Install SM64 Reloaded (hi-res textures)"\
		TRUE EXIT "Exit this menu.")

	if [ $? -eq 1 ] || [ "$Choice" == "EXIT" ]; then
		echo -e "\nUser selected EXIT, going back to main menu.\n"
		break

	elif [ "$Choice" == "DEPENDENCIES" ]; then
		sudo_password=$(zen_nospam --password --title="Super Mario 64 Steam Deck Builder")
		if [[ ${?} != 0 || -z ${sudo_password} ]]; then
			echo -e "User canceled.\n"
		elif ! sudo -kSp '' [ 1 ] <<<${sudo_password} 2>/dev/null; then
			echo -e "User entered wrong password.\n"
			zen_nospam --error --title "Super Mario 64 Steam Deck Builder" --text "Wrong password." --width 300
		else
			# Disable the filesystem until we're done
			echo -e "Disabling read-only mode...\n"
			sudo -Sp '' steamos-readonly disable <<<${sudo_password}

			# Get pacman keys
			echo -e "Populating pacman keys...\n"
			sudo pacman-key --init
			sudo pacman-key --populate archlinux holo

			echo -e "Installing essential build tools...\n"
			sudo pacman -S --needed --noconfirm base-devel "$(cat /usr/lib/modules/$(uname -r)/pkgbase)-headers"

			# some additional commands needed to install SM64Plus
			if ( zen_nospam --title="Super Mario 64 Steam Deck Builder" --width=300 height=200 --question --text="Additional tools are required to install $SM64PLUS. Would you like to install these?" ); then
			yes |
				sudo sed -i 's/\(^\[.*\]\)/\1\nSigLevel = Never/g' /etc/pacman.conf
				sudo pacman -Syyu --noconfirm
				sudo pacman -S --needed $(pacman -Ql | grep include | cut -d' ' -f1 | awk '!a[$0]++') --noconfirm
				sudo pacman --overwrite=/etc/ld.so.conf.d/fakeroot.conf -S --needed --noconfirm python sdl2 glew
			else
				echo -e "\nUser selected no, continuing...\n"
			fi

			# restore the read-only FS
			echo -e "Restoring read-only filesystem...\n"
			sudo steamos-readonly enable
			echo -e "Done.\n"

			zen_nospam --info --title "Super Mario 64 Steam Deck Builder" --text "Make dependencies installed!" --width 400 --height 75
		fi

	elif [ "$Choice" == "BACKUP" ]; then
		mkdir -p $HOME/sm64_save_backups
		mkdir -p $HOME/sm64_save_backups/$RENDER96
		mkdir -p $HOME/sm64_save_backups/$SM64EX
		mkdir -p $HOME/sm64_save_backups/$SM64
		mkdir -p $HOME/sm64_save_backups/$SM64PLUS
		cp $HOME/.local/share/sm64ex/render96_save_file_0.sav $HOME/sm64_save_backups/$RENDER96
		cp $HOME/.local/share/sm64ex/sm64_save_file.bin $HOME/sm64_save_backups/$SM64EX
		cp $HOME/$SM64/build/$REGION${PC}/sm64_save_file.bin $HOME/sm64_save_backups/$SM64
		cp $HOME/$SM64PLUS/build/$REGION${PC}/savedata.bin $HOME/sm64_save_backups/$SM64PLUS

		zen_nospam --info --title "Super Mario 64 Steam Deck Builder" --text "Save data backed up to $HOME/sm64_save_backups." --width 400 --height 75

	elif [ "$Choice" == "INSTALL_SM64_RELOADED" ]; then
		cd $HOME
		curl -L https://evilgames.eu/texture-packs/files/sm64-reloaded-v2.4.0-pc-1080p.zip -o sm64-reloaded.zip
		7za x sm64-reloaded.zip
		cp -r gfx/ $SM64EX/build/$REGION${PC}/res/
		cp -r gfx/ $SM64EX_ALO/build/$REGION${PC}/res/
		cp -r gfx/ $SM64PLUS/build/$REGION${PC}/

		rm sm64-reloaded.zip
		rm -rf gfx/

		zen_nospam --info --title "Super Mario 64 Steam Deck Builder" --text "Hi-res textures installed to $SM64EX, $SM64EX_ALO, and $SM64PLUS." --width 400 --height 75
	fi
	done
fi
done
