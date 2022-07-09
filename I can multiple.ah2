#SingleInstance force
ListLines 0
KeyHistory 0
SendMode "Input" ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir ; Ensures a consistent starting directory.

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

just_SHOpenFolderAndSelectItems.RegisterDirectory("C:\dir1", callback)
just_SHOpenFolderAndSelectItems.RegisterDirectory("C:\dir2", callback)

return

f3::Exitapp