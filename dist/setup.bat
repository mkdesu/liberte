@ECHO OFF

IF NOT EXIST %~d0\liberte\setup.bat GOTO baddir

ECHO SYSLINUX setup requires administrator privileges for raw disk access.
ECHO If you see a message about MBR update failure below, please
ECHO right-click on the script and select "Run as administrator".
ECHO.

ECHO Installing SYSLINUX on %~d0, optionally with bootloader.
ECHO.
%~d0\liberte\boot\syslinux\syslinux.exe -i -m -a -d /liberte/boot/syslinux %~d0
ECHO.

ECHO Hiding %~d0\liberte and %~d0\otfe directories.
IF NOT EXIST %~d0\otfe MKDIR %~d0\otfe
ATTRIB +H %~d0\liberte
ATTRIB +H %~d0\otfe

GOTO end

:baddir
ECHO %~d0\liberte\setup.bat not found! The directory "%~pd0" should be the
ECHO top-level "liberte" directory of a removable disk.

:end
ECHO.
PAUSE
