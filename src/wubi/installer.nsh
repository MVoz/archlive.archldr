!include installer_preseed.nsh
!include installer_download.nsh
!include installer_bootloader.nsh
!include installer_diskimages.nsh

Function UncompressFilesPriorInstall
    ${debug} "UncompressFilesPriorInstall"
    DetailPrint "$(InstallHeaderUncompressWubifolder)"
    ${IF} ${IsNT}
        ExecShell "" "compact" "$INSTDIR\*.* /U /S /A /F" SW_HIDE
        ExecShell "" "compact" "$INSTDIR\ /U /S /A /F" SW_HIDE
    ${endif}
FunctionEnd

Function UncompressFilesAfterInstall
    ${debug} "UncompressFilesAfterInstall"
FunctionEnd

Function MakeUninstall
    ${debug} "MakeUninstall"
    strcpy $uninstallername "Uninstall-$distro.exe"
    DetailPrint $(InstallHeaderWriteUninstaller)
    WriteUninstaller "$INSTDIR\$uninstallername"
    ${debug} "Created $INSTDIR\$uninstallername"
    #WriteUninstaller "$WINDIR\$uninstallername"
    #${debug} "Created $WINDIR\$uninstallername"
    #${if} $cdboot == true
    #    SetShellVarContext all
    #    WriteUninstaller "$SMSTARTUP\$uninstallername"
    #    ${debug} "Created $SMSTARTUP\$uninstallername"
    #${endif}
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${AppName}" "DisplayName" "$distro"
    ${debug} "Created reg key HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\${AppName}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${AppName}" "UninstallString" "$INSTDIR\$uninstallername"
    CopyFiles /SILENT "$PLUGINSDIR\data\images\$distro.ico" "$INSTDIR\"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${AppName}" "DisplayIcon" "$INSTDIR\$distro.ico"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${AppName}" "DisplayVersion" "${AppVersion}.${AppRevision}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${AppName}" "Publisher" "${Publisher}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${AppName}" "URLInfoAbout" "${SupportPageURL}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${AppName}" "HelpLink" "${HomePageURL}"
FunctionEnd

Function BackupTargetFolder
    ${if} $AlreadyInstalled == true
    ${andif} "$OldInstallationDrive\${DefaultInstallationDir}" == "$INSTDIR"
        return
    ${endif}
    ${if} ${FileExists} "$INSTDIR"
        strcpy $0  "$INSTDIR.old"
        strcpy $1 0
        ${do} 
            ${ifnot} ${FileExists} "$0"
                ${break}
            ${endif}
            intop $1 $1 + 1
            strcpy $0  "$INSTDIR.old$1"
        ${loop}
        ${debug} "Backing up existing $INSTDIR -> $0"
        Rename "$INSTDIR" "$0"
    ${endif}
FunctionEnd

Function CopyDistFolder
    ${debug} "CopyDistFolders"
    DetailPrint $(InstallCopyFiles)
    strcpy $0 $OUTDIR ;saves then restore outdir path
    
    strcpy $OUTDIR $INSTDIR\install
    File /r /x .svn "custom-installation"
    !insertmacro ReplaceLineStr "$OUTDIR\custom-installation\hooks\failure-command.sh" "msg=" "msg='$(FailureCommand)'"
    
    ;#strcpy $OUTDIR $INSTDIR
    ;#File /r /x .svn "winboot"
    ;# Archlive remarks: No needed, use grub.cfg for grub2

    ;strcpy $OUTDIR $0
    ;#CopyFiles /SILENT "$PLUGINSDIR\data\menu.install" "$INSTDIR\install\boot\grub\menu.lst"
FunctionEnd
    ;# Archlive remarks: No needed, use grub.cfg for grub2

Function CreateInstallationFolders
    ${debug} "CreateInstallationFolders"
    DetailPrint $(InstallCreateFolders)
    ${if} $AlreadyInstalled == true
        Rename "$OldInstallationDrive\${DefaultInstallationDir}" "$INSTDIR"
    ${endif}
    CreateDirectory "$INSTDIR"                        ;if it's a CD burn it may be possible to avoid creating install folder entirely
    CreateDirectory "$INSTDIR\disks"
    CreateDirectory "$INSTDIR\disks\boot"
    CreateDirectory "$INSTDIR\disks\boot\grub" #also used to detect installation folder
    CreateDirectory "$INSTDIR\disks\shared"
    CreateDirectory "$INSTDIR\docs"
    CreateDirectory "$INSTDIR\install"
    CreateDirectory "$INSTDIR\install\boot"
    CreateDirectory "$INSTDIR\install\boot\grub" #also used to detect installation folder
    CreateDirectory "$INSTDIR\winboot"
FunctionEnd

Function CD2ISO
    call CheckCD
    ${if} "$status" != "success"
        return
    ${endif}
trycd2iso:
    strcpy $isopath $INSTDIR\install\installation.iso
    ${debug} "CD2ISO $isopath"
    DetailPrint $(InstallRetrieveIso)
    ClearErrors
    cd2iso::create "$cddrive" "$isopath"
    Pop $R2 ;Get the return value
    ClearErrors
    #${if} "$R2" == "success"
        ${debug} "CD2ISO finished successfully"
        #already checked squashfs, should be enough
        strcpy "$skipmd5check" true 
        return
    #${elseif} "$R2" == "cancel"
    #    ${debug} "CD2ISO was cancelled, quitting"
    #    quit
    #${else}
     #   ${debug} "CD2ISO failed: $R2"
     #   ${debug} "Asking user to retry CD2ISO"
    #    messagebox MB_RETRYCANCEL $(ErrorCD2ISO) IDRETRY trycd2iso
     #   ${debug} "User did not select to retry CD2ISO, quitting."
      #  quit
    #${endif}
FunctionEnd

Function CheckCD
    ${debug} "CheckCD"
    call check_internet_connection
    strcpy $status "success"
    #${if} "$skipmd5check" == true
        ${debug} "skipmd5check specified, skipping CheckCD"
        return
    #${elseif} "$cdFileCheck" == ""
    #    ${debug} "No cdFileCheck, skipping CheckCD"
     #   return
    #${elseif} "$cdmd5sums" == ""
    #    ${debug} "No cdmd5sums, skipping CheckCD"
    #    return
    #${elseif} "$cddrive" == ""
    #    ${debug} "No cddrive, skipping CheckCD"
    #    return
    #${elseifnot} ${FileExists} "$cddrive\$cdFileCheck"
    #    ${debug} "No file $cddrive\$cdFileCheck, skipping CheckCD"
        #That should be an error
    #    return
    #${elseifnot} ${FileExists} "$cddrive\$cdmd5sums"
    #    ${debug} "No file $cddrive\$cdmd5sums, skipping CheckCD"
        #That should be an error
    #    return
    ## using ISO check may create problems at point releases
    #${elseif} "$connected" == true
    #    ${debug} "We are connected and can get the ISO md5, skipping CheckCD"
    #    return
    #${endif}
    
    strcpy $md5 ""
    ClearErrors
    strcpy $filename "./$cdFileCheck"
    ${StrRep} $filename "$filename" "\" "/"
    ${LineFind} "$cddrive\$cdmd5sums" "/NUL" "1:-1" "extract_MD5"
    ${if} ${errors}
        ${debug} "Errors parsing $cddrive\$cdmd5sums"
        ClearErrors
        return
    ${elseif} "$md5" == ""
        ${debug} "No md5, skipping CheckCD"
        return
    ${else}
        ${debug} "md5=$md5"
    ${endif}
    ${debug} "Checking md5 of $cddrive\$cdFileCheck"
       #MetaDL::download /MD5 "$md5" /TRANSLATE "$(MetadlDownloading)" "$(MetadlChecking)" "$(MetadlConnecting)" "$(MetadlInitializing)" "$(MetadlChecksums)" "$(MetadlRetrying1)" "$(MetadlRetrying2)" "$(MetadlSecond)" "$(MetadlSeconds)" "$(MetadlProgress)" "$(MetadlRemaining)" /CHECK "$cddrive\$cdFileCheck"
    pop $0
    ${debug} "CheckCD raw status = $0"
    strcpy $1 $0 7
    #${if} ${Errors}
        #ClearErrors
        #${debug} "CheckCD there were errors... setting status to failure"
        #strcpy $status "failure"
    #${elseif} "$1" == "success"
        strcpy $status "success"
    #${else}
        #strcpy $status "failure"
   # ${endif}
    ${debug} "CheckCD status = $status"
FunctionEnd

Function EjectCD
    #IOCTL_STORAGE_EJECT_MEDIA 0x2D4808
    #FILE_SHARE_READ 1
    #FILE_SHARE_WRITE 2
    #FILE_SHARE_READ|FILE_SHARE_WRITE 3
    #GENERIC_READ 0x80000000
    #OPEN_EXISTING 3
    strcpy $RebootMsg $(RebootMsg)
    ${if} $cddrive != ""
    ${andif} $usecd != true
        strcpy $RebootMsg $(EjectRebootMsg)
        ${debug} "EjectCD"
        ClearErrors
        System::Call 'kernel32::CreateFile(t "\\.\$cddrive", i 0x80000000, i 3, i 0, i 3, i 0, i 0) i .r0'
        IfErrors exit
        ${debug} "Ejecting CDHandle=$0 for drive=$cddrive"
        ${If} $0 > 0
            System::Call 'kernel32::DeviceIoControl(i r0, i 0x2D4808, i 0, i 0, i 0, i 0, *i r1, i 0) i .r2'
            ${debug} "EjectCD DeviceIoControl exited with code $2 (1==success)"
            System::Call 'kernel32::CloseHandle(i r0)'
        ${endif}
    ${endif}
    ClearErrors
    return
exit:
    ${debug} "Error in EjectCD"
    ClearErrors
FunctionEnd

Function GetIso
    ${debug} "GetIso"
    DetailPrint $(InstallRetrieveIso)
    ${if} $UseCD == true
        ${debug} "Using CD"
        return
    ${endif}

    call DetectCD
    ${if} $cddrive != ""
        ${debug} "Installing in automatic mode from CD"
        call CD2ISO
    ${else}
        call DetectIso
        #strcpy "$isopath" "$exedir\$isoname"
        ${if} "$isopath" != ""
            DetailPrint "$(InstallHeaderCopyIso)"
            ${strtok} $isoname "$isopath" "\" "L" "1"
            ${if} "$BackupFolder\$isoname" == "$isopath"
            ${orif} "$INSTDIR\install\$isoname" == "$isopath"
                ${debug} "Using $isopath"
                #No need to move it, will be done by the installer
            ${else}
                ${debug} "Copying $isopath -> $INSTDIR\install\$isoname"
                CopyFiles "$isopath" "$INSTDIR\install\$isoname"
                strcpy "$isopath" "$INSTDIR\install\$isoname"
                ${debug} "Copying done"
            ${endif}
            ClearErrors
            Sleep 1000
        ${endif}
    ${endif}
    
    #CheckISO and/or Download
    call GetDistroInfo
#    call Download
FunctionEnd

Function CopyKernel
    ${debug} "CopyKernel isokernel=$isokernel, iso=$INSTDIR\install\$isoName, cddrive=$cddrive"
    DetailPrint $(InstallRetrieveIso)
    ${if} $isokernel == ""
    ${orif} $isoinitrd == ""
        ${debug} "No isokernel/isonitrd: isokernel=$isokernel, isoinitrd=$isoinitrd"
        ${alert} $(ErrorNoKernel)
        Quit
    ${elseif} ${FileExists} $INSTDIR\install\$isoname
        ${debug} "Extracting with 7z kernel/initrd from $INSTDIR\install\$isoName"
        nsExec::Exec "$PLUGINSDIR\7z.exe e -y -i!$IsoKernel -o$INSTDIR\install\boot $INSTDIR\install\$isoName "
        nsExec::Exec "$PLUGINSDIR\7z.exe e -y -i!$IsoInitrd -o$INSTDIR\install\boot $INSTDIR\install\$isoName "
        Pop $dos_return_line1
        ${if} $dos_return_line1 == 0
            return
        ${else}
            ${debug} "7z error: $dos_return_line1"
        ${endif}
    ${else}
        ${debug} "No file $INSTDIR\install\$filename"
    ${endif}
    ${if} $cddrive != ""
        ${if} ${FileExists} "$cddrive\$IsoKernel"
        ${andif} ${FileExists} "$cddrive\$IsoInitrd"
            ${debug} "Copying kernel from $cddrive\$IsoKernel" 
            CopyFiles /SILENT "$cddrive\$IsoKernel" "$INSTDIR\install\boot\vmlinuz"
            CopyFiles /SILENT "$cddrive\$IsoInitrd" "$INSTDIR\install\boot\initrd.gz"
            return
        ${else}
            ${debug} "No CD file $cddrive\$IsoKernel"
        ${endif}
    ${endif}
    ${alert} $(ErrorNoKernel)
    quit
FunctionEnd
