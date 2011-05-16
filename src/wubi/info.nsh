!include info_disk.nsh
!include info_iso.nsh
!include info_networking.nsh
!include winver.nsh


Function detect_all
    ${debug} "detect_all"
    call parse_command_line_parameters
    call CheckAdminRights
    call CheckMemory
    call DetectProcessorArchitecture
    call DetectCD #override arch if CD or ISO is found????
    ${if} $cdboot == true
    ${andif} $cddrive == ""
        ${debug} "CDBoot selected but could not find any CD, quitting"
        ${alert} $(ErrorNoCD)
        quit
    ${endif}
    ${if} $cddistro != ""
        #REBRAND!
        strcpy $appname $cddistro
        strcpy $distro $cddistro
        call ChangeIcon
    ${endif} 
    call CheckIfinstalled
    call ChooseInstallationDrive
    call CheckFreeSpace
    call DetectBackupFolder
    
    #do not change order
    call DetectGMT
    call DetectCountry
    call DetectLocale
    call DetectLayoutCode
    call DetectTimeZone
    call DetectDomain
    call DetectHostName
    call DetectComputerName
    call DetectUserName
    call DetectUserDomain
    call DetectUserInfoName
    call DetectUserProfileFolder
    call DetectUserProfileName
    call DefaultNetInit
    ${debug} "detect_all finished"
FunctionEnd

Function GetDistroInfo
    ${if} "$distro" == ""
        strcpy $0 $cddistro
    ${else}
        strcpy $0 $distro
    ${endif}
    ${if} "$cdarch" == "i686"
        strcpy $distroFullName "$0-$cdarch"
    ${else}
        strcpy $distroFullName "$0-$arch"
    ${endif}

    ${debug} "      GetDistroInfo distrofullname=$distroFullName distro=$distro cddistro=$cddistro cdarch=$cdarch arch=$arch"
    ReadINIStr $isoName $PLUGINSDIR\data\IsoList.ini "$distroFullName" "IsoName"
    ReadINIStr $isoSize $PLUGINSDIR\data\IsoList.ini "$distroFullName" "IsoSize"
    ReadINIStr $minIsoSize $PLUGINSDIR\data\IsoList.ini "$distroFullName" "MinIsoSize"
    ReadINIStr $isoKernel $PLUGINSDIR\data\IsoList.ini "$distroFullName" "kernel"
    ReadINIStr $isoInitrd $PLUGINSDIR\data\IsoList.ini "$distroFullName" "initrd"
    ReadINIStr $metalinkUrl $PLUGINSDIR\data\IsoList.ini "$distroFullName" "metalink"
    ReadINIStr $metalinkUrl2 $PLUGINSDIR\data\IsoList.ini "$distroFullName" "metalink2"
    ReadINIStr $distroPackages $PLUGINSDIR\data\IsoList.ini "$distroFullName" "packages"
    ReadINIStr $distroVersion $PLUGINSDIR\data\IsoList.ini "$distroFullName" "version"
    ReadINIStr $distroSubVersion $PLUGINSDIR\data\IsoList.ini "$distroFullName" "subversion"
    ReadINIStr $md5sums_filename $PLUGINSDIR\data\IsoList.ini "$distroFullName" "md5sums"
    ReadINIStr $md5sums_signature $PLUGINSDIR\data\IsoList.ini "$distroFullName" "md5sums_signature"
    ReadINIStr $cdFileCheck $PLUGINSDIR\data\IsoList.ini "$distroFullName" "cdFileCheck"
    ReadINIStr $cdmd5sums $PLUGINSDIR\data\IsoList.ini "$distroFullName" "cdmd5sums"    
    ClearErrors
        ${if} "$IsoName" == ""
        strcpy $IsoName "archlive.iso"
    ${endif}
    ${if} "$isoKernel" == ""
        strcpy $isoKernel "archlive\boot\i686.ker"
    ${endif}
    ${if} "$distroVersion" == ""
        strcpy $distroVersion "hd"       
      ${endif}  
      ${if} "$isoinitrd" == ""
        strcpy $isoinitrd "archlive\boot\i686.img"
    ${endif} 
    ${debug} "      ->metalinkURL=$metalinkUrl"
    ${debug} "      ->isoKernel=$isoKernel"
    ${debug} "      ->distroVersion=$distroVersion"
FunctionEnd

Function DetectBackupFolder
    ${debug} "DetectBackupFolder"
    strcpy $BackupFolder ""
    ${if} $OldInstallationDrive != ""
    ${andif} ${FileExists} "$OldInstallationDrive\${BackupFolderName}"
        strcpy $BackupFolder "$OldInstallationDrive\${BackupFolderName}"
        ${debug} "Found BackupFolder $OldInstallationDrive\${BackupFolderName}"
    ${else}
        ${GetDrives} "HDD" IsBackupFolder
    ${endif}
FunctionEnd

Function IsBackupFolder
    ${debug} "IsBackupFolder $9"
    ${if} ${FileExists} "$9${BackupFolderName}"
        strcpy $BackupFolder "$9${BackupFolderName}"
        ${debug} "Found BackupFolder $9${BackupFolderName}"
        Push "StopGetDrives"
    ${Else}
        Push "KeepSearching"
    ${endif}
FunctionEnd

Function parse_command_line_parameters
    ${debug} "Parsing cmdline $CMDLINE"
    ${StrStr} $str $CMDLINE "--debug"
    ${if} "$str" != ""
        strcpy $debug true
    ${endif}
    
    ${StrStr} $str $CMDLINE "--skipmd5check"
    ${if} "$str" != ""
        strcpy $skipmd5check true
    ${endif}
    
    ${StrStr} $str $CMDLINE "--skipmemorycheck"
    ${if} "$str" != ""
        strcpy $skipmemorycheck true
    ${endif}
    
    ${StrStr} $str $CMDLINE "--skipspacecheck"
    ${if} "$str" != ""
        strcpy $skipspacecheck true
    ${endif}
    
    ${StrStr} $str $CMDLINE "--32bit"
    ${if} "$str" != ""
        strcpy $force32bit true
    ${endif}
    
    ${StrStr} $str $CMDLINE "--cdboot"
    ${if} "$str" != ""
    ${orif} ${cdBootOnly} == true
        strcpy $cdboot true
    ${endif}
    ${debug} "debug=$debug, 32bit=$force32bit, cdboot=$cdboot"
FunctionEnd

Function CheckFreeSpace
    !insertmacro  GetInstallationDriveFreeSpace $installationDrive
    ${if} $AlreadyInstalled != true
    ${andif} $freeSpace < ${MinSizeMB}
    ${Andif} $cdboot != true
        ${debug} "Not enough free space in $installationDrive, $freeSpace < ${MinSizeMB}, quitting."
        ${if} $debug != true
        ${andif} $skipspacecheck != true
            messagebox mb_yesno "$(ErrorNoFreeSpace)"  IDYES skipspacecheck
            ${debug} "User quitting because of low disk space"
            quit
        ${endif}
    ${endif}
    ${debug} "FreeSpace in $installationDrive is $freeSpace"
    return
skipspacecheck:
    strcpy $skipspacecheck true
FunctionEnd

Function CheckIfinstalled
    ${debug} "CheckIfinstalled"
    StrCpy $AlreadyInstalled false
    StrCpy $OldInstallationDrive ""
    StrCpy $InstallCompleted false
    call DetectInstallationDrive
    ${if} "$OldInstallationDrive" != ""
    ${andif} ${FileExists} "$OldInstallationDrive\${DefaultInstallationDir}"
        StrCpy $AlreadyInstalled true
        ${if} ${FileExists} "$OldInstallationDrive\${DefaultInstallationDir}\disks\boot\grub\menu.lst"
        ${Orif} ${FileExists} "$OldInstallationDrive\${DefaultInstallationDir}\disks\root.disk"
        ${Orif} ${FileExists} "$OldInstallationDrive\${DefaultInstallationDir}\disks\home.disk"
            StrCpy $InstallCompleted true
        ${endif}
    ${endif}
    ${debug} "AlreadyInstalled=$AlreadyInstalled OldInstallationDrive=$OldInstallationDrive InstallCompleted=$InstallCompleted"
FunctionEnd

Function DetectInstallationDrive
    ${debug} "DetectInstallationDrive"
    ${GetDrives} "HDD" isInstallationDrive
FunctionEnd

Function isInstallationDrive
    ${debug} "isInstallationDrive $9${DefaultInstallationDir}"
    ${if} ${FileExists} "$9${DefaultInstallationDir}\install\boot\grub"
    ${orif} ${FileExists} "$9${DefaultInstallationDir}\disks\boot\grub"
        strcpy $OldInstallationDrive $9 2
        strcpy $BackupFolder "$OldInstallationDrive\${BackupFolderName}"
        Push "StopGetDrives"
        ${debug} "Found InstallationDrive $9${DefaultInstallationDir}"
    ${Else}
        Push "KeepSearching"
    ${endif}
FunctionEnd

Function DetectCountry
    ReadRegStr $country HKCU "Control Panel\International" iCountry
    ReadINIStr $country $PLUGINSDIR\data\countries.ini "icountry2country" $country
    ${if} "$country" == ""
        ReadRegStr $country HKCU "Control Panel\International" sCountry
        ReadINIStr $country $PLUGINSDIR\data\countries.ini "name2country" $country
    ${endif}
    ${if} "$country" == ""
        ReadINIStr $country $PLUGINSDIR\data\timezones.ini "gmt2country" $wingmt
    ${endif}
    ${if} "$country" == "" #safety net
        strcpy $country "US"
    ${endif}
    ${debug} "Country=$country"
FunctionEnd

Function DetectLocale
    ReadINIStr $lang $PLUGINSDIR\data\languages.ini "languages" "$LANGUAGE"
    ${if} "$lang" == ""  #safety net
        strcpy $lang "en"
    ${endif}
    ReadINIStr $locale $PLUGINSDIR\data\locales.ini "langcountry2linuxlocale" "$lang_$country"
    ${if} $locale == ""
        ${ConfigRead} "$PLUGINSDIR\data\locales.ini" "$lang_" $locale
        ${StrStrAdv} $locale "$locale" "=" ">" ">" "0" "0" "0"
    ${endif}
    ${if} $locale == ""
        strcpy $locale "en_US.UTF-8"
    ${endif}
    ${debug} "Locale=$locale"
FunctionEnd

Function DetectLayoutCode
    System::Call "user32::GetKeyboardLayout(i 0x0) i .r0"
    IfErrors safetynet
    ; lower word is the locale identifier (higher word is a handler to the actual layout)
    IntOp $hkl $0 & 0xFFFFFFFF
    IntFmt $hkl "0x%08X" $hkl
    IntOp $localeid $0 & 0x0000FFFF
    IntFmt $localeid "0x%04X" $localeid
    ReadINIStr $layoutcode $PLUGINSDIR\data\keymaps.ini "keymaps" "$localeid"
    ReadINIStr $keyboardvariant $PLUGINSDIR\data\variants.ini "hkl2variant" "$hkl"
    #${debug} "hkl=$hkl, localeid=$localeid, layoutcode=$layoutcode, keyboardvariant=$keyboardvariant"
    ${if} "$layoutcode" != ""
        return
    ${endif}
safetynet:
    StrCpy $layoutcode "$country"
    ${StrFilter} "$layoutcode" "-" "" "" "$layoutcode" #lowercase
    ${debug} "LayoutCode=$LayoutCode"
FunctionEnd

Function DetectGMT
    #ReadRegDWORD $0 HKLM SYSTEM\CurrentControlSet\Control\TimeZoneInformation ActiveTimeBias
    ReadRegDWORD $0 HKLM SYSTEM\CurrentControlSet\Control\TimeZoneInformation Bias
    Intop $0 0 - $0
    Intop $wingmt $0 / 60
    ${if} $wingmt == "" #safety net
    ${orif} $wingmt > 12
    ${orif} $wingmt < -12
        strcpy $wingmt 0
    ${endif}
    ${debug} "GMT=$wingmt"
FunctionEnd

Function DetectTimeZone
    ReadINIStr $timezone $PLUGINSDIR\data\timezones.ini "country2tz" "$country"
    ReadINIStr $0 $PLUGINSDIR\data\timezones.ini "tz_$country" "$wingmt"
    ${if} $0 != ""
        strcpy $timezone $0
    ${endif}
    #ReadINIStr $gmt $PLUGINSDIR\data\countries.ini "gmt" "$country"
    #${if} $gmt != $wingmt
        #single-timezone country which does not match! do we give priority to country or to gmt?
        #ReadINIStr $timezone $PLUGINSDIR\data\countries.ini "tzfailover" "$gmt"
    #${endif}
    ${if} $timezone == "" #safety net
        ReadINIStr $timezone $PLUGINSDIR\data\timezones.ini "gmt2tz" "$wingmt"
    ${endif}
    ${if} $timezone == "" #safety net
        strcpy $timezone "America/New_York"
    ${endif}
    ${debug} "TimeZone=$TimeZone"
FunctionEnd

Function DetectDomain
    System::Call "kernel32.dll::GetComputerNameExW(i 2,w .r0,*i ${NSIS_MAX_STRLEN} r1)i.r2"
    ${if} "$2" != 0
        ${if} "$0" == ""
            StrCpy $0 "localdomain"
        ${endif}
        StrCpy $domain "$0"
    ${endif}
    ${debug} "Domain=$domain"
FunctionEnd

Function DetectHostName
    System::Call "kernel32.dll::GetComputerNameExW(i 1,w .r0,*i ${NSIS_MAX_STRLEN} r1)i.r2"
    ${if} "$2" != 0
        ${if} "$0" == ""
            StrCpy $0 "myhostname"
        ${endif}
        StrCpy $hostname "$0"
    ${endif}
    ${debug} "HostName=$hostname"
FunctionEnd

Function DetectUserName
    ReadEnvStr $EnvUsername USERNAME
    ${if} $EnvUsername == ""
        StrCpy $EnvUsername "user"
    ${endif}
    ${debug} "EnvUsername=$EnvUsername"
FunctionEnd

Function DetectUserDomain
    ReadEnvStr $userdomain USERDOMAIN
    ${if} "$userdomain" == ""
      StrCpy $userdomain "mydomain"
    ${endif}
    ${debug} "UserDomain=$userdomain"
FunctionEnd

Function DetectComputerName
    ReadEnvStr $computerName COMPUTERNAME
    ${if} "$computerName" == ""
      StrCpy $computerName "mycomputer"
    ${endif}
    ${debug} "ComputerName=$computerName"
FunctionEnd

Function DetectUserInfoName
    userInfo::getName
    Pop $UserInfoName
    ${if} "$UserInfoName" == ""
      StrCpy $UserInfoName "user"
    ${endif}
    ${debug} "UserInfoName=$UserInfoName"
FunctionEnd

Function DetectUserProfileFolder
    ReadEnvStr $userprofilefolder USERPROFILE
    ${if} "$userprofilefolder" == ""
        StrCpy $userprofilefolder "c:\documents and settings\user"
    ${endif}
    ${debug} "UserProfileFolder=$userprofilefolder"
FunctionEnd

Function DetectUserProfileName
    ReadEnvStr $userprofilename USERNAME
    ${if} "$userprofilename" == ""
        StrCpy $userprofilename "user"
    ${endif}
    ${debug} "UserProfileName=$userprofilename "
FunctionEnd

Function DetectProcessorArchitecture
   test64::get_arch
   StrCpy $arch $0
   ${if} $arch == i686
       SetRegView 32
    ${else}
        SetRegView 64
    ${endif}
   ${if} $force32bit == true
        strcpy $arch i686
   ${endif}
   ${debug} "arch=$arch"
FunctionEnd

Function ChangeIcon
    ${if} ${FileExists} "$PLUGINSDIR\data\images\$appname.ico"
        ${debug} "Changing icon to $appname.ico"
        System::Call 'user32::LoadImage(i 0, t "$PLUGINSDIR\data\images\$appname.ico", i ${IMAGE_ICON}, i 0, i 0, i ${LR_LOADFROMFILE}) i.s'
        pop $0
        SendMessage $HWNDPARENT ${WM_SETICON} 0 $0
        System::Call gdi32::DeleteObject(i$0)
    ${endif}
    ClearErrors
FunctionEnd

Function CheckAdminRights
    ClearErrors
    UserInfo::GetAccountType
    ${If} ${errors} 
        ${debug} "Errors in GetAccountType"
    ${else}
        pop $1
        ${debug} "User account type=$1"
        ${if} $1 != "Admin"
        ${andif} $1 != "Power"
        ${andifnot} ${IsWin98}
            ${debug} "User is not an admin, quitting"
            ${alert} "$(ErrorNoAdmin)"
            quit
        ${endif}
    ${endif}
    ClearErrors
FunctionEnd

Function check_internet_connection
    ${debug} "check_internet_connection"
    Push $R0
    ClearErrors
    #Dialer::AttemptConnect
    Dialer::GetConnectedState
    ${if} ${errors}
        ${debug} "Connection errors"
        strcpy $R0 "Errors"
        ClearErrors
    ${else}
        Pop $R0
        ${debug} "Dialer $R0"
    ${endif}
    ${if} $R0 != "online"
        ${debug} "not connected"
        strcpy $connected false
    ${else}
        ${debug} "connected"
        strcpy $connected true
        Pop $R0
    ${endif}
FunctionEnd

Function extract_MD5
    ${StrRep} $md5 "$R9" "  $filename" ""
    ${if} "$md5" != ""
    ${andif} "$md5" != "$R9"
        strcpy $md5 "$md5" 32
        push "StopLineFind"
    ${else}
        strcpy $md5 ""
        push "KeepSearching"
    ${endif}
FunctionEnd

Function CheckMemory
    ${if} "$skipmemorycheck" != true
        System::Alloc 64
        Pop $1
        System::Call "*$1(i64)"
        System::Call "Kernel32::GlobalMemoryStatusEx(i r1)"
        System::Call "*$1(i.r2, i.r3, l.r4, l.r5, l.r6, l.r7, l.r8, l.r9, l.r10)"
        System::Free $1
        #DetailPrint "Structure size: $2 bytes"
        #DetailPrint "Memory load: $3%"
        #DetailPrint "Total physical memory: $4 bytes"
        #DetailPrint "Free physical memory: $5 bytes"
        #DetailPrint "Total page file: $6 bytes"
        #DetailPrint "Free page file: $7 bytes"
        #DetailPrint "Total virtual: $8 bytes"
        #DetailPrint "Free virtual: $9 bytes"
        ClearErrors
        intop $4 $4 / 1048576
        strcpy $memoryMB "$4"
        ${debug} "Memory=$memoryMB MB"
        ${if} "$memoryMB" > 0
        ${andif} "$memoryMB" < ${MinMemoryMB}
            ${debug} "Not enough memory: $memoryMB < ${MinMemoryMB}"
            messagebox mb_yesno "$(ErrorNoMemory)"  IDYES continue
            ${debug} "User quitting because of low memory"
            quit
        ${endif}
    ${endif}
continue:
FunctionEnd
