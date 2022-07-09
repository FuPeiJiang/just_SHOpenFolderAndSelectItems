need better name than/to replace `just_SHOpenFolderAndSelectItems`, to describe the project<br>

___

https://github.com/derceg/explorerplusplus/commit/67c3687f3012330d802d70028f36968788d80aff

___

add `for registry (single).ah2` to registry
then run `test run SHOpenFolderAndSelectItems.ah2` with your directory paths

HKEY_CLASSES_ROOT\Folder\shell -> (default)<br>
`AnythingYouWant`<br>
HKEY_CLASSES_ROOT\Folder\shell\AnythingYouWant\command -> (default)<br>
`"C:\AutoHotkey_2.0-beta.3\AutoHotkey64.exe" "C:\for registry (single).ah2" "%1 "`
