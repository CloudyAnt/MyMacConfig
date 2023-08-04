if [ "$OSTYPE" = "cygwin" ];then if ! type dos2unix >/dev/null 2>/dev/null;then echo "Please install dos2unix so that we can resolve potential CRLF problems (cygwin doesn't auto fix them)";exit 1;fi; rm -rf peer 2>/dev/null;mkdir peer;cp -r command script init.sh configTemplate activation.sh ./peer;dos2unix -q peer/command/* peer/script/* peer/init.sh peer/configTemplate peer/activation.sh;./peer/activation.sh;else echo "Please run activation.sh instead";fi 