!define LanguageField 1
!define UsernameField 2
!define PasswordField 3
!define Password2Field 4
!define ErrorField 5
!define LanguageLabel 7
!define UsernameLabel 8
!define PasswordLabel 9

!define InstallationDriveField 13
!define InstallationSizeField 14
!define DistroField 15
!define InstallationDriveLabel 16
!define InstallationSizeLabel 17
!define DistroLabel 18

ReserveFile "main_page.ini"
AddBrandingImage left 150

Function ShowMainPage
    ${debug} "ShowMainPage"
    StrCpy $dialog "$PLUGINSDIR\main_page.ini"
    ${if} $AlreadyInstalled == true
        ${if} $InstallCompleted == true
            ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${AppName}" "UninstallString"
            ${if} ${FileExists} $0
                ${debug} "Existing installation detected, calling old uninstaller and quitting."
                Exec $0
                Quit
            ${endif}
        ${endif}
        !insertmacro GetInstallationDriveFreeSpace $OldInstallationDrive
        ${if} $freeSpace > ${MinSizeMB}
            strcpy $installationDrive $OldInstallationDrive
        ${endif}
    ${endif}
    ${if} $cdboot == true
    ${andif} $cddrive != ""
        ${debug} "cdboot mode, skipping main page"
        strcpy $UseCD true
        abort
    ${endif}
    
    call MakeDriveListBoxString
    call ChangeInstallationDrive
    WriteINIStr $dialog "Field ${InstallationDriveField}" "ListItems" $DriveListBoxString
    ${if} $initMainPage != false
        call PopulateDistroList
        call PopulateLanguageListBox
        ${StrFilter} "$EnvUsername" "-12" "" "" $username ; only lowercase letters and digits in username
        WriteINIStr $dialog "Field ${UsernameField}" "State" $username
        WriteINIStr $dialog "Field ${LanguageLabel}" "Text" $(MainLanguageLabel)
        WriteINIStr $dialog "Field ${UsernameLabel}" "Text" $(MainUsernameLabel)
        WriteINIStr $dialog "Field ${PasswordLabel}" "Text" $(MainPasswordLabel)

        WriteINIStr $dialog "Field ${InstallationDriveField}" "State" $installationDrive
        WriteINIStr $dialog "Field ${DistroField}"            "State" $distro

        WriteINIStr $dialog "Field ${InstallationSizeLabel}" "Text" $(MainInstallationSizeLabel)
        WriteINIStr $dialog "Field ${DistroLabel}"        "Text" $(MainDistroLabel)

        WriteINIStr $dialog "Field 11" "Text" $PLUGINSDIR\data\images\user.bmp
        WriteINIStr $dialog "Field 10" "Text" $PLUGINSDIR\data\images\language.bmp
        WriteINIStr $dialog "Field 12" "Text" $PLUGINSDIR\data\images\lock.bmp
        WriteINIStr $dialog "Field 19" "Text" $PLUGINSDIR\data\images\install.bmp
        WriteINIStr $dialog "Field 20" "Text" $PLUGINSDIR\data\images\disksize.bmp
        WriteINIStr $dialog "Field 21" "Text" $PLUGINSDIR\data\images\desktop.bmp
        
        WriteINIStr $dialog "Settings"         "BackButtonText" "$(AccessibilityButton)"
        StrCpy $initMainPage false
    ${endif}
    call ChangeDistro
    InstallOptions::initDialog /NOUNLOAD $dialog
    #Change Foreground Color Of Error Labels
    Pop $hWnd
    !insertmacro SetColor $dialog ${ErrorField} "FF0000" transparent
    #!insertmacro HideBackButton
    
    
    call InitMainPageToolTips
    InstallOptions::show
    Pop $status
FunctionEnd

Function ChangeInstallationSize
    ${debug} "ChangeInstallationSize to $InstallationSize"
    strcpy $usecd false
    strcpy $readonly false
    ${if} $InstallationSize == "0 $(UseCD)"
        strcpy $usecd true
    ${endif}
    ${if} $InstallationSize == "1 $(ReadOnly)"
        strcpy $readonly true
    ${endif}
    ${if} $UseCD == true
    ${orif} $readonly == true
        !insertmacro Disable $dialog ${UsernameField}
        !insertmacro Disable $dialog ${PasswordField}
        !insertmacro Disable $dialog ${Password2Field}
    ${else}
        !insertmacro Enable $dialog ${UsernameField}
        !insertmacro Enable $dialog ${PasswordField}
        !insertmacro Enable $dialog ${Password2Field}
    ${endif}
FunctionEnd

Function ChangeInstallationDrive
    !insertmacro GetInstallationDriveFreeSpace $InstallationDrive
    ${debug} "ChangeInstallationDrive to $InstallationDrive"
    strcpy $sizeListBoxString ""
    strcpy $oldinstallationsize "$InstallationSize"
    strcpy $InstallationSize ""
    #${if} $freeSpace < ${MinSizeMB}
        #${if} $cddrive != ""
        #    strcpy $InstallationSize "0 $(UseCD)"
        #${elseif} $freeSpace >= ${ReallyMinSizeMB}
        #    strcpy $InstallationSize "1 $(ReadOnly)"
        #${else}
        #${alert} "$(ErrorNoFreeSpace) ($freeSpace MB < ${MinSizeMB} MB)"
        #${endif}
    ${if} $freeSpace > 31000
        strcpy $sizeListBoxString "3|4|5|6|7|8|9|10|15|30"
        strcpy $InstallationSize "15"
    ${elseif} $freeSpace > 21000
        strcpy $sizeListBoxString "3|4|5|6|7|8|9|10|15|20"
        strcpy $InstallationSize "10"
    ${elseif} $freeSpace > 16000
        strcpy $sizeListBoxString "3|4|5|6|7|8|9|10|15"
        strcpy $InstallationSize "10"
    ${elseif} $freeSpace > 11000
        strcpy $sizeListBoxString "3|4|5|6|7|8|9|10"
        strcpy $InstallationSize "8"
    ${elseif} $freeSpace > 10000
        strcpy $sizeListBoxString "3|4|5|6|7|8|9"
        strcpy $InstallationSize "7"
    ${elseif} $freeSpace > 9000
        strcpy $sizeListBoxString "3|4|5|6|7|8"
        strcpy $InstallationSize "6"
    ${elseif} $freeSpace > 8000
        strcpy $sizeListBoxString "3|4|5|6|7"
        strcpy $InstallationSize "6"
    ${elseif} $freeSpace > 7000
        strcpy $sizeListBoxString "3|4|5|6"
        strcpy $InstallationSize "5"
    ${elseif} $freeSpace > 6000
        strcpy $sizeListBoxString "3|4|5"
        strcpy $InstallationSize "5"
    ${elseif} $freeSpace > 5000
        strcpy $sizeListBoxString "3|4"
        strcpy $InstallationSize "4"
    ${else}
        strcpy $sizeListBoxString "3"
        strcpy $InstallationSize "3"
    ${endif}
    #${if} $cddrive != ""
    #    ${if} $sizeListBoxString == ""
    #        strcpy $sizeListBoxString "0 $(UseCD)"
    #    ${else}
    #        strcpy $sizeListBoxString "0 $(UseCD)|$sizeListBoxString"
    #    ${endif}
    #${else}
    #    ${if} $sizeListBoxString == ""
    #        strcpy $sizeListBoxString "1 $(ReadOnly)"
    #    ${else}
    #        strcpy $sizeListBoxString "1 $(ReadOnly)|$sizeListBoxString"
    #    ${endif}    
    #${endif}

    IntOp $freeSpace $freeSpace / 1024
    ${if} "$oldinstallationsize" != ""
    ${andif} "$oldinstallationsize" < "$freeSpace"
        strcpy $installationsize "$oldinstallationsize"
    ${endif}

    StrCpy $DiskSpaceMessage "$(MainInstallationDriveLabel)"
    !insertmacro SetText $dialog ${InstallationDriveLabel} $DiskSpaceMessage
    !insertmacro SetListItems $dialog ${InstallationSizeField} $sizeListBoxString
    !insertmacro SetListItem $dialog ${InstallationSizeField} $InstallationSize
    call ChangeInstallationSize
FunctionEnd

Function ChangeDistro
    call GetDistroInfo
    ${if} ${ChangeArtworkOnDistroChange} == true
        call ChangeDistroArtwork
    ${endif}
    ${if} ${ChangeIconOnDistroChange} == true
        strcpy $appname $distro
        call ChangeIcon
    ${endif}
    !insertmacro MUI_HEADER_TEXT "$(AboutToInstall)" $(MainHeaderSubText)
FunctionEnd

Function LeaveMainPage
    ${debug} "LeaveMainPage"
    #Read Inputs
    StrCpy $errorMessage ""
    StrCpy $ErrorMode 0
    ReadINIStr $trigger $dialog "Settings" "State"
    ReadINIStr $installationDrive $dialog "Field ${InstallationDriveField}" "State"
    ReadINIStr $installationSize $dialog "Field ${InstallationSizeField}" "State"
    ReadINIStr $distro $dialog "Field ${DistroField}" "State"
    ReadINIStr $userLanguage $dialog "Field ${LanguageField}" "State"
    ReadINIStr $username $dialog "Field ${UsernameField}" "State"
    ReadINIStr $password $dialog "Field ${PasswordField}" "State"
    ReadINIStr $password2 $dialog "Field ${Password2Field}" "State"

    ${if} $trigger == ${LanguageField}
        abort
    ${elseif} $trigger == ${InstallationDriveField}
        call ChangeInstallationDrive
        abort
    ${elseif} $trigger == ${InstallationSizeField}
        call ChangeInstallationSize
        abort
    ${elseif} $trigger == ${DistroField}
        call ChangeDistro
        abort
    ${ElseIf} $trigger != 0
        abort
    ${endif}

    ${StrStr} $1 $username " "
    Strcpy $2 $username 1
    ${StrFilter} "$2" "2" "" "" $2 ;store the first char in $2 if it is a letter, else return empty string
    ${StrFilter} "$username" "12" "" "" $3 ;only letters and digits are stored in $3
    ${StrStr} $4 $password " "
    ${StringInFile} "$PLUGINSDIR\data\reserved_usernames.ini" "$username$\n" $5
    ${StrFilter} "$username" "-" "" "" $0 ; convert username to lowercase
    
    #${debug} "distro: $distro usecd:$UseCD readonly:$ReadOnly username:$username"
    ${if} $UseCD != true
    ${andif} $ReadOnly != true
        ${if} $username == ""
            StrCpy $errorMessage $(ErrorNoUsername)
            StrCpy $ErrorMode 1
        ${elseIf} $username S!= $0 ; case sensitive comparison
            StrCpy $errorMessage $(ErrorUsernameUpperCase)
            StrCpy $ErrorMode 2
        ${elseIf} $1 != "" ; white space
            StrCpy $errorMessage $(ErrorSpaceInUsername)
            StrCpy $ErrorMode 3
        ${elseIf} $2 == "" ; first char is number
            StrCpy $errorMessage $(ErrorUsernameFirstCharNotLetter)
            StrCpy $ErrorMode 4
        ${elseIf} $3 != $username ; illegal chars only allowed are letters and digits
            StrCpy $errorMessage $(ErrorUsernameIllegalChars)
            StrCpy $ErrorMode 5
        ${elseIf} $5 == true
            StrCpy $errorMessage $(ErrorReservedUsername)
            StrCpy $ErrorMode 5
        ${elseif} $password == ""
            StrCpy $errorMessage $(ErrorNoPassword)
            StrCpy $ErrorMode 6
        ${elseIf} $4 != "" ; white space
            StrCpy $errorMessage $(ErrorSpaceInPassword)
            StrCpy $ErrorMode 7
        ${elseIf} $password S!= $password2 ; case sensitive comparison
            StrCpy $errorMessage $(ErrorPasswordMismatch)
            StrCpy $ErrorMode 8
        ${endif}
    ${endif}
    ${if} $InstallationSize == ""
        StrCpy $errorMessage "$(ErrorNoFreeSpace)"
        StrCpy $ErrorMode 9
    ${endif}

    #Write Error Messages
    !insertmacro SetText $dialog ${ErrorField} $errorMessage
    ${if} $ErrorMode > 0
        abort
    ${endif}

    #Recalc locale
    ReadINIStr $LANGUAGE "$PLUGINSDIR\data\NSISCodes.ini" "NSISCODES" "$userLanguage"
    Call DetectLocale
FunctionEnd

Function PopulateLanguageListBox
    ${debug} "PopulateLanguageListBox"
    strcpy $0 "Chinese (Simplified)|Chinese (Traditional)|English"
    ReadINIStr $1 "$PLUGINSDIR\data\NSISCodes.ini" "NSISLANGUAGES" "$language"
    WriteINIStr $dialog "Field ${LanguageField}" "ListItems" $0
    WriteINIStr $dialog "Field ${LanguageField}" "State" $1
FunctionEnd

Function InitMainPageToolTips
    ${debug} "InitMainPageToolTips"
    #Usage ${SetToolTip} FieldNumber ToolTipTitle ToolTipMessage
    ${SetToolTip} ${LanguageField} "$(MainLanguageLabel)" "$(MainLanguageToolTip)"
    ${SetToolTip} ${UsernameField} "$(MainUsernameLabel)" "$(MainUsernameToolTip)"
    ${SetToolTip} ${PasswordField} "$(MainPasswordLabel)" "$(MainPasswordToolTip)"
    ${SetToolTip} ${Password2Field} "$(MainPasswordLabel)" "$(MainPasswordToolTip)"
    #FIXME Tool Tips does not seem to work on labels and icons
    ${SetToolTip} ${LanguageLabel} "$(MainLanguageLabel)" "$(MainLanguageToolTip)"
    ${SetToolTip} ${UsernameLabel} "$(MainUsernameLabel)" "$(MainUsernameToolTip)"
    ${SetToolTip} ${InstallationSizeField}              "$(MainInstallationSizeLabel)"        "$(MainInstallationSizeToolTip)"
    ${SetToolTip} ${InstallationDriveField}       "$(MainInstallationDriveLabel)" "$(MainInstallationDriveToolTip)"
    ${SetToolTip} ${DistroField}                  "$(MainDistroLabel)"            "$(MainDistroToolTip)"
FunctionEnd

Function PopulateDistroList
    ${debug} "PopulateDistroList"
    ${if} $distro == ""
        call DetectIso
        ${if} $cddistro != ""
            strcpy $distro $cddistro
        ${endif}
    ${endif}
    ${if} $cddrive != ""
        strcpy $distroListBoxString $cddistro
        strcpy $distro $cddistro
    ${else}
        strcpy $distroListBoxString ""
        ${GetSectionNames} "$PLUGINSDIR\data\isolist.ini" "AddDistroToList"
    ${endif}
    WriteINIStr $dialog "Field ${DistroField}" "ListItems" $distroListBoxString
    ${debug} "DistroList = $distroListBoxString"
FunctionEnd

Function AddDistroToList
    ${debug} "AddDistroToList $9"
    ${StrStrAdv} $distroName "$9" "-$arch" ">" "<" "0" "0" "0"
    ${if} $distroName != ""
        ${if} $distroListBoxString == ""
            strcpy $distroListBoxString "$distroName"
            ${if} $distro == "" #set default value
                strcpy $distro $distroListBoxString
            ${else} 
                strcpy $distroListBoxString  $distro
            ${endif}
        ${else}
            strcpy $distroListBoxString "$distroListBoxString|$distroName"
        ${endif}
    ${endif}
    push "NextDistro"
FunctionEnd

Function ChangeDistroArtwork
    ${debug} "Changing artwork to distro=$distro"
    #HeaderImage
    ${if} ${FileExists} "$PLUGINSDIR\data\images\$distro-header.bmp"
        SetBrandingImage /IMGID=1046 /RESIZETOFIT "$PLUGINSDIR\data\images\$distro-header.bmp"
    ${endif}
    
    #VerticalImage
    ${if} ${FileExists} "$PLUGINSDIR\data\images\$distro-vertical.bmp"
        #Exploits some nsis weirdness, such as hardcoded filenames, works with nsis 2.34    
        CopyFiles /SILENT "$PLUGINSDIR\data\images\$distro-vertical.bmp" "$PLUGINSDIR\modern-wizard.bmp"
    ${endif}
    ClearErrors
FunctionEnd
