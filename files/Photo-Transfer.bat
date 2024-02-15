::Florida Memory Photo Search
:: See instructions pdf for information about usage
::This bat will search an invoice or list of file ids and copy the files that are already on the cloud to a new directory and  generate a list of items that are not yet located on the cloud

@echo off
setlocal enabledelayedexpansion

:: Set the server location
set "SERVER_LOCATION=\\dosshares1\FloridaMemory"

:: Set the Photo Masters directory location
set "PHOTO_MASTERS_DIR=%SERVER_LOCATION%\Photo Masters"

:: Set the Photo Orders directory location
set "PHOTO_ORDERS_DIR=%SERVER_LOCATION%\Photo Orders"

:: Set the Florida Maps directory location
set "FLORIDA_MAPS_LOCATION=\\dosshares1\FlMemory03\Collections\State Library Collection - Florida Map Collection"

:: Set the input file path
set "input_file=%PHOTO_ORDERS_DIR%\invoice-data.txt"

::Intro text
echo.
echo *********************************************
echo ******** Florida Memory Photo Search ********
echo *********************************************

echo.
echo Current mode: Copy invoice items and create a document of items that are not yet on the cloud

echo.

:: Extract the invoice number from the input file
for /f "tokens=2" %%a in ('type "%input_file%" ^| find /i "Invoice #"') do (
    set "invoice_number=%%a"
)

if "%invoice_number%"=="" (
    for /f "tokens=2" %%a in ('type "%input_file%" ^| find /i "Order (#"') do (
    set "invoice_number=%%a"
    set "invoice_number=!invoice_number:(=!"
    set "invoice_number=!invoice_number:)=!"
)
)

if "%invoice_number%"=="" (
    for /f "tokens=2" %%a in ('type "%input_file%" ^| find /i "Order #"') do (
    set "invoice_number=%%a"
)
)

:: Check if the invoice # was found. If not throw an error
if "%invoice_number%"=="" (
    echo No invoice number found. Check to make sure invoice-data.txt has a valid invoice number then try running again.
    echo Check Instructions.pdf for detailed instructions.
    echo.
    type nul > "%input_file%"
    echo Press any key to exit
    pause >nul
    exit /b
) else (
    echo Current invoice !invoice_number!
)

echo.

:: Extract image IDs from the input file and store them in a variable
echo Locating item ids...
set "img_ids="
for /f "tokens=1,* delims=: " %%a in ('type "%input_file%" ^| find /i "Image Number:"') do (
    set "img_id=%%b"
    set "img_id=!img_id:Image Number: =!"
    set "img_ids=!img_ids! !img_id!"
    echo !img_id!
)

:: Extract map IDs from the input file and store them in a variable
set "map_ids="
for /f "tokens=1,* delims=: " %%a in ('type "%input_file%" ^| find /i "Map Number:"') do (
    set "map_id=%%b"
    set "map_id=!map_id:Map Number: =!"
    set "map_ids=!map_ids! !map_id!"
    echo !map_id!
)
     if defined img_ids if defined map_ids (
    set "located_file_ids=%img_ids% %map_ids%"
    )
     if defined img_ids if not defined map_ids (
     set "located_file_ids=%img_ids%"
    )
         if defined map_ids if not defined img_ids (
     set "located_file_ids=%map_ids%"
    )

    if not defined map_ids if not defined img_ids (
      for /f "tokens=1,* delims=." %%a in ('type "%input_file%" ^| findstr /v /i "Invoice #"') do (
            set "located_file_id=%%a"
            set "located_file_ids=!located_file_ids! !located_file_id!"
            echo !located_file_id!
        )
    )

    echo.

:: Clear the content of the invoice-data.txt file
type nul > "%input_file%"

:: check to see if any invoice #s found
if "%located_file_ids%"=="" (
    echo No image numbers found. Check to make sure invoice-data.txt has a valid copied invoice form or a list of file items to search for. Check the help.txt form in the Photo Orders folder for more information.
    echo.
    echo Press any key to exit
    pause >nul
    exit /b
)

:: Check if the "Photo Masters" directory exists
if not exist "%PHOTO_MASTERS_DIR%" (
    echo Unable to locate the Photo Masters directory. Double check to make sure the directory exists and that it is set to the correct file path in the Photo-Search.bat file. It is currently searching at %PHOTO_MASTERS_DIR%.
    echo.
    echo Press any key to exit
    pause >nul
    exit /b
)

:: Check if the "Photo Orders" directory exists
if not exist "%PHOTO_ORDERS_DIR%" (
    echo Unable to locate the Photo Orders directory. Double check to make sure the directory exists and that it is set to the correct file path in the Photo-Search.bat file. It is currently set to %PHOTO_ORDERS_DIR%.
    echo.
    echo Press any key to exit
    pause >nul
    exit /b
)

:: Check if the "Photo Orders" directory exists
if not exist "%FLORIDA_MAPS_LOCATION%" (
    echo Unable to locate the Florida Maps directory. Double check to make sure the directory exists and that it is set to the correct file path in the Photo-Search.bat file. It is currently set to %FLORIDA_MAPS_LOCATION%.
    echo.
    echo Press any key to exit
    pause >nul
    exit /b
)

:: Set the resulting directory name using the invoice number and timestamp
set TIMESTAMP=%DATE:/=-%_%TIME::=-%
set TIMESTAMP=%TIMESTAMP: =%
set RESULTING_DIR_NAME=%invoice_number%__%TIMESTAMP%

:: Set the path for the failed transfers file
set "TRANSFER_RESULTS_DIR=%PHOTO_ORDERS_DIR%\transfer_results"
set "RESULTING_DIR=%TRANSFER_RESULTS_DIR%\%RESULTING_DIR_NAME%"
set "NOT_ON_CLOUD_FILE=%RESULTING_DIR%\not-on-cloud.txt"

echo Creating new folder: transfer-results\!RESULTING_DIR_NAME!
echo.
:: Generating directory for copied files
mkdir "%RESULTING_DIR%"
mkdir "%RESULTING_DIR%\copied_images"
set "COPIED_IMAGES_DIR=%RESULTING_DIR%\copied_images"
echo. > "%NOT_ON_CLOUD_FILE%"

echo Searching for files...

:: Store the remaining located_file_ids
set "remaining_ids=%located_file_ids%"

:: Loop for Florida Maps directory
for %%i in (%located_file_ids%) do (
    dir /s /b "%FLORIDA_MAPS_LOCATION%\*%%i*" 2>nul | findstr /r /c:".*" > nul && (
        for /r "%FLORIDA_MAPS_LOCATION%" %%f in (*%%i*) do (
            if not "%%~xf"==".md5" (
                if not exist "%COPIED_IMAGES_DIR%\%%~nxf" (
                    copy "%%f" "%COPIED_IMAGES_DIR%" > nul 2>&1 && (
                        set "filePath=%%f"
                        setlocal enabledelayedexpansion
                        echo !filePath:*FloridaMemory\=!
                        endlocal
                    ) || (
                        echo %%f -- File located but failed to transfer
                    )
                )
            )
        )
        set "remaining_ids=!remaining_ids:%%i=!"
    )
)

:: Remove processed files from located_file_ids
set "located_file_ids=%remaining_ids%"

:: Loop for Photo Masters directory
for %%i in (%located_file_ids%) do (
    dir /s /b "%PHOTO_MASTERS_DIR%\*%%i*" 2>nul | findstr /r /c:".*" > nul || (
        echo %%i -- File not on cloud
    )
    for /r "%PHOTO_MASTERS_DIR%" %%f in (*%%i*) do (
        if not "%%~xf"==".md5" (
            if not exist "%COPIED_IMAGES_DIR%\%%~nxf" (
                copy "%%f" "%COPIED_IMAGES_DIR%" > nul 2>&1 && (
                    set "filePath=%%f"
                    setlocal enabledelayedexpansion
                    echo !filePath:*FloridaMemory\=!
                    endlocal
                ) || (
                    echo %%f -- File located but failed to transfer
                )
            )
        )
        set "remaining_ids=!remaining_ids:%%i=!"
    )
)

:: Add the remaining located_file_ids to the NOT_ON_CLOUD_FILE all at once
for %%i in (%remaining_ids%) do (
    echo %%i >> "%NOT_ON_CLOUD_FILE%"
)

popd

echo.

echo Clearing invoice-data.txt...
echo.
echo Search completed.
echo.

echo Press any key to exit

pause >nul

endlocal