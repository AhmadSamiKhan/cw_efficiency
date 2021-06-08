#!/bin/bash

#------AUTHOR: Ahmad Sami------#

clear

#------variables used------#
S="================================================"
D="------------------------------------------------"

HOME="/home/master"
DATE=$(date "+%Y-%m-%d %H:%M:")
mkdir -p $HOME/tmp_cw_scanner
FLAG_FILE=$HOME/tmp_cw_scanner/flag_file_autogenerated
FLAG_FILE_Wp_rocket=$HOME/tmp_cw_scanner/flag_file_autogenerated_wpr



green='\e[32m'
yel='\e[4;33m'
cya='\e[1;36m'
blue='\e[34m'
pur='\e[1;35m'
clear='\e[0m'
GCOLOR="\e[92m ------ OK/HEALTHY \e[0m"
WCOLOR="\e[93m ------ WARNING \e[0m"
CCOLOR="\e[91m ------ CRITICAL \e[0m"
GPCOLOR="\e[92m ------ PERFECT \e[0m"
WCOLOR="\e[93m ------ WARNING \e[0m"
CCOLOR="\e[91m ------ CRITICAL \e[0m"
EndCOLOR="\e[0m"
BIGre='\e[1;92m';
BIRed='\e[1;91m';
BBlu='\e[1;34m';
BCya='\e[1;36m';
red=$'\e[1;31m'
yel=$'\e[1;33m'


file_domain=file-DOMAINNAME
read -r -p $'\e[0;32m1- Enter the Website Domain name\e[0m: '  RAW_DOMAINNAME
URL_DOMAIN=$(curl -Ls -k -o /dev/null -w %{url_effective} $RAW_DOMAINNAME)
#DOMAINNAME=http://minhalas.com
DOMAINNAME=$(echo "$RAW_DOMAINNAME" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
TTFB_APP_RAWDOMAINNAME=$RAW_DOMAINNAME/cw_phpinfo.php
#echo -e "\n"
#echo -e "\n"



APP_NAME=$(grep -lr $DOMAINNAME /home/master/applications/*/conf/server.nginx)

APP_NAME=$(basename $(dirname $(dirname $APP_NAME)))

APP_TYPE=$(awk '{sub(/-.*/, ""); print}' $HOME/applications/$APP_NAME/conf/server.nginx | grep -v "Domain_alias" | sed -r '/^\s*$/d' | cut -f 3 -d ' ' | head -n1)

[ -z "$APP_TYPE" ] && APP_TYPE=$(awk '{sub(/-.*/, ""); print}' $HOME/applications/$APP_NAME/conf/server.nginx | grep -v "Domain_alias" | sed -r '/^\s*$/d' | cut -f 6 -d ' ')

if [[ ! $APP_TYPE =~ ^(wordpress|woocommerce|wordpressmu)$ ]]; then
  echo "app is not WP type."
  exit 1;
fi
HOMEDIR=$HOME/applications/$APP_NAME/public_html/
#echo $APP_TYPE
#echo $APP_NAME

##############################################################--STARTING FUNCTIONS Declaration--##################################################################################################

ColorGreen(){
        echo -ne $green$1$clear
}
ColorBlue(){
        echo -ne $blue$1$clear
}
ColorYellow(){
        echo -ne $yel$1$clear
}
ColorCyan(){
        echo -ne $cya$1$clear
}
ColorPurp(){
        echo -ne $pur$1$clear
}


TTFB_APP () {


    TTFB_APP_VALUE=$(curl -so /dev/null -w "\n%{time_total} \n" "$1")

    TTFB_APP_VALUE=$(echo "scale=4; $TTFB_APP_VALUE*1000" | bc)
     echo -e "( 0-300ms = PERFECT,  301ms-600ms= WARNING,  601ms-so on = CRITICAL )"
     echo -e "$D-----------------"
     COLC1=$(echo "$TTFB_APP_VALUE" | tr -d '%')
     COLC2=$(echo "$COLC1" | printf "%.0f" "$COLC1")

    for i in $(echo "$COLC2"); do
        {
            if [[ $i = *[[:digit:]]* ]]; then
            {
            if [ $i -ge 601 ]; then
            COLC3="$(echo -e APP_TTFB: $i"ms $CCOLOR\n$COLC3")"
            elif [[ $i -ge 301 && $i -lt 600 ]]; then
                COLC3="$(echo -e APP_TTFB: $i"ms $WCOLOR\n$COLC3")"
            else
                COLC3="$(echo -e APP_TTFB: $i"ms $GPCOLOR\n$COLC3")"
            fi
            }
            else
                COLC3="$(echo -e $i"% (Free CPU Percentage details not available)\n$COLC3")"
            fi
        }
    done
     COLC3=$(echo "$COLC3"|sort -k1n)
     echo -e "\nTTFB OF APPLICATION :\n"
     paste  <(echo "$COLC3") -d' '|column -t



}

APP_STATS () {

    for OUTPUT in $(ls -la /home/master/applications/ | awk '{if(NR>3)print}' | awk '{print $NF}')
    do
    ###### SETUP ############
    LOG_FOLDER=/home/master/applications/$OUTPUT/logs
    ACCESS_LOG=$LOG_FOLDER/apache_*.access.log
    HOW_MANY_ROWS=20000
    ######### FUNCTIONS ##############
    function appname() {
        echo -e "
##################################
    "$BIGre $OUTPUT $EndCOLOR"
##################################
    "
    }
    function title() {
        echo "
---------------------------------
    $*
---------------------------------
    "
    }
    function urls_by_ip() {
        local IP=$1
        tail -5000 $ACCESS_LOG | awk -v ip=$IP ' $1 ~ ip {freq[$7]++} END {for (x in freq) {print freq[x], x}}' | sort -rn | head -5
    }
    function ip_addresses_by_user_agent(){
        local USERAGENT_STRING="$1"
        local TOP_20_IPS="`tail  -$HOW_MANY_ROWS $ACCESS_LOG | grep "${USERAGENT_STRING}"  | awk '{freq[$1]++} END {for (x in freq) {print freq[x], x}}' | sort -rn | head -5`"
        echo "$TOP_20_IPS"
    }
    ####### RUN REPORTS #############
    appname
    title "top 5 URLs"
    TOP_20_URLS="`tail -$HOW_MANY_ROWS $ACCESS_LOG | awk '{freq[$7]++} END {for (x in freq) {print freq[x], x}}' | sort -rn | head -5`"
    echo "$TOP_20_URLS"
    title "top 5 URLS excluding POST data"
    TOP_20_URLS_WITHOUT_POST="`tail  -$HOW_MANY_ROWS $ACCESS_LOG | awk -F"[ ?]" '{freq[$7]++} END {for (x in freq) {print freq[x], x}}' | sort -rn | head -5`"
    echo "$TOP_20_URLS_WITHOUT_POST"
    title "top 5 IPs"
    TOP_20_IPS="`tail  -$HOW_MANY_ROWS $ACCESS_LOG | awk '{freq[$1]++} END {for (x in freq) {print freq[x], x}}' | sort -rn | head -5`"
    echo "$TOP_20_IPS"
    title "top 5 user agents"
    TOP_20_USER_AGENTS="`tail  -$HOW_MANY_ROWS $ACCESS_LOG | cut -d\  -f12- | sort | uniq -c | sort -rn | head -5`"
    echo "$TOP_20_USER_AGENTS"
    done


}

CACHE() {

    CACHE=$(curl -sv -k $URL_DOMAIN   -H 'authority: $DOMAINNAME'   -H 'upgrade-insecure-requests: 1'   -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36'   -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9'   -H 'sec-fetch-site: none'   -H 'sec-fetch-mode: navigate'   -H 'sec-fetch-dest: document'   -H 'accept-language: en-US,en;q=0.9'  --compressed 2>&1 > /dev/null | egrep -i '< (X-Cache|x-magento-cache-debug)' | cut -d':' -f2 | cut -f 2 -d ' ' | sed -e 's/\r//g')


case $APP_TYPE in

wordpress|wordpressmu|woocommerce)

        case $CACHE in
        HIT)
                echo -e "CACHE STATUS:$BIGre  ------  Varnish is CACHING $EndCOLOR"

        ;;
        MISS)
                echo -e "CACHE STATUS:$BIRed  ------  Varnish is not CACHING $EndCOLOR"
        ;;
             *) echo -e "CACHE STATUS:$BIRed  ------  Varnish is not Enabled, Please check under app settings or managed services tab $EndCOLOR"
        ;;
        esac
;;


magento)

        MAG_VERSION=$(php $HOME/applications/$APP_NAME/public_html/bin/magento --version | cut -f 3 -d ' ' | cut -d'.' -f1)

        case $MAG_VERSION in
        2)

             case $CACHE in
                HIT)
                    echo -e "CACHE STATUS:$BIGre  ------ Varnish is CACHING $EndCOLOR"

                ;;
                MISS)
                echo -e "CACHE STATUS:$BIRed  ------   Varnish is not CACHING $EndCOLOR"
                ;;
                *) echo -e "CACHE STATUS:$BIRed  ------   Varnish is not Enabled, Please check under app settings or managed services tab $EndCOLOR"
                ;;
            esac
        ;;
        *) echo -e "CACHE STATUS:$BIRed  ------   Varnish is not supported for Magento-1. Use Cloudways FPC please $EndCOLOR"
        ;;
        esac

;;



*) echo -e "CACHE STATUS:$BIRed  ------   Varnish is not supported for this application. Please check https://support.cloudways.com/most-common-varnish-issues-and-queries/ $EndCOLOR"
;;

esac
}


displaySpinner()
{
  local pid=$!
  local delay=0.3
  local spinstr='|/-\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
      local temp=${spinstr#?}
      printf "${COLOR_RESET}${COLOR_CYAN}Please wait... [ %c ]  " "$spinstr${COLOR_RESET}" # Count number of backspaces needed (A = 25)
      local spinstr=$temp${spinstr%"$temp"}
      sleep $delay
      printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b" # Number of backspaces from (A)
  done
  printf "\n" # Number of spaces, then backspaces from (A)
  
}

TTFB_SERVER () {

    rm $HOME/applications/$APP_NAME/public_html/cw_phpinfo.php

    touch $HOME/applications/$APP_NAME/public_html/cw_phpinfo.php

    cat <<EOT >> $HOME/applications/$APP_NAME/public_html/cw_phpinfo.php
        <?php
        phpinfo();
        ?>
EOT
    TTFB_SERVER_VALUE=$(curl -so /dev/null -w "\n%{time_total} \n" "$1")

    TTFB_SERVER_VALUE=$(echo "scale=4; $TTFB_SERVER_VALUE*1000" | bc)

     COLC4=$(echo "$TTFB_SERVER_VALUE" | tr -d '%')
     COLC5=$(echo "$COLC4" | printf "%.0f" "$COLC4")

    for i in $(echo "$COLC5"); do
        {
            if [[ $i = *[[:digit:]]* ]]; then
            {
            if [ $i -ge 601 ]; then
            COLC6="$(echo -e SERVER_TTFB: $i"ms $CCOLOR\n$COLC6")"
            elif [[ $i -ge 301 && $i -lt 600 ]]; then
                COLC6="$(echo -e SERVER_TTFB: $i"ms $WCOLOR\n$COLC6")"
            else
                COLC6="$(echo -e SERVER_TTFB: $i"ms $GPCOLOR\n$COLC6")"
            fi
            }
            else
                COLC6="$(echo -e $i"% (Free CPU Percentage details not available)\n$COLC6")"
            fi
        }
    done
     COLC6=$(echo "$COLC6"|sort -k1n)
     echo -e "\nTTFB OF SERVER :\n"
     paste  <(echo "$COLC6") -d' '|column -t

    }

TTFB_VALUE () {

TTFB_APP $RAW_DOMAINNAME
TTFB_SERVER $TTFB_APP_RAWDOMAINNAME

}

HTTPS_CHECK () {

    wget $DOMAINNAME -O /dev/null 2>&1 | grep -E "Location:|HSTS" | tail -n1 > $file_domain



    if grep -q "https:" $file_domain
        then
    echo -e "HTTPS-ENABLED: $GCOLOR"
        elif
    grep -q "HSTS" $file_domain
        then
    echo -e "HTTPS-ENABLED: $GCOLOR"
        else
    echo -e "HTTPS-ENABLED: $RCOLOR"
    fi
}

MySQL_DUMP  () {

    BREAK_LINE
    mkdir -p /home/master/database_dump
    cd $HOMEDIR && wp db export - | gzip > /home/master/database_dump/$APP_NAME-db_backup-$(date +%Y-%m-%d-%H%M%S).sql.gz
    echo "Dump Complete"
    BREAK_LINE

}



STATUS_CODE () {

    #------Status code check start------#

    code=$(curl -skLo /dev/null -w "%{http_code}"  $URL_DOMAIN)

    case $code in
     000) status="Not responding " ;;
     100) status="Informational: Continue" ;;
     101) status="Informational: Switching Protocols" ;;
     200) status="Successful: OK " ;;
     201) status="Successful: Created" ;;
     202) status="Successful: Accepted" ;;
     203) status="Successful: Non-Authoritative Information" ;;
     204) status="Successful: No Content" ;;
     205) status="Successful: Reset Content" ;;
     206) status="Successful: Partial Content" ;;
     300) status="Redirection: Multiple Choices" ;;
     301) status="Redirection: Moved Permanently" ;;
     302) status="Redirection: Found residing temporarily under different URI" ;;
     303) status="Redirection: See Other" ;;
     304) status="Redirection: Not Modified" ;;
     305) status="Redirection: Use Proxy" ;;
     306) status="Redirection: status not defined" ;;
     307) status="Redirection: Temporary Redirect" ;;
     400) status="Client Error: Bad Request" ;;
     401) status="Client Error: Unauthorized" ;;
     402) status="Client Error: Payment Required" ;;
     403) status="Client Error: Forbidden" ;;
     404) status="Client Error: Not Found" ;;
     405) status="Client Error: Method Not Allowed" ;;
     406) status="Client Error: Not Acceptable" ;;
     407) status="Client Error: Proxy Authentication Required" ;;
     408) status="Client Error: Request Timeout " ;;
     409) status="Client Error: Conflict" ;;
     410) status="Client Error: Gone" ;;
     411) status="Client Error: Length Required" ;;
     412) status="Client Error: Precondition Failed" ;;
     413) status="Client Error: Request Entity Too Large" ;;
     414) status="Client Error: Request-URI Too Long" ;;
     415) status="Client Error: Unsupported Media Type" ;;
     416) status="Client Error: Requested Range Not Satisfiable" ;;
     417) status="Client Error: Expectation Failed" ;;
     500) status="Server Error: Internal Server Error" ;;
     501) status="Server Error: Not Implemented" ;;
     502) status="Server Error: Bad Gateway" ;;
     503) status="Server Error: Service Unavailable" ;;
     504) status="Server Error: Gateway Timeout " ;;
     505) status="Server Error: HTTP Version Not Supported" ;;
     *)   echo -n "unknown" ;;
    esac

    if [ "$code" != "200" ]; then
               echo -e "STATUS_CODE: $BIRed  ------ $code $status$EndCOLOR"
            else
               echo -e "STATUS_CODE: $BIGre  ------ $code $status$EndCOLOR"
    fi

    #------Status code check end------#
}

MAIN_HEADING () {

    echo -e "\t${1} ${2}"
}

SUB_HEADING () {

    echo -e "$BCya${1} $EndCOLOR"

}

TAG_HEADING () {

        echo -e "$BIRed${1} $EndCOLOR"

}

BREAK_LINE () {

    echo ""
}

STAR_BREAK_LONG () {

    echo -e "$BBlu${S}${S} $EndCOLOR"
}

DASH_BREAK_LONG () {

    echo $D$D
}

STAR_BREAK_SHORT () {

    echo $S
}

DASH_BREAK_SHORT () {

    echo $D
}


CPU_USAGE () {
    BREAK_LINE
    CPU_USAGE=$(top -b -n2 -p 1 | fgrep "Cpu(s)" | tail -1 | awk -F'id,' -v prefix="$prefix" '{ split($1, vs, ","); v=vs[length(vs)]; sub("%", "", v); printf "%s%.1f%%\n", prefix, 100 - v }')


     echo -e "( 0-80% = OK/HEALTHY,  80-90% = WARNING,  90-100% = CRITICAL )"
     echo -e "$D-----------------"
     COLC1=$(echo "$CPU_USAGE" | tr -d '%')
     COLC2=$(echo "$COLC1" | printf "%.0f" "$COLC1")
    for i in $(echo "$COLC2"); do
        {
            if [[ $i = *[[:digit:]]* ]]; then
            {
            if [ $i -ge 90 ]; then
            COLC3="$(echo -e $i"% $CCOLOR\n$COLC3")"
            elif [[ $i -ge 80 && $i -lt 90 ]]; then
                COLC3="$(echo -e $i"% $WCOLOR\n$COLC3")"
            else
                COLC3="$(echo -e $i"% $GCOLOR\n$COLC3")"
            fi
            }
            else
                COLC3="$(echo -e $i"% (Free CPU Percentage details not available)\n$COLC3")"
            fi
        }
    done
     COLC3=$(echo "$COLC3"|sort -k1n)
     echo -e "\nCurrent CPU Utilization % :\n"
     paste  <(echo "$COLC2") <(echo "$COLC3") -d' '|column -t
     BREAK_LINE
}


WP_DOCTOR () {

    BREAK_LINE
    SALT_HANDELING_DEL

    if  [[ ! -f "$FLAG_FILE" ]]; then
                echo "Installing Wp-DOCTOR"
                wp package install wp-cli/doctor-command >> install_wpdoctor
                touch $FLAG_FILE
    fi
    
    cd $HOMEDIR && BREAK_LINE && wp doctor check  autoload-options-size cron-duplicates cron-count plugin-deactivated --skip-plugins --skip-themes --spotlight 
    BREAK_LINE
    SALT_HANDELING_ADD

}


DB_OPTIMIZATION () {

    BREAK_LINE

    read -p "Would you like to take DB DUMP? [yn]" answer
        if [[ $answer = y ]] ; then
                MySQL_DUMP & displaySpinner
        fi


    echo "DB Optimizations"
            cd $HOMEDIR && wp plugin is-installed wp-sweep

            if [ $? = "1" ]; then

                STAR_BREAK_SHORT
                SALT_HANDELING_DEL
                cd $HOMEDIR

                wp plugin deactivate wp-sweep  --quiet
                wp plugin uninstall wp-sweep  --quiet
                wp plugin install wp-sweep  --quiet
                wp plugin activate wp-sweep --quiet
                wp sweep spam_comments deleted_comments unused_terms optimize_database duplicated_postmeta duplicated_commentmeta duplicated_usermeta  duplicated_termmeta transient_options orphan_postmeta orphan_commentmeta orphan_usermeta orphan_termmeta orphan_term_relationships
                wp plugin deactivate wp-sweep --quiet
                wp plugin uninstall wp-sweep --quiet
                STAR_BREAK_SHORT
                BREAK_LINE
            else
                STAR_BREAK_SHORT
                wp plugin activate wp-sweep --quiet
                wp sweep spam_comments deleted_comments unused_terms optimize_database duplicated_postmeta duplicated_commentmeta duplicated_usermeta  duplicated_termmeta transient_options orphan_postmeta orphan_commentmeta orphan_usermeta orphan_termmeta orphan_term_relationships
                STAR_BREAK_SHORT
                BREAK_LINE
            fi

            echo $S
echo $D
echo $DATE
echo "Custom-Count Before cleaning"
echo $D

wp db query "Select count(*) from ${dbprefix}actionscheduler_actions"
wp db query "Select count(*) from ${dbprefix}options"
wp db query "Select count(*) from ${dbprefix}toret_fio_log"
wp db query "Select count(*) from ${dbprefix}actionscheduler_logs"


wp db query "DELETE FROM ${dbprefix}actionscheduler_actions WHERE status='failed'"
wp db query "DELETE FROM ${dbprefix}actionscheduler_actions WHERE status='complete'"
wp db query "DELETE FROM ${dbprefix}actionscheduler_actions WHERE status='canceled'"
wp db query "DELETE FROM ${dbprefix}options WHERE option_name LIKE 'fio_%'"
wp db query "DELETE FROM ${dbprefix}toret_fio_log WHERE datetime < DATE_SUB(NOW(), INTERVAL 12 HOUR)"
wp db query "DELETE FROM ${dbprefix}actionscheduler_logs WHERE log_date_gmt < DATE_SUB(NOW(), INTERVAL 12 HOUR)"

echo ""
echo $D
echo $DATE
echo "Custom-Count After cleaning"
echo $D

wp db query "Select count(*) from ${dbprefix}actionscheduler_actions"
wp db query "Select count(*) from ${dbprefix}options"
wp db query "Select count(*) from ${dbprefix}toret_fio_log"
wp db query "Select count(*) from ${dbprefix}actionscheduler_logs"

            SALT_HANDELING_ADD




}

SALT_HANDELING_DEL () {

    cd $HOME/applications/$APP_NAME/public_html

    if grep -q "wp-salt.php" "$HOME"/applications/"$APP_NAME"/public_html/wp-config.php; then
    
        sed -i "/wp-salt.php/d' " "$HOME"/applications/"$APP_NAME"/public_html/wp-config.php

fi


}

SALT_HANDELING_ADD () {

    cd $HOME/applications/$APP_NAME/public_html

    if ! grep -q "wp-salt.php" $HOME/applications/$APP_NAME/public_html/wp-config.php; then
    
        sed -i "/table_prefix/a require('wp-salt.php');" $HOME/applications/$APP_NAME/public_html/wp-config.php

    fi

}


IMAGE_OPTIMIZATION () {

            BREAK_LINE
            echo "Image compression"
            cd $HOMEDIR/wp-content/uploads/
            nice -n 19 find . -iname '*.jpg' -print0 | xargs -0 jpegoptim --max=82 --all-progressive --strip-all --preserve --totals --force
            nice -n 19 find . -iname '*.jpeg' -print0 | xargs -0 jpegoptim --max=82 --all-progressive --strip-all --preserve --totals --force
            nice -n 19 find . -iname '*.png' -print0 | xargs -0 optipng -o7 -preserve
            BREAK_LINE
}

CACHE_CONFIGURATION () {
                BREAK_LINE

                    read -p "Would you like to take DB DUMP? [yn]" answer
                        if [[ $answer = y ]] ; then
                            MySQL_DUMP & displaySpinner
                    fi

                if [[ $APP_TYPE == "wordpress" ||  $APP_TYPE == "wordpressmu" || $APP_TYPE == "woocommerce" ]]; then

                if  [[ -f "$HOME/applications/$APP_NAME/public_html/wp-content/advanced-cache.php" ]]; then

                    if grep -q "breeze"  $HOME/applications/$APP_NAME/public_html/wp-content/advanced-cache.php

                    then
                        CACHE_PLUGIN=Breeze
                        echo $CACHE_PLUGIN
                    elif
                        grep -q "w3-total-cache"  $HOME/applications/$APP_NAME/public_html/wp-content/advanced-cache.php
                    then
                        CACHE_PLUGIN=w3-total-cache

                        wget https://raw.githubusercontent.com/platformops-cw/cw-automation-scripts/main/cw-w3-tc.json
                        wp w3-total-cache import cw-w3-tc.json

            elif grep -q "wp-rocket"  $HOME/applications/$APP_NAME/public_html/wp-content/advanced-cache.php
                then
                    if  [[ ! -f "$FLAG_FILE_Wp_rocket" ]]; then
                    echo "Installing Wp-ROCKET-cli"
                    wp package install wp-media/wp-rocket-cli
                    touch $FLAG_FILE_Wp_rocket
                    fi

                    CACHE_PLUGIN=wp-rocket
                    wp rocket export
                    wget https://raw.githubusercontent.com/platformops-cw/cw-automation-scripts/main/cw-wp-rocket.json
                    wp rocket import --file=cw-wp-rocket.json

                else

                    echo -e "WP CACHE PLUGIN:$BIGre  ------ Different Cache plugin is being used, Plesae check /wp-content/advanced-cache.php file to know the name of the plugin and review the settings from it's KB or install Breeze on it. $EndCOLOR"

            fi
                else

                    echo -e "WP CACHE PLUGIN:$BIRed  ------ No Cache plugin is being used. Please take a help from senior $EndCOLOR"
            fi

                else

                    echo -e "WP CACHE PLUGIN:$BIRed  ------ It isn't a WP family $EndCOLOR"

            fi
            BREAK_LINE
}


CRON_COUNT () {

            BREAK_LINE

    read -p "Would you like to take DB DUMP? [yn]" answer
        if [[ $answer = y ]] ; then
                MySQL_DUMP & displaySpinner
        fi

            cd $HOMEDIR
            dbprefix=$(cat wp-config.php | grep "\$table_prefix" | cut -d \' -f 2)
            SALT_HANDELING_DEL
            wp db query "UPDATE ${dbprefix}options SET option_value = '' WHERE option_name = 'cron'"
            echo "Cron Count has been reduced"
            SALT_HANDELING_ADD
            BREAK_LINE
}

AUTOLOAD () {

      read -p "Would you like to take DB DUMP? [yn]" answer
        if [[ $answer = y ]] ; then
                MySQL_DUMP & displaySpinner
        fi

  cd $HOME/applications/$APP_NAME/public_html/

  dbprefix=$(cat wp-config.php | grep "\$table_prefix" | cut -d \' -f 2)
  SALT_HANDELING_DEL

  wp db query "SELECT option_name, length(option_value) AS option_value_length FROM ${dbprefix}options WHERE autoload='yes' ORDER BY option_value_length DESC LIMIT 10" --skip-column-names --skip-plugins --skip-themes --quiet > /home/master/autoloaded_data


        awk '{print $1;}' /home/master/autoloaded_data > /home/master/autoloaded_data_final

  for A in $(cat /home/master/autoloaded_data_final); do

  cd $HOME/applications/$APP_NAME/public_html/wp-content/plugins
  output_plugins=$(grep -lr $A)

  cd $HOME/applications/$APP_NAME/public_html/wp-content/themes
  output_themes=$(grep -lr $A)

   if [[ -z "$output_plugins" || -z "output_themes" ]] ; then

   wp db query "DELETE FROM ${dbprefix}options WHERE autoload = 'yes' AND option_name LIKE '%${A}%'" --skip-column-names --skip-plugins --skip-themes --quiet;
   echo "Number: $A"
   fi

done
    SALT_HANDELING_ADD
}



DB_ENGINE () {

        read -p "Would you like to take DB DUMP? [yn]" answer
        if [[ $answer = y ]] ; then
                MySQL_DUMP & displaySpinner
        fi

    cd $HOME/applications/$APP_NAME/public_html/
    SALT_HANDELING_DEL
  # create array of MyISAM tables
    WPTABLES=($(wp db query "SHOW TABLE STATUS WHERE Engine = 'MyISAM'" --allow-root --silent --skip-column-names | awk '{ print $1}'))

# loop through array and alter tables
    for WPTABLE in ${WPTABLES[@]}
do
    echo "Converting ${WPTABLE} to InnoDB"
    wp db query "ALTER TABLE ${WPTABLE} ENGINE=InnoDB" --allow-root
    echo "Converted ${WPTABLE} to InnoDB"
done
    SALT_HANDELING_ADD
}



MEMORY_LIMIT () {

        MEMORY_LIMIT=$(curl -s $TTFB_APP_RAWDOMAINNAME | grep -i memory_limit)
        MEMORY_LIMIT=$(echo $MEMORY_LIMIT| grep -o -P '.{5}M' | head -n1 | sed 's/>//')
        echo Memory Limit: $MEMORY_LIMIT
}

ttfb_optimizations(){

echo -ne "
TTFB OPTIMIZATIONS
$(ColorGreen '1)') CHECK TTFB
$(ColorGreen '2)') CHECK CACHING
$(ColorGreen '3)') WP-DOCTOR
$(ColorGreen '4)') DB OPTIMIZATIONS
$(ColorGreen '5)') REDUCE AUTOLOADED
$(ColorGreen '6)') REDUCE CRON COUNT
$(ColorPurp '7)') RETURN TO MAIN MENU
$(ColorPurp '0)') Exit
$(ColorYellow 'Choose an option:') "
        read a
        case $a in
                1) TTFB_VALUE ; ttfb_optimizations ;;
                2) CACHE ; ttfb_optimizations ;;
                3) WP_DOCTOR & displaySpinner ; ttfb_optimizations ;;
                4) DB_OPTIMIZATION ; ttfb_optimizations ;;
                5) AUTOLOAD ; ttfb_optimizations ;;
                6) CRON_COUNT ; ttfb_optimizations ;;
                7) mainmenu ;;
                0) exit 0 ;;
                *) echo -e $red"Wrong option."$clear; WrongCommand;;
        esac
}


cpu_load_optimizations(){

echo -ne "
CPU USAGE
$(ColorGreen '1)') CHECK CPU USAGE
$(ColorGreen '2)') DB OPTIMIZATIONS
$(ColorGreen '3)') WP-DOCTOR
$(ColorGreen '4)') CHECK CACHING
$(ColorGreen '5)') REDUCE AUTOLOADED
$(ColorGreen '6)') REDUCE CRON COUNT
$(ColorGreen '7)') CHECK APP STATS
$(ColorPurp '8)') RETURN TO MAIN MENU
$(ColorPurp '0)') Exit
$(ColorYellow 'Choose an option:') "
        read a
        case $a in
                1) CPU_USAGE ; cpu_load_optimizations ;;
                2) DB_OPTIMIZATION ; cpu_load_optimizations ;;
                3) WP_DOCTOR ; cpu_load_optimizations ;;
                4) CACHE ; cpu_load_optimizations ;;
                5) AUTOLOAD ; cpu_load_optimizations ;;
                6) CRON_COUNT ; cpu_load_optimizations ;;
                7) APP_STATS ; cpu_load_optimizations ;;
                8) mainmenu ;;
                0) exit 0 ;;
                *) echo -e $red"Wrong option."$clear; WrongCommand;;
        esac
}

wp_performance_optimizations(){

echo -ne "
WP PERFORMANCE
$(ColorGreen '1)') CHECK CPU USAGE
$(ColorGreen '2)') DB OPTIMIZATIONS
$(ColorGreen '3)') WP-DOCTOR
$(ColorGreen '4)') CHECK CACHING
$(ColorGreen '5)') REDUCE AUTOLOADED
$(ColorGreen '6)') REDUCE CRON COUNT
$(ColorGreen '7)') OPTIMIZE IMAGES
$(ColorPurp '8)') RETURN TO MAIN MENU
$(ColorPurp '0)') Exit
$(ColorYellow 'Choose an option:') "
        read a
        case $a in
                1) CPU_USAGE ; wp_performance_optimizations ;;
                2) DB_OPTIMIZATION ; wp_performance_optimizations ;;
                3) WP_DOCTOR ; wp_performance_optimizations ;;
                4) CACHE ; wp_performance_optimizations ;;
                5) AUTOLOAD ; wp_performance_optimizations ;;
                6) CRON_COUNT ; wp_performance_optimizations ;;
                7) IMAGE_OPTIMIZATION ; wp_performance_optimizations ;;
                8) mainmenu ;;
                0) exit 0 ;;
                *) echo -e $red"Wrong option."$clear; WrongCommand;;
        esac
}

slow_admin/import_optimizations(){

echo -ne "
SLOW ADMIN/IMPORT OPTIMIZATIONS
$(ColorGreen '1)') CHECK MEMORY LIMIT
$(ColorGreen '2)') DB OPTIMIZATIONS
$(ColorGreen '3)') WP-DOCTOR
$(ColorGreen '4)') CONVERT ENGINE From MyISAM TO INNODB 
$(ColorPurp '5)') RETURN TO MAIN MENU
$(ColorPurp '0)') Exit
$(ColorYellow 'Choose an option:') "
        read a
        case $a in
                1) MEMORY_LIMIT ; slow_admin/import_optimizations ;;
                2) DB_OPTIMIZATION ; slow_admin/import_optimizations ;;
                3) WP_DOCTOR ; slow_admin/import_optimizations ;;
                4) DB_ENGINE ; slow_admin/import_optimizations ;;
                5) mainmenu ;;
                0) exit 0 ;;
                *) echo -e $red"Wrong option."$clear; WrongCommand;;
        esac
}





mainmenu(){

echo -ne "
WP-TOOL BOX MENU
$(ColorCyan '1)') TTFB OPTIMIZATIONS
$(ColorCyan '2)') CPU LOAD OPTIMIZATIONS
$(ColorCyan '3)') WP PERFORMANCE OPTIMIZATIONS
$(ColorCyan '4)') Slow Admin/import Optimizations
$(ColorPurp '0)') Exit
$(ColorYellow 'Choose an option:') "
        read a
        case $a in
                1) ttfb_optimizations ; mainmenu ;;
                2) cpu_load_optimizations ; mainmenu ;;
                3) wp_performance_optimizations ; mainmenu ;;
                4) slow_admin/import_optimizations ; mainmenu ;;
                0) exit 0 ;;
                *) echo -e $red"Wrong option."$clear; WrongCommand;;
        esac
}

# Call the menu function
mainmenu

