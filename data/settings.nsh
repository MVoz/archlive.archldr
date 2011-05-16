!define AppName archlive-installer
!define AppVersion 0.01
!define AppSubversion 0
!ifndef AppRevision
    !define AppRevision archlive
!endif
!ifndef AppSuffix
    #!define AppSuffix beta
!endif
!ifndef DefaultDistro
    !define DefaultDistro Arch
!endif
!ifndef DefaultBrand
    !define DefaultBrand ${DefaultDistro}
!endif
!ifndef ChangeIconOnDistroChange
    !define ChangeIconOnDistroChange true
!endif
!ifndef ChangeArtworkOnDistroChange
    !define ChangeArtworkOnDistroChange true
!endif
!ifndef CompulsoryMetalinkSignature
    !define CompulsoryMetalinkSignature true
!endif
!define CDInfoFile ".disk\info"
!define HomePageURL "http://archlive.googlecode.com"
!define SupportPageURL "http://archlive.googlecode.com"
!define Publisher "Archlive"
!define BackupFolderName arch-backup
!define DefaultInstallationDir "archlive"
!define MinMemoryMB 128 #min memory size for installation puroposes 256
!define MinSizeMB 3000 #min disk size for installation puroposes 5000
!define ReallyMinSizeMB 0 #min size if booting from ISO 1000
!define cdBootOnly false

!ifdef ${AppSuffix}
    !define AppFullVersion "${AppVersion}-${AppSuffix}"
!else
    !define AppFullVersion "${AppVersion}"
!endif

!if ${cdBootOnly} == true
    !define AppFullName "${AppName}-cdboot-${AppFullVersion}"
!else
    !define AppFullName "${AppName}-${AppFullVersion}"
!endif

!define OutFile "${AppFullName}-rev${AppRevision}.exe"

VIAddVersionKey "ProductName" "${AppName}"
VIAddVersionKey "Comments" "Licenced under GPL version 2 or later"
VIAddVersionKey "LegalTrademarks" "Ubuntu is a trademark of Canonical Ltd."
VIAddVersionKey "LegalCopyright" " Agostino Russo et al., and Canonical Ltd."
VIAddVersionKey "FileDescription" "Windows based UBuntu Installer"
VIAddVersionKey "FileVersion" "${AppFullVersion}"
VIProductVersion "${AppVersion}.${AppSubVersion}.${AppRevision}"
