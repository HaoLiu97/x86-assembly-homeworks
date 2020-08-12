;--------------------------------------
;By Hao Liu 3160104994
;Zhejiang University
;2018.1.7
;--------------------------------------
data segment
	hexTable db "0123456789ABCDEF"
	messageInput db "Please input filename:",0Dh,0Ah,"$"
	messageError db 0Dh,0Ah,"Cannot open file!$"
	filename db 255, 0, 256 dup(0);给读入的回车留1位
	filesize db 4 dup(0)
	handle dw 0
	foffset db 4 dup(0);当前屏第一个字符地址，32位
	roffset db 4 dup(0);当前要显示行的偏移地址
	buf db 257 dup("$")
	rows db 0, 0
	rowaddress db 0, 0
data ends

code segment
assume cs:code, ds:data
main:
	mov ax, data
	mov ds, ax
	mov es, ax
	mov ax, offset messageInput
	call dispString;吸取上次debug的教训，这次尽量把部分操作写成函数形式，且参数统一用ax，在进入和退出时用堆栈保护数据。
	mov ax, offset filename
	call getFilename
	mov ax, offset filename
	add ax, 2;ax指向文件名
	call fopen;同时lseek，结束后filesize中储存文件大小
begin:;准备开始显示文件
	mov ax, word ptr filesize[0]
	mov dx, word ptr filesize[2];(dx:ax) = filesize
	sub ax, word ptr foffset[0]
	sbb dx, word ptr foffset[2];(dx:ax) = (dx:ax) - foffset
	sub ax, 256
	sbb dx, 0;(dx:ax) = filesize - 256
	jc less256;if(filesize < 256) ax = filsize
	xor ax, ax;else ax = 256
less256:
	add ax, 256
	push ax
lseek:;从头移动文件指针，距离为(dx:cx)
	mov ah, 42h
	mov al, 0
	mov bx, handle
	mov cx, word ptr foffset[2]
	mov dx, word ptr foffset[0]
	int 21h
fread:;读文件到ds:dx
	mov ah, 3Fh
	mov bx, handle;文件代号
	pop cx;读取的字节数为之前压栈的ax
	mov dx, offset buf;缓冲区地址
	int 21h
	mov ax, cx
	call showThisPage
pressKey:
	mov ah, 0
	int 16h;键盘输入
	cmp ax, 4900h
	je KEYpageup
	cmp ax, 5100h
	je KEYpagedown
	cmp ax, 4700h
	je KEYhome
	cmp ax, 4F00h
	je KEYend
	cmp ax, 011Bh;KEYexit
	je fclose
	jmp begin
KEYpageup:;foffset = foffset - 256;
          ;if(foffset < 0)
          ;	foffset = 0;
	mov ax, word ptr foffset[0]
	mov dx, word ptr foffset[2]
	sub ax, 256
	sbb dx, 0;foffset = foffset - 256
	jc KEYhome;if(foffset < 0)
	mov word ptr foffset[0], ax
	mov word ptr foffset[2], dx
	jmp begin
KEYpagedown:;if(foffset + 256 < file_size)
            ;	foffset = foffset + 256;
    mov ax, word ptr foffset[0]
    mov dx, word ptr foffset[2]
    add ax, 256
    adc dx, 0;(dx:ax) = foffset + 256
    push ax
    push dx
    sub ax, word ptr filesize[0]
    sbb dx, word ptr filesize[2];(dx:ax) = (dx:ax) - filesize
    jnc toBegin;foffset >= filesize时无反应
    pop dx
    pop ax
    mov word ptr foffset[0], ax
    mov word ptr foffset[2], dx
    toBegin:;跳板
    jmp begin
KEYhome:;offset = 0
	mov word ptr foffset[0], 0
	mov word ptr foffset[2], 0
	jmp begin
KEYend:;offset = file_size - file_size % 256;
       ;if(offset == file_size)
       ;	offset = file_size - 256;
	xor ax, ax
	mov al, byte ptr filesize[0];(ax) = filesize%256
	cmp ax, 0
	jne ONES;if(foffset == file_size)
	mov ax, 256
	ONES:
	push bx
	mov bx, ax
	mov ax, word ptr filesize[0]
	mov dx, word ptr filesize[2]
	sub ax, bx
	sbb dx, 0
	pop bx
	mov word ptr foffset[0], ax
	mov word ptr foffset[2], dx
	jmp begin
fclose:
	mov ah, 3Eh
	mov bx, handle
	int 21h;fclose(handle)
exit:;结束程序
	mov ah,4Ch
	int 21h
;--------------------------------------


;----------------------------------------------------------
dispString:;显示ds:ax处字符串的函数
	push dx
	mov dx, ax
	mov ah, 09h
	int 21h
	pop dx
	ret
;------------------------------------------
getFilename:;输入字符串到ds:ax,并用0替换回车
	push dx
	mov dx, ax
	mov ah, 0Ah
	int 21h
	mov di, dx
	add di, 2
	mov al, 0Dh;回车
	mov cx, 256
	cld
	repne scasb
	dec di
	mov al, 0
	mov ds:[di], al
	pop dx
	ret
;------------------------------------------
fopen:;打开ds:ax指向文件名的文件，成功则cf为0，失败则cf为1
	push dx
	mov dx, ax
	mov ah, 3Dh
	mov al, 0
	int 21h
	jc openFail
	mov handle, ax
	mov ah,42h
	mov al,2
	mov bx, handle
	mov cx, 0
	mov dx, 0
	int 21h;lseek(handle,0,2)
	mov word ptr filesize[2],dx
	mov word ptr filesize[0],ax
	pop dx
	ret
;------------------------------------------
openFail:
	mov ax, offset messageError
	call dispString
	jmp exit
;------------------------------------------
showThisPage:;ax为buf长度
	push ax
	mov ax, 0B800h;显存地址
	mov es, ax
	xor di, di;es:di指向显存首地址
clearThisPage:;清屏
	mov cx, 80*16
	mov ax, 0020h;空格ASCII码
	cld
	rep stosw;清屏
calRows:;rows = (bytes_in_buf + 15) / 16; /* 计算当前页的行数 */
	pop ax;buf长度
	mov dx, ax
	add ax, 0Fh
	mov cl, 4
	shr ax, cl;ax = ax/16
	mov cx, ax;显示行数
	push cx
	sub ax, 1
	mov cl, 4
	shl ax, cl
	sub dx, ax
	pop cx;当前页行数
	mov word ptr rows[0], cx
	xor di,di
showPage:;循环来显示每一页
	mov ax, cx;剩余行数
	sub ax, 1
	call showThisRow
	loop showPage
	ret
;--------------------------------------
showThisRow:;显示每一行
	push cx;剩余行数
	push ax
	mov cl, 160
	mul cl
	mov di, ax
	pop ax
	mov cl, 4
	shl ax, cl
	mov si, offset buf
	add si, ax;当前行buf中首个字符地址
	push di
	push si
	push dx
	mov cx, word ptr foffset[0]
	mov dx, word ptr foffset[2]
	add cx, ax
	adc dx, 0;(dx:ax)为文件当前要显示的字符地址
	mov word ptr roffset[0], cx
	mov word ptr roffset[2], dx
	pop dx
	add di, 16
	std
	mov ax, 073Ah;
	stosw;显示白色:
	xor bx,bx
dispAddress:
	xor ax,ax
	mov al, byte ptr roffset[bx]
	and al, 0Fh;偏移地址低4位
	push bx
	mov bx, offset hexTable
	xlat;转化为对应ASCII码
	mov ah, 07h;白色
	stosw;显示
	pop bx
	xor ax, ax
	mov al, byte ptr roffset[bx]
	mov cl, 4
	and al, 0F0h;偏移地址高4位
	rol al, cl
	push bx
	mov bx, offset hexTable
	xlat;转化为对应ASCII码
	mov ah, 07h
	stosw;显示
	pop bx
	inc bx
	cmp bx, 4;偏移地址为4个字节，显示32位地址要循环4次
	jne dispAddress

	pop si;当前行buf中首个字符地址
	pop di;当前显存地址
	pop cx
	push cx
	push di
	push si

	cld
	cmp cx, word ptr rows[0]

	je isLastLine
	mov dx, 16
	isLastLine:
	mov cx, dx
	add di, 59*2
	dispChar:
		movsb
		mov al, 07h
		stosb
	loop dispChar

	pop si;当前行buf中首个字符地址
	pop di;当前显存地址
	mov cx, dx
	add di, 18
	push di
	dispASCII:
		push cx
		mov ax, 0720h
		stosw
		xor ax, ax
		lodsb
		push ax
		mov cl, 4
		and al, 0F0h
		rol al, cl
		mov bx, offset hexTable
		xlat;转化
		mov ah, 07h
		stosw
		pop ax
		and al, 0Fh
		mov bx, offset hexTable
		xlat;转化
		mov ah, 07h;白色
		stosw
		pop cx
	loop dispASCII

	pop di
	add di, 2
	mov cx, 3
	dispPartition:
		add di, 22
		mov ax, 0F7Ch;亮白色竖线
		stosw
	loop dispPartition
	pop cx
	ret

code ends
end main