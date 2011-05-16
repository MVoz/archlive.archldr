Function MakeDriveList
    strcpy $drives ""
    ${GetDrives} "CDROM+HDD" AddDrive
FunctionEnd

Function AddDrive
    strcpy $drives "$drives$9"
    push "KeepSearching"
FunctionEnd

Function DetectCD
    ${debug} DetectCD
    #Test exedir first
    strcpy $cddrive $EXEDIR 2
    call IsValidCD
    ${if} "$cddrive" != ""
        ${Debug} "Found CD cddrive=$cddrive"
        return
    ${endif}
    call MakeDriveList
    ${For} $ndrive 0 100
        ${StrTok} $cddrive "$drives" "\" "$ndrive" "1"
        ${if} "$cddrive" == ""
            ${break}
        ${endif}
        call IsValidCD   
        ${if} "$cddrive" != ""
            ${Debug} "Found CD cddrive=$cddrive"
            return
        ${endif}
    ${Next}
    ${debug} "No CD found"
FunctionEnd

Function DetectIso
    ${debug} DetectIso
    ${locate} "$installationDrive\${DefaultInstallationDir}\install" "/L=F /G=0 /M=*.iso" "IsValidISO"
    StrCmp $status success finish
    ${locate} "$installationDrive\${DefaultInstallationDir}" "/L=F /G=0 /M=*.iso" "IsValidISO"
    StrCmp $status success finish
    ${locate} "$BackupFolder" "/L=F /G=0 /M=*.iso" "IsValidISO"
    StrCmp $status success finish
    ${locate} "$exedir" "/L=F /G=0 /M=*.iso" "IsValidISO"
    StrCmp $status success finish
    ${locate} "$DESKTOP" "/L=F /G=0 /M=*.iso" "IsValidISO"
    StrCmp $status success finish
    ${locate} "$DOCUMENTS" "/L=F /G=0 /M=*.iso" "IsValidISO"
finish:
FunctionEnd

Function ClearCdInfo
    strcpy $status ""
    strcpy $cdinfo ""
    strcpy $cddrive ""
    strcpy $isopath ""
    strcpy $cddistro ""
    strcpy $cdversion ""
    strcpy $cdsubversion ""
    strcpy $cdarch ""
    strcpy $cdcodename ""
    strcpy $cdsize ""
    strcpy $isosize ""
    strcpy $filename ""
    ${debug} "CDInfo cleared"
FunctionEnd

Function IsValid
    
    #Test cdinfo
    ${debug} "      IsValid $cdinfo"
    ${if} "$cdinfo" == ""
        ${debug} "no cdinfo"
        #goto failed
    ${endif}
    
    #Test cddistro
    call ParseCdInfo
    ${if} "$cddistro" == ""
        ${debug} "no cddistro"
        #goto failed
    ${endif}
    
    #Get distro info
    call GetDistroInfo
    ${if} "$distroVersion" == ""
        ${debug} "no distroversion"
        #goto failed
    ${endif}
    
    #isoname
    ${if} "$isoname" != ""
    ${andif} "$filename" != ""
    ${andif} "$isoname" != "$filename"
        ${debug} "different isoname $isoname != $filename"
        goto failed
    ${endif}
    
    #Test distro
    ${if} "$distro" != ""
    ${andif} "$distro" !=  "$cddistro"
        ${debug} "different distro $distro != $cddistro"
        #goto failed
    ${endif}
    
    #Test version/subversion
    ${if} "$distroVersion" != "$cdversion"
    #${orif} "$distroSubVersion" != "$cdsubversion"
        ${debug} "different version $distroVersion != $cdversion"
        #goto failed
    ${endif}
    
    #Test cdfilecheck
    ${if} "$cdFileCheck" != ""
    ${andif} "$cddrive" != ""
    ${andifnot} ${FileExists} "$cddrive\$cdFileCheck"
        ${debug} "file to be checked does not exists: $cddrive\$cdFileCheck"
        goto failed
    ${endif}
    
    #Test size/minsize
    ${if} "$cdsize" != ""
    ${andif} "$isosize" != ""
    ${andif} "$isosize" != "$cdsize"
        ${debug} "different size $isosize != $cdsize"
        #goto failed
    ${endif}
    ${if} "$cdsize" != ""
    ${andif} "$minIsoSize" != ""
    ${andif} $cdsize < $minIsoSize
        #${debug} "too small $cdsize < $minIsoSize"
        #goto failed
    ${endif}

    #Test arch
    ${if} "$cdarch" != i386
        ${if} "$force32bit" == true
        ${orif} "$cdarch" != "$arch"
            #${debug} "Invalid cdarch=$cdarch != arch=$arch"
            #goto failed
        ${endif}
    ${endif}
    
    ${debug} "Found a good ISO: $cdinfo"
    strcpy $status success
    return
failed:
    call ClearCdInfo
FunctionEnd

Function IsValidCD
    ${debug} "      Is Valid CD $cddrive"
    ${If} ${FileExists} "$cddrive\${CDInfoFile}"
        ClearErrors
        ${lineread} "$cddrive\${CDInfoFile}" "1" "$cdinfo"
        ${if} ${errors}
            ClearErrors
        ${else}
            #TBD get CD size
            call IsValid
            ${if} "$status" == "success"
                ${debug} "Found CD $cddrive"
                Push "StopGetDrives"
                return
            ${endif}
        ${endif}
    ${endif}
    call ClearCdInfo
    Push "KeepSearching"
FunctionEnd

Function IsValidISO
    strcpy $isopath "$R9"
    strcpy $filename "$R7"
    strcpy $cdsize "$R6"
    strcpy $status ""
    ${debug} "      IsValidIso ispoath=$isopath"
    ${If} ${FileExists} "$isopath"
        call ExtractIsoInfo
        call IsValid
        ${if} "$status" == "success"
            Push "StopLocate"
        ${endif}
    ${else}
        call ClearCdInfo
    ${endif}
    Push "KeepSearching"
FunctionEnd

Function ParseCdInfo
        ${StrTok} $cddistro "$cdinfo"   " " "0" "1"
        ${StrTok} $cdversion "$cdinfo" " " "1" "1"
        ${StrTok} $cdcodename "$cdinfo" "$\"" "1" "1"
        ${StrTok} $cdbuild "$cdinfo" "()" "1" "1"
        ${StrStrAdv} $str "$cdinfo"  "- " "<" ">" "0" "0" "0"
        ${StrStrAdv} $str "$str"  " (" "<" "<" "0" "0" "0"
        ${StrTok} $cdarch "$str"     " " "L" "1"
        ${StrStrAdv} $cdsubversion "$str" " " "<" "<" "0" "0" "0"
        ${debug} "      cdversion=$cdversion \
            cddistro=$cddistro \
            cdarch=$cdarch \
            cdcodename=$cdcodename \
            cdsubversion=$cdsubversion \
            cdbuild=$cdbuild \
        "
FunctionEnd

Function ExtractIsoInfo
    ${debug} "      ExtractIsoInfo"
    strcpy $cdinfo ""
    ${if} ${FileExists} "$TEMP\info"
        Delete "$TEMP\info"
    ${endif}
    ClearErrors
    ${debug} "      $PLUGINSDIR\7z.exe e -y -i!${CDInfoFile} -o$TEMP $isopath"
    nsExec::Exec '"$PLUGINSDIR\7z.exe" e -y -i!"${CDInfoFile}" -o"$TEMP" "$isopath"'
    pop $dos_return_line1
    ${if} ${errors}
        pop $0
        ClearErrors
        ${debug} "Errors in 7z ExtractISOinfo"
        return
    ${endif}
    ${if} $dos_return_line1 != 0
        ${debug} "$PLUGINSDIR\7z error: $dos_return_line1"
    ${elseif} ${FileExists} "$TEMP\info"
        ${lineread} "$TEMP\info" "1" $cdinfo
        ${if} ${errors}
            strcpy $cdinfo ""
            ClearErrors
        ${endif}
    ${else}
        ${debug} "Could not find $TEMP\info"
    ${endif}
FunctionEnd
