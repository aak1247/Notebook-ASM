;.586

;.model flat,stdcall

option casemap:none

	include windows.inc
	include user32.inc
	include kernel32.inc
	include comctl32.inc
	include comdlg32.inc
	include debug.inc
	include winmm.inc
	includelib winmm.lib
	includelib user32.lib
	includelib kernel32.lib
	includelib comctl32.lib
	includelib comdlg32.lib
	includelib debug.lib
;================================原型声明
	WinMain proto :DWORD,:DWORD,:DWORD,:DWORD
	_CreateWnd proto  :DWORD,:DWORD,:DWORD,:DWORD
	EditWndProc proto :DWORD,:DWORD,:DWORD,:DWORD
	_StrLen proto :DWORD
	_ThreadProc proto
	sqlInsert proto
	sqlExc  proto :DWORD
	sqlcallback  proto :DWORD,:DWORD,:DWORD,:DWORD
	initSql  proto
	formatComb proto
	formatWords proto
	changeKeySound proto
	playKeySound proto
;========================================
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;SQLite相关函数指针定义
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
sql_open  typedef proto :dword,:dword
SQL_Open  typedef ptr   sql_open

sql_close typedef proto :dword
SQL_Close typedef ptr   sql_close

callback  typedef proto :dword,:dword,:dword,:dword
CallBack  typedef ptr   callback

sql_exec  typedef proto :dword,:dword,:CallBack,:dword,:dword
SQL_Exec  typedef ptr   sql_exec

sql_slct  typedef proto :dword,:dword,:dword,:dword,:dword,:dword
SQL_Slct  typedef ptr   sql_slct
.code


