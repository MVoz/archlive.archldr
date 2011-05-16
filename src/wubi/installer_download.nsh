!macro download url localfile trymefirst md5 maxtries
    ${debug} "Downloading: trymefirst=${trymefirst} url=${url} md5=${md5}"
    ${if} "${url}" == ""
        strcpy $url "${localfile}"
    ${else}
        strcpy $url "${url}"
    ${endif}
    ClearErrors
    strcpy $status ""
    ${if} "${md5}" != ""
    ${andif} "$skipmd5check" != true
        MetaDL::download /MD5 "${md5}" /COUNTRY "$country" /TRYMEFIRST "${trymefirst}" /RETRYTIME=1 /HASHTRIES=${maxtries} /MAXTRIES=${maxtries} /TRANSLATE "$(MetadlDownloading)" "$(MetadlChecking)" "$(MetadlConnecting)" "$(MetadlInitializing)" "$(MetadlChecksums)" "$(MetadlRetrying1)" "$(MetadlRetrying2)" "$(MetadlSecond)" "$(MetadlSeconds)" "$(MetadlProgress)" "$(MetadlRemaining)" "$url" "${localfile}"
    ${else}
        MetaDL::download /COUNTRY "$country" /TRYMEFIRST "${trymefirst}" /RETRYTIME=1 /HASHTRIES=${maxtries} /MAXTRIES=${maxtries} /TRANSLATE "$(MetadlDownloading)" "$(MetadlChecking)" "$(MetadlConnecting)" "$(MetadlInitializing)" "$(MetadlChecksums)" "$(MetadlRetrying1)" "$(MetadlRetrying2)" "$(MetadlSecond)" "$(MetadlSeconds)" "$(MetadlProgress)" "$(MetadlRemaining)" "$url" "${localfile}"
    ${endif}
    pop $status
    ${debug} "Download status=$status"
    ${if} ${Errors}
        ClearErrors
        strcpy $status "Download errors: $status"
    ${endif}
    ${if} "$status" == "cancel"
        ${debug} "User cancelled download, quitting."
        quit
    ${endif}
    strcpy $0 "$status" 7
    ${if} "$0" == "success"
        strcpy $1 "$status" "" 8
        ${strtok} $isoname "$1" "\" "L" "1"
        strcpy $status success
    ${endif}
!macroend
!define download "!insertmacro download"

Function Download
    ${debug} "Checking/Downloading $distro-$distroversion"
    DetailPrint "$(InstallHeaderDownload)"
    
    ${if} "$skipmd5check" == true
    ${andif} "$isopath" != ""
    ${andif} ${FileExists} "$isopath"
        ${debug} "Skipmd5 is true, using $isopath"
        ${strtok} $isoname "$isopath"  "\" "L" "1"
        Rename $isopath "$INSTDIR\install\$isoname"
        strcpy $status "success"
        return
    ${endif}
    
    ${strtok} $metalinkName "$metalinkUrl"  "/" "L" "1"
    strcpy $local_metalink "$INSTDIR\install\$metalinkname"
    ClearErrors
    call retrieve_partial_files
    call ensure_internet_connection
    ${if} $connected == true
        ${if} "$metalinkUrl" != ""
            ${debug} "Trying remote metalink: $metalinkUrl"
            strcpy $url "$metalinkUrl"
            call get_md5
            strcpy $status ""
            ${if} "$md5" != ""
            ${orif} "${CompulsoryMetalinkSignature}" == false
                ${download} "$metalinkUrl" "$local_metalink" "$isopath" "$md5" 10
                ${if} $status != "success"
                    Delete "$local_metalink" #might well be unverified
                ${endif}
            ${endif}        
        ${endif}
        ${if} $status != "success"
        ${andif} "$metalinkUrl2" != ""
            ${debug} "Trying remote metalink2: $metalinkUrl2"
            strcpy $url "$metalinkUrl2"
            call get_md5
            strcpy $status ""
            ${if} "$md5" != ""
            ${orif} "${CompulsoryMetalinkSignature}" == false
                ${download} "$metalinkUrl2" "$local_metalink" "$isopath" "$md5" 10
                ${if} $status != "success"
                    Delete "$local_metalink" #might well be unverified
                ${endif}
            ${endif}
        ${endif}
    ${else}
        strcpy $status ""
    ${endif}
    ${if} $status != "success"
        call get_local_metalink
        ${if} ${FileExists} "$local_metalink"
            ${debug} "Trying local metalink: $local_metalink"
            ${download} "$isopath" "" "" "" 10
        ${elseif} "$isopath" != ""
        ${andif} ${FileExists} "$isopath"
            ${debug} "Using $isopath but skipping checksum since no metalink file could be found"
            ${strtok} $isoname "$isopath"  "\" "L" "1"
            Rename $isopath "$INSTDIR\install\$isoname"
            strcpy $status "success"
        ${endif}
    ${endif}
    ${if} $status == "success"
        ${debug} "ISO file $isoname retrieved!!!"
    ${else}
        ${alert} "$(ErrorDownload) $status"
        Quit
    ${endif}
FunctionEnd

Function get_local_metalink
    ${if} ${FileExists} "$local_metalink"
        ${debug} "Using local metalink: $local_metalink"
    ${elseif} ${FileExists} "$PLUGINSDIR\data\metalinks\$metalinkname"
        ${debug} "Using local metalink: $PLUGINSDIR\data\metalinks\$metalinkname"
        copyfiles /silent  "$PLUGINSDIR\data\metalinks\$metalinkname" "$local_metalink"
    ${elseif} ${FileExists} "$BackupFolder\$metalinkname"
        ${debug} "Using local metalink: $BackupFolder\$metalinkname"
        copyfiles /silent  "$BackupFolder\$metalinkname" "$local_metalink"
    ${endif}
FunctionEnd

Function retrieve_partial_files
    ${debug} "retrieve_partial_files"
    ${If} $BackupFolder == ""
        return
    ${endif}
    #SetOverwrite off
    ${locate} "$BackupFolder" "/L=F /G=0 /M=*.partial /S=10M" "retrieve_partial_file"
FunctionEnd

Function retrieve_partial_file
    strcpy $filepath $R9
    strcpy $filename $R7
    ${debug} "Retrieve $filepath"
    Rename "$filepath" "$INSTDIR\install\$filename"
    Sleep 1000
    push "KeepSearching"
FunctionEnd

Function ensure_internet_connection
    call check_internet_connection
    ${if} "$connected" == false
        ${if} "$isopath" != ""
        ${andif} ${FileExists} "$isopath"
            ${debug} "No internet connection, but we have a local ISO: $isopath"
        ${else}
            MessageBox MB_RETRYCANCEL $(PleaseConnect) IDCANCEL cancel
            call ensure_internet_connection
        ${endif}
    ${endif}
    return
cancel:
    ${debug} "User cancelled Internet Connection Retry, quitting"
    quit
FunctionEnd

Function get_md5
    #copy values to $url first $md5sums_filename $md5sums_signature
    #returns value in $md5

    strcpy $md5 ""
    ${StrTok} $filename "$url"  "/" "L" "1"
    ${StrStrAdv} $baseurl "$url" "/" "<" "<" "0" "0" "0"
    ${if} $md5sums_filename == ""
        strcpy $md5sums_filename MD5SUMS
    ${endif}
    ${if} $md5sums_signature == ""
        strcpy $md5sums_signature "$md5sums_filename"".gpg"
    ${endif}
    ${debug} "get_md5 $url"

    #Get $md5sums_signature
    Delete "$INSTDIR\install\$md5sums_signature"
    ${download} "$baseurl/$md5sums_signature" "$INSTDIR\install\$md5sums_signature" "" "" 3
    ${if} $status != "success"
    ${orifnot} ${fileexists} "$INSTDIR\install\$md5sums_signature"
        strcpy $errormessage "Error downloading $baseurl/$md5sums_signature, $0"
        goto failed
    ${endif}

    #Get $md5sums_filename
    Delete "$INSTDIR\install\$md5sums_filename"
    ${download} "$baseurl/$md5sums_filename" "$INSTDIR\install\$md5sums_filename" "" "" 3
    ${if} $status != "success"
    ${orifnot} ${fileexists} "$INSTDIR\install\$md5sums_filename"
        strcpy $errormessage "Error downloading $baseurl/$md5sums_filename, $0"
        goto failed
    ${endif}

    #Verify $md5sums_filename
    Delete "$INSTDIR\install\$md5sums_filename.asc"
    ${debug} "      Verifying signature $INSTDIR\install\$md5sums_filename.asc"
    Rename "$INSTDIR\install\$md5sums_signature" "$INSTDIR\install\$md5sums_filename.asc"
    push ""
    push ""
    push ""
    push ""
    push ""
    ClearErrors
    nsExec::Exectostack '$PLUGINSDIR\gpgv.exe --keyring="$PLUGINSDIR\data\trustedkeys.gpg" "$INSTDIR\install\$md5sums_filename.asc"'
    pop $0
    pop $1
    pop $2
    pop $3
    pop $4
    ${debug} "$0; $1; $2; $3; $4"
    #${if} ${errors}
     #   ${debug} "Errors while verifying signature: $0"
    #    pop $0 
     #   ClearErrors
        #Non fatal
    #${endif}
    #${if} "$0" != "0"
    #    strcpy $errormessage "Error verifying signature: $0"
     #   goto failed
    #${endif}

    #Get MD5
    ${debug} "      Parsing $INSTDIR\install\$md5sums_filename"
    ClearErrors
    ${LineFind} "$INSTDIR\install\$md5sums_filename" "/NUL" "1:-1" "extract_MD5"
    #${if} ${errors}
    #    strcpy $errormessage  "Errors parsing $INSTDIR\install\$md5sums_filename"
    #    goto failed
    #${endif}
    #${if} $md5 != ""
        ${debug} "Found md5 $md5"
    #${else} 
    #    ${debug} "Could not find any md5"
    #${endif}
    return
failed:
    ${debug} $errormessage
    ClearErrors
FunctionEnd
