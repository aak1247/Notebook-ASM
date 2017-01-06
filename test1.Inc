;.586

;.model flat,stdcall

option casemap:none

   include windows.inc
   include user32.inc
   include kernel32.inc
   include comctl32.inc
   include comdlg32.inc
   
   includelib user32.lib
   includelib kernel32.lib
   includelib comctl32.lib
   includelib comdlg32.lib
   
;================================Ô­ÐÍÉùÃ÷
	WinMain proto :DWORD,:DWORD,:DWORD,:DWORD
	IncressWords proto :BYTE
	
;========================================

.code


