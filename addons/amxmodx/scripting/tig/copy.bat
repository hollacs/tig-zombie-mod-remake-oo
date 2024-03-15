@echo off
set source_folder=%cd%\compiled
set destination_folder=%cd%\..\..\plugins

xcopy /y /s "%source_folder%\*.amxx" "%destination_folder%"