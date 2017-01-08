.386
.model flat, stdcall
option casemap: none


public Preload
public hIcon
public hBitmapBgnd

include windows.inc
include gdi32.inc
includelib gdi32.lib
include msimg32.inc
includelib msimg32.lib
include user32.inc
includelib user32.lib
include kernel32.inc
includelib kernel32.lib
include masm32.inc
includelib masm32.lib
include debug.inc
includelib debug.lib

.data?
hIcon dd ?
hBitmapBgnd dd ?

.const
szIcon db 'img\\mysterious\\icon.ico', 0
szBitmapBgnd1 db 'Res\\5.bmp', 0

.code


Preload proc
  invoke LoadImage, NULL, addr szBitmapBgnd1, IMAGE_BITMAP, 592, 592, LR_LOADFROMFILE
  mov hBitmapBgnd, eax                    ; default background color
  invoke LoadImage, NULL, addr szIcon, IMAGE_ICON, 16, 16, LR_LOADFROMFILE
  mov hIcon, eax
  ret
Preload endp
  end