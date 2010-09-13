@ECHO OFF

IF NOT EXIST %~d0\liberte\liberte.tag GOTO baddir

ECHO Installing SYSLINUX on %~d0, optionally with bootloader.
%~d0\liberte\boot\syslinux\syslinux.exe -m -a -d /liberte/boot/syslinux %~d0

IF ERRORLEVEL 0 ECHO Success!
GOTO end

:baddir
ECHO The directory "%~pd0" should be located at the root of a removable disk.

:end
PAUSE
