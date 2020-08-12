;------------------------------------------
;By Hao Liu 3160104994
;Zhejiang University
;2018.12.16
;------------------------------------------
.386
data segment use16
	buffer db 7, 0, 6 dup(0);缓冲区最大字符数7，输入的单个数字最多为5位字符，字符串结尾为'\r'
	formula db 30 dup(0);算式
	decimal db 20 dup(0), 0Dh, 0Ah, '$';十进制结果
	hex db 20 dup(0), 0Dh, 0Ah, '$';十六进制结果
	binary db 40 dup(0), 0Dh, 0Ah, '$';二进制结果
data ends

code segment use16
assume cs:code, ds:data
main:
	mov ax, data
	mov ds, ax

	call getNum;以字符串形式从键盘读取第一个数字
	mov si, 2
	mov di, 0
	call writeNum;将第一个数字字符串写入formula
	mov formula[di], '*';将*写入formula
	inc di
	call toNum;将第一个数字字符串转化为数字
	push ax;把第一个数字压栈

	call endl

	call getNum;以字符串形式从键盘读取第二个数字
	mov si, 2
	call writeNum;以字符串形式从键盘读取第二个数字
	call toNum;将第二个数字字符串转化为数字
	pop bx;把第一个数字pop到bx中，同时现在ax中为第一个数字
	mul bx;ax*bx，结果高16位存储在dx，低16位存储在ax

	mov formula[di], '='
	inc di
	mov formula[di], '$'

	call dispFormula;显示算式
	call dispDec;显示十进制结果
	call dispHex;显示十六进制结果
	call dispBin;显示二进制结果

	mov ah, 4Ch
	int 21h
;------------------------------------------
getNum:;从键盘输入数字存储到buffer
	mov ah, 0Ah
	mov dx, offset buffer;将字符串储存到buffer
	int 21h;int21h的0Ah号功能，从键盘输入，回车结束，读取到ds:[dx]
	ret
;------------------------------------------
writeNum:;将数字字符串复制到算式字符串
	again1:
	mov al, [si]
	cmp al, 0Dh
	jz done1
	mov formula[di], al
	inc di
	inc si
	jmp again1

	done1:
	ret
;------------------------------------------
toNum:;将字符串转化为数字
	mov bx, 2
	mov ax, 0
	mov cx, 0

	again2:
	mov cl, [bx]
	cmp cl, 0Dh
	jz done2
	imul ax, ax, 10
	sub cl, '0'
	add ax, cx
	inc bx
	jmp again2

	done2:
	ret
;------------------------------------------
endl:;换行回车
	push ax
	push dx
	mov dl, 0Dh
	mov ah, 02h
	int 21h
	mov dl, 0Ah
	mov ah, 02h
	int 21h
	pop dx
	pop ax
	ret
;------------------------------------------
dispFormula:;显示算式
	call endl
	push dx
	push ax
	mov ah, 09h
	mov dx, offset formula
	int 21h;显示算式
	pop ax
	pop dx
	call endl
	ret
;------------------------------------------
dispDec:;显示十进制结果,方法是多次除以10，将余数储存在栈，再一次弹出
	push ax
	push dx

	mov cx, 0
	mov si, 0
again3:
	call divTen
	add dl, '0'
	push dx;余数压入栈中
	mov dx, bx;将bx与ax中的结果放到dx与ax中
	inc cx;	记录压栈次数
	push ax
	or ax, dx
	cmp ax, 0;dx和ax均为0，即上次除以10之后商为0
	pop ax
	jne again3

popToString:
	pop dx
	mov decimal[si], dl
	inc si
	dec cx;	保证出栈次数与压栈次数
	jnz popToString

	mov ah, 09h
	mov dx, offset decimal
	int 21h

	pop dx
	pop ax
	ret
;------------------------------------------
divTen:;防止除法溢出的函数，将dx与ax存储的32位数除以10，商高低16位分别在bx和ax，余数在dx
	push cx
	mov cx, 10
	push ax
	mov ax, dx
	mov dx, 0
	div cx;dx/cx
	mov bx, ax
	pop ax
	div cx;ax/cx
	pop cx
	ret
;------------------------------------------
dispHex:;利用循环移位显示十六进制结果
	mov si, 0
	mov cx, 2
	c1_H:
	push cx
	mov cx, 4
		c2_H:
		push cx
		mov cl, 4
		rol dx, cl
		pop cx
		mov bx, dx
		and bx, 000Fh
		cmp bx, 10
		jb digit
		ja alpha
		digit:
		add bl, '0'
		jmp next
		alpha:
		sub bl, 10
		add bl, 'A'
		next:
		mov hex[si], bl
		inc si
		loop c2_H
	pop cx
	push dx
	mov dx, ax
	loop c1_H

	mov hex[si], 'h'

	pop dx
	pop dx
	push ax
	push dx
	mov ah, 09h
	mov dx, offset hex
	int 21h
	pop dx
	pop ax
	ret
;------------------------------------------
dispBin:;利用循环移位显示二进制结果
	mov si, 0

	mov cx, 2
	c1_B:
	push cx
	mov cx, 4
		c2_B:
		push cx
		mov cx, 4
			c3_B:
			rol dx, 1
			mov bx, dx
			and bl, 0001h
			add bl, '0'
			mov binary[si], bl
			inc si
			loop c3_B
		pop cx
		mov binary[si], ' ';每隔4位显示一个空格
		inc si
		loop c2_B
	pop cx
	mov dx, ax
	loop c1_B

	dec si
	mov binary[si], 'B'
	mov ah, 09h
	mov dx, offset binary
	int 21h

	ret
;------------------------------------------
code ends
end main