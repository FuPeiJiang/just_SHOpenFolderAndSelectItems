#SingleInstance force
ListLines 0
KeyHistory 0
SendMode "Input" ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir ; Ensures a consistent starting directory.


actual_SHOpenFolderAndSelectItems("C:", ["a.txt"])
; actual_SHOpenFolderAndSelectItems("C:\dir with spaces\", ["test.ahk", "test3.ah2"])

actual_SHOpenFolderAndSelectItems(dir_fullPath, childNamesArr) {
    DllCall("shell32\SHParseDisplayName"
        ,"Wstr",dir_fullPath
        ,"Uint",0
        ,"Ptr*",&dir_PIDL:=0
        ,"Uint",0
        ,"Uint",0
    )
    DllCall("shell32\SHBindToObject"
        ,"Ptr",0
        ,"Ptr",dir_PIDL
        ,"Ptr",0
        ,"Ptr",string_to_bufGUID("{000214E6-0000-0000-C000-000000000046}") ;IID_IShellFolder
        ,"Ptr*",&pIShellFolder:=0
    )
    length:=childNamesArr.Length
    arr_childPIDL:=Buffer(length*A_PtrSize)
    i_:=0
    while (i_ < length) {
        ;IShellFolder:ParseDisplayName
        ComCall(3, pIShellFolder
            ,"Ptr",0
            ,"Ptr",0
            ,"Wstr",childNamesArr[i_ + 1]
            ,"Uint*",0
            ,"Ptr*",&childPIDL:=0
            ,"Uint*",0
        )
        NumPut("Ptr", childPIDL, arr_childPIDL, i_*A_PtrSize)
        i_++
    }
    DllCall("shell32\SHOpenFolderAndSelectItems"
        ,"Ptr",dir_PIDL
        ,"Uint",length
        ,"Ptr",arr_childPIDL
        ,"Uint",0
    )
}

string_to_bufGUID(str_guid) {
    ; "{00000000-0000-0000-0000-000000000000}"
    bufGUID:=Buffer(16)
    HRESULT:=DllCall("Ole32\CLSIDFromString", "WStr",str_guid, "Ptr",bufGUID)
    return bufGUID
}

return



f3::Exitapp