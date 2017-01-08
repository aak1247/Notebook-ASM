.586
.model flat,stdcall
option casemap:none


   include Notebook.inc
;******************************************************************************************************
;;软件42  柳亚辉 2141601029
;;本程序为日记本主程序，其功能包括文字的输入与显示、文件的打开与保存、
;; 字数统计、词频统计、连击计数(每两次输入之间小于2秒视为一次连击)
;;利用SQLite数据库实现对连击的存储，通过子模块儿存储和输出最大历史连击数、累计输入字数、输入最大字等等
;;通过记录每一次修改的时间完成时间线的功能
;******************************************************************************************************
.const
	szText  db 'welcome to use this diary !',0
	Message  db "You pressed Enter in the text box!",0
	;按钮的变量
	szButton db 'start',0
	szButtonText db 'Start',0
	szBitmapBgnd1 db 'Res\\5.bmp', 0
	szKeySound1	db	'Res\\key1.wav',0
	szKeySound2	db	'Res\\key2.wav',0
	IDR_MENU1			equ 10000
	IDM_START			equ 10001
	IDM_QUIT			equ 10002
	IDM_SHOW			equ 10004
	IDM_ADD				equ 10005
	IDM_CHGSOU			equ 10006
	IDM_SLIENCE			equ 10007
	IDM_SAVE			equ 10003
	IDR_VERSION1			equ 1
	IDB_BMP1			equ 20001
	IDM_COMB 			equ 10008
 	IDM_WORDS 			equ 10009
  	MAXSIZE equ 260
	MEMSIZE equ 65535 
	EditID equ 1 
;SQLite相关信息*****************************************************************************
	libName       db       'src\\sqlite3.dll',0
	sqlite3_open  db       'sqlite3_open',0
	sqlite3_close db       'sqlite3_close',0
	sqlite3_exec  db       'sqlite3_exec',0
	sqlite3_slct  db       'sqlite3_get_table',0 
	fileName      db       'data.db',0  
	
	createTable   db       'create table if not exists Input(id integer primary key autoincrement,';数据库建表语句
	              db       'time varchar(60),comb integer,words integer)',0 
	selectMaxComb    db       'select max(comb) from Input',0
	selectMaxWords	db	'select max(words) from Input',0
	split         db       ':',0
	endline       db       0dh,0ah,0
	empty         db       0
	Input_id	db	'id',0
	Input_time	db	'time',0
	Input_comb	db	'comb',0
	Input_words	db	'words',0
	
.data
	ClassName db "DiaryClass",0
	AppName  db "Diary",0
	msgTitleStat db "输入统计",0
	msgContStat db "当前造成连击"
	countComb db 20h,20h,20h,30h              ;4字节存储，输出时从这里输出
		 db "次，打出"
	countWords  db 20h,20h,20h,30h
		 db "字",0
	msgContClose db "关闭前是否保存",0
	msgTitleClose db "提醒",0
	maxUsedWordValue db 4 dup(0)               ;4个字节用于存储此值，最大为9999,采用BCD码运算方式进行计算
	EditClass  db "EDIT",0 
	countComb_s dw 0                   ;连击数
	countWords_s dw 0                  ;输入字数
	maxComb dw 0                      ;最大连击数
	idleCount db 0
	msgTotal db "本次最多造成连击"
	countCombMax db 20h,20h,20h,30h              ;4字节存储，输出时从这里输出
		 db "次，打出"
	countWordsTotal  db 20h,20h,20h,30h
		 db "字",0
	ofn   OPENFILENAME <>
	FilterString db "All Files",0,"*.*",0
		     db "Text Files",0,"*.txt",0
		     db "Asm Files",0,"*.asm",0,0
	buffer db MAXSIZE dup(0) 
	;;;test
	szOutofTime db "outoftime",0
	szInTime db "int time",0
	wndCount dd 0                      ;窗口实例计数
	chooseKeySound	dd szKeySound1
	chooseKeySound_count db 0
	soundFlag	db 1
;;================================SQLite 相关=================================	
	insertData    db       'insert into Input(time,comb,words) values(',39
	insertTime    db	'20170107',0
	inter_1	      db	39,',',39
	insertComb    db	'0000',0
	inter_2       db	39,',',39
	insertWords   db	'0000',0
	inter_3       db	39,')',0
	updateData    db	'update Input set '
	updateVar     db	' words',0
	update_1      db	'=',39
	updateValue   db	'0000',0
	update_2      db	39,' where '
	updateConVar  db	'id',0
	update_3      db	'=',39
	updateConVal  db	'0000',0
	update_4	db	39,0
	deleteData	db	'delete from Input where'
	deleteConVar	db	'  id',0
	delete_1	db	'=',39
	deleteConVal	db	'0000',0
	delete_2	db	39,0
	selectData	db	'select '
	selectVar	db	' comb',0
	select_1	db	' from Input where '
	selectConVar	db	'  id',0
	select_2	db	'=',39
	selectConVal	db	'0000',0
	select_3	db	39,0
	;;;;
.data?
	hwndEdit dd 21 dup(?)                ;输入框句柄
	hwndText HWND ?				;文本框句柄
	OldWndProc dd ?
	hInstance HINSTANCE ?                 ;实例句柄
	CommandLine LPSTR ?
	hWinMain HWND  ?                     ;主窗口句柄
	hWinAdd HWND 20 dup(?)
	hMenu 	dd  ?
	hwndButton1 dd ?                     ;子窗口句柄
	OldButtonProc dd ?
	curSeconds dw ?
	curTime dw 4 dup(?)
	org $-8
	curTime_hour dw ?
	curTime_minute dw ?
	curTime_second dw ?
	curTime_nothing dw ?
	hFile HANDLE ?           ; File handle
	hMemory HANDLE ?          ;handle to the allocated memory block
	pMemory DWORD ?          ;pointer to the allocated memory block
	SizeReadWrite DWORD ?       ; number of bytes actually read or write 
	hBitmapBgnd dd ?
	
	
	

;SQLite相关信息*****************************************************************************
	hLib          dd       ?
	hDB           dd       ?
	errorInfo     dd       ?
	hs_open       SQL_Open ?
	hs_close      SQL_Close ?
	hs_exec       SQL_Exec ?
	hs_slct       SQL_Slct ?
	db_result	dd ?
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
	invoke   LoadLibrary,offset libName
	mov      hLib,eax
	invoke   GetProcAddress,hLib,addr sqlite3_open
	mov      hs_open,eax
	invoke   GetProcAddress,hLib,addr sqlite3_close
	mov      hs_close,eax
	invoke   GetProcAddress,hLib,addr sqlite3_exec
	mov      hs_exec,eax
	invoke   GetProcAddress,hLib,addr sqlite3_slct
	mov      hs_slct,eax
	invoke   hs_open,offset fileName,offset hDB
	invoke   hs_exec,hDB,offset createTable,NULL,NULL,offset errorInfo
	invoke   WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
	invoke  formatComb
	invoke  formatWords
	invoke  sqlInsert
	invoke  MessageBox,NULL,addr msgTotal,addr msgTitleStat,MB_OK
	invoke   hs_close,hDB
	invoke  ExitProcess,eax
	
;;                                
;*******************************************************************************
;;                                 主窗口
;**********************************************************************************
WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL wc:WNDCLASSEX
	LOCAL msg:MSG
	LOCAL hwnd:HWND
	LOCAL chilehwnd1:HWND
	invoke RtlZeroMemory,addr wc,sizeof wc 
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
        invoke RegisterClassEx,addr wc  
        invoke LoadMenu,hInst,IDR_MENU1  
        mov hMenu,eax      
	invoke LoadImage, NULL, \
  		addr szBitmapBgnd1, \
  		IMAGE_BITMAP, \
  		592, 592, LR_LOADFROMFILE
  	mov hBitmapBgnd, eax      
	invoke RegisterClassEx, addr wc
	invoke CreateWindowEx,WS_EX_CLIENTEDGE,ADDR ClassName,ADDR AppName,\
            WS_OVERLAPPEDWINDOW ,100,100,600,600,NULL,hMenu,\
           hInst,NULL
        lea edi,hWinMain
        mov ebx,wndCount
	mov [edi+ebx*4],eax
	
	invoke ShowWindow, hWinMain,SW_SHOWNORMAL
	invoke UpdateWindow, hWinMain
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
;;播放键盘按下音效
playKeySound proc
	invoke PlaySound,chooseKeySound,0,SND_ASYNC or SND_NODEFAULT or SND_FILENAME
	ret
playKeySound endp

changeKeySound proc uses eax
	mov al,chooseKeySound_count
	inc al
	cmp al ,2
	jb choose1
	mov chooseKeySound,offset szKeySound1
	mov chooseKeySound_count,0
	jmp choose2
choose1:
	mov chooseKeySound,offset szKeySound2
	mov chooseKeySound_count,1
choose2:
	ret
changeKeySound endp

;修改当前连击数和字数和最频繁使用单词
IncreaseWords proc uses ax edi   ;增加字数
	inc countWords_s
	call UpdateWord
	ret
IncreaseWords endp

IncreaseComb proc uses edi eax ebx ecx edx                         ;增加连击数
	LOCAL @stTime: SYSTEMTIME
	invoke  GetLocalTime,addr @stTime
	lea edi, curTime
	mov bx,[edi+2]
	mov cx,@stTime.wMinute
	sub cx,bx
	mov ax,cx
	mov cx,60
	imul cx
	mov bx,[edi+4]
	mov cx,@stTime.wSecond
	sub cx,bx
	add ax,cx
   	cmp cx,1
   	jg outOfTime
	inc countComb_s
	jmp last
outOfTime:
	mov countComb_s,1
last:
       	call UpdateComb
       	mov ax,countComb_s
       	mov bx,maxComb
       	cmp ax,bx
       	jbe outofproc
       	mov maxComb,ax
outofproc:
	ret
IncreaseComb endp

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;计算字符串长度
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_StrLen       proc     uses ebx ecx,pstr
              mov      ebx,pstr
              mov      eax,0
              mov      cl,[ebx]
              .while   cl
                       inc      ebx
                       inc      eax
                       mov      cl,[ebx]
              .endw
              ret
_StrLen       endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;计算字符串复制
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_StrCopy      proc     uses ebx esi,src
              local    @strAddr,@len
              invoke   _StrLen,src
              inc      eax
              invoke   GlobalAlloc,GPTR,eax
              mov      @strAddr,eax
              mov      ebx,eax
              mov      esi,src
              mov      al,[esi]
              .while   al
                       mov  [ebx],al
                       inc  ebx
                       inc  esi
                       mov  al,[esi]
              .endw
              mov      al,0
              mov      [ebx],al
              mov      eax,@strAddr
              ret
_StrCopy      endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;计算字符串拼接
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_StrCat       proc     uses ebx esi,str1,str2
              local    @strAddr,@len
              invoke   _StrLen,str1
              mov      @len,eax
              invoke   _StrLen,str2
              add      eax,@len
              inc      eax
              invoke   GlobalAlloc,GPTR,eax
              mov      @strAddr,eax
              mov      ebx,eax
              mov      esi,str1
              mov      al,[esi]
              .while   al
                       mov  [ebx],al
                       inc  ebx
                       inc  esi
                       mov  al,[esi]
              .endw
              mov      esi,str2
              mov      al,[esi]
              .while   al
                       mov  [ebx],al
                       inc  ebx
                       inc  esi
                       mov  al,[esi]
              .endw
              mov      al,0
              mov      [ebx],al
              mov      eax,@strAddr
              ret
_StrCat       endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;;       初始化数据库连接
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
initSql	proc uses eax
;	invoke   LoadLibrary,offset libName
;	mov      hLib,eax
;	invoke   GetProcAddress,hLib,addr sqlite3_open
;	mov      hs_open,eax
;	invoke   GetProcAddress,hLib,addr sqlite3_close
;	mov      hs_close,eax
;	invoke   GetProcAddress,hLib,addr sqlite3_exec
;	mov      hs_exec,eax
;	invoke   GetProcAddress,hLib,addr sqlite3_slct
;	mov      hs_slct,eax
;	invoke   hs_open,offset fileName,offset hDB
;	invoke   hs_exec,hDB,offset createTable,NULL,NULL,offset errorInfo
	ret
initSql endp


;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;查询语句回调函数
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
sqlcallback   proc    uses ebx esi edi,para,intn_column,column_value,column_name
              local   @str,@count
              mov     eax,0
              mov     @count,eax
              mov     esi,column_name
              mov     edi,column_value
              invoke  _StrCopy,offset empty
              mov     @str,eax
              .while  TRUE
                      invoke  _StrCat,@str,[esi]
                      mov     ebx,@str
                      mov     @str,eax
                      invoke  GlobalFree,ebx
                      invoke  _StrCat,@str,offset split
                      mov     ebx,@str
                      mov     @str,eax
                      invoke  GlobalFree,ebx
                      invoke  _StrCat,@str,[edi]
                      mov     ebx,@str
                      mov     @str,eax
                      invoke  GlobalFree,ebx
                      invoke  _StrCat,@str,offset endline
                      mov     ebx,@str
                      mov     @str,eax
                      invoke  GlobalFree,ebx
                      mov     eax,@count
                      inc     eax
                      mov     @count,eax
                      .break  .if     eax == intn_column
                      add     esi,4
                      add     edi,4
              .endw
              invoke  MessageBox,NULL,@str,offset fileName,MB_OK
              invoke  GlobalFree,@str
              mov     eax,0
              ret
sqlcallback   endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;查询语句执行函数
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
sqlExc        proc     uses  ebx esi edi edx,@selectData
              local    @result,@nRow,@nCol,@str
              local    @i,@j,@index
              invoke   hs_slct,hDB,@selectData,addr @result,addr @nRow,\
                       addr @nCol,offset errorInfo
              invoke   _StrCopy,offset empty
              mov      @str,eax
              mov      edi,@nCol
              mov      eax,@nRow
              mov      @i,eax
              mov      ebx,@result
              .while   @i
                       mov    esi,0
                      .while  esi < @nCol
                              invoke  _StrCat,@str,[ebx + esi*4]
                              mov     edx,@str
                              mov     @str,eax
                              invoke  GlobalFree,edx
                              invoke  _StrCat,@str,offset split
                              mov     edx,@str
                              mov     @str,eax
                              invoke  GlobalFree,edx
                              invoke  _StrCat,@str,[ebx + edi*4]
                              mov     edx,@str
                              mov     @str,eax
                              invoke  GlobalFree,edx
                              invoke  _StrCat,@str,offset endline
                              mov     edx,@str
                              mov     @str,eax
                              invoke  GlobalFree,edx
                              inc     esi
                              inc     edi
                      .endw
                      mov    eax,@i
                      dec    eax
                      mov    @i,eax
              .endw
              invoke  MessageBox,NULL,@str,offset fileName,MB_OK
              invoke  GlobalFree,@str
              mov eax,@str
              mov db_result,eax
              mov     eax,0
              ret
sqlExc        endp
;===================================================================
;;                              数据插入语句
;===================================================================
sqlInsert    proc uses eax ebx ecx esi
	LOCAL @str
	invoke  _StrCopy,offset empty
        mov     @str,eax
	invoke  _StrCat,@str,offset insertData
	mov ebx,@str
	mov  @str,eax
	invoke  GlobalFree,ebx
	invoke  _StrCat,@str,offset inter_1
	mov ebx,@str
	mov  @str,eax
	invoke  GlobalFree,ebx
	invoke  _StrCat,@str,offset inter_2
	mov ebx,@str
	mov  @str,eax
	invoke  GlobalFree,ebx
	invoke  _StrCat,@str,offset inter_3
	mov ebx,@str
	mov  @str,eax
	invoke  GlobalFree,ebx
	invoke  hs_exec,hDB,@str,NULL,NULL,offset errorInfo
	invoke GlobalFree,@str
	ret
sqlInsert endp
;===================================================================
;;                            数据更新语句
;===================================================================
sqlUpdate    proc uses eax ebx ecx esi
	LOCAL @str
	invoke  _StrCopy,offset empty
        mov     @str,eax
	invoke  _StrCat,@str,offset updateData
	mov ebx,@str
	mov  @str,eax
	invoke  GlobalFree,ebx
	invoke  _StrCat,@str,offset update_1
	mov ebx,@str
	mov  @str,eax
	invoke  GlobalFree,ebx
	invoke  _StrCat,@str,offset update_2
	mov ebx,@str
	mov  @str,eax
	invoke  GlobalFree,ebx
	invoke  _StrCat,@str,offset update_3
	mov ebx,@str
	mov  @str,eax
	invoke  GlobalFree,ebx
	invoke  _StrCat,@str,offset update_4
	mov ebx,@str
	mov  @str,eax
	invoke  GlobalFree,ebx
	invoke  hs_exec,hDB,@str,NULL,NULL,offset errorInfo
	invoke GlobalFree,@str
	ret
sqlUpdate endp


UpdateComb proc uses eax ecx edx edi
	;================================================================将连击数转换为ASCII码存入输出内存单元
	mov eax,0
	mov ax, countComb_s
	lea edi, countComb
	mov ecx, 4
	loop1:
		mov bl, 10
		div bl
		mov ebx,ecx
		dec ebx
		mov byte ptr[edi+ebx],ah
		add byte ptr[edi+ebx],30h
		mov ah,0
		dec ecx
	jnz loop1
lastline:
	ret
UpdateComb endp

UpdateWord proc uses eax edx ecx esi
	;================================================================将输入词数转换为ASCII码存入输出内存单元	
	mov eax,0
	mov ax, countWords_s
	lea edi, countWords
	mov ecx, 4
	loop1:
		mov bl, 10
		div bl
		mov ebx,ecx
		dec ebx
		mov byte ptr[edi+ebx],ah
		add byte ptr[edi+ebx],30h
		mov ah,0
		dec ecx
	jnz loop1
	ret
UpdateWord endp
formatComb proc uses eax ebx ecx edx esi edi
;================================================================将最大连击数转换为ASCII码存入输出内存单元
	mov eax,0
	mov ax, maxComb
	
	lea edi, countCombMax
	mov ecx, 4
	loop1:
		mov bl, 10
		div bl
		mov ebx,ecx
		dec ebx
		mov byte ptr[edi+ebx],ah
		add byte ptr[edi+ebx],30h
		mov ah,0
		dec ecx
	jnz loop1
;==================================================================预备将最大连击数存入数据库
	lea esi,countCombMax
	lea edi,insertComb
	mov ecx,4
	CLD
	REP MOVSB
	ret
formatComb endp

formatWords proc uses eax ebx ecx edx esi edi
	;================================================================将输入词转换为ASCII码存入输出内存单元	
	mov eax,0
	mov ax, countWords_s
	lea esi, countWords
	lea edi, countWordsTotal
	mov ecx,4
	cld
	rep movsb
;===================================================================================预备将输入词数存入数据库
	mov ecx,4
	cld
	lea esi,countWords
	lea edi,insertWords
	rep movsb
	ret
formatWords endp

;===========================记录上一次操作时间
Update_curTime proc uses eax ebx ecx edx esi edi
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
	mov ax,@stTime.wSecond
	mov curSeconds,ax
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
	LOCAL @stPos:POINT
	local @stRect:RECT
  	local @hDc
  	LOCAL @hPopupMenu1
	LOCAL @hText
  	mov eax,uMsg
;********************************************************************
  	.if eax == WM_PAINT
   		invoke BeginPaint,hWnd,addr @stPs
   		mov @hDc,eax
   		
   		invoke GetClientRect,hWnd,addr @stRect
;   		invoke DrawText,@hDc,addr szText,-1,\
;    			addr @stRect,\
;    			DT_SINGLELINE or DT_CENTER or DT_VCENTER
	
   		invoke EndPaint,hWnd,addr @stPs
;********************************************************************
   	.elseif eax == WM_CREATE
		call Update_curTime                                 ;;      初始化计时，用于计算是否连击
;;========================================================================================== 
		;invoke                                                                       ;用于贴图SS_GRAYFRAME
;		 invoke CreateWindowEx,NULL,ADDR EditClass,NULL,\               
;           	WS_CHILD or WS_VISIBLE or SS_GRAYFRAME or ES_READONLY,0,0,65,20,hWnd,NULL,\
;            	hInstance,NULL
;            	mov hwndText,eax
	        invoke CreateWindowEx,NULL,ADDR EditClass,NULL,\                ;创建输入框
           	WS_CHILD or WS_VISIBLE or ES_MULTILINE or ES_AUTOVSCROLL or WS_VSCROLL,0,20,600,580,hWnd,NULL,\
            	hInstance,NULL
		mov hwndEdit,eax
        	push eax
        	invoke SetFocus,eax
		pop eax
		;================================================================
		; 		  子类化,替换默认的处理函数
		;================================================================
        	invoke SetWindowLong,eax,GWL_WNDPROC,addr EditWndProc
        	.if wndCount == 0
        		mov OldWndProc,eax
		.endif
;==================================================================================
;       		 初始化OPENFILENAME
;==========================================================================
      		mov ofn.lStructSize,SIZEOF ofn
		push hWnd
		pop  ofn.hWndOwner
		push hInstance
		pop  ofn.hInstance
		mov  ofn.lpstrFilter, OFFSET FilterString
		mov  ofn.lpstrFile, OFFSET buffer
		mov  ofn.nMaxFile,MAXSIZE
;		inc wndCount
;********************************************************************
;                        响应鼠标和键盘控制
	.elseif eax == WM_COMMAND
		mov eax,wParam
		.if ax == IDM_QUIT
			;==================退出并返回输入统计========================================
			invoke MessageBox,hWnd,addr msgContClose,addr msgTitleClose,MB_YESNO
			.if eax == IDNO
				invoke DestroyWindow, hWnd
				invoke PostQuitMessage,NULL
			.endif
			.if eax == IDYES
				invoke SendMessage,hWnd,WM_COMMAND,IDM_SAVE,0
				invoke SendMessage,hWnd,WM_CLOSE,0,0
			.endif
			ret
		.elseif ax == IDM_START
			;===================浏览并打开文件===========================================
			mov  ofn.Flags, OFN_FILEMUSTEXIST or\
			OFN_PATHMUSTEXIST or OFN_LONGNAMES or\
			OFN_EXPLORER or OFN_HIDEREADONLY
			invoke GetOpenFileName, ADDR ofn
			.if eax==TRUE
				invoke CreateFile,ADDR buffer,\
				GENERIC_READ or GENERIC_WRITE ,\
				FILE_SHARE_READ or FILE_SHARE_WRITE,\
				NULL,OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,\
				NULL
				mov hFile,eax
				invoke GlobalAlloc,GMEM_MOVEABLE or GMEM_ZEROINIT,MEMSIZE
				mov  hMemory,eax
				invoke GlobalLock,hMemory
				mov  pMemory,eax
				invoke ReadFile,hFile,pMemory,MEMSIZE-1,ADDR SizeReadWrite,NULL
				invoke SendMessage,hwndEdit,WM_SETTEXT,NULL,pMemory
				invoke CloseHandle,hFile
				invoke GlobalUnlock,pMemory
				invoke GlobalFree,hMemory
			.endif
         		 invoke SetFocus,hwndEdit
		.elseif ax == IDM_SAVE
			;===================关闭并保存文件===========================================
			mov ofn.Flags,OFN_LONGNAMES or\
			OFN_EXPLORER or OFN_HIDEREADONLY
			invoke GetSaveFileName, ADDR ofn
			.if eax==TRUE
				invoke CreateFile,ADDR buffer,
				GENERIC_READ or GENERIC_WRITE ,
				FILE_SHARE_READ or FILE_SHARE_WRITE,
				NULL,CREATE_NEW,FILE_ATTRIBUTE_ARCHIVE,
				NULL
				mov hFile,eax
				invoke GlobalAlloc,GMEM_MOVEABLE or GMEM_ZEROINIT,MEMSIZE
				mov  hMemory,eax
				invoke GlobalLock,hMemory
				mov  pMemory,eax
				invoke SendMessage,hwndEdit,WM_GETTEXT,MEMSIZE-1,pMemory
				
				invoke WriteFile,hFile,pMemory,eax,ADDR SizeReadWrite,NULL
				
				invoke CloseHandle,hFile
				invoke GlobalUnlock,pMemory
				invoke GlobalFree,hMemory
			.endif
			invoke SetFocus,hwndEdit
		.elseif ax == IDM_SHOW
			invoke MessageBox,hWnd,addr msgContStat,addr msgTitleStat,MB_OK
		.elseif ax == IDM_ADD
			invoke CreateThread,NULL,0,addr _ThreadProc,NULL,0,0
		;=============================开始新笔记==========================================
		.elseif ax == IDM_CHGSOU
			invoke changeKeySound
		.elseif ax == IDM_SLIENCE
			mov al,soundFlag
			.if al ==1
				mov soundFlag,0
			.else
				mov soundFlag,1
			.endif
			
		.elseif ax == IDM_COMB
			invoke sqlExc,addr selectMaxComb
		.elseif ax == IDM_WORDS
			invoke sqlExc,addr selectMaxWords
		.endif		

;***********************************************************
;;             移动窗口

	.elseif eax == WM_LBUTTONDOWN
		invoke UpdateWindow,hWnd ;即时刷新
		invoke ReleaseCapture
		invoke SendMessage,hWnd,WM_NCLBUTTONDOWN,HTCAPTION,0
;********************************************************************
;;           创建弹出式菜单
	.elseif eax == WM_RBUTTONDOWN
		call _CreatePopupMenu
		mov @hPopupMenu1,eax
		invoke GetCursorPos,addr @stPos
		invoke TrackPopupMenu,@hPopupMenu1,TPM_LEFTALIGN,@stPos.x,@stPos.y,\
			NULL,hWnd,NULL
;*********************************************************************
  	.elseif eax == WM_CLOSE ;窗口关闭事件
 
   		invoke MessageBox,hWnd,addr msgContClose,addr msgTitleClose,MB_YESNO
		.if eax == IDNO
			invoke DestroyWindow, hWnd
			invoke PostQuitMessage,NULL
		.endif
		.if eax == IDYES
			invoke SendMessage,hWnd,WM_COMMAND,IDM_SAVE,0
			invoke SendMessage,hWnd,WM_CLOSE,0,0
		.endif
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


EditWndProc PROC uses ebx,hEdit:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
	local @stPs:PAINTSTRUCT
	local @hDc 
	local @stRect:RECT
    .if uMsg==WM_CHAR
;    	invoke GetDC,hWinMain
;    	mov @hDc,eax
;    	
;    	invoke GetClientRect,hWinMain,addr @stRect
;    	invoke DrawText,@hDc,addr szText,-1,\
;    		addr @stRect,\
;    		TA_LEFT or  TA_TOP or SS_GRAYFRAME
        mov eax,wParam
            call IncreaseComb
       	    call Update_curTime
       	    call IncreaseWords
            invoke CallWindowProc,OldWndProc,hEdit,uMsg,eax,lParam
            ret
    .elseif uMsg==WM_KEYDOWN
    	mov bl,soundFlag
    	.if bl == 1
    		invoke playKeySound
    	.endif
        mov eax,wParam
        .if al==VK_RETURN
            invoke SetFocus,hEdit
            ret
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


_CreatePopupMenu proc
	LOCAL @hPopMenu1
	;invoke MessageBox,NULL,addr msgContStat,addr msgTitleStat,MB_OK
	invoke CreatePopupMenu
	mov @hPopMenu1,eax
	invoke AppendMenu,@hPopMenu1,MF_STRING,IDM_QUIT,CTEXT("关闭程序") 
        push @hPopMenu1  
        pop eax  
	ret
_CreatePopupMenu endp

_CreateWnd proc  hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL wc:WNDCLASSEX
	LOCAL msg:MSG
	LOCAL hwnd:HWND
	LOCAL chilehwnd1:HWND
	inc wndCount
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
	invoke LoadImage, NULL, \
  		addr szBitmapBgnd1, \
  		IMAGE_BITMAP, \
  		592, 592, LR_LOADFROMFILE
  	mov hBitmapBgnd, eax      
	invoke RegisterClassEx, addr wc
	invoke CreateWindowEx,WS_EX_CLIENTEDGE,ADDR ClassName,ADDR AppName,\
            WS_DLGFRAME or WS_SYSMENU,100,100,600,600,NULL,hMenu,\
           hInst,NULL
        mov hwnd,eax
        lea edi,hWinMain
        mov ebx,wndCount
	mov [edi+ebx*4],eax
	
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
_CreateWnd endp
_ThreadProc proc
	invoke _CreateWnd,NULL,NULL,NULL,NULL
	ret
_ThreadProc endp
end start
