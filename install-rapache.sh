#!/bin/bash -
###############################################################################
# File: 			install-rapache.sh
#
# Description:			Script to install & setup R(Apache) on Mac OS 10.6
#
# Prerequisites:		Xcode  (free Xcode3 can be downloaded here: http://bit.ly/xcode3Download)
#				R (Install R-2.13.0.pkg from http://cran.r-project.org/bin/macosx)
#				Ensure you click 'Customize' and select 'R GUI 1.40 (64-bit)'
#				if your machine supports it
#
# Instructions:			run this script as *ROOT*
#
# Todo:				-Ability to install in 32 bit machines
#				-Option to install R from source
#
# Author:			JT
###############################################################################

export EXPECTED_HASH=f66641def8127efd35b76d6e32bfaa13
export ACTUAL_HASH=`MD5 -q /private/etc/apache2/httpd.conf`
export EXPECTED_USER=root
export ACTUAL_USER=`whoami`

#Checking script is being run as root
if [ "$EXPECTED_USER" != "$ACTUAL_USER" ];then
	echo "
		Error: Insufficient privileges
		
		This script needs to be run as root. Simply run:
		sudo ./install-rapache.sh
		"
	exit
fi

#Checking R is installed
if [ ! -s /usr/bin/R64 ]; then
	echo "
		Error: Required software is not installed in your system
		
		R is a prerequisite for installing R(Apache)
		Please install R-2.13.0.pkg from http://cran.r-project.org/bin/macosx and,
		during the setup ensure you click 'Customize' and add the 'R GUI 1.40 (64-bit) option
		if your machine supports it'
		"
	exit
fi

#Checking Xcode is installed
if [ ! -s /Developer ]; then
	echo "
		Error: Required software is not installed in your system
		
		Please install Xcode. 
		Note: Xcode 3 can be downloaded for free here: http://bit.ly/xcode3Download
		"
	exit
fi


#Installing required Apache2 library: libapreq2
cd /tmp
curl -O http://apache.mirrors.timporter.net/httpd/libapreq/libapreq2-2.13.tar.gz
tar xzvf libapreq2-2.13.tar.gz
cd libapreq2-2.13
./configure 
make
sudo make install


#Installing R(Apache)
cd /tmp
curl -O http://rapache.net/files/rapache-1.1.14.tar.gz
tar xzvf rapache-1.1.14.tar.gz
cd rapache-1.1.14
./configure --with-apache2-apxs=/usr/sbin/apxs --with-R=/usr/bin/R64
sudo make
sudo make install


#Editing httpd.conf
if [ "$EXPECTED_HASH" == "$ACTUAL_HASH" ];

then
	cp /private/etc/apache2/httpd.conf /private/etc/apache2/httpd.conf_bk

	sed -i '' -e '118i\
	LoadModule R_module libexec/apache2/mod_R.so' /private/etc/apache2/httpd.conf

	sed -i '' -e '119i\
	ROutputErrors' /private/etc/apache2/httpd.conf
	
else
	echo "
		########################################################################################
		** MANUAL STEP **
		It looks like you have been tinkering with Apache's config, as a result you will have to 
		manually add the two lines below after your last 'LoadModule' entry in your httpd.conf 
		file (/private/etc/apache2/httpd.conf)

		-----COPY STARTS-----
		LoadModule R_module libexec/apache2/mod_R.so
		ROutputErrors
		----- COPY ENDS -----
		
		When you are done bounce Apache:
		sudo apachectl restart

		And check the R(Apache) info page
		http://localhost/RApacheInfo
		########################################################################################"
fi

echo '
# Required for report about R running within Apache
<Location /RApacheInfo>
    SetHandler r-info
</Location>

<Location /r>
    SetHandler r-script
    RHandler sys.source
</Location>' >> /private/etc/apache2/httpd.conf


#Bounce Apache and open demo page if installation was automated
if [ "$EXPECTED_HASH" == "$ACTUAL_HASH" ];
then
	#Restart Apache
	sudo apachectl restart

	#Open Browser with info page
	open http://localhost/RApacheInfo
fi
