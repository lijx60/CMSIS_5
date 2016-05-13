:: Batch file for generating CMSIS pack
:: This batch file uses:
::    7-Zip for packaging.
::    goxygen for creating documentation.
:: the generated pack file can be found in folder ../../Local_Release
@ECHO off

SETLOCAL

:: Tool path for zipping tool 7-Zip
SET ZIPPATH=C:\Program Files\7-Zip

:: Tool path for doxygen
SET DOXYGENPATH=C:\Program Files\doxygen\bin

:: Tool path for mscgen utility
SET MSCGENPATH=C:\Program Files (x86)\Mscgen

:: These settings should be passed on to subprocesses as well
SET PATH=%ZIPPATH%;%DOXYGENPATH%;%MSCGENPATH%;%PATH%

:: Pack Path (where generated pack is stored)
SET RELEASE_PATH=..\..\Local_Release


:: Remove previous build
IF EXIST %RELEASE_PATH% (
  ECHO removing %RELEASE_PATH%
  RMDIR /Q /S  %RELEASE_PATH%
)

:: Create build output directory
MKDIR %RELEASE_PATH%

:: Copy PDSC file
COPY ..\..\ARM.CMSIS.pdsc %RELEASE_PATH%\ARM.CMSIS.pdsc

:: Copy Device folder
XCOPY /Q /S /Y ..\..\Device\*.* %RELEASE_PATH%\Device\*.*

:: Copy CMSIS folder 
:: -- Core files 
XCOPY /Q /S /Y ..\..\CMSIS\Core\Include\*.* %RELEASE_PATH%\CMSIS\Include\*.*

:: -- DAP files 
XCOPY /Q /S /Y ..\..\CMSIS\DAP\*.* %RELEASE_PATH%\CMSIS\DAP\*.*

:: -- Driver files 
XCOPY /Q /S /Y ..\..\CMSIS\Driver\*.* %RELEASE_PATH%\CMSIS\Driver\*.*

:: -- DSP files 
XCOPY /Q /S /Y ..\..\CMSIS\DSP\Include\*.* %RELEASE_PATH%\CMSIS\Include\*.*
XCOPY /Q /S /Y ..\..\CMSIS\DSP\Source\*.*  %RELEASE_PATH%\CMSIS\DSP_Lib\Source\*.*
XCOPY /Q /S /Y ..\..\CMSIS\DSP\Examples\*.*  %RELEASE_PATH%\CMSIS\DSP_Lib\Examples\*.*

:: -- DSP libraries
XCOPY /Q /S /Y ..\..\CMSIS\DSP\Lib\ARM\*.lib %RELEASE_PATH%\CMSIS\Lib\ARM\*.*
XCOPY /Q /S /Y ..\..\CMSIS\DSP\Lib\GCC\*.a   %RELEASE_PATH%\CMSIS\Lib\GCC\*.*

:: -- Pack files 
XCOPY /Q /S /Y ..\..\CMSIS\Pack\Example\*.* %RELEASE_PATH%\CMSIS\Pack\Example\*.*
XCOPY /Q /S /Y ..\..\CMSIS\Pack\Tutorials\*.* %RELEASE_PATH%\CMSIS\Pack\Tutorials\*.*

:: -- RTOS files 
XCOPY /Q /S /Y ..\..\CMSIS\RTOS\Template\*.* %RELEASE_PATH%\CMSIS\RTOS\Template\*.*
XCOPY /Q /S /Y ..\..\CMSIS\RTOS\RTX\*.* %RELEASE_PATH%\CMSIS\RTOS\RTX\*.*

:: -- RTOS2 files 
XCOPY /Q /S /Y ..\..\CMSIS\RTOS2\Template\*.* %RELEASE_PATH%\CMSIS\RTOS2\Template\*.*

:: -- SVD files 
XCOPY /Q /S /Y ..\..\CMSIS\Utilities\ARM_Example.* %RELEASE_PATH%\CMSIS\SVD\*.*

:: -- Utilities files 
XCOPY /Q /S /Y ..\..\CMSIS\Utilities\CMSIS-SVD.xsd %RELEASE_PATH%\CMSIS\Utilities\*.*
XCOPY /Q /S /Y ..\..\CMSIS\Utilities\PACK.xsd      %RELEASE_PATH%\CMSIS\Utilities\*.*
XCOPY /Q /S /Y ..\..\CMSIS\Utilities\PackChk.exe   %RELEASE_PATH%\CMSIS\Utilities\*.*
XCOPY /Q /S /Y ..\..\CMSIS\Utilities\SVDConv.exe   %RELEASE_PATH%\CMSIS\Utilities\*.*
XCOPY /Q /S /Y ..\..\CMSIS\Utilities\SVDConv.linux %RELEASE_PATH%\CMSIS\Utilities\*.*


:: Generate Documentation 
:: -- Generate doxygen files 
PUSHD ..\DoxyGen

:: -- Delete previous generated HTML files
ECHO.
ECHO Delete previous generated HTML files

PUSHD ..\Documentation
FOR %%A IN (Core, DAP, Driver, DSP, General, Pack, RTOS, RTOS2, SVD) DO IF EXIST %%A (RMDIR /S /Q %%A)
POPD

:: -- Generate HTML Files
ECHO.
ECHO Generate HTML Files

pushd Core
doxygen core.dxy
popd

pushd DAP
doxygen dap.dxy
popd

pushd Driver
doxygen Driver.dxy
popd

pushd DSP
doxygen dsp.dxy
popd

pushd General
doxygen general.dxy
popd

pushd Pack
doxygen Pack.dxy
popd

pushd RTOS
doxygen rtos.dxy
popd

pushd RTOS2
doxygen rtos.dxy
popd

pushd SVD
doxygen svd.dxy
popd

:: -- Copy search style sheet
ECHO.
ECHO Copy search style sheets
copy /Y Doxygen_Templates\search.css ..\Documentation\CORE\html\search\. 
copy /Y Doxygen_Templates\search.css ..\Documentation\Driver\html\search\.
REM copy /Y Doxygen_Templates\search.css ..\Documentation\General\html\search\. 
copy /Y Doxygen_Templates\search.css ..\Documentation\Pack\html\search\.
REM copy /Y Doxygen_Templates\search.css ..\Documentation\SVD\html\search\.
copy /Y Doxygen_Templates\search.css ..\Documentation\DSP\html\search\.
copy /Y Doxygen_Templates\search.css ..\Documentation\DAP\html\search\.
  
ECHO.
POPD

:: -- Copy generated doxygen files 
XCOPY /Q /S /Y ..\Documentation\*.* %RELEASE_PATH%\CMSIS\Documentation\*.*

:: -- Remove generated doxygen files
PUSHD ..\Documentation
FOR %%A IN (Core, DAP, Driver, DSP, General, Pack, RTOS, RTOS2, SVD) DO IF EXIST %%A (RMDIR /S /Q %%A)
POPD


:: Checking 
PackChk.exe %RELEASE_PATH%\ARM.CMSIS.pdsc -n %RELEASE_PATH%\PackName.txt -x M353

:: --Check if PackChk.exe has completed successfully
IF %errorlevel% neq 0 GOTO ErrPackChk


:: Packing 
PUSHD %RELEASE_PATH%

:: -- Pipe Pack's Name into Variable
set /p PackName=<PackName.txt
del /q PackName.txt

:: Pack files
7z.exe a %PackName% -tzip
REM MOVE %PackName% ..\
POPD
GOTO End


:ErrPackChk
ECHO PackChk.exe has encountered an error!
EXIT /b

:End
ECHO removing temporary folders
RMDIR /Q /S  %RELEASE_PATH%\CMSIS
RMDIR /Q /S  %RELEASE_PATH%\Device

ECHO PACK generation completed.