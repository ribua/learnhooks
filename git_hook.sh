#!/bin/bash  -x

# This script is a pre-receive hook allowing pushes whose every file:
# - is smaller than 20 M
# - and its extension is not one of the following:
#   - dll
#   - exe
#   - war
#   - ear
#   - jar
# and whose directories are not named 'node_modules'.

GITCMD="git"
NULLSHA="0000000000000000000000000000000000000000"
EMPTYTREESHA=$($GITCMD hash-object -t tree /dev/null)
MAXSIZE="10"
MAXBYTES=$(( $MAXSIZE * 1048576 ))
EXIT=0
PRIVATELOGFILE="/tmp/git_private.log"
SUB='namespaces'

function erivate_log() {
    moment=`date '+%d/%m/%Y %H:%M:%S'`
    echo "[ $moment ] [ POLICY CHECK ] $1" >> $PRIVATELOGFILE
}

function log() {
    moment=`date '+%d/%m/%Y %H:%M:%S'`
    echo "[ $moment ] [ POLICY CHECK ] $1"
}



log "Starting validation..."


     newFiles=$($GITCMD diff-tree --no-commit-id --name-only -r  $1)

    if [[ $? -ne 0 ]]; then
        log "Error 101: Repository incosistency. Cancelling push..."
        exit 1;
    fi


old_IFS=$IFS
    IFS='
    '
    for filename in $newFiles; do
        filesize=$($GITCMD cat-file -s "${newref}:${filename}") 2> $PRIVATELOGFILE

        if [[ -z $filesize  ]]; then filesize=0; fi
        filesize_mb=$(($filesize / 1048576))

        if [ "${filesize}" -gt "${MAXBYTES}" ]; then
            log "File $filename is greater than $MAXSIZE MB. Its size is $filesize_mb MB."
            exit 1
        fi

        if [[ "$filename" =~ "node_modules" ]]; then
            log "Folder 'node_modules' not allowed: $filename."
            exit 1
        else
            if [[ "$filename" =~ \.dll$ ]] || [[ "$filename" =~ \.exe$ ]] || [[ "$filename" =~ \.war$ ]] || [[ "$filename" =~ \.ear$ ]] || [[ "$filename" =~ \.jar$ ]]; then
                extension="${filename##*.}"
                log "Files with extension $extension not allowed. Please remove file $filename"
                exit 1
            fi
        fi

        kind=`grep -i -m 1 kind $filename |cut -d: -f2 | sed 's/ //g' |tr '[:upper:]' '[:lower:]'`
        filetype=`echo $filename| awk -F/ '{print $NF}' |cut -d . -f1 |cut -d . -f1  |tr '[:upper:]' '[:lower:]'`


if [[ "$filename" =~ \.yaml$ ]]; then

  if [[ "$filename" == *"$SUB"* ]]; then

      ns=`echo $filename |awk -F/ '{print $4}'`
      name=`grep -i -m 1 name $filename |cut -d: -f2 | sed 's/ //g' |tr '[:upper:]' '[:lower:]'`
      file=`echo $filename | awk -F/ '{print $NF}'   |tr '[:upper:]' '[:lower:]'`
      check=$kind.$name.$ns.yaml



      if [[  "$file" != $check ]]; then

        log "File naming conventions are incorrect based on the namespace resources."
             exit 1

      fi

     else
     if [[ $filetype != $kind ]]; then

             log "File naming conventions are incorrect based on the resource kind."
             exit 1

          fi

    fi

fi



    done
    IFS=$old_IFS
