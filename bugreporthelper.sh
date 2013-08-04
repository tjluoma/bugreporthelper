#!/bin/zsh -f
# Purpose: show relevant information about this Mac (helpful for bug reporting)
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2013-08-03

## NOTE:
## Keyboard Maestro uses a modified version of this, but it is embedded in the macro itself

NAME="$0:t:r"

zmodload zsh/datetime

TEMPFILE="${TMPDIR-/tmp/}${NAME}.${EPOCHSECONDS}.$$.$RANDOM"

umask 022

touch "$TEMPFILE"


if [ "$1" = "--fromKM" ]
then
		FROM_KEYBOARD_MAESTRO=yes
		shift
else
		FROM_KEYBOARD_MAESTRO=no
fi

if [ "$#" = "0" -a "$FROM_KEYBOARD_MAESTRO" = "no" ]
then

		echo -n "\nIf you are requesting support for an Application or PreferencePane, enter the name of it here (i.e. Dropbox, Hazel, etc): "

		read APP_NAME

else

		APP_NAME="$@"
fi


mdfind filename:"$APP_NAME" -onlyin /Applications -onlyin /Library/PreferencePanes -onlyin ~/Applications -onlyin ~/Library/PreferencePanes | while read line
do

PLIST="$line/Contents/Info.plist"

if [ -e "$PLIST" ]
then

	echo "\nVersion Information for: $line" | tee -a "$TEMPFILE"

# Do not indent that one line
	plutil -convert xml1 -o - "$PLIST" |\
	egrep -A1 '(CFBundleVersion|CFBundleShortVersionString)' |\
	sed 's#<key>##g; s#</key>##g ; s#<string>##g; s#</string>##g' |\
	tr -s '\t|\012' ' ' |\
	sed 's#--#\
#g' |\
	sed 's#^#     #g' |\
	tee -a "$TEMPFILE"
# Do not indent that one line


fi

done


echo "\nHardware Information (system_profiler):" | tee -a "$TEMPFILE"
system_profiler SPHardwareDataType | egrep 'Model Name|Model Identifier|Processor|Cores|Cache|Memory' | tee -a "$TEMPFILE"

echo "\nOperating System Information (sw_vers):" | tee -a "$TEMPFILE"
sw_vers | sed 's#^#      #g' | tee -a "$TEMPFILE"

echo "\nThird Party Kernel Extensions (kextstat):"  | tee -a "$TEMPFILE"
kextstat | awk '{print $6}' | sort | egrep -v '^com\.apple\.|^Name$' | sed 's#^#      #g' | tee -a "$TEMPFILE"

echo "\nLogin Items (com.apple.loginitems): " | tee -a "$TEMPFILE"
defaults read com.apple.loginitems | fgrep 'Name = ' | sed 's#^.*Name = "#      #g ; s#";##g' | tee -a "$TEMPFILE"

for i in \
	"$HOME/Library/LaunchAgents/" \
	"$HOME/Library/LaunchDaemons/" \
	"/Library/LaunchAgents/" \
	"/Library/LaunchDaemons/"
do

	if [ -d "$i" ]
	then
			cd "$i"
			echo "\nlaunchd items in: $i" | sed "s#$HOME#~#g" | tee -a "$TEMPFILE"
			command ls -1 | egrep '\.plist$' | sed 's#^#      #g' | tee -a "$TEMPFILE"
	fi

done


if [ "$FROM_KEYBOARD_MAESTRO" = "no" ]
then

			# if the script was NOT called from Keyboard Maestro then ask if the user wants the information copied to their pasteboard

		echo -n "\n$NAME: copy information above to the pasteboard (so it can be pasted into an email, etc)? [Y/n] "

		read ANS

		case "$ANS" in
			n*|N*)
					exit 0
			;;

			*)
					pbcopy < $TEMPFILE && echo "$NAME: copied to pasteboard" && exit 0
			;;

		esac

fi


exit
#
#EOF
