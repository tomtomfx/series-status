#!/bin/bash

# Write deploy usage
displayHelp()
{
    echo ""
	echo "Usage: deploy.sh -d targetDirectory [-h]"
	echo "-d \"targetDirectory\" 	Defines the directory where the files will be installed"
	echo "-u \"user\"				User that will be used to launch the system"
	echo "-h			Displays this message"
	echo ""
}

if [ $# -eq 0 ];
then 
	displayHelp
	exit 1
fi

# Retrieve input parameters
while getopts hd:u: option
do
	case "${option}"
	in
		d) targetDir=${OPTARG};;
		u) user=${OPTARG};;
		h)	displayHelp
			exit 1;;
		\?)
			displayHelp
			exit 1;;
	esac
done

###########################################################
# Perl scripts and config management

# Create destination folder
echo "Install directory will be ${targetDir}"
mkdir -p ${targetDir}
mkdir -p ${targetDir}/logs
echo "$targetDir created ==> success"
# Copy all files to the target directory
echo -n "Copy all files and directory to ${targetDir}"
cp -R ./bin/ "${targetDir}/."
cp -R ./lib/ "${targetDir}/."
mkdir -p ${targetDir}/logs
# Change the files to executable and propoerty of the user
chmod ug+x ${targetDir}/bin/*.pl
echo " ==> success"
echo "Change config file location in each script"
for file in ${targetDir}/bin/*.pl; do
	echo -n ${file}
	escapedTargetDir=${targetDir//\//\\\\\\\/}
	sed -i "s:scriptsDir:${escapedTargetDir}:g" "$file"
	echo " ==> OK"
done
# Config management
# Copy config to bin folder
if [ -e "${targetDir}/bin/config" ]
then
	echo -n "Config already exists, not copied"
else
	echo -n "Copy config to ${targetDir}/bin and update file location"
	cp config "${targetDir}/bin/."
fi
# Change scripts directory by target directory
sed -i "s:scriptsDir:${targetDir}:g" "${targetDir}/bin/config"
chmod ugo+rw ${targetDir}/bin/config
echo " ==> success"

# Change user to the requested user
chown -R $user:$user ${targetDir}

###########################################################
# Copy files for website
echo "Copy website files to local path (/var/www)"
# Create directory if does not exist
if [ ! -d "/var/www" ]; then
	mkdir -p "/var/www"
fi
# Copy php files to directory
cp www/*.php /var/www/.
cp www/*.css /var/www/.
cp -R www/series /var/www/.
cp -R www/photos /var/www/.
cp -R www/home /var/www/.
cp -R www/images /var/www/.

# Copy website options config if does not exists
if [ -e "/var/www/configWeb" ]
then
	echo -n "Website options config already exists, not copied"
else
	echo -n "Copying website options config to /var/www/."
	cp www/configWeb "/var/www/."
fi

# Copy CGI files
cp -R cgi-bin /var/www/.
cp lib/betaSeries.pm /var/www/cgi-bin/.
for file in /var/www/cgi-bin/*.cgi; do
	echo -n ${file}
	escapedTargetDir=${targetDir//\//\\\\\\\/}
	sed -i "s:scriptsDir:${escapedTargetDir}:g" "$file"
	echo " ==> OK"
done

# Change owner and rights
chown -R www-data:www-data /var/www
chmod ug+rw /var/www/series/*.php
chmod ug+rw /var/www/photos/*.php
chmod ug+rw /var/www/home/*.php
chmod ug+rwx /var/www/cgi-bin/*.cgi
chmod -R ug+rw /var/www/images/

###########################################################
# Update cron jobs for specified user
echo "Update cron jobs"
crontab -u ${user} -l > cron.tmp
grep 'getUnseen.pl' cron.tmp || echo "0 8,10,16 * * * perl ${targetDir}/bin/getUnseen.pl >> /opt/shows/logs/cron.log 2>&1" >> cron.tmp
grep 'dl_Move.pl' cron.tmp || echo "30 7,9,12,15,18 * * * perl ${targetDir}/bin/dl_Move.pl >> /opt/shows/logs/cron.log 2>&1" >> cron.tmp
grep 'removeDownloads.pl' cron.tmp || echo "15,35,55 * * * * perl ${targetDir}/bin/removeDownloads.pl >> /opt/shows/logs/cron.log 2>&1" >> cron.tmp
grep 'seriesStatus.pl' cron.tmp || echo "0 19 * * * perl ${targetDir}/bin/seriesStatus.pl 1 >> /opt/shows/logs/cron.log 2>&1" >> cron.tmp
grep '*.log' cron.tmp || echo "0 3 * * 0 rm ${targetDir}/logs/*.log" >> cron.tmp
grep 'tabletManager.pl' cron.tmp || echo "4 * * * * perl ${targetDir}/bin/tabletManager.pl >> /opt/shows/logs/cron.log 2>&1" >> cron.tmp
crontab -u ${user} cron.tmp
rm cron.tmp
systemctl restart cron
echo "Crontab update ==> success"

exit 0