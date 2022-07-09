#SingleInstance force
ListLines 0
KeyHistory 0
SendMode "Input" ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir ; Ensures a consistent starting directory.

; HKEY_CLASSES_ROOT\Folder\shell\bruh\command
; "C:\my_programs\AutoHotkey_2.0-beta.3\AutoHotkey64.exe" "C:\for registry (single).ah2" "%1 "

; my workaround:
; "%1 "
; instead of
; "%1"
; https://stackoverflow.com/questions/41607045/why-does-trailing-backslash-followed-by-quote-behave-so-strangely-in-cmd
; SubStr(A_Args[1], 1, -1)

; or else
; -> actual_SHOpenFolderAndSelectItems("C:", ["a.txt"])
; will fail

#Include %A_LineFile%\..\lib\just_SHOpenFolderAndSelectItems.ah2
just_SHOpenFolderAndSelectItems.init()

callback(normalized_dir_fullPath, childNamesArr) {
    toPrint:=normalized_dir_fullPath "`n`n["
    for k, v in childNamesArr {
        if (k > 1) {
            toPrint.=", "
        }
        toPrint.="`"" v "`""
    }
    toPrint.="]"
    A_Clipboard:=toPrint
    MsgBox toPrint
}

just_SHOpenFolderAndSelectItems.RegisterDirectory(SubStr(A_Args[1], 1, -1), callback)

return

f3::Exitapp