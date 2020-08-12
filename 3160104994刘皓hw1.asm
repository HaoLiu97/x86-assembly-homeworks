;-------------------
;By Hao Liu 3160104994
;Zhejiang University
;2018.11.19
;-------------------
assume cs:code
code segment
	mov bl, 00h;从ASCII为00h的字符开始显示
	mov bh, 04h;字符颜色为红色
	mov dl, 0Ah;ASCII码颜色为绿色

	mov cx, 000Bh;设置外循环次数为Bh（十进制的11）
	mov ax, 0B800h;显存地址
	mov es, ax;

	mov ax, 0003h;
	int 10h;设置视频模式为80*25文本模式, 同时起到清屏效果

	mov di, 0
	mov cx, 0Bh;外循环0B（11）次
r:	
	push cx;外循环次数进栈
	mov cx, 19h;内循环19h（25）次 
	mov si, 0
	add si, di
	c:;内循环，打印每一列
		mov es:[si], bl
		inc si
		mov es:[si], bh
		inc si


		mov al, bl
		shr al, 1
		shr al, 1
		shr al, 1
		shr al, 1;逻辑右移4位
		cmp al, 9;小于等于则为0～9，大于则为A～F
		jl decimal1
		jz decimal1
		jg alpha1


		decimal1:
		add al, 30h;将0～9转化为字符
		jmp out1

		alpha1:
		add al, 37h;将A～F转化为字符
		jmp out1

		out1:
		mov es:[si], al
		inc si
		mov es:[si], dl


		inc si
		mov al, bl
		and al, 0fh

		cmp al, 9;小于等于则为0～9，大于则为A～F
		jl decimal2
		jz decimal2
		jg alpha2

		decimal2:
		add al, 30h;将0～9转化为字符
		jmp out2

		alpha2:
		add al, 37h;将A～F转化为字符
		jmp out2


		out2:
		mov es:[si], al
		inc si
		mov es:[si], dl


		inc bl;显示下一个字符
		add si, 80*2-5;
		cmp bl, 0;
		jz done;结束输出
	loop c
pop cx;外循环出栈
add di, 14;
loop r

	done:
	mov ax, 0;
	int 16h;
	mov ah, 4Ch;
	int 21h;

code ends
end