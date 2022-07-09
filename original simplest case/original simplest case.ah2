#SingleInstance force
ListLines 0
KeyHistory 0
SendMode "Input" ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir ; Ensures a consistent starting directory.

; dir_fullPath:="C:\dir1"
; dir_fullPath:="C:\dir2"
; dir_fullPath:="C:\"

; HKEY_CLASSES_ROOT\Folder\shell\bruh\command
; "C:\my_programs\AutoHotkey_2.0-beta.3\AutoHotkey64.exe" "C:\original simplest case.ah2" "%1 "

; my workaround:
; "%1 "
; instead of
; "%1"
; https://stackoverflow.com/questions/41607045/why-does-trailing-backslash-followed-by-quote-behave-so-strangely-in-cmd
; SubStr(A_Args[1], 1, -1)

; or else
; -> actual_SHOpenFolderAndSelectItems("C:", ["a.txt"])
; will fail

dir_fullPath:=SubStr(A_Args[1], 1, -1)
; MsgBox dir_fullPath
dir_PIDL:=path_to_PIDL(dir_fullPath)
; MsgBox PIDL_to_path(dir_PIDL)
; ExitApp
; return
; sleep 5000

IID_IShellWindows := "{85CB6900-4D95-11CF-960C-0080C7F4EE85}"
CLSID_ShellWindows := "{9BA05972-F6A8-11CF-A442-00A0C90A8F39}"
m_shellWindows:=ComObject(CLSID_ShellWindows , IID_IShellWindows)

; QueryInterface 0
; AddRef 1
; Release 2
; GetTypeInfoCount 3
; GetTypeInfo 4
; GetIDsOfNames 5
; Invoke 6
; get_Count 7
; Item 8
; _NewEnum 9
; Register 10
; RegisterPending 11
; Revoke 12
; OnNavigate 13
; OnActivated 14
; FindWindowSW 15
; OnCreated 16
; ProcessAttachDetach 17
VT_EMPTY := 0
VT_NULL := 1
VT_VARIANT := 0xC
VT_BYREF := 0x4000
SWC_BROWSER := 0x1



; MsgBox NumGet(dir_PIDL, "0", "Ushort")

size_dir_PIDL:= DllCall("Shell32\ILGetSize"
    ,"Ptr",dir_PIDL
)

; MsgBox A_Clipboard:=readPtrStartEnd(dir_PIDL, 0, 20)

pvar:=Buffer(24, 0)
HRESULT:=DllCall("Propsys\InitVariantFromBuffer"
    ,"Ptr",dir_PIDL
    ,"Uint",size_dir_PIDL
    ,"Ptr",pvar
)
; MsgBox NumGet(pvar, "0", "Ushort")
; MsgBox Format("0x{:016X}", NumGet(pvar, 8, "Ptr"))

; MsgBox readPtrStartEnd(pvar,0,24) "`n" readPtrStartEnd(wow.Ptr,0,24)

HRESULT:=ComCall(11, m_shellWindows
    ,"int", DllCall("GetCurrentThreadId")
    ,"Ptr", pvar
    ,"Ptr", Buffer(24,0) ;VARIANT VT_EMPTY
    ,"int", SWC_BROWSER
    ,"int*", &m_shellWindowCookie:=0
)
; MsgBox m_shellWindowCookie

ret_not_implemented(context) {
    MsgBox "this should never happen"
    return 0x80004001 ;E_NOTIMPL
}
Address_ret_not_implemented := CallbackCreate(ret_not_implemented, "F")

IShellView_QueryInterface(this, riid, ppvObject) { ;https://www.autohotkey.com/boards/viewtopic.php?t=36025&start=20#p176225
    if (!ppvObject) {
        return 0x80070057 ;E_INVALIDARG
    }

    map1:=Map(
        "{00000000-0000-0000-C000-000000000046}",1, ;IUnknown
        "{00000114-0000-0000-C000-000000000046}",1, ;IOleWindow
        "{000214E3-0000-0000-C000-000000000046}",1, ;IShellView
    )

    str_riid:=pGUID_to_string(riid)
    if (map1.Has(str_riid)) {
        NumPut("Ptr", this, ppvObject, 0)
        IShellView_AddRef(this)
        return 0 ;S_OK
    }
    ; *ppvObject = NULL;
    NumPut("Ptr", 0, ppvObject, 0)
    return 0x80004002 ;E_NOINTERFACE
}
IShellView_AddRef(this) {
    global childNamesArr
    refCount:=NumGet(this, A_PtrSize, "UInt")
    refCount++
    NumPut("UInt", refCount, this, A_PtrSize)
    if (refCount==1) {
        childNamesArr:=[]
    }
    return refCount
}
IShellView_Release(this) {
    global childNamesArr
    refCount:=NumGet(this, A_PtrSize, "UInt")
    refCount--
    NumPut("UInt", refCount, this, A_PtrSize)
    if (refCount==0) {
        toPrint:="["
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
    return refCount
}

DllCall("Shell32\SHGetDesktopFolder", "Ptr*",&ppshf:=0)
; QueryInterface 0
; AddRef 1
; Release 2
; ParseDisplayName 3
; EnumObjects 4
; BindToObject 5
; BindToStorage 6
; CompareIDs 7
; CreateViewObject 8
; GetAttributesOf 9
; GetUIObjectOf 10
; GetDisplayNameOf 11
; SetNameOf 12
HRESULT:=ComCall(3,ppshf
    ,"Ptr",A_ScriptHwnd
    ,"Ptr",0
    ,"WStr",dir_fullPath
    ,"Uint*",0
    ,"Ptr*",&ppidl_relative:=0
    ,"Uint*",0
)
HRESULT:=ComCall(5,ppshf
    ,"Ptr",ppidl_relative
    ,"Ptr",0
    ,"Ptr",string_to_bufGUID("{000214E6-0000-0000-C000-000000000046}")
    ,"Ptr*",&dir_ppshf:=0
)
; MsgBox dir_ppshf
; MsgBox ppidl_relative
; dir_fullPath
IShellView_SelectItem(this, pidlItem, flags) {
    global dir_ppshf, childNamesArr
    ; https://github.com/microsoft/wil/blob/5eb59d60e167482639cc47ffb40442158da7fd04/include/wil/common.h#L347
    SVSI_SELECT:=0x1
    if ((flags & SVSI_SELECT) == SVSI_SELECT) {
        SHGDN_INFOLDER:=0x1
        pName:=Buffer(272)
        HRESULT:=ComCall(11,dir_ppshf
            ,"Ptr",pidlItem
            ,"Uint",0
            ; ,"Ptr*",&pName:=0
            ,"Ptr",pName
        )
        DllCall("Shlwapi\StrRetToStrW"
            ,"Ptr",pName
            ,"Ptr",pidlItem
            ,"WStr*",&ppsz:=0
        )
        childNamesArr.Push(ppsz)
        return 0 ;S_OK
    }
    return 0x80004001 ;E_NOTIMPL
}
; QueryInterface 0
; AddRef 1
; Release 2
; GetWindow 3
; ContextSensitiveHelp 4
; TranslateAccelerator 5
; EnableModeless 6
; UIActivate 7
; Refresh 8
; CreateViewWindow 9
; DestroyViewWindow 10
; GetCurrentInfo 11
; AddPropertySheetPages 12
; SaveViewState 13
; SelectItem 14
; GetItemObject 15
IShellView_vtable_methodCount:=16
IShellView_vtable:=Buffer(IShellView_vtable_methodCount*A_PtrSize)
loop IShellView_vtable_methodCount {
    NumPut("Ptr", CallbackCreate(ret_not_implemented.Bind(A_Index-1)), IShellView_vtable, (A_Index-1)*A_PtrSize)
}
NumPut("Ptr", CallbackCreate(IShellView_QueryInterface), IShellView_vtable, 0*A_PtrSize)
NumPut("Ptr", CallbackCreate(IShellView_AddRef), IShellView_vtable, 1*A_PtrSize)
NumPut("Ptr", CallbackCreate(IShellView_Release), IShellView_vtable, 2*A_PtrSize)
NumPut("Ptr", CallbackCreate(IShellView_SelectItem), IShellView_vtable, 14*A_PtrSize)

IShellView:=Buffer(A_PtrSize + 4)
NumPut("Ptr", IShellView_vtable.Ptr, IShellView, 0)
NumPut("Uint", 0, IShellView, A_PtrSize) ;refCount

DocumentServiceProvider_IServiceProvider_QueryInterface(this, riid, ppvObject) { ;https://www.autohotkey.com/boards/viewtopic.php?t=36025&start=20#p176225
    if (!ppvObject) {
        return 0x80070057 ;E_INVALIDARG
    }

    str_IID_IUnknown:="{00000000-0000-0000-C000-000000000046}"
    str_IID_IServiceProvider:="{6D5140C1-7436-11CE-8034-00AA006009FA}"

    str_IID_IDispatch:="{00020400-0000-0000-C000-000000000046}"

    str_riid:=pGUID_to_string(riid)

    if (str_riid==str_IID_IUnknown || str_riid==str_IID_IServiceProvider) {
        NumPut("Ptr", this, ppvObject, 0)
        DocumentServiceProvider_IServiceProvider_AddRef(this)
        return 0 ;S_OK
    }
    if (str_riid==str_IID_IDispatch) {
        NumPut("Ptr", this + A_PtrSize, ppvObject, 0)
        DocumentServiceProvider_IServiceProvider_AddRef(this)
        return 0 ;S_OK
    }
    ; *ppvObject = NULL;
    NumPut("Ptr", 0, ppvObject, 0)
    return 0x80004002 ;E_NOINTERFACE
}
DocumentServiceProvider_IServiceProvider_AddRef(this) {
    refCount:=NumGet(this, 2*A_PtrSize, "UInt")
    refCount++
    NumPut("UInt", refCount, this, 2*A_PtrSize)
    return refCount
}
DocumentServiceProvider_IServiceProvider_Release(this) {
    refCount:=NumGet(this, 2*A_PtrSize, "UInt")
    refCount--
    NumPut("UInt", refCount, this, 2*A_PtrSize)
    return refCount
}
DocumentServiceProvider_IServiceProvider_QueryService(this, guidService, riid, ppv) {
    global IShellView
    str_IID_IFolderView:="{CDE725B0-CCC9-4519-917E-325D72FAB4CE}"
    str_guidService:=pGUID_to_string(guidService)
    if (str_guidService !== str_IID_IFolderView) {
        MsgBox "we have some trouble.."
    }
    str_riid:=pGUID_to_string(riid)
    return IShellView_QueryInterface(IShellView.Ptr, riid, ppv)
}

; QueryInterface 0
; AddRef 1
; Release 2
; QueryService 3
DocumentServiceProvider_IServiceProvider_vtable:=Buffer(4*A_PtrSize)
NumPut("Ptr", CallbackCreate(DocumentServiceProvider_IServiceProvider_QueryInterface), DocumentServiceProvider_IServiceProvider_vtable, 0*A_PtrSize)
NumPut("Ptr", CallbackCreate(DocumentServiceProvider_IServiceProvider_AddRef), DocumentServiceProvider_IServiceProvider_vtable, 1*A_PtrSize)
NumPut("Ptr", CallbackCreate(DocumentServiceProvider_IServiceProvider_Release), DocumentServiceProvider_IServiceProvider_vtable, 2*A_PtrSize)
NumPut("Ptr", CallbackCreate(DocumentServiceProvider_IServiceProvider_QueryService), DocumentServiceProvider_IServiceProvider_vtable, 3*A_PtrSize)

DocumentServiceProvider_IDispatch_QueryInterface(this, riid, ppvObject) {
    return DocumentServiceProvider_IServiceProvider_QueryInterface(this - A_PtrSize, riid, ppvObject)
}
DocumentServiceProvider_IDispatch_AddRef(this) {
    return DocumentServiceProvider_IServiceProvider_AddRef(this - A_PtrSize)
}
DocumentServiceProvider_IDispatch_Release(this) {
    return DocumentServiceProvider_IServiceProvider_Release(this - A_PtrSize)
}
; QueryInterface 0
; AddRef 1
; Release 2
; GetTypeInfoCount 3
; GetTypeInfo 4
; GetIDsOfNames 5
; Invoke 6
DocumentServiceProvider_IDispatch_vtable:=Buffer(7*A_PtrSize)
NumPut("Ptr", CallbackCreate(DocumentServiceProvider_IDispatch_QueryInterface), DocumentServiceProvider_IDispatch_vtable, 0*A_PtrSize)
NumPut("Ptr", CallbackCreate(DocumentServiceProvider_IDispatch_AddRef), DocumentServiceProvider_IDispatch_vtable, 1*A_PtrSize)
NumPut("Ptr", CallbackCreate(DocumentServiceProvider_IDispatch_Release), DocumentServiceProvider_IDispatch_vtable, 2*A_PtrSize)
NumPut("Ptr", CallbackCreate(ret_not_implemented), DocumentServiceProvider_IDispatch_vtable, 3*A_PtrSize)
NumPut("Ptr", CallbackCreate(ret_not_implemented), DocumentServiceProvider_IDispatch_vtable, 4*A_PtrSize)
NumPut("Ptr", CallbackCreate(ret_not_implemented), DocumentServiceProvider_IDispatch_vtable, 5*A_PtrSize)
NumPut("Ptr", CallbackCreate(ret_not_implemented), DocumentServiceProvider_IDispatch_vtable, 6*A_PtrSize)

DocumentServiceProvider:=Buffer(2*A_PtrSize + 4)
NumPut("Ptr", DocumentServiceProvider_IServiceProvider_vtable.Ptr, DocumentServiceProvider, 0)
NumPut("Ptr", DocumentServiceProvider_IDispatch_vtable.Ptr, DocumentServiceProvider, A_PtrSize)
NumPut("Uint", 0, DocumentServiceProvider, 2*A_PtrSize) ;refCount

WebBrowserApp_QueryInterface(this, riid, ppvObject) { ;https://www.autohotkey.com/boards/viewtopic.php?t=36025&start=20#p176225
    if (!ppvObject) {
        return 0x80070057 ;E_INVALIDARG
    }

    map1:=Map(
        "{00000000-0000-0000-C000-000000000046}",1, ;IUnknown
        "{00020400-0000-0000-C000-000000000046}",1, ;IDispatch
        "{EAB22AC1-30C1-11CF-A7EB-0000C05BAE0B}",1, ;IWebBrowser
        "{0002DF05-0000-0000-C000-000000000046}",1, ;IWebBrowserApp
    )

    str_riid:=pGUID_to_string(riid)
    if (map1.Has(str_riid)) {
        NumPut("Ptr", this, ppvObject, 0)
        WebBrowserApp_AddRef(this)
        return 0 ;S_OK
    }
    ; *ppvObject = NULL;
    NumPut("Ptr", 0, ppvObject, 0)
    return 0x80004002 ;E_NOINTERFACE
}
WebBrowserApp_AddRef(this) {
    refCount:=NumGet(this, A_PtrSize, "UInt")
    refCount++
    NumPut("UInt", refCount, this, A_PtrSize)
    return refCount
}
WebBrowserApp_Release(this) {
    refCount:=NumGet(this, A_PtrSize, "UInt")
    refCount--
    NumPut("UInt", refCount, this, A_PtrSize)
    return refCount
}
WebBrowserApp_get_Document(this, dispatch) {
    global DocumentServiceProvider
    ; MsgBox dispatch
    ; MsgBox DocumentServiceProvider.Ptr
    DocumentServiceProvider_IServiceProvider_AddRef(DocumentServiceProvider.Ptr)
    ; NumPut("Ptr",DocumentServiceProvider.Ptr,dispatch,0)
    NumPut("Ptr",DocumentServiceProvider.Ptr + A_PtrSize,dispatch,0)
    return 0 ;S_OK
}
WebBrowserApp_get_HWND(this, hwnd) {
    NumPut("Ptr",A_ScriptHwnd,hwnd,0)
    return 0 ;S_OK
}

browserApp_vtable_methodCount:=52
; QueryInterface 0
; AddRef 1
; Release 2
; GetTypeInfoCount 3
; GetTypeInfo 4
; GetIDsOfNames 5
; Invoke 6
; GoBack 7
; GoForward 8
; GoHome 9
; GoSearch 10
; Navigate 11
; Refresh 12
; Refresh2 13
; Stop 14
; get_Application 15
; get_Parent 16
; get_Container 17
; get_Document 18
; get_TopLevelContainer 19
; get_Type 20
; get_Left 21
; put_Left 22
; get_Top 23
; put_Top 24
; get_Width 25
; put_Width 26
; get_Height 27
; put_Height 28
; get_LocationName 29
; get_LocationURL 30
; get_Busy 31
; Quit 32
; ClientToWindow 33
; PutProperty 34
; GetProperty 35
; get_Name 36
; get_HWND 37
; get_FullName 38
; get_Path 39
; get_Visible 40
; put_Visible 41
; get_StatusBar 42
; put_StatusBar 43
; get_StatusText 44
; put_StatusText 45
; get_ToolBar 46
; put_ToolBar 47
; get_MenuBar 48
; put_MenuBar 49
; get_FullScreen 50
; put_FullScreen 51
browserApp_vtable:=Buffer(browserApp_vtable_methodCount*A_PtrSize)
loop browserApp_vtable_methodCount {
    ; NumPut("Ptr", Address_ret_not_implemented, browserApp_vtable, (A_Index-1)*A_PtrSize)
    NumPut("Ptr", CallbackCreate(ret_not_implemented.Bind(A_Index-1)), browserApp_vtable, (A_Index-1)*A_PtrSize)
}
NumPut("Ptr", CallbackCreate(WebBrowserApp_QueryInterface), browserApp_vtable, 0*A_PtrSize)
NumPut("Ptr", CallbackCreate(WebBrowserApp_AddRef), browserApp_vtable, 1*A_PtrSize)
NumPut("Ptr", CallbackCreate(WebBrowserApp_Release), browserApp_vtable, 2*A_PtrSize)
NumPut("Ptr", CallbackCreate(WebBrowserApp_get_Document), browserApp_vtable, 18*A_PtrSize)
NumPut("Ptr", CallbackCreate(WebBrowserApp_get_HWND), browserApp_vtable, 37*A_PtrSize)

; MsgBox readPtrStartEnd(browserApp_vtable, 0, browserApp_vtable_methodCount*A_PtrSize)
browserApp:=Buffer(A_PtrSize + 4)
NumPut("Ptr", browserApp_vtable.Ptr, browserApp, 0)
NumPut("Uint", 0, browserApp, A_PtrSize) ;refCount

HRESULT:=ComCall(10, m_shellWindows
    ,"Ptr", browserApp
    ,"int", A_ScriptHwnd
    ; ,"int", myGui.Hwnd
    ,"int", SWC_BROWSER
    ,"int*", &registeredCookie:=0
)

; MsgBox m_shellWindowCookie ", " registeredCookie

HRESULT:=ComCall(13, m_shellWindows
    ,"int",registeredCookie
    ,"Ptr",pvar
)
return

path_to_PIDL(fullPath) {
    HRESULT:= DllCall("Shell32\SHParseDisplayName"
        , "Str",fullPath
        , "Ptr",0
        , "Ptr*",&ppidl:=0
        , "Uint",0
        , "Uint*",0
    )
    return ppidl
}
PIDL_to_path(pidl) {
    MAX_PATH:=260
    pszPath:=Buffer(MAX_PATH*2)
    BOOL:=DllCall("Shell32\SHGetPathFromIDListW"
        ,"Ptr",pidl
        ,"Ptr",pszPath
    )
    return StrGet(pszPath)
}

pGUID_to_string(riid) {
    someStr:=Buffer(80)
    DllCall("Ole32\StringFromGUID2", "Ptr", riid, "Ptr",someStr, "Ptr",40)
    str_riid:=StrGet(someStr)
    return str_riid
}
string_to_bufGUID(str_guid) {
    ; "{00000000-0000-0000-0000-000000000000}"
    bufGUID:=Buffer(16)
    HRESULT:=DllCall("Ole32\CLSIDFromString", "WStr",str_guid, "Ptr",bufGUID)
    return bufGUID
}
vtable(ppv, idx)
{
    return NumGet(NumGet(ppv, 0, "Ptr"), idx*A_PtrSize, "Ptr")
}

readPtrStartEnd(ptr, start, end) {
    i_:=start
    if (i_>=end) {
        return ""
    }
    finalStr:=Format("{:02X}", NumGet(ptr, i_, "UChar"))
    i_++
    while (i_<end) {
        finalStr.=" " Format("{:02X}", NumGet(ptr, i_, "UChar"))
        i_++
    }
    return finalStr
}


f3::Exitapp