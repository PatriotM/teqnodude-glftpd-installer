#!/bin/bash
VER=1.27
#----------------------------------------------------------------#
#								 #
# Section Manager by Teqno     			 		 #
#								 #
# This will simplify the add/remove of sections for people       #
# that finds it too tedious to manually do the work. It checks   #
# for various scripts in /glftpd/bin folder including the script #
# pzs-ng and adds the proper lines. Be sure to put the right     #
# paths for glftpd and pzs-ng before running this script and 	 #
# don't forget to rehash the bot after the script is done. This	 #
# manager is intended for incoming sections only and not archive #
#								 #
# If the script cam't find the file defined in the path below 	 #
# the script will just skip it. 				 #
#			 					 # 
# This script only add/remove sections directly under /site and	 #
# not under any other location.					 #
#								 #
# ALERT!!!!!!!!!! 						 #					
# The script works only with the scripts installed by the	 #
# glftpd-installer created by Teqno. Do NOT attempt to use this  #
# on a system set up by other methods.                           #
#								 #
#--[ Settings ]--------------------------------------------------#

glroot=/glftpd							 # path for glftpd dir
pzsbot=$glroot/sitebot/scripts/pzs-ng/ngBot.conf		 # path for ngBot.conf 
pzsng=$glroot/backup/pzs-ng		 			 # path for pzs-ng
incoming=changeme					 	 # path for incoming device for glftpd

# Leave them empty if you want to disable them
turautonuke=$glroot/bin/tur-autonuke.conf			 # path for tur-autonuke
turspace=$glroot/bin/tur-space.conf				 # path for tur-space
approve=$glroot/bin/approve.sh					 # path for approve
foopre=$glroot/etc/pre.cfg					 # path for foopre 
turlastul=$glroot/bin/tur-lastul.sh				 # path for tur-lastul
psxcimdb=$glroot/etc/psxc-imdb.conf				 # path for psxc-imdb
dated=$glroot/bin/dated.sh					 # path for dated.sh

#--[ Script Start ]----------------------------------------------#

clear

rootdir=`pwd`

function start
{
echo "Already configured sections: "`grep "set sections" $pzsbot | sed 's/REQUEST//g' | cut -d "\"" -f2`
while [[ -z $section ]]
do
    echo -n "What section do you want to manage, if not listed just type it in : "; read section
done
section=${section^^}
echo -n "What do you wanna do with $section ? [A]dd [R]remove, default A : "; read action
echo -n "Is this a dated section ? [Y]es [N]o, default N : "; read day
echo -n "Does it contain zip files ? [Y]es [N]o, default N : "; read zipfiles
echo -n "Is this a movie section ? [Y]es [N]o, default N : " ; read movie

case $action in
    [Rr])
        if [ `grep "set sections" $pzsbot | cut -d "\"" -f2 | sed 's/ /\n/g' | grep "$section$" | wc -l` = "0" ]
        then
	    echo "Section does not exist, please try again."
	    exit 2
	else
	    actionname="Removed the section from"
	    echo -n "Remove folder $section under $glroot/site ? [Y]es [N]o, default N : " ; read remove
	    case $remove in
	        [Yy])
		    echo "Removing $section, please wait..."
		    rm -rf $glroot/site/$section
		    echo "$actionname $glroot/site"
		    ;;
		*)
		    echo "Remember, section folder $section needs to be removed under $glroot/site"
		    ;;
	    esac
	fi
	;;	
    *)
        if [ `grep "set sections" $pzsbot | cut -d "\"" -f2 | sed 's/ /\n/g' | grep "$section$" | wc -l` = "1" ]
        then
    	    echo "Section already exist, please try again."
	    exit 2
	else
    	    actionname="Added the section to"
	    echo -n "Create folder $section under $glroot/site ? [Y]es [N]o, default N : " ; read create
	    case $create in
	        [Yy])
		    echo "$actionname $glroot/site"
		    mkdir -m 777 $glroot/site/$section
		    ;;
		*)
		    echo "Remember, section folder $section needs to be created under $glroot/site"
		    ;;
	    esac
	fi
	;;
esac
}

function turautonuke
{
if [ -f "$turautonuke" ]
then
    case $action in
        [Rr])
	    sed -i "/\/site\/$section$/d" $turautonuke
	    ;;
	*)
	    case $day in
		[Yy])
		    sed -i '/^DIRS/a '"/site/$section/\$today" $turautonuke
		    sed -i '/^DIRS/a '"/site/$section/\$yesterday" $turautonuke
		    ;;
		*)
		    sed -i '/^DIRS/a '"/site/$section" $turautonuke
		    ;;
	    esac
	    ;;
    esac
    echo "$actionname Tur-Autonuke"
else	
    echo "Tur-Autonuker config file not found"
fi
}

function turspace
{
if [ -f "$turspace" ]
then
    case $action in
	[Rr])
	    sed -i "/\/site\/$section:/d" $turspace
	    ;;
	*)
	    case $day in
	        [Yy])
		    sed -i '/^\[INCOMING\]/a '"INC$section=$incoming:$glroot/site/$section:" $turspace
		    ;;
		*)
		    sed -i '/^\[INCOMING\]/a '"INC$section=$incoming:$glroot/site/$section:" $turspace
		    ;;
	    esac
	    ;;
    esac
    echo "$actionname Tur-Space"
else
    echo "Tur-Space config file not found"
fi
}

function pzsng
{
if [ -f "$pzsng/zipscript/conf/zsconfig.h" ]
then
    case $action in
	[Rr])
            sed -i -e "s/\/site\/$section\/%Y-%m-%d\///gI" -e "s/\/site\/$section\///gI" $pzsng/zipscript/conf/zsconfig.h
            sed -i 's/ "$/"/g' $pzsng/zipscript/conf/zsconfig.h
            sed -i 's/" /"/g' $pzsng/zipscript/conf/zsconfig.h
            sed -i '/\//s/\/  \//\/ \//g' $pzsng/zipscript/conf/zsconfig.h
	    ;;
	*)
	    case $day in
	        [Yy])
		    sed -i "/\bcleanupdirs_dated\b/ s/\"$/ \/site\/$section\/%Y-%m-%d\/\"/" $pzsng/zipscript/conf/zsconfig.h    
		    ;;
		*)
		    sed -i "/\bcleanupdirs\b/ s/\"$/ \/site\/$section\/\"/" $pzsng/zipscript/conf/zsconfig.h
		    ;;
	    esac

	    case $zipfiles in
	        [Yy])
		    sed -i "/\bzip_dirs\b/ s/\"$/ \/site\/$section\/\"/" $pzsng/zipscript/conf/zsconfig.h
		    ;;
		*)
		    sed -i "/\bsfv_dirs\b/ s/\"$/ \/site\/$section\/\"/" $pzsng/zipscript/conf/zsconfig.h
		    ;;
	    esac
	    sed -i "/\bcheck_for_missing_nfo_dirs\b/ s/\"$/ \/site\/$section\/\"/" $pzsng/zipscript/conf/zsconfig.h
	    ;;
    esac
    echo
    echo -n "Recompiling PZS-NG for changes to go into effect, please wait..."
    cd $pzsng && make distclean >/dev/null 2>&1 && ./configure -q && make >/dev/null 2>&1 && make install >/dev/null 2>&1 && cd $rootdir
    echo -e "   \e[32mDone\e[0m"
    echo "$actionname PZS-NG"
else 
    echo "PZS-NG config file not found"
fi
}

function pzsbot
{
if [ -f "$pzsbot" ]
then
    case $action in
	[Rr])
	    before=`grep "set sections" $pzsbot | cut -d "\"" -f2`
	    after=`grep "set sections" $pzsbot | cut -d "\"" -f2 | sed 's/ /\n/g' | grep -vw "$section$" | sort | xargs`
	    sed -i "/set sections/s/$before/$after/gI" $pzsbot
	    sed -i "/set paths("$section")/d" $pzsbot
	    sed -i "/set chanlist("$section")/d" $pzsbot
	    ;;
	*)
	    case $day in
                [Yy])
	    	    sed -i '/set paths(REQUEST)/i set paths('"$section"')				"/site/'"$section"'/*/*"' $pzsbot
		    ;;
		*)
	    	    sed -i '/set paths(REQUEST)/i set paths('"$section"')				"/site/'"$section"'/*"' $pzsbot
    	    	    ;;
	    esac
	    sed -i '/set chanlist(REQUEST)/i set chanlist('"$section"')			"$mainchan"' $pzsbot
	    sed -i "/set sections/s/\"$/\ $section\"/g" $pzsbot
	    ;;
    esac
    sed -i '/set sections/s/  / /g' $pzsbot
    sed -i '/set sections/s/ "/"/g' $pzsbot
    sed -i '/set sections/s/" /"/g' $pzsbot
    echo "$actionname PZS-NG bot"
else 
    echo "PZS-NG bot config file not found"
fi
}

function approve
{
if [ -f "$approve" ]
then
    case $action in
        [Rr])
    	    sed -i "/$section$/d" $approve
	    ;;
	*)
	    if [[ ${section^^} != @(0DAY|MP3|FLAC|EBOOKS) ]]
	    then
	    	sed -i '/^SECTIONS="/a '"$section" $approve
	    else
	        sed -i '/^DAYSECTIONS="/a '"$section" $approve
	    fi
	    ;;
    esac
    sections=`sed -n '/^SECTIONS="/,/"/p' $approve | grep -v DAYSECTIONS | grep -v NUMDAYFOLDERS | grep -v SECTIONS | grep -v "\"" | wc -l`
    daysections=`sed -n '/^DAYSECTIONS="/,/"/p' $approve | grep -v DAYSECTIONS | grep -v NUMDAYFOLDERS | grep -v SECTIONS | grep -v "\"" | wc -l`
    current=`grep -i ^numfolders= $approve | cut -d "\"" -f2`
    ncurrent=`grep -i ^numdayfolders= $approve | cut -d "\"" -f2`
    sed -i -e "s/^NUMFOLDERS=\".*\"/NUMFOLDERS=\"$sections\"/" $approve
    sed -i -e "s/^NUMDAYFOLDERS=\".*\"/NUMDAYFOLDERS=\"$daysections\"/" $approve
    echo "$actionname Approve"
else
    echo "Approve config file not found"
fi
}

function eur0pre
{
if [[ -f "$foopre" ]]
then
    case $action in
	[Rr])
            before=`grep "allow=" $foopre | cut -d "=" -f2 | cut -d "'" -f1 | uniq`
            after=`grep "allow=" $foopre | cut -d "=" -f2 | uniq | sed 's/|/\n/g' | sort | grep -vw "$section$" | xargs | sed 's/ /|/g'`
	    sed -i "/allow=/s/$before/$after/g" $foopre
	    sed -i "/section.$section\./d" $foopre
	    ;;
	*)
	    sed -i "s/.allow=/.allow=$section\|/" $foopre
	    if [[ ${section^^} != @(0DAY|MP3|FLAC|EBOOKS) ]]
	    then
	        echo "section.$section.name=$section" >> $foopre
		echo "section.$section.dir=/site/$section" >> $foopre
		echo "section.$section.gl_credit_section=0" >> $foopre
		echo "section.$section.gl_stat_section=0" >> $foopre
	    else
	        echo "section.$section.name=$section" >> $foopre
	    	echo "section.$section.dir=/site/$section/YYYY-MM-DD" >> $foopre
		echo "section.$section.gl_credit_section=0" >> $foopre
		echo "section.$section.gl_stat_section=0" >> $foopre		    
	    fi
	    ;;
    esac
    sed -i "/allow=/s/=|/=/" $foopre
    sed -i "/allow=/s/||/|/" $foopre
    sed -i "/allow=/s/|$//" $foopre
    echo "$actionname foo-pre"
else
    echo "foopre config file not found"
fi

}

function turlastul
{
if [ -f "$turlastul" ]
then
    case $action in
	[Rr])
            before=`grep "sections=" $turlastul | cut -d "=" -f2 | tr -d "\""`
            after=`grep "sections=" $turlastul | cut -d "=" -f2  | tr -d "\"" | sed 's/ /\n/g' | sort | grep -vw "$section$" | xargs`
            sed -i "/sections=/s/$before/$after/g" $turlastul
	    ;;
	*)
	    sed -i "s/^sections=\"/sections=\"$section /" $turlastul
	    ;;
    esac
    sed -i '/^sections=/s/  / /g' $turlastul
    sed -i '/^sections=/s/" /"/g' $turlastul
    sed -i '/^sections=/s/ "/"/g' $turlastul
    echo "$actionname Tur-Lastul"
else
    echo "Tur-Lastul config file not found"
fi
}

function psxcimdb
{
if [ -f "$psxcimdb" ]
then
    case $movie in
	[Yy])
	    case $action in
	        [Rr])
		    sed -i "/^SCANDIRS/ s/\/site\/\b$section\b//" $psxcimdb
		    ;;
		*)
	    	    sed -i "s/^SCANDIRS=\"/SCANDIRS=\"\/site\/$section /" $psxcimdb
		    ;;
	    esac
	    sed -i '/^SCANDIRS=/s/  / /g' $psxcimdb
	    sed -i '/^SCANDIRS=/s/" /"/g' $psxcimdb
	    sed -i '/^SCANDIRS=/s/ "/"/g' $psxcimdb
	    echo "$actionname PSXC-IMDB"
	    ;;
    esac
else
    echo "PSXC-IMDB config file not found"
fi
}

function dated
{
if [ -f "$dated" ]
then
    case $day in
	[Yy])
	    case $action in
		[Rr])
            	    sed -i "/$section/d" $dated
		    ;;
		*)
		    sed -i '/^sections="/a '"$section" $dated
		    ;;
	    esac
	    echo "$actionname dated.sh"
	    ;;
    esac
else
    echo "dated.sh file not found"
fi
}

start
pzsng
pzsbot
turautonuke
turspace
approve
eur0pre
turlastul
psxcimdb
dated
echo
case $action in
    [Rr])
        [ -f "$glroot/bin/tur-rules.sh" ] && echo -e "\e[31mBe sure to remove rules for section $section in $glroot/bin/tur-rules.sh and $glroot/ftp-data/misc/site.rules\e[0m"
        ;;
    *)
        [ -f "$glroot/bin/tur-rules.sh" ] && echo -e "\e[31mBe sure to add rules for section $section in $glroot/bin/tur-rules.sh and $glroot/ftp-data/misc/site.rules\e[0m"
        ;;
esac
echo
echo -e "\e[31mPlease rehash the bot or the updated settings will not take effect\e[0m"
echo


[ `ls /glftpd/site | egrep -iv "today" | egrep -i "0DAY|EBOOKS|FLAC|MP3|XXX-PAYSITE" | wc -l` = 0 ] && sed -i /dated.sh/d /var/spool/cron/crontabs/root
if [ `ls /glftpd/site | egrep -iv "today" | egrep -i "0DAY|EBOOKS|FLAC|MP3|XXX-PAYSITE" | wc -l` -ge 1 ]
then
    [ `grep "dated.sh" /var/spool/cron/crontabs/root | wc -l` = 0 ] && echo "0 0 * * *               $glroot/bin/dated.sh >/dev/null 2>&1" >> /var/spool/cron/crontabs/root
fi

exit 0
