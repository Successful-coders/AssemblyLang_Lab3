.386
.model flat

.data
	x				dd 0.22			; xi, x0 = 0,22
	const1			dd 1.8			; константа для вычисления ф-ии
	const2			dd 10.0			; константа для вычисления ф-ии
	deriv1Const1	dd 7.2			; константа для вычисления первой производной ф-ии
	deriv2Const1	dd 21.6			; константа для вычисления второй производной ф-ии
	deriv2Const2	dd 100.0		; константа для вычисления второй производной ф-ии
	two				dd 2.0			; двойка
	accuracy		dd ?			; точность вычисления
	iterCountAdr    dd ?			; адрес переменной для количества итераций
	y				dq ?			; значение ф-ии в точке
	buf				dq ?			; для хранения y при вычислениях

.code
	_findSolve@8 proc
		push	ebp
		mov		ebp, esp

		mov		eax, [ebp]+8		; извлекаем точность
		mov		accuracy, eax	 

		mov		eax, [ebp]+12		; извлекаем адрес переменной для кол-ва итераций 
		mov		iterCountAdr, eax

		xor		ebx, ebx			; обнуляем счетчик итераций

		finit						; инициализация сопроцессора

		mov		edx, 1				; edx != 0, значит не бесконечность

		main:
			call	func		; y = f(x)

			cmp		edx, 0
			jnz		notInf		; если в edx != 0, то при вычислении не возникла бесконечность 
			dec		ebx
			jmp		exit

		notInf:
			fld		y			; st(0) = f(x)
			fldz				; st(0) = 0,   st(1) = f(x)
			fcompp				; 0 <?> f(x), затем убираются из стека
			fstsw	ax			; загрузка флагов в ax
			sahf				; загрузка флагов в eflags
			jnc		negative	; если 0 > f(x), меняем знак f(x)
			jmp		positive	; иначе, не менять знак

		negative:
			fld		y			; st(0) = f(x)
			fchs				; st(0) = -f(x)

		positive:
			fld		accuracy	; st(0) = accuracy, st(1) = |f(x)|
			fcompp				; accuracy <?> |f(x)|, затем убираются из стека
			fstsw	ax  		; загрузка флагов в ax
			sahf				; загрузка флагов в eflags
			jc		cycle		; если accuracy < |f(x)|, то нужна большая точность и еще итерация
			jmp		exit		; иначе, выход

		cycle: 
			call	iter
			inc		ebx			; увеличиваем количество итераций
		jne main

		exit:	
			mov		eax, iterCountAdr
			mov		[eax], ebx			; сохраняем количество итераций
			fld		x					; st(0) = x - возвращаемое значение 

			pop		ebp
			ret
	_findSolve@8 endp


	iter proc
		fld		y				; st(0) = f(x)
		call	funcDerivative2	; st(0) = f"(x), st(1) = f(x)
		fmulp					; st(0) = f(x)*f"(x)

		call	funcDerivative1	; st(0) = f'(x)
		call	funcDerivative1	; st(0) = f'(x)
		fmulp					; st(0) = (f'(x))^2
		fld		two				; st(0) = 2
		fmulp					; st(0) = 2*(f'(x))^2

		fdivp	st(1), st(0)	; st(0) = f(x)*f"(x) / 2*(f'(x))^2

		fld1					; st(0) = 1, st(1) = f(x)*f"(x) / 2*(f'(x))^2
		fsubrp					; st(0) = 1 - f(x)*f"(x) / 2*(f'(x))^2

		fld1					; st(0) = 1
		fdivrp					; st(0) = (1 - f(x)*f"(x) / 2*(f'(x))^2)^-1

		fld		y				; st(0) = f(x)
		call	funcDerivative1	; st(0) = f'(x), st(1) = f(x)
		fdivp					; st(0) = f(x) / f'(x), st(1) = (1 - f(x)*f"(x) / 2*(f'(x))^2)^-1
		fmulp					; st(0) = (f(x) / f'(x)) * ((1 - f(x)*f"(x) / 2*(f'(x))^2)^-1)

		fld		x				; st(0) = x, st(1) = (f(x) / f'(x)) * ((1 - f(x)*f"(x) / 2*(f'(x))^2)^-1)
		fsubrp					; st(0) = x - (f(x) / f'(x)) * ((1 - f(x)*f"(x) / 2*(f'(x))^2)^-1)

					; проверка на бесконечность
		fxam
		fstsw ax	; загрузка флагов в ax
		sahf		; загрузка флагов в eflags

		jz		continue
		jnp		continue
		jnc		continue 
							; если zf = 0, pf = 1, cf = 1, то результат - бесконечность
		xor		edx, edx	; edx = 0 обработаем вне функции, как бесконечность
		jmp		exit

		; если один из флагов другой, то продолжаем обычную обработку
	continue:
		fstp	x	; x = st(0)

	exit:
		ret
	iter endp



	; y = 1.8x^4 - sin(10x); f(x=0.22) = -0.80427
	func proc
		fld		const1			; st(0) = 1.8
		fld		x				; st(0) = x, st(1) = 1.8
		fld		x				; st(0) = x, st(1) = x, st(2) = 1.8
		fmul	st(1), st(0)	; st(0) = x, st(1) = x^2, st(2) = 1.8
		fmul	st(1), st(0)	; st(0) = x, st(1) = x^3, st(2) = 1.8
		fmulp					; st(0) = x^4, st(1) = 1.8
		fmulp					; st(0) = 1.8*x^4

		fld		const2			; st(0) = 10, st(1) = 1.8*x^4
		fld		x				; st(0) = x, st(1) = 10, st(2) = 1.8*x^4
		fmulp					; st(0) = 10x, st(1) = 1.8*x^4
		fsin					; st(0) = sin(10x), st(1) = 1.8*x^4

		fsubp					; st(0) = 1.8*x^4 - sin(10x)

		fstp	y				; y = st(0) = 1.8*x^4 - sin(10x)

		ret
	func endp

	; y' = 7.2x^3 - 10*sin(10x) = f'(x)
	funcDerivative1 proc
		fld		deriv1Const1	; st(0) = 7.2
		fld		x				; st(0) = x, st(1) = 7.2
		fld		x				; st(0) = x, st(1) = x, st(2) = 7.2
		fmul	st(1), st(0)	; st(0) = x, st(1) = x^2, st(2) = 7.2
		fmulp					; st(0) = x^3, st(1) = 7.2
		fmulp					; st(0) = 7.2*x^3

		fld		const2			; st(0) = 10, st(1) = 7.2*x^3
		fld		x				; st(0) = x, st(1) = 10, st(2) = 7.2*x^3
		fmulp					; st(0) = 10x, st(1) = 7.2*x^3
		fcos					; st(0) = cos(10x), st(1) = 7.2*x^3
		fld		const2			; st(0) = 10, st(1) = cos(10x), st(2) = 7.2*x^3
		fmulp					; st(0) = 10*cos(10x), st(1) = 7.2*x^3

		fsubp					; st(0) = 7.2*x^3 - 10*cos(10x)

		ret
	funcDerivative1 endp

	; y" = 21.6x^3 + 100*sin(10x) = f"(x)
	funcDerivative2 proc
		fld		deriv2Const1	; st(0) = 21.6
		fld		x				; st(0) = x, st(1) = 21.6
		fld		x				; st(0) = x, st(1) = x, st(2) = 21.6
		fmulp					; st(0) = x^2, st(1) = 21.6
		fmulp					; st(0) = 21.6*x^2

		fld		const2			; st(0) = 10, st(1) = 21.6*x^2
		fld		x				; st(0) = x, st(1) = 10, st(2) = 21.6*x^2
		fmulp					; st(0) = 10x, st(1) = 21.6*x^2
		fsin					; st(0) = sin(10x), st(1) = 21.6*x^2
		fld		deriv2Const2	; st(0) = 100, st(1) = sin(10x), st(2) = 21.6*x^2
		fmulp					; st(0) = 100*sin(10x), st(1) = 21.6*x^2

		faddp					; st(0) = 21.6*x^2 + 100*sin(10x)

		ret
	funcDerivative2 endp
end