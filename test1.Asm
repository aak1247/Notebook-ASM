.586
.model flat,stdcall
option casemap:none


   include test1.inc
;******************************************************************************************************
;;软件42  柳亚辉 2141601029
;;本程序为日记本主程序，其功能包括文字的输入、字数统计、词频统计、连击计数(每两次输入之间小于5秒视为一次连击)
;;利用SQLite数据库实现对连击的存储，通过子模块儿存储和输出最大历史连击数、累计输入字数、输入最大字等等
;;通过记录每一次修改的时间完成时间线的功能-待定
;******************************************************************************************************
.data
	ClassName db "MainWinClass",0
	AppName  db "TEST Window",0
	msgTitle1 db "输入统计",0
	msgContent1 db "本次共完成连击"
	countWords db 20h,20h,20h,30h
		 db "次，打出"
	countComb  db 20h,20h,20h,30h
		 db "字，使用次数最高的字是"
	maxUsedWord db "NULL",0
	maxUsedWordValue db 4 dup(0)               ;4个字节用于存储此值，最大为9999,采用BCD码运算方式进行计算
	ClassName1 db 'WelcomeWindow',0            ;用于显示时间线的区域
	AppName1 db 'show area',0
	EditClass  db "EDIT",0
	
.data?
	hwndEdit dd ?
	OldWndProc dd ?
	hInstance HINSTANCE ?
	CommandLine LPSTR ?
	hWinMain HWND  ?
	hMenu           dd  ?
	curTime dw 4 dup(?)
	org $-8
	curTime_hour dw ?
	curTime_minute dw ?
	curTime_second dw ?
	curTime_nothing dw ?
.const
	szText  db 'welcome to use this diary !',0
	Message  db "You pressed Enter in the text box!",0
	;按钮的变量
	szButton db 'start',0
	szButtonText db 'Start',0
	IDR_MENU1			equ 10000
	IDM_START			equ 10001
	IDM_QUIT			equ 10002
	IDM_SAVE			equ 10003
	IDR_VERSION1			equ 1
  
.code


; ---------------------------------------------------------------------------
;;                                 主程序入口
;**********************************************************************************
start:
	invoke InitCommonControls
	invoke GetModuleHandle, NULL
	mov    hInstance,eax
	
	invoke GetCommandLine
	mov    CommandLine,eax
	invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
;	invoke IncressWords,2
;	invoke MessageBox,NULL,addr msgContent1,addr msgTitle1,MB_OK
	invoke ExitProcess,eax

;;                                
;*******************************************************************************
;;                                 主窗口
;**********************************************************************************
WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL wc:WNDCLASSEX
	LOCAL msg:MSG
	LOCAL hwnd:HWND
	LOCAL chilehwnd1:HWND
	invoke RtlZeroMemory,addr wc,sizeof wc ;对内存空间置0
	mov	wc.cbSize,SIZEOF WNDCLASSEX
	mov	wc.style, CS_HREDRAW or CS_VREDRAW
	mov	wc.lpfnWndProc, OFFSET WndProc
	mov	wc.cbClsExtra,NULL
	mov	wc.cbWndExtra,NULL
	push	hInstance
	pop	wc.hInstance
	mov	wc.hbrBackground,COLOR_BTNFACE+1
	mov	wc.lpszMenuName,NULL
	mov	wc.lpszClassName,OFFSET ClassName
	mov	wc.cbSize,sizeof WNDCLASSEX  
	invoke LoadIcon,NULL,IDI_APPLICATION
	mov   wc.hIcon,eax
	mov   wc.hIconSm,eax
	
	invoke LoadCursor,NULL,IDC_ARROW
	mov   wc.hCursor,eax
	
	;-------------[Regist Window]-------------  
        invoke RegisterClassEx,addr wc 
        ;------------[Load Menu]------------------  
        invoke LoadMenu,hInst,IDR_MENU1  
        mov hMenu,eax      
	
	invoke RegisterClassEx, addr wc
	invoke CreateWindowEx,WS_EX_CLIENTEDGE,ADDR ClassName,ADDR AppName,\
           WS_POPUP,100,100,600,600,NULL,hMenu,\
           hInst,NULL
	mov   hwnd,eax
	
	invoke ShowWindow, hwnd,SW_SHOWNORMAL
	invoke UpdateWindow, hwnd
	

	.WHILE TRUE
	;{
		invoke GetMessage, ADDR msg,NULL,0,0
		.BREAK .IF (!eax)
		invoke TranslateMessage, ADDR msg
		invoke DispatchMessage, ADDR msg
	.ENDW
	;}
	
	mov     eax,msg.wParam
	ret
WinMain endp



;****************************************************************************************
;;                                 其他函数
;------------------------------------------------------------------------------------
;修改当前连击数和字数和最频繁使用单词
IncressWords proc uses ax edi addedWords:Byte   ;增加字数
	;先判断传入参数的位数
	;再对数据进行处理
	mov edi,offset countWords
	
	mov al,addedWords
	add byte ptr [edi+2],al
	ret
IncressWords endp

IncressComb proc uses edi eax ebx ecx edx                       ;增加连击数
	LOCAL @stTime: SYSTEMTIME
	invoke  GetLocalTime,addr @stTime
	lea edi, curTime
	mov eax, 0
	mov ecx, 0
   	mov ebx, 60
   	mov ax,@stTime.wHour
   	sub ax,[edi]
   	imul bx
   	mov ecx, eax
   	mov eax, 0
   	
   	
   	add ax,@stTime.wMinute
   	sub ax,[edi+2]
   	add eax, ecx
   	imul bx
   	mov ecx, eax
   	mov eax, 0
   	mov ax, @stTime.wSecond
   	add ecx,eax
   	mov ax, [edi+4]
   	sub ecx, eax
   	.if ecx < 31
   		mov edi,offset countComb
   		inc byte ptr[edi+3]
   		mov ax,[edi+3]
   		.if ax > 39h
   			add
   		.endif	
   	.endif
	ret
IncressComb endp

UpdateWord proc ;uses eax,ebx,ecx,edi
	
	
	ret

UpdateWord endp

;===========================记录上一次操作时间
Update_curTime proc
	LOCAL @stTime:SYSTEMTIME
	push eax
	push edx
	push ebx
	invoke  GetLocalTime,addr @stTime
	lea esi, curTime
	mov ax,@stTime.wHour
	mov [esi], ax
	mov ax, @stTime.wMinute
	mov [esi+2], ax
	mov ax, @stTime.wSecond
	mov [esi+4], ax
	mov ax,@stTime.wMilliseconds
	mov [esi+6], ax
	
	mov eax,0
	mov ebx,60
	mov ax,@stTime.wMinute
	mul bx
	add ax,@stTime.wSecond
	mul bx
	add ax,@stTime.wMilliseconds
	pop ebx
	pop edx
	pop eax
	ret
Update_curTime endp


;------------------------------------------------------------------------------------



;***************************************************************************************
;;                              主窗口消息处理函数
;***************************************************************************************
WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local @stTime:SYSTEMTIME
	local @stPs:PAINTSTRUCT
	local @stRect:RECT
  	local @hDc
	
	
  	mov eax,uMsg
;********************************************************************
  	.if eax == WM_PAINT
   		invoke BeginPaint,hWnd,addr @stPs
   		mov @hDc,eax

   		invoke GetClientRect,hWnd,addr @stRect
   		invoke DrawText,@hDc,addr szText,-1,\
    			addr @stRect,\
    			DT_SINGLELINE or DT_CENTER or DT_VCENTER
		
   		invoke EndPaint,hWnd,addr @stPs
;********************************************************************
   	.elseif eax == WM_CREATE
		call Update_curTime                   ;;      初始化计时，用于计算是否连击
		
;;==========================================================================================
	        invoke CreateWindowEx,WS_EX_CLIENTEDGE,ADDR EditClass,NULL,\                ;创建输入框
           	WS_CHILD+WS_VISIBLE+WS_BORDER,0,20,600,580,hWnd,NULL,\
            	hInstance,NULL
        	mov hwndEdit,eax
        	invoke SetFocus,eax
        ;-----------------------------------------
        ; 		子类化
        ;-----------------------------------------
        	invoke SetWindowLong,hwndEdit,GWL_WNDPROC,addr EditWndProc
        	mov OldWndProc,eax
		
		
;;       生成Button按钮的语句，按钮用于调用子模块儿
   		invoke CreateWindowEx,NULL,\
    			offset szButton,offset szButtonText,\
    			WS_CHILD or WS_VISIBLE,\
    			10,10,65,22,\	
     			hWnd,1,hInstance,NULL
     		;invoke LoadMenu, hWnd, IDR_MENU1
     		
;********************************************************************
;         响应鼠标和键盘控制
	.elseif eax == WM_COMMAND
		mov eax,wParam
		;invoke MessageBox,NULL,addr msgContent1,addr msgTitle1,MB_OK
		.if ax == IDM_QUIT
			invoke MessageBox,NULL,addr msgContent1,addr msgTitle1,MB_OK
			invoke DestroyWindow, hWinMain
			invoke PostQuitMessage,NULL
		.elseif ax == IDM_START
			invoke IncressWords,2
		.elseif ax == IDM_SAVE
			;====================保存文件
			;invoke 
		.endif		
		





;********************************************************************
  	.elseif eax == WM_CLOSE ;窗口关闭事件
   		invoke DestroyWindow,hWinMain
   		invoke PostQuitMessage,NULL
;********************************************************************
  	.else
   		invoke DefWindowProc,hWnd,uMsg,wParam,lParam
   		ret
;         消息的默认处理
  	.endif
;********************************************************************
  	xor eax,eax
  	ret
WndProc endp


EditWndProc PROC hEdit:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
    .if uMsg==WM_CHAR
        mov eax,wParam
            call IncressComb
       	    call Update_curTime
       	    invoke IncressWords,2
            invoke CallWindowProc,OldWndProc,hEdit,uMsg,eax,lParam
            ret
    .elseif uMsg==WM_KEYDOWN
    	call IncressComb
       	call Update_curTime
        mov eax,wParam
        .if al==VK_RETURN
            invoke MessageBox,hEdit,addr Message,addr AppName,MB_OK+MB_ICONINFORMATION
            ;===============此处应修改光标位置=============
            invoke SetFocus,hEdit
        .else
            invoke CallWindowProc,OldWndProc,hEdit,uMsg,wParam,lParam
            ret
        .endif
    .else
        invoke CallWindowProc,OldWndProc,hEdit,uMsg,wParam,lParam
        ret
    .endif
    xor eax,eax
    ret
EditWndProc endp


end start
