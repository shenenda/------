	.file	"log.cpp"
	.text
	.def	_ZL11localtime_rPKxP2tm;	.scl	3;	.type	32;	.endef
	.seh_proc	_ZL11localtime_rPKxP2tm
_ZL11localtime_rPKxP2tm:
.LFB11:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	16(%rbp), %rdx
	movq	24(%rbp), %rax
	movq	%rax, %rcx
	call	_localtime64_s
	testl	%eax, %eax
	jne	.L2
	movq	24(%rbp), %rax
	jmp	.L4
.L2:
	movl	$0, %eax
.L4:
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_Z9vsnprintfPcyPKcS_,"x"
	.linkonce discard
	.globl	_Z9vsnprintfPcyPKcS_
	.def	_Z9vsnprintfPcyPKcS_;	.scl	2;	.type	32;	.endef
	.seh_proc	_Z9vsnprintfPcyPKcS_
_Z9vsnprintfPcyPKcS_:
.LFB43:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	%r8, 32(%rbp)
	movq	%r9, 40(%rbp)
	movq	40(%rbp), %r8
	movq	32(%rbp), %rcx
	movq	24(%rbp), %rdx
	movq	16(%rbp), %rax
	movq	%r8, %r9
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	__mingw_vsnprintf
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt9exceptionC1Ev,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt9exceptionC1Ev
	.def	_ZNSt9exceptionC1Ev;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt9exceptionC1Ev
_ZNSt9exceptionC1Ev:
.LFB197:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	.refptr._ZTVSt9exception(%rip), %rax
	leaq	16(%rax), %rdx
	movq	16(%rbp), %rax
	movq	%rdx, (%rax)
	nop
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt11char_traitsIcE6assignERcRKc,"x"
	.linkonce discard
	.globl	_ZNSt11char_traitsIcE6assignERcRKc
	.def	_ZNSt11char_traitsIcE6assignERcRKc;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt11char_traitsIcE6assignERcRKc
_ZNSt11char_traitsIcE6assignERcRKc:
.LFB293:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	24(%rbp), %rax
	movzbl	(%rax), %edx
	movq	16(%rbp), %rax
	movb	%dl, (%rax)
	nop
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt11char_traitsIcE6lengthEPKc,"x"
	.linkonce discard
	.globl	_ZNSt11char_traitsIcE6lengthEPKc
	.def	_ZNSt11char_traitsIcE6lengthEPKc;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt11char_traitsIcE6lengthEPKc
_ZNSt11char_traitsIcE6lengthEPKc:
.LFB297:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	strlen
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt11char_traitsIcE4moveEPcPKcy,"x"
	.linkonce discard
	.globl	_ZNSt11char_traitsIcE4moveEPcPKcy
	.def	_ZNSt11char_traitsIcE4moveEPcPKcy;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt11char_traitsIcE4moveEPcPKcy
_ZNSt11char_traitsIcE4moveEPcPKcy:
.LFB299:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	%r8, 32(%rbp)
	cmpq	$0, 32(%rbp)
	jne	.L12
	movq	16(%rbp), %rax
	jmp	.L13
.L12:
	movq	32(%rbp), %rcx
	movq	24(%rbp), %rdx
	movq	16(%rbp), %rax
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	memmove
	nop
.L13:
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt11char_traitsIcE4copyEPcPKcy,"x"
	.linkonce discard
	.globl	_ZNSt11char_traitsIcE4copyEPcPKcy
	.def	_ZNSt11char_traitsIcE4copyEPcPKcy;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt11char_traitsIcE4copyEPcPKcy
_ZNSt11char_traitsIcE4copyEPcPKcy:
.LFB300:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	%r8, 32(%rbp)
	cmpq	$0, 32(%rbp)
	jne	.L15
	movq	16(%rbp), %rax
	jmp	.L16
.L15:
	movq	16(%rbp), %rdx
	movq	24(%rbp), %rax
	movq	%rdx, %rcx
	movq	%rax, %rdx
	movq	32(%rbp), %rax
	movq	%rax, %r8
	call	memcpy
	nop
.L16:
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
_ZStL6ignore:
	.space 1
_ZStL19piecewise_construct:
	.space 1
	.section	.text$_ZN6lockerC1Ev,"x"
	.linkonce discard
	.align 2
	.globl	_ZN6lockerC1Ev
	.def	_ZN6lockerC1Ev;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN6lockerC1Ev
_ZN6lockerC1Ev:
.LFB1755:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$40, %rsp
	.seh_stackalloc	40
	leaq	32(%rsp), %rbp
	.seh_setframe	%rbp, 32
	.seh_endprologue
	movq	%rcx, 32(%rbp)
	movq	32(%rbp), %rax
	movl	$0, %edx
	movq	%rax, %rcx
	call	pthread_mutex_init
	testl	%eax, %eax
	setne	%al
	testb	%al, %al
	je	.L19
	movl	$8, %ecx
	call	__cxa_allocate_exception
	movq	%rax, %rbx
	movq	%rbx, %rcx
	call	_ZNSt9exceptionC1Ev
	movq	.refptr._ZNSt9exceptionD1Ev(%rip), %rdx
	leaq	_ZTISt9exception(%rip), %rax
	movq	%rdx, %r8
	movq	%rax, %rdx
	movq	%rbx, %rcx
	call	__cxa_throw
.L19:
	nop
	addq	$40, %rsp
	popq	%rbx
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZN6lockerD1Ev,"x"
	.linkonce discard
	.align 2
	.globl	_ZN6lockerD1Ev
	.def	_ZN6lockerD1Ev;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN6lockerD1Ev
_ZN6lockerD1Ev:
.LFB1758:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	pthread_mutex_destroy
	nop
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_handler	__gxx_personality_seh0, @unwind, @except
	.seh_handlerdata
.LLSDA1758:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE1758-.LLSDACSB1758
.LLSDACSB1758:
.LLSDACSE1758:
	.section	.text$_ZN6lockerD1Ev,"x"
	.linkonce discard
	.seh_endproc
	.section	.text$_ZN6locker4lockEv,"x"
	.linkonce discard
	.align 2
	.globl	_ZN6locker4lockEv
	.def	_ZN6locker4lockEv;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN6locker4lockEv
_ZN6locker4lockEv:
.LFB1759:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	pthread_mutex_lock
	testl	%eax, %eax
	sete	%al
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZN6locker6unlockEv,"x"
	.linkonce discard
	.align 2
	.globl	_ZN6locker6unlockEv
	.def	_ZN6locker6unlockEv;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN6locker6unlockEv
_ZN6locker6unlockEv:
.LFB1760:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	pthread_mutex_unlock
	testl	%eax, %eax
	sete	%al
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZN6locker3getEv,"x"
	.linkonce discard
	.align 2
	.globl	_ZN6locker3getEv
	.def	_ZN6locker3getEv;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN6locker3getEv
_ZN6locker3getEv:
.LFB1761:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZN12locker_guardC1ER6locker,"x"
	.linkonce discard
	.align 2
	.globl	_ZN12locker_guardC1ER6locker
	.def	_ZN12locker_guardC1ER6locker;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN12locker_guardC1ER6locker
_ZN12locker_guardC1ER6locker:
.LFB1764:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	16(%rbp), %rax
	movq	24(%rbp), %rdx
	movq	%rdx, (%rax)
	movq	16(%rbp), %rax
	movq	(%rax), %rax
	movq	%rax, %rcx
	call	_ZN6locker4lockEv
	nop
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZN12locker_guardD1Ev,"x"
	.linkonce discard
	.align 2
	.globl	_ZN12locker_guardD1Ev
	.def	_ZN12locker_guardD1Ev;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN12locker_guardD1Ev
_ZN12locker_guardD1Ev:
.LFB1767:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	movq	(%rax), %rax
	movq	%rax, %rcx
	call	_ZN6locker6unlockEv
	nop
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_handler	__gxx_personality_seh0, @unwind, @except
	.seh_handlerdata
.LLSDA1767:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE1767-.LLSDACSB1767
.LLSDACSB1767:
.LLSDACSE1767:
	.section	.text$_ZN12locker_guardD1Ev,"x"
	.linkonce discard
	.seh_endproc
	.section	.text$_ZN4condC1Ev,"x"
	.linkonce discard
	.align 2
	.globl	_ZN4condC1Ev
	.def	_ZN4condC1Ev;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN4condC1Ev
_ZN4condC1Ev:
.LFB1770:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$40, %rsp
	.seh_stackalloc	40
	leaq	32(%rsp), %rbp
	.seh_setframe	%rbp, 32
	.seh_endprologue
	movq	%rcx, 32(%rbp)
	movq	32(%rbp), %rax
	movl	$0, %edx
	movq	%rax, %rcx
	call	pthread_cond_init
	testl	%eax, %eax
	setne	%al
	testb	%al, %al
	je	.L31
	movl	$8, %ecx
	call	__cxa_allocate_exception
	movq	%rax, %rbx
	movq	%rbx, %rcx
	call	_ZNSt9exceptionC1Ev
	movq	.refptr._ZNSt9exceptionD1Ev(%rip), %rdx
	leaq	_ZTISt9exception(%rip), %rax
	movq	%rdx, %r8
	movq	%rax, %rdx
	movq	%rbx, %rcx
	call	__cxa_throw
.L31:
	nop
	addq	$40, %rsp
	popq	%rbx
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZN4condD1Ev,"x"
	.linkonce discard
	.align 2
	.globl	_ZN4condD1Ev
	.def	_ZN4condD1Ev;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN4condD1Ev
_ZN4condD1Ev:
.LFB1773:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	pthread_cond_destroy
	nop
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_handler	__gxx_personality_seh0, @unwind, @except
	.seh_handlerdata
.LLSDA1773:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE1773-.LLSDACSB1773
.LLSDACSB1773:
.LLSDACSE1773:
	.section	.text$_ZN4condD1Ev,"x"
	.linkonce discard
	.seh_endproc
	.section	.text$_ZN4cond4waitEPx,"x"
	.linkonce discard
	.align 2
	.globl	_ZN4cond4waitEPx
	.def	_ZN4cond4waitEPx;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN4cond4waitEPx
_ZN4cond4waitEPx:
.LFB1774:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$48, %rsp
	.seh_stackalloc	48
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movl	$0, -4(%rbp)
	movq	16(%rbp), %rax
	movq	24(%rbp), %rdx
	movq	%rax, %rcx
	call	pthread_cond_wait
	movl	%eax, -4(%rbp)
	cmpl	$0, -4(%rbp)
	sete	%al
	addq	$48, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZN4cond9broadcastEv,"x"
	.linkonce discard
	.align 2
	.globl	_ZN4cond9broadcastEv
	.def	_ZN4cond9broadcastEv;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN4cond9broadcastEv
_ZN4cond9broadcastEv:
.LFB1777:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	pthread_cond_broadcast
	testl	%eax, %eax
	sete	%al
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.globl	_ZZN3Log12get_instanceEvE8instance
	.section	.data$_ZZN3Log12get_instanceEvE8instance,"w"
	.linkonce same_size
	.align 32
_ZZN3Log12get_instanceEvE8instance:
	.space 336
	.globl	_ZGVZN3Log12get_instanceEvE8instance
	.section	.data$_ZGVZN3Log12get_instanceEvE8instance,"w"
	.linkonce same_size
	.align 8
_ZGVZN3Log12get_instanceEvE8instance:
	.space 8
	.text
	.def	__tcf_ZZN3Log12get_instanceEvE8instance;	.scl	3;	.type	32;	.endef
	.seh_proc	__tcf_ZZN3Log12get_instanceEvE8instance
__tcf_ZZN3Log12get_instanceEvE8instance:
.LFB1791:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	leaq	_ZZN3Log12get_instanceEvE8instance(%rip), %rax
	movq	%rax, %rcx
	call	_ZN3LogD1Ev
	nop
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZN3Log12get_instanceEv,"x"
	.linkonce discard
	.globl	_ZN3Log12get_instanceEv
	.def	_ZN3Log12get_instanceEv;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN3Log12get_instanceEv
_ZN3Log12get_instanceEv:
.LFB1790:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rsi
	.seh_pushreg	%rsi
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$32, %rsp
	.seh_stackalloc	32
	leaq	32(%rsp), %rbp
	.seh_setframe	%rbp, 32
	.seh_endprologue
	movzbl	_ZGVZN3Log12get_instanceEvE8instance(%rip), %eax
	testb	%al, %al
	sete	%al
	testb	%al, %al
	je	.L39
	leaq	_ZGVZN3Log12get_instanceEvE8instance(%rip), %rax
	movq	%rax, %rcx
	call	__cxa_guard_acquire
	testl	%eax, %eax
	setne	%al
	testb	%al, %al
	je	.L39
	movl	$0, %esi
	leaq	_ZZN3Log12get_instanceEvE8instance(%rip), %rax
	movq	%rax, %rcx
.LEHB0:
	call	_ZN3LogC1Ev
.LEHE0:
	leaq	__tcf_ZZN3Log12get_instanceEvE8instance(%rip), %rax
	movq	%rax, %rcx
	call	atexit
	leaq	_ZGVZN3Log12get_instanceEvE8instance(%rip), %rax
	movq	%rax, %rcx
	call	__cxa_guard_release
.L39:
	leaq	_ZZN3Log12get_instanceEvE8instance(%rip), %rax
	jmp	.L44
.L43:
	movq	%rax, %rbx
	testb	%sil, %sil
	jne	.L42
	leaq	_ZGVZN3Log12get_instanceEvE8instance(%rip), %rax
	movq	%rax, %rcx
	call	__cxa_guard_abort
.L42:
	movq	%rbx, %rax
	movq	%rax, %rcx
.LEHB1:
	call	_Unwind_Resume
.LEHE1:
.L44:
	addq	$32, %rsp
	popq	%rbx
	popq	%rsi
	popq	%rbp
	ret
	.seh_handler	__gxx_personality_seh0, @unwind, @except
	.seh_handlerdata
.LLSDA1790:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE1790-.LLSDACSB1790
.LLSDACSB1790:
	.uleb128 .LEHB0-.LFB1790
	.uleb128 .LEHE0-.LEHB0
	.uleb128 .L43-.LFB1790
	.uleb128 0
	.uleb128 .LEHB1-.LFB1790
	.uleb128 .LEHE1-.LEHB1
	.uleb128 0
	.uleb128 0
.LLSDACSE1790:
	.section	.text$_ZN3Log12get_instanceEv,"x"
	.linkonce discard
	.seh_endproc
	.section .rdata,"dr"
	.align 8
.LC0:
	.ascii "Exception in flush_log_thread: \0"
	.section	.text$_ZN3Log16flush_log_threadEPv,"x"
	.linkonce discard
	.globl	_ZN3Log16flush_log_threadEPv
	.def	_ZN3Log16flush_log_threadEPv;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN3Log16flush_log_threadEPv
_ZN3Log16flush_log_threadEPv:
.LFB1792:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$56, %rsp
	.seh_stackalloc	56
	leaq	48(%rsp), %rbp
	.seh_setframe	%rbp, 48
	.seh_endprologue
	movq	%rcx, 32(%rbp)
.LEHB2:
	call	_ZN3Log12get_instanceEv
	movq	%rax, %rcx
	call	_ZN3Log15async_write_logEv
.LEHE2:
.L49:
	movl	$0, %eax
	jmp	.L53
.L51:
	cmpq	$1, %rdx
	je	.L48
	movq	%rax, %rcx
.LEHB3:
	call	_Unwind_Resume
.LEHE3:
.L48:
	movq	%rax, %rcx
	call	__cxa_begin_catch
	movq	%rax, -8(%rbp)
	leaq	.LC0(%rip), %rdx
	movq	.refptr._ZSt4cerr(%rip), %rax
	movq	%rax, %rcx
.LEHB4:
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc
	movq	%rax, %rbx
	movq	-8(%rbp), %rax
	movq	(%rax), %rax
	addq	$16, %rax
	movq	(%rax), %rdx
	movq	-8(%rbp), %rax
	movq	%rax, %rcx
	call	*%rdx
	movq	%rax, %rdx
	movq	%rbx, %rcx
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc
	movq	%rax, %rcx
	movq	.refptr._ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_(%rip), %rax
	movq	%rax, %rdx
	call	_ZNSolsEPFRSoS_E
.LEHE4:
	call	__cxa_end_catch
	jmp	.L49
.L52:
	movq	%rax, %rbx
	call	__cxa_end_catch
	movq	%rbx, %rax
	movq	%rax, %rcx
.LEHB5:
	call	_Unwind_Resume
.LEHE5:
.L53:
	addq	$56, %rsp
	popq	%rbx
	popq	%rbp
	ret
	.seh_handler	__gxx_personality_seh0, @unwind, @except
	.seh_handlerdata
	.align 4
.LLSDA1792:
	.byte	0xff
	.byte	0x9b
	.uleb128 .LLSDATT1792-.LLSDATTD1792
.LLSDATTD1792:
	.byte	0x1
	.uleb128 .LLSDACSE1792-.LLSDACSB1792
.LLSDACSB1792:
	.uleb128 .LEHB2-.LFB1792
	.uleb128 .LEHE2-.LEHB2
	.uleb128 .L51-.LFB1792
	.uleb128 0x1
	.uleb128 .LEHB3-.LFB1792
	.uleb128 .LEHE3-.LEHB3
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB4-.LFB1792
	.uleb128 .LEHE4-.LEHB4
	.uleb128 .L52-.LFB1792
	.uleb128 0
	.uleb128 .LEHB5-.LFB1792
	.uleb128 .LEHE5-.LEHB5
	.uleb128 0
	.uleb128 0
.LLSDACSE1792:
	.byte	0x1
	.byte	0
	.align 4
	.long	.LDFCM0-.
.LLSDATT1792:
	.section	.text$_ZN3Log16flush_log_threadEPv,"x"
	.linkonce discard
	.seh_endproc
	.section	.text$_ZN3Log15async_write_logEv,"x"
	.linkonce discard
	.align 2
	.globl	_ZN3Log15async_write_logEv
	.def	_ZN3Log15async_write_logEv;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN3Log15async_write_logEv
_ZN3Log15async_write_logEv:
.LFB1794:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$88, %rsp
	.seh_stackalloc	88
	leaq	80(%rsp), %rbp
	.seh_setframe	%rbp, 80
	.seh_endprologue
	movq	%rcx, 32(%rbp)
	leaq	-32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev
	jmp	.L55
.L56:
	movq	32(%rbp), %rax
	leaq	320(%rax), %rdx
	leaq	-40(%rbp), %rax
	movq	%rax, %rcx
.LEHB6:
	call	_ZN12locker_guardC1ER6locker
.LEHE6:
	movq	32(%rbp), %rax
	movq	288(%rax), %rbx
	leaq	-32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE5c_strEv
	movq	%rbx, %rdx
	movq	%rax, %rcx
.LEHB7:
	call	fputs
.LEHE7:
	leaq	-40(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN12locker_guardD1Ev
.L55:
	movq	32(%rbp), %rax
	movq	304(%rax), %rax
	leaq	-32(%rbp), %rdx
	movq	%rax, %rcx
.LEHB8:
	call	_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEE3popERS5_
.LEHE8:
	testb	%al, %al
	jne	.L56
	leaq	-32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev
	jmp	.L61
.L59:
	movq	%rax, %rbx
	leaq	-40(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN12locker_guardD1Ev
	jmp	.L58
.L60:
	movq	%rax, %rbx
.L58:
	leaq	-32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev
	movq	%rbx, %rax
	movq	%rax, %rcx
.LEHB9:
	call	_Unwind_Resume
	nop
.LEHE9:
.L61:
	addq	$88, %rsp
	popq	%rbx
	popq	%rbp
	ret
	.seh_handler	__gxx_personality_seh0, @unwind, @except
	.seh_handlerdata
.LLSDA1794:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE1794-.LLSDACSB1794
.LLSDACSB1794:
	.uleb128 .LEHB6-.LFB1794
	.uleb128 .LEHE6-.LEHB6
	.uleb128 .L60-.LFB1794
	.uleb128 0
	.uleb128 .LEHB7-.LFB1794
	.uleb128 .LEHE7-.LEHB7
	.uleb128 .L59-.LFB1794
	.uleb128 0
	.uleb128 .LEHB8-.LFB1794
	.uleb128 .LEHE8-.LEHB8
	.uleb128 .L60-.LFB1794
	.uleb128 0
	.uleb128 .LEHB9-.LFB1794
	.uleb128 .LEHE9-.LEHB9
	.uleb128 0
	.uleb128 0
.LLSDACSE1794:
	.section	.text$_ZN3Log15async_write_logEv,"x"
	.linkonce discard
	.seh_endproc
	.text
	.align 2
	.globl	_ZN3LogC2Ev
	.def	_ZN3LogC2Ev;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN3LogC2Ev
_ZN3LogC2Ev:
.LFB1796:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	leaq	16+_ZTV3Log(%rip), %rdx
	movq	16(%rbp), %rax
	movq	%rdx, (%rax)
	movq	16(%rbp), %rax
	addq	$320, %rax
	movq	%rax, %rcx
	call	_ZN6lockerC1Ev
	movq	16(%rbp), %rax
	movq	$0, 272(%rax)
	movq	16(%rbp), %rax
	movb	$0, 312(%rax)
	movq	16(%rbp), %rax
	movq	$0, 288(%rax)
	movq	16(%rbp), %rax
	movq	$0, 296(%rax)
	movq	16(%rbp), %rax
	movq	$0, 304(%rax)
	movq	16(%rbp), %rax
	movl	$1, 328(%rax)
	movq	16(%rbp), %rax
	movl	$0, 280(%rax)
	movq	16(%rbp), %rax
	movl	$0, 264(%rax)
	movq	16(%rbp), %rax
	movl	$0, 268(%rax)
	movq	16(%rbp), %rax
	addq	$8, %rax
	movl	$128, %r8d
	movl	$0, %edx
	movq	%rax, %rcx
	call	memset
	movq	16(%rbp), %rax
	addq	$136, %rax
	movl	$128, %r8d
	movl	$0, %edx
	movq	%rax, %rcx
	call	memset
	nop
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.globl	_ZN3LogC1Ev
	.def	_ZN3LogC1Ev;	.scl	2;	.type	32;	.endef
	.set	_ZN3LogC1Ev,_ZN3LogC2Ev
	.align 2
	.globl	_ZN3LogD2Ev
	.def	_ZN3LogD2Ev;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN3LogD2Ev
_ZN3LogD2Ev:
.LFB1799:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$40, %rsp
	.seh_stackalloc	40
	leaq	32(%rsp), %rbp
	.seh_setframe	%rbp, 32
	.seh_endprologue
	movq	%rcx, 32(%rbp)
	leaq	16+_ZTV3Log(%rip), %rdx
	movq	32(%rbp), %rax
	movq	%rdx, (%rax)
	movq	32(%rbp), %rax
	movq	288(%rax), %rax
	testq	%rax, %rax
	je	.L64
	movq	32(%rbp), %rax
	movq	288(%rax), %rax
	movq	%rax, %rcx
	call	fflush
	movq	32(%rbp), %rax
	movq	288(%rax), %rax
	movq	%rax, %rcx
	call	fclose
	movq	32(%rbp), %rax
	movq	$0, 288(%rax)
.L64:
	movq	32(%rbp), %rax
	movzbl	312(%rax), %eax
	testb	%al, %al
	je	.L65
	movq	32(%rbp), %rax
	movq	304(%rax), %rax
	testq	%rax, %rax
	je	.L65
	movq	32(%rbp), %rax
	movq	304(%rax), %rbx
	testq	%rbx, %rbx
	je	.L66
	movq	%rbx, %rcx
	call	_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEED1Ev
	movq	%rbx, %rcx
	call	_ZdlPv
.L66:
	movq	32(%rbp), %rax
	movq	$0, 304(%rax)
.L65:
	movq	32(%rbp), %rax
	movq	296(%rax), %rax
	testq	%rax, %rax
	je	.L67
	movq	32(%rbp), %rax
	movq	296(%rax), %rax
	movq	%rax, %rcx
	call	_ZdaPv
.L67:
	movq	32(%rbp), %rax
	movq	$0, 296(%rax)
	movq	32(%rbp), %rax
	addq	$320, %rax
	movq	%rax, %rcx
	call	_ZN6lockerD1Ev
	nop
	addq	$40, %rsp
	popq	%rbx
	popq	%rbp
	ret
	.seh_handler	__gxx_personality_seh0, @unwind, @except
	.seh_handlerdata
.LLSDA1799:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE1799-.LLSDACSB1799
.LLSDACSB1799:
.LLSDACSE1799:
	.text
	.seh_endproc
	.globl	_ZN3LogD1Ev
	.def	_ZN3LogD1Ev;	.scl	2;	.type	32;	.endef
	.set	_ZN3LogD1Ev,_ZN3LogD2Ev
	.align 2
	.globl	_ZN3LogD0Ev
	.def	_ZN3LogD0Ev;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN3LogD0Ev
_ZN3LogD0Ev:
.LFB1801:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN3LogD1Ev
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZdlPv
	nop
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC1:
	.ascii "Invalid log configuration.\0"
.LC2:
	.ascii "Failed to get local time.\0"
.LC3:
	.ascii "%s\0"
.LC4:
	.ascii "%d_%02d_%02d_%s\0"
.LC5:
	.ascii "%s%d_%02d_%02d_%s\0"
.LC6:
	.ascii "a\0"
.LC7:
	.ascii "Failed to open log file: \0"
.LC8:
	.ascii "Failed to create log thread.\0"
	.text
	.align 2
	.globl	_ZN3Log4initEPKciiii
	.def	_ZN3Log4initEPKciiii;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN3Log4initEPKciiii
_ZN3Log4initEPKciiii:
.LFB1802:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rdi
	.seh_pushreg	%rdi
	pushq	%rsi
	.seh_pushreg	%rsi
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$424, %rsp
	.seh_stackalloc	424
	leaq	128(%rsp), %rbp
	.seh_setframe	%rbp, 128
	.seh_endprologue
	movq	%rcx, 336(%rbp)
	movq	%rdx, 344(%rbp)
	movl	%r8d, 352(%rbp)
	movl	%r9d, 360(%rbp)
	cmpq	$0, 344(%rbp)
	je	.L70
	cmpl	$2, 360(%rbp)
	jle	.L70
	cmpl	$0, 368(%rbp)
	jg	.L71
.L70:
	leaq	.LC1(%rip), %rdx
	movq	.refptr._ZSt4cerr(%rip), %rax
	movq	%rax, %rcx
.LEHB10:
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc
	movq	%rax, %rcx
	movq	.refptr._ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_(%rip), %rax
	movq	%rax, %rdx
	call	_ZNSolsEPFRSoS_E
	movl	$0, %eax
	jmp	.L89
.L71:
	cmpl	$0, 376(%rbp)
	setg	%al
	movb	%al, 279(%rbp)
	movq	336(%rbp), %rax
	movl	352(%rbp), %edx
	movl	%edx, 328(%rax)
	movq	336(%rbp), %rax
	movl	360(%rbp), %edx
	movl	%edx, 268(%rax)
	movq	336(%rbp), %rax
	movl	268(%rax), %eax
	cltq
	movq	%rax, %rcx
	call	_Znay
	movq	%rax, %rdx
	movq	336(%rbp), %rax
	movq	%rdx, 296(%rax)
	movq	336(%rbp), %rax
	movl	268(%rax), %eax
	movslq	%eax, %rdx
	movq	336(%rbp), %rax
	movq	296(%rax), %rax
	movq	%rdx, %r8
	movl	$0, %edx
	movq	%rax, %rcx
	call	memset
	movq	336(%rbp), %rax
	movl	368(%rbp), %edx
	movl	%edx, 264(%rax)
	movl	$0, %ecx
	call	_time64
	movq	%rax, 256(%rbp)
	leaq	208(%rbp), %rdx
	leaq	256(%rbp), %rax
	movq	%rax, %rcx
	call	_ZL11localtime_rPKxP2tm
	testq	%rax, %rax
	sete	%al
	testb	%al, %al
	je	.L73
	leaq	.LC2(%rip), %rdx
	movq	.refptr._ZSt4cerr(%rip), %rax
	movq	%rax, %rcx
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc
	movq	%rax, %rcx
	movq	.refptr._ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_(%rip), %rax
	movq	%rax, %rdx
	call	_ZNSolsEPFRSoS_E
	movq	336(%rbp), %rax
	movq	296(%rax), %rax
	testq	%rax, %rax
	je	.L74
	movq	336(%rbp), %rax
	movq	296(%rax), %rax
	movq	%rax, %rcx
	call	_ZdaPv
.L74:
	movq	336(%rbp), %rax
	movq	$0, 296(%rax)
	movl	$0, %eax
	jmp	.L89
.L73:
	movq	344(%rbp), %rax
	movl	$47, %edx
	movq	%rax, %rcx
	call	strrchr
	movq	%rax, 264(%rbp)
	movq	$0, -48(%rbp)
	movq	$0, -40(%rbp)
	movq	$0, -32(%rbp)
	movq	$0, -24(%rbp)
	movq	$0, -16(%rbp)
	movq	$0, -8(%rbp)
	movq	$0, 0(%rbp)
	movq	$0, 8(%rbp)
	movq	$0, 16(%rbp)
	movq	$0, 24(%rbp)
	movq	$0, 32(%rbp)
	movq	$0, 40(%rbp)
	movq	$0, 48(%rbp)
	movq	$0, 56(%rbp)
	movq	$0, 64(%rbp)
	movq	$0, 72(%rbp)
	movq	$0, 80(%rbp)
	movq	$0, 88(%rbp)
	movq	$0, 96(%rbp)
	movq	$0, 104(%rbp)
	movq	$0, 112(%rbp)
	movq	$0, 120(%rbp)
	movq	$0, 128(%rbp)
	movq	$0, 136(%rbp)
	movq	$0, 144(%rbp)
	movq	$0, 152(%rbp)
	movq	$0, 160(%rbp)
	movq	$0, 168(%rbp)
	movq	$0, 176(%rbp)
	movq	$0, 184(%rbp)
	movq	$0, 192(%rbp)
	movq	$0, 200(%rbp)
	cmpq	$0, 264(%rbp)
	jne	.L75
	movq	336(%rbp), %rax
	movb	$0, 8(%rax)
	movq	336(%rbp), %rax
	addq	$136, %rax
	movq	344(%rbp), %rdx
	leaq	.LC3(%rip), %rcx
	movq	%rdx, %r9
	movq	%rcx, %r8
	movl	$128, %edx
	movq	%rax, %rcx
	call	__mingw_snprintf
	movq	336(%rbp), %rax
	leaq	136(%rax), %r8
	movl	220(%rbp), %edx
	movl	224(%rbp), %eax
	leal	1(%rax), %ecx
	movl	228(%rbp), %eax
	leal	1900(%rax), %r9d
	leaq	.LC4(%rip), %r10
	leaq	-48(%rbp), %rax
	movq	%r8, 48(%rsp)
	movl	%edx, 40(%rsp)
	movl	%ecx, 32(%rsp)
	movq	%r10, %r8
	movl	$256, %edx
	movq	%rax, %rcx
	call	__mingw_snprintf
	jmp	.L76
.L75:
	movq	264(%rbp), %rax
	leaq	1(%rax), %rcx
	movq	336(%rbp), %rax
	addq	$136, %rax
	leaq	.LC3(%rip), %rdx
	movq	%rcx, %r9
	movq	%rdx, %r8
	movl	$128, %edx
	movq	%rax, %rcx
	call	__mingw_snprintf
	movq	264(%rbp), %rax
	subq	344(%rbp), %rax
	addq	$1, %rax
	movq	%rax, 280(%rbp)
	cmpq	$127, 280(%rbp)
	jbe	.L77
	movq	$127, 280(%rbp)
.L77:
	movq	336(%rbp), %rax
	leaq	8(%rax), %rcx
	movq	280(%rbp), %rdx
	movq	344(%rbp), %rax
	movq	%rdx, %r8
	movq	%rax, %rdx
	call	memcpy
	movq	336(%rbp), %rdx
	movq	280(%rbp), %rax
	addq	%rdx, %rax
	addq	$8, %rax
	movb	$0, (%rax)
	movq	336(%rbp), %rax
	leaq	136(%rax), %r9
	movl	220(%rbp), %edx
	movl	224(%rbp), %eax
	leal	1(%rax), %r8d
	movl	228(%rbp), %eax
	leal	1900(%rax), %ecx
	movq	336(%rbp), %rax
	leaq	8(%rax), %r11
	leaq	.LC5(%rip), %r10
	leaq	-48(%rbp), %rax
	movq	%r9, 56(%rsp)
	movl	%edx, 48(%rsp)
	movl	%r8d, 40(%rsp)
	movl	%ecx, 32(%rsp)
	movq	%r11, %r9
	movq	%r10, %r8
	movl	$256, %edx
	movq	%rax, %rcx
	call	__mingw_snprintf
.L76:
	movl	220(%rbp), %edx
	movq	336(%rbp), %rax
	movl	%edx, 280(%rax)
	leaq	.LC6(%rip), %rdx
	leaq	-48(%rbp), %rax
	movq	%rax, %rcx
	call	fopen
	movq	336(%rbp), %rdx
	movq	%rax, 288(%rdx)
	movq	336(%rbp), %rax
	movq	288(%rax), %rax
	testq	%rax, %rax
	jne	.L78
	leaq	.LC7(%rip), %rdx
	movq	.refptr._ZSt4cerr(%rip), %rax
	movq	%rax, %rcx
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc
	movq	%rax, %rcx
	leaq	-48(%rbp), %rax
	movq	%rax, %rdx
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc
	movq	%rax, %rcx
	movq	.refptr._ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_(%rip), %rax
	movq	%rax, %rdx
	call	_ZNSolsEPFRSoS_E
	movq	336(%rbp), %rax
	movq	296(%rax), %rax
	testq	%rax, %rax
	je	.L79
	movq	336(%rbp), %rax
	movq	296(%rax), %rax
	movq	%rax, %rcx
	call	_ZdaPv
.L79:
	movq	336(%rbp), %rax
	movq	$0, 296(%rax)
	movl	$0, %eax
	jmp	.L89
.L78:
	cmpb	$0, 279(%rbp)
	je	.L80
	movl	$40, %ecx
	call	_Znwy
.LEHE10:
	movq	%rax, %rbx
	movl	$1, %edi
	movl	376(%rbp), %eax
	movl	%eax, %edx
	movq	%rbx, %rcx
.LEHB11:
	call	_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEEC1Ei
.LEHE11:
	movl	$0, %edx
	movq	336(%rbp), %rax
	movq	%rbx, 304(%rax)
	testb	%dl, %dl
	je	.L90
	movq	%rbx, %rcx
	call	_ZdlPv
.L90:
	nop
	leaq	_ZN3Log16flush_log_threadEPv(%rip), %rax
	movq	%rax, %rdx
	leaq	-56(%rbp), %rax
	movl	$0, %r9d
	movq	%rdx, %r8
	movl	$0, %edx
	movq	%rax, %rcx
.LEHB12:
	call	pthread_create
	testl	%eax, %eax
	setne	%al
	testb	%al, %al
	je	.L82
	leaq	.LC8(%rip), %rdx
	movq	.refptr._ZSt4cerr(%rip), %rax
	movq	%rax, %rcx
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc
	movq	%rax, %rcx
	movq	.refptr._ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_(%rip), %rax
	movq	%rax, %rdx
	call	_ZNSolsEPFRSoS_E
	movq	336(%rbp), %rax
	movq	304(%rax), %rbx
	testq	%rbx, %rbx
	je	.L83
	movq	%rbx, %rcx
	call	_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEED1Ev
	movq	%rbx, %rcx
	call	_ZdlPv
.L83:
	movq	336(%rbp), %rax
	movq	$0, 304(%rax)
	movq	336(%rbp), %rax
	movq	288(%rax), %rax
	movq	%rax, %rcx
	call	fclose
	movq	336(%rbp), %rax
	movq	$0, 288(%rax)
	movq	336(%rbp), %rax
	movq	296(%rax), %rax
	testq	%rax, %rax
	je	.L84
	movq	336(%rbp), %rax
	movq	296(%rax), %rax
	movq	%rax, %rcx
	call	_ZdaPv
.L84:
	movq	336(%rbp), %rax
	movq	$0, 296(%rax)
	movl	$0, %eax
	jmp	.L89
.L82:
	movq	-56(%rbp), %rax
	movq	%rax, %rcx
	call	pthread_detach
	movq	336(%rbp), %rax
	movb	$1, 312(%rax)
.L80:
	movl	$1, %eax
	jmp	.L89
.L88:
	movq	%rax, %rsi
	testb	%dil, %dil
	je	.L91
	movq	%rbx, %rcx
	call	_ZdlPv
.L91:
	nop
	movq	%rsi, %rax
	movq	%rax, %rcx
	call	_Unwind_Resume
.LEHE12:
.L89:
	addq	$424, %rsp
	popq	%rbx
	popq	%rsi
	popq	%rdi
	popq	%rbp
	ret
	.seh_handler	__gxx_personality_seh0, @unwind, @except
	.seh_handlerdata
.LLSDA1802:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE1802-.LLSDACSB1802
.LLSDACSB1802:
	.uleb128 .LEHB10-.LFB1802
	.uleb128 .LEHE10-.LEHB10
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB11-.LFB1802
	.uleb128 .LEHE11-.LEHB11
	.uleb128 .L88-.LFB1802
	.uleb128 0
	.uleb128 .LEHB12-.LFB1802
	.uleb128 .LEHE12-.LEHB12
	.uleb128 0
	.uleb128 0
.LLSDACSE1802:
	.text
	.seh_endproc
.lcomm _ZZN3Log9write_logEiPKczE12dropped_logs,4,4
	.section .rdata,"dr"
.LC9:
	.ascii "%d_%02d_%02d_\0"
.LC10:
	.ascii "%s%s%s\0"
.LC11:
	.ascii "%s%s%s.%lld\0"
	.align 8
.LC12:
	.ascii "%d-%02d-%02d %02d:%02d:%02d.%06ld %s \0"
	.align 8
.LC13:
	.ascii "Log queue full. Dropped logs count: \0"
	.text
	.align 2
	.globl	_ZN3Log9write_logEiPKcz
	.def	_ZN3Log9write_logEiPKcz;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN3Log9write_logEiPKcz
_ZN3Log9write_logEiPKcz:
.LFB1803:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%r12
	.seh_pushreg	%r12
	pushq	%rdi
	.seh_pushreg	%rdi
	pushq	%rsi
	.seh_pushreg	%rsi
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$544, %rsp
	.seh_stackalloc	544
	leaq	128(%rsp), %rbp
	.seh_setframe	%rbp, 128
	.seh_endprologue
	movq	%rcx, 464(%rbp)
	movl	%edx, 472(%rbp)
	movq	%r8, 480(%rbp)
	movq	%r9, 488(%rbp)
	cmpq	$0, 480(%rbp)
	je	.L134
	movq	464(%rbp), %rax
	movq	296(%rax), %rax
	testq	%rax, %rax
	je	.L134
	movq	464(%rbp), %rax
	movq	288(%rax), %rax
	testq	%rax, %rax
	je	.L134
	movq	464(%rbp), %rax
	movl	268(%rax), %eax
	cmpl	$2, %eax
	jle	.L134
	movq	464(%rbp), %rax
	movl	264(%rax), %eax
	testl	%eax, %eax
	jle	.L134
	movl	$0, 388(%rbp)
	movl	$0, 392(%rbp)
	leaq	388(%rbp), %rax
	movl	$0, %edx
	movq	%rax, %rcx
.LEHB13:
	call	gettimeofday
	movl	388(%rbp), %eax
	cltq
	movq	%rax, 376(%rbp)
	leaq	336(%rbp), %rdx
	leaq	376(%rbp), %rax
	movq	%rax, %rcx
	call	_ZL11localtime_rPKxP2tm
	testq	%rax, %rax
	sete	%al
	testb	%al, %al
	jne	.L135
	movq	$0, 320(%rbp)
	movq	$0, 328(%rbp)
	cmpl	$3, 472(%rbp)
	je	.L97
	cmpl	$3, 472(%rbp)
	jg	.L98
	cmpl	$2, 472(%rbp)
	je	.L99
	cmpl	$2, 472(%rbp)
	jg	.L98
	cmpl	$0, 472(%rbp)
	je	.L100
	cmpl	$1, 472(%rbp)
	je	.L101
	jmp	.L98
.L100:
	leaq	320(%rbp), %rax
	movabsq	$4205631380893557851, %rsi
	movq	%rsi, (%rax)
	movb	$0, 8(%rax)
	jmp	.L102
.L101:
	leaq	320(%rbp), %rax
	movabsq	$16428281690483035, %rdi
	movq	%rdi, (%rax)
	jmp	.L102
.L99:
	leaq	320(%rbp), %rax
	movabsq	$16428277595993947, %rsi
	movq	%rsi, (%rax)
	jmp	.L102
.L97:
	leaq	320(%rbp), %rax
	movabsq	$4205643450020947291, %rdi
	movq	%rdi, (%rax)
	movb	$0, 8(%rax)
	jmp	.L102
.L98:
	leaq	320(%rbp), %rax
	movabsq	$16428281690483035, %rsi
	movq	%rsi, (%rax)
	nop
.L102:
	movq	464(%rbp), %rax
	leaq	320(%rax), %rdx
	leaq	256(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN12locker_guardC1ER6locker
.LEHE13:
	movq	464(%rbp), %rax
	movq	272(%rax), %rax
	leaq	1(%rax), %rdx
	movq	464(%rbp), %rax
	movq	%rdx, 272(%rax)
	movq	464(%rbp), %rax
	movl	280(%rax), %edx
	movl	348(%rbp), %eax
	cmpl	%eax, %edx
	jne	.L103
	movq	464(%rbp), %rax
	movq	272(%rax), %rax
	movq	464(%rbp), %rdx
	movl	264(%rdx), %edx
	movslq	%edx, %rdi
	cqto
	idivq	%rdi
	movq	%rdx, %rcx
	movq	%rcx, %rax
	testq	%rax, %rax
	jne	.L104
.L103:
	movq	$0, -32(%rbp)
	movq	$0, -24(%rbp)
	movq	$0, -16(%rbp)
	movq	$0, -8(%rbp)
	movq	$0, 0(%rbp)
	movq	$0, 8(%rbp)
	movq	$0, 16(%rbp)
	movq	$0, 24(%rbp)
	movq	$0, 32(%rbp)
	movq	$0, 40(%rbp)
	movq	$0, 48(%rbp)
	movq	$0, 56(%rbp)
	movq	$0, 64(%rbp)
	movq	$0, 72(%rbp)
	movq	$0, 80(%rbp)
	movq	$0, 88(%rbp)
	movq	$0, 96(%rbp)
	movq	$0, 104(%rbp)
	movq	$0, 112(%rbp)
	movq	$0, 120(%rbp)
	movq	$0, 128(%rbp)
	movq	$0, 136(%rbp)
	movq	$0, 144(%rbp)
	movq	$0, 152(%rbp)
	movq	$0, 160(%rbp)
	movq	$0, 168(%rbp)
	movq	$0, 176(%rbp)
	movq	$0, 184(%rbp)
	movq	$0, 192(%rbp)
	movq	$0, 200(%rbp)
	movq	$0, 208(%rbp)
	movq	$0, 216(%rbp)
	movq	464(%rbp), %rax
	movq	288(%rax), %rax
	movq	%rax, %rcx
.LEHB14:
	call	fflush
	movq	464(%rbp), %rax
	movq	288(%rax), %rax
	movq	%rax, %rcx
	call	fclose
	movq	464(%rbp), %rax
	movq	$0, 288(%rax)
	movq	$0, 240(%rbp)
	movq	$0, 248(%rbp)
	movl	348(%rbp), %edx
	movl	352(%rbp), %eax
	leal	1(%rax), %ecx
	movl	356(%rbp), %eax
	leal	1900(%rax), %r9d
	leaq	.LC9(%rip), %r8
	leaq	240(%rbp), %rax
	movl	%edx, 40(%rsp)
	movl	%ecx, 32(%rsp)
	movl	$16, %edx
	movq	%rax, %rcx
	call	__mingw_snprintf
	movq	464(%rbp), %rax
	movl	280(%rax), %edx
	movl	348(%rbp), %eax
	cmpl	%eax, %edx
	je	.L105
	movq	464(%rbp), %rax
	leaq	136(%rax), %rdx
	movq	464(%rbp), %rax
	leaq	8(%rax), %r8
	leaq	.LC10(%rip), %rcx
	leaq	-32(%rbp), %rax
	movq	%rdx, 40(%rsp)
	leaq	240(%rbp), %rdx
	movq	%rdx, 32(%rsp)
	movq	%r8, %r9
	movq	%rcx, %r8
	movl	$256, %edx
	movq	%rax, %rcx
	call	__mingw_snprintf
	movl	348(%rbp), %edx
	movq	464(%rbp), %rax
	movl	%edx, 280(%rax)
	movq	464(%rbp), %rax
	movq	$0, 272(%rax)
	jmp	.L106
.L105:
	movq	464(%rbp), %rax
	movq	272(%rax), %rax
	movq	464(%rbp), %rdx
	movl	264(%rdx), %edx
	movslq	%edx, %rsi
	cqto
	idivq	%rsi
	movq	%rax, %r9
	movq	464(%rbp), %rax
	leaq	136(%rax), %rdx
	movq	464(%rbp), %rax
	leaq	8(%rax), %r8
	leaq	.LC11(%rip), %rcx
	leaq	-32(%rbp), %rax
	movq	%r9, 48(%rsp)
	movq	%rdx, 40(%rsp)
	leaq	240(%rbp), %rdx
	movq	%rdx, 32(%rsp)
	movq	%r8, %r9
	movq	%rcx, %r8
	movl	$256, %edx
	movq	%rax, %rcx
	call	__mingw_snprintf
.L106:
	leaq	.LC6(%rip), %rdx
	leaq	-32(%rbp), %rax
	movq	%rax, %rcx
	call	fopen
	movq	464(%rbp), %rdx
	movq	%rax, 288(%rdx)
	movq	464(%rbp), %rax
	movq	288(%rax), %rax
	testq	%rax, %rax
	jne	.L104
	leaq	.LC7(%rip), %rdx
	movq	.refptr._ZSt4cerr(%rip), %rax
	movq	%rax, %rcx
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc
	movq	%rax, %rcx
	leaq	-32(%rbp), %rax
	movq	%rax, %rdx
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc
	movq	%rax, %rcx
	movq	.refptr._ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_(%rip), %rax
	movq	%rax, %rdx
	call	_ZNSolsEPFRSoS_E
.LEHE14:
	movl	$0, %ebx
	jmp	.L108
.L104:
	movl	$1, %ebx
.L108:
	leaq	256(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN12locker_guardD1Ev
	cmpl	$1, %ebx
	jne	.L136
	nop
	leaq	488(%rbp), %rax
	movq	%rax, 312(%rbp)
	leaq	272(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev
	movb	$1, 415(%rbp)
	movq	464(%rbp), %rax
	leaq	320(%rax), %rdx
	leaq	232(%rbp), %rax
	movq	%rax, %rcx
.LEHB15:
	call	_ZN12locker_guardC1ER6locker
.LEHE15:
	movl	392(%rbp), %r11d
	movl	336(%rbp), %r10d
	movl	340(%rbp), %r9d
	movl	344(%rbp), %r8d
	movl	348(%rbp), %ecx
	movl	352(%rbp), %eax
	leal	1(%rax), %esi
	movl	356(%rbp), %eax
	leal	1900(%rax), %r12d
	movq	464(%rbp), %rax
	movl	268(%rax), %eax
	movslq	%eax, %rdx
	movq	464(%rbp), %rax
	movq	296(%rax), %rax
	leaq	.LC12(%rip), %rdi
	leaq	320(%rbp), %rbx
	movq	%rbx, 80(%rsp)
	movl	%r11d, 72(%rsp)
	movl	%r10d, 64(%rsp)
	movl	%r9d, 56(%rsp)
	movl	%r8d, 48(%rsp)
	movl	%ecx, 40(%rsp)
	movl	%esi, 32(%rsp)
	movl	%r12d, %r9d
	movq	%rdi, %r8
	movq	%rax, %rcx
.LEHB16:
	call	__mingw_snprintf
	movl	%eax, 404(%rbp)
	cmpl	$0, 404(%rbp)
	jns	.L111
	movb	$0, 415(%rbp)
	jmp	.L112
.L111:
	movl	404(%rbp), %eax
	movl	%eax, 408(%rbp)
	movq	464(%rbp), %rax
	movl	268(%rax), %eax
	subl	$1, %eax
	cmpl	%eax, 408(%rbp)
	jl	.L113
	movq	464(%rbp), %rax
	movl	268(%rax), %eax
	subl	$2, %eax
	movl	%eax, 408(%rbp)
.L113:
	movq	464(%rbp), %rax
	movl	268(%rax), %eax
	subl	408(%rbp), %eax
	subl	$1, %eax
	movl	%eax, 400(%rbp)
	movq	312(%rbp), %r8
	movl	400(%rbp), %eax
	cltq
	movq	464(%rbp), %rdx
	movq	296(%rdx), %rcx
	movl	408(%rbp), %edx
	movslq	%edx, %rdx
	addq	%rdx, %rcx
	movq	480(%rbp), %rdx
	movq	%r8, %r9
	movq	%rdx, %r8
	movq	%rax, %rdx
	call	_Z9vsnprintfPcyPKcS_
	movl	%eax, 396(%rbp)
	cmpl	$0, 396(%rbp)
	jns	.L114
	movb	$0, 415(%rbp)
	jmp	.L112
.L114:
	movl	396(%rbp), %eax
	cmpl	400(%rbp), %eax
	jl	.L115
	movq	464(%rbp), %rax
	movl	268(%rax), %eax
	subl	$2, %eax
	movl	%eax, 408(%rbp)
	jmp	.L116
.L115:
	movl	396(%rbp), %eax
	addl	%eax, 408(%rbp)
.L116:
	movq	464(%rbp), %rax
	movq	296(%rax), %rcx
	movl	408(%rbp), %eax
	leal	1(%rax), %edx
	movl	%edx, 408(%rbp)
	cltq
	addq	%rcx, %rax
	movb	$10, (%rax)
	movq	464(%rbp), %rax
	movq	296(%rax), %rdx
	movl	408(%rbp), %eax
	cltq
	addq	%rdx, %rax
	movb	$0, (%rax)
	movq	464(%rbp), %rax
	movq	296(%rax), %rdx
	leaq	272(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSEPKc
.LEHE16:
.L112:
	leaq	232(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN12locker_guardD1Ev
	movzbl	415(%rbp), %eax
	xorl	$1, %eax
	testb	%al, %al
	je	.L117
	movl	$0, %ebx
	jmp	.L118
.L117:
	movq	464(%rbp), %rax
	movzbl	312(%rax), %eax
	testb	%al, %al
	je	.L119
	movq	464(%rbp), %rax
	movq	304(%rax), %rax
	testq	%rax, %rax
	je	.L119
	movq	464(%rbp), %rax
	movq	304(%rax), %rax
	leaq	272(%rbp), %rdx
	movq	%rax, %rcx
.LEHB17:
	call	_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEE4pushERKS5_
	xorl	$1, %eax
	testb	%al, %al
	je	.L120
	movq	464(%rbp), %rax
	leaq	320(%rax), %rdx
	leaq	224(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN12locker_guardC1ER6locker
.LEHE17:
	movl	_ZZN3Log9write_logEiPKczE12dropped_logs(%rip), %eax
	addl	$1, %eax
	movl	%eax, _ZZN3Log9write_logEiPKczE12dropped_logs(%rip)
	movl	_ZZN3Log9write_logEiPKczE12dropped_logs(%rip), %edx
	movslq	%edx, %rax
	imulq	$1374389535, %rax, %rax
	shrq	$32, %rax
	sarl	$5, %eax
	movl	%edx, %ecx
	sarl	$31, %ecx
	subl	%ecx, %eax
	imull	$100, %eax, %ecx
	movl	%edx, %eax
	subl	%ecx, %eax
	testl	%eax, %eax
	jne	.L121
	leaq	.LC13(%rip), %rdx
	movq	.refptr._ZSt4cerr(%rip), %rax
	movq	%rax, %rcx
.LEHB18:
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc
	movq	%rax, %rcx
	movl	_ZZN3Log9write_logEiPKczE12dropped_logs(%rip), %eax
	movl	%eax, %edx
	call	_ZNSolsEi
	movq	%rax, %rcx
	movq	.refptr._ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_(%rip), %rax
	movq	%rax, %rdx
	call	_ZNSolsEPFRSoS_E
.LEHE18:
.L121:
	leaq	224(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN12locker_guardD1Ev
.L120:
	movl	$0, %ebx
	jmp	.L118
.L119:
	movq	464(%rbp), %rax
	leaq	320(%rax), %rdx
	leaq	264(%rbp), %rax
	movq	%rax, %rcx
.LEHB19:
	call	_ZN12locker_guardC1ER6locker
.LEHE19:
	movq	464(%rbp), %rax
	movq	288(%rax), %rax
	testq	%rax, %rax
	je	.L122
	movq	464(%rbp), %rax
	movq	288(%rax), %rbx
	leaq	272(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE5c_strEv
	movq	%rbx, %rdx
	movq	%rax, %rcx
.LEHB20:
	call	fputs
.LEHE20:
.L122:
	leaq	264(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN12locker_guardD1Ev
	movl	$1, %ebx
.L118:
	leaq	272(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev
	cmpl	$1, %ebx
	jmp	.L136
.L129:
	movq	%rax, %rbx
	leaq	256(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN12locker_guardD1Ev
	movq	%rbx, %rax
	movq	%rax, %rcx
.LEHB21:
	call	_Unwind_Resume
.L130:
	movq	%rax, %rbx
	leaq	232(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN12locker_guardD1Ev
	jmp	.L126
.L132:
	movq	%rax, %rbx
	leaq	224(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN12locker_guardD1Ev
	jmp	.L126
.L133:
	movq	%rax, %rbx
	leaq	264(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN12locker_guardD1Ev
	jmp	.L126
.L131:
	movq	%rax, %rbx
.L126:
	leaq	272(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev
	movq	%rbx, %rax
	movq	%rax, %rcx
	call	_Unwind_Resume
.LEHE21:
.L134:
	nop
	jmp	.L92
.L135:
	nop
	jmp	.L92
.L136:
	nop
.L92:
	addq	$544, %rsp
	popq	%rbx
	popq	%rsi
	popq	%rdi
	popq	%r12
	popq	%rbp
	ret
	.seh_handler	__gxx_personality_seh0, @unwind, @except
	.seh_handlerdata
.LLSDA1803:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE1803-.LLSDACSB1803
.LLSDACSB1803:
	.uleb128 .LEHB13-.LFB1803
	.uleb128 .LEHE13-.LEHB13
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB14-.LFB1803
	.uleb128 .LEHE14-.LEHB14
	.uleb128 .L129-.LFB1803
	.uleb128 0
	.uleb128 .LEHB15-.LFB1803
	.uleb128 .LEHE15-.LEHB15
	.uleb128 .L131-.LFB1803
	.uleb128 0
	.uleb128 .LEHB16-.LFB1803
	.uleb128 .LEHE16-.LEHB16
	.uleb128 .L130-.LFB1803
	.uleb128 0
	.uleb128 .LEHB17-.LFB1803
	.uleb128 .LEHE17-.LEHB17
	.uleb128 .L131-.LFB1803
	.uleb128 0
	.uleb128 .LEHB18-.LFB1803
	.uleb128 .LEHE18-.LEHB18
	.uleb128 .L132-.LFB1803
	.uleb128 0
	.uleb128 .LEHB19-.LFB1803
	.uleb128 .LEHE19-.LEHB19
	.uleb128 .L131-.LFB1803
	.uleb128 0
	.uleb128 .LEHB20-.LFB1803
	.uleb128 .LEHE20-.LEHB20
	.uleb128 .L133-.LFB1803
	.uleb128 0
	.uleb128 .LEHB21-.LFB1803
	.uleb128 .LEHE21-.LEHB21
	.uleb128 0
	.uleb128 0
.LLSDACSE1803:
	.text
	.seh_endproc
	.align 2
	.globl	_ZN3Log5flushEv
	.def	_ZN3Log5flushEv;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN3Log5flushEv
_ZN3Log5flushEv:
.LFB1804:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$56, %rsp
	.seh_stackalloc	56
	leaq	48(%rsp), %rbp
	.seh_setframe	%rbp, 48
	.seh_endprologue
	movq	%rcx, 32(%rbp)
	movq	32(%rbp), %rax
	leaq	320(%rax), %rdx
	leaq	-8(%rbp), %rax
	movq	%rax, %rcx
.LEHB22:
	call	_ZN12locker_guardC1ER6locker
.LEHE22:
	movq	32(%rbp), %rax
	movq	288(%rax), %rax
	testq	%rax, %rax
	je	.L138
	movq	32(%rbp), %rax
	movq	288(%rax), %rax
	movq	%rax, %rcx
.LEHB23:
	call	fflush
.LEHE23:
.L138:
	leaq	-8(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN12locker_guardD1Ev
	jmp	.L141
.L140:
	movq	%rax, %rbx
	leaq	-8(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN12locker_guardD1Ev
	movq	%rbx, %rax
	movq	%rax, %rcx
.LEHB24:
	call	_Unwind_Resume
	nop
.LEHE24:
.L141:
	addq	$56, %rsp
	popq	%rbx
	popq	%rbp
	ret
	.seh_handler	__gxx_personality_seh0, @unwind, @except
	.seh_handlerdata
.LLSDA1804:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE1804-.LLSDACSB1804
.LLSDACSB1804:
	.uleb128 .LEHB22-.LFB1804
	.uleb128 .LEHE22-.LEHB22
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB23-.LFB1804
	.uleb128 .LEHE23-.LEHB23
	.uleb128 .L140-.LFB1804
	.uleb128 0
	.uleb128 .LEHB24-.LFB1804
	.uleb128 .LEHE24-.LEHB24
	.uleb128 0
	.uleb128 0
.LLSDACSE1804:
	.text
	.seh_endproc
	.section	.text$_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE5c_strEv,"x"
	.linkonce discard
	.align 2
	.globl	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE5c_strEv
	.def	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE5c_strEv;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE5c_strEv
_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE5c_strEv:
.LFB1805:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEv
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_Alloc_hiderD1Ev,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_Alloc_hiderD1Ev
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_Alloc_hiderD1Ev;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_Alloc_hiderD1Ev
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_Alloc_hiderD1Ev:
.LFB1882:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$48, %rsp
	.seh_stackalloc	48
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt15__new_allocatorIcED2Ev
	nop
	nop
	addq	$48, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev:
.LFB1884:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$72, %rsp
	.seh_stackalloc	72
	leaq	64(%rsp), %rbp
	.seh_setframe	%rbp, 64
	.seh_endprologue
	movq	%rcx, 32(%rbp)
	movq	32(%rbp), %rbx
	leaq	-17(%rbp), %rax
	movq	%rax, -16(%rbp)
	nop
	nop
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_local_dataEv
	leaq	-17(%rbp), %rdx
	movq	%rdx, %r8
	movq	%rax, %rdx
	movq	%rbx, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_Alloc_hiderC1EPcOS3_
	leaq	-17(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt15__new_allocatorIcED2Ev
	nop
	movq	32(%rbp), %rax
	movq	%rax, -8(%rbp)
	nop
	movq	32(%rbp), %rax
	movl	$0, %edx
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_set_lengthEy
	nop
	addq	$72, %rsp
	popq	%rbx
	popq	%rbp
	ret
	.seh_handler	__gxx_personality_seh0, @unwind, @except
	.seh_handlerdata
.LLSDA1884:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE1884-.LLSDACSB1884
.LLSDACSB1884:
.LLSDACSE1884:
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev,"x"
	.linkonce discard
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev:
.LFB1887:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_disposeEv
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_Alloc_hiderD1Ev
	nop
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_handler	__gxx_personality_seh0, @unwind, @except
	.seh_handlerdata
.LLSDA1887:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE1887-.LLSDACSB1887
.LLSDACSB1887:
.LLSDACSE1887:
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev,"x"
	.linkonce discard
	.seh_endproc
	.section	.text$_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4sizeEv,"x"
	.linkonce discard
	.align 2
	.globl	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4sizeEv
	.def	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4sizeEv;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4sizeEv
_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4sizeEv:
.LFB1995:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$48, %rsp
	.seh_stackalloc	48
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	movq	8(%rax), %rax
	movq	%rax, -8(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE8max_sizeEv
	cmpq	-8(%rbp), %rax
	setb	%al
	testb	%al, %al
	movq	-8(%rbp), %rax
	addq	$48, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEE3popERS5_,"x"
	.linkonce discard
	.align 2
	.globl	_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEE3popERS5_
	.def	_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEE3popERS5_;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEE3popERS5_
_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEE3popERS5_:
.LFB2024:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$40, %rsp
	.seh_stackalloc	40
	leaq	32(%rsp), %rbp
	.seh_setframe	%rbp, 32
	.seh_endprologue
	movq	%rcx, 32(%rbp)
	movq	%rdx, 40(%rbp)
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN6locker4lockEv
	jmp	.L151
.L153:
	movq	32(%rbp), %rax
	leaq	8(%rax), %rbx
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN6locker3getEv
	movq	%rax, %rdx
	movq	%rbx, %rcx
	call	_ZN4cond4waitEPx
	xorl	$1, %eax
	testb	%al, %al
	je	.L151
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN6locker6unlockEv
	movl	$0, %eax
	jmp	.L152
.L151:
	movq	32(%rbp), %rax
	movl	24(%rax), %eax
	testl	%eax, %eax
	jle	.L153
	movq	32(%rbp), %rax
	movl	32(%rax), %eax
	leal	1(%rax), %ecx
	movq	32(%rbp), %rax
	movl	28(%rax), %ebx
	movl	%ecx, %eax
	cltd
	idivl	%ebx
	movl	%edx, %ecx
	movl	%ecx, %edx
	movq	32(%rbp), %rax
	movl	%edx, 32(%rax)
	movq	32(%rbp), %rax
	movq	16(%rax), %rdx
	movq	32(%rbp), %rax
	movl	32(%rax), %eax
	cltq
	salq	$5, %rax
	addq	%rax, %rdx
	movq	40(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSERKS4_
	movq	32(%rbp), %rax
	movl	24(%rax), %eax
	leal	-1(%rax), %edx
	movq	32(%rbp), %rax
	movl	%edx, 24(%rax)
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN6locker6unlockEv
	movl	$1, %eax
.L152:
	addq	$40, %rsp
	popq	%rbx
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEED1Ev,"x"
	.linkonce discard
	.align 2
	.globl	_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEED1Ev
	.def	_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEED1Ev;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEED1Ev
_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEED1Ev:
.LFB2027:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$40, %rsp
	.seh_stackalloc	40
	leaq	32(%rsp), %rbp
	.seh_setframe	%rbp, 32
	.seh_endprologue
	movq	%rcx, 32(%rbp)
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN6locker4lockEv
	movq	32(%rbp), %rax
	movq	16(%rax), %rax
	testq	%rax, %rax
	je	.L155
	movq	32(%rbp), %rax
	movq	16(%rax), %rax
	testq	%rax, %rax
	je	.L155
	movq	32(%rbp), %rax
	movq	16(%rax), %rdx
	movq	32(%rbp), %rax
	movq	16(%rax), %rax
	subq	$8, %rax
	movq	(%rax), %rax
	salq	$5, %rax
	leaq	(%rdx,%rax), %rbx
.L157:
	movq	32(%rbp), %rax
	movq	16(%rax), %rax
	cmpq	%rax, %rbx
	je	.L156
	subq	$32, %rbx
	movq	%rbx, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev
	jmp	.L157
.L156:
	movq	32(%rbp), %rax
	movq	16(%rax), %rax
	subq	$8, %rax
	movq	%rax, %rcx
	call	_ZdaPv
.L155:
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN6locker6unlockEv
	movq	32(%rbp), %rax
	addq	$8, %rax
	movq	%rax, %rcx
	call	_ZN4condD1Ev
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN6lockerD1Ev
	nop
	addq	$40, %rsp
	popq	%rbx
	popq	%rbp
	ret
	.seh_handler	__gxx_personality_seh0, @unwind, @except
	.seh_handlerdata
.LLSDA2027:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE2027-.LLSDACSB2027
.LLSDACSB2027:
.LLSDACSE2027:
	.section	.text$_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEED1Ev,"x"
	.linkonce discard
	.seh_endproc
	.section	.text$_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEEC1Ei,"x"
	.linkonce discard
	.align 2
	.globl	_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEEC1Ei
	.def	_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEEC1Ei;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEEC1Ei
_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEEC1Ei:
.LFB2030:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rdi
	.seh_pushreg	%rdi
	pushq	%rsi
	.seh_pushreg	%rsi
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$40, %rsp
	.seh_stackalloc	40
	leaq	32(%rsp), %rbp
	.seh_setframe	%rbp, 32
	.seh_endprologue
	movq	%rcx, 48(%rbp)
	movl	%edx, 56(%rbp)
	movq	48(%rbp), %rax
	movq	%rax, %rcx
.LEHB25:
	call	_ZN6lockerC1Ev
.LEHE25:
	movq	48(%rbp), %rax
	addq	$8, %rax
	movq	%rax, %rcx
.LEHB26:
	call	_ZN4condC1Ev
.LEHE26:
	cmpl	$0, 56(%rbp)
	jg	.L159
	movl	$-1, %ecx
	call	exit
.L159:
	movq	48(%rbp), %rax
	movl	56(%rbp), %edx
	movl	%edx, 28(%rax)
	movl	56(%rbp), %eax
	movslq	%eax, %rbx
	movabsq	$288230376151711743, %rax
	cmpq	%rbx, %rax
	jb	.L160
	movq	%rbx, %rax
	salq	$5, %rax
	addq	$8, %rax
	jmp	.L161
.L160:
	movq	$-1, %rax
.L161:
	movq	%rax, %rcx
.LEHB27:
	call	_Znay
.LEHE27:
	movq	%rax, %rsi
	movq	%rbx, (%rsi)
	leaq	8(%rsi), %rax
	leaq	-1(%rbx), %rdx
	movq	%rdx, %rbx
	movq	%rax, %rdi
	jmp	.L162
.L163:
	movq	%rdi, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev
	subq	$1, %rbx
	addq	$32, %rdi
.L162:
	testq	%rbx, %rbx
	jns	.L163
	movl	$0, %ecx
	leaq	8(%rsi), %rdx
	movq	48(%rbp), %rax
	movq	%rdx, 16(%rax)
	testb	%cl, %cl
	je	.L170
	movq	%rsi, %rcx
	call	_ZdaPv
.L170:
	nop
	movq	48(%rbp), %rax
	movl	$0, 24(%rax)
	movq	48(%rbp), %rax
	movl	$-1, 32(%rax)
	movq	48(%rbp), %rax
	movl	$-1, 36(%rax)
	jmp	.L169
.L168:
	movq	%rax, %rbx
	movq	48(%rbp), %rax
	addq	$8, %rax
	movq	%rax, %rcx
	call	_ZN4condD1Ev
	jmp	.L166
.L167:
	movq	%rax, %rbx
.L166:
	movq	48(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN6lockerD1Ev
	movq	%rbx, %rax
	movq	%rax, %rcx
.LEHB28:
	call	_Unwind_Resume
	nop
.LEHE28:
.L169:
	addq	$40, %rsp
	popq	%rbx
	popq	%rsi
	popq	%rdi
	popq	%rbp
	ret
	.seh_handler	__gxx_personality_seh0, @unwind, @except
	.seh_handlerdata
.LLSDA2030:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE2030-.LLSDACSB2030
.LLSDACSB2030:
	.uleb128 .LEHB25-.LFB2030
	.uleb128 .LEHE25-.LEHB25
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB26-.LFB2030
	.uleb128 .LEHE26-.LEHB26
	.uleb128 .L167-.LFB2030
	.uleb128 0
	.uleb128 .LEHB27-.LFB2030
	.uleb128 .LEHE27-.LEHB27
	.uleb128 .L168-.LFB2030
	.uleb128 0
	.uleb128 .LEHB28-.LFB2030
	.uleb128 .LEHE28-.LEHB28
	.uleb128 0
	.uleb128 0
.LLSDACSE2030:
	.section	.text$_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEEC1Ei,"x"
	.linkonce discard
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSEPKc,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSEPKc
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSEPKc;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSEPKc
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSEPKc:
.LFB2031:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	24(%rbp), %rdx
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6assignEPKc
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEE4pushERKS5_,"x"
	.linkonce discard
	.align 2
	.globl	_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEE4pushERKS5_
	.def	_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEE4pushERKS5_;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEE4pushERKS5_
_ZN11block_queueINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEE4pushERKS5_:
.LFB2032:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN6locker4lockEv
	movq	16(%rbp), %rax
	movl	24(%rax), %edx
	movq	16(%rbp), %rax
	movl	28(%rax), %eax
	cmpl	%eax, %edx
	jl	.L174
	movq	16(%rbp), %rax
	addq	$8, %rax
	movq	%rax, %rcx
	call	_ZN4cond9broadcastEv
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN6locker6unlockEv
	movl	$0, %eax
	jmp	.L175
.L174:
	movq	16(%rbp), %rax
	movl	36(%rax), %eax
	leal	1(%rax), %ecx
	movq	16(%rbp), %rax
	movl	28(%rax), %r8d
	movl	%ecx, %eax
	cltd
	idivl	%r8d
	movl	%edx, %ecx
	movl	%ecx, %edx
	movq	16(%rbp), %rax
	movl	%edx, 36(%rax)
	movq	16(%rbp), %rax
	movq	16(%rax), %rdx
	movq	16(%rbp), %rax
	movl	36(%rax), %eax
	cltq
	salq	$5, %rax
	leaq	(%rdx,%rax), %rcx
	movq	24(%rbp), %rax
	movq	%rax, %rdx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSERKS4_
	movq	16(%rbp), %rax
	movl	24(%rax), %eax
	leal	1(%rax), %edx
	movq	16(%rbp), %rax
	movl	%edx, 24(%rax)
	movq	16(%rbp), %rax
	addq	$8, %rax
	movq	%rax, %rcx
	call	_ZN4cond9broadcastEv
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZN6locker6unlockEv
	movl	$1, %eax
.L175:
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEv,"x"
	.linkonce discard
	.align 2
	.globl	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEv
	.def	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEv;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEv
_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEv:
.LFB2033:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	movq	(%rax), %rax
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_local_dataEv,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_local_dataEv
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_local_dataEv;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_local_dataEv
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_local_dataEv:
.LFB2034:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	addq	$16, %rax
	movq	%rax, %rcx
	call	_ZNSt19__ptr_traits_ptr_toIPccLb0EE10pointer_toERc
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_Alloc_hiderC1EPcOS3_,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_Alloc_hiderC1EPcOS3_
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_Alloc_hiderC1EPcOS3_;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_Alloc_hiderC1EPcOS3_
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_Alloc_hiderC1EPcOS3_:
.LFB2043:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$48, %rsp
	.seh_stackalloc	48
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	%r8, 32(%rbp)
	movq	32(%rbp), %rax
	movq	%rax, -40(%rbp)
	movq	-40(%rbp), %rax
	movq	16(%rbp), %rdx
	movq	%rdx, -8(%rbp)
	movq	%rax, -16(%rbp)
	movq	-8(%rbp), %rax
	movq	%rax, -24(%rbp)
	movq	-16(%rbp), %rax
	movq	%rax, -32(%rbp)
	nop
	nop
	movq	16(%rbp), %rax
	movq	24(%rbp), %rdx
	movq	%rdx, (%rax)
	nop
	addq	$48, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_set_lengthEy,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_set_lengthEy
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_set_lengthEy;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_set_lengthEy
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_set_lengthEy:
.LFB2045:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$48, %rsp
	.seh_stackalloc	48
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	24(%rbp), %rdx
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_lengthEy
	movb	$0, -1(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEv
	movq	24(%rbp), %rdx
	leaq	(%rax,%rdx), %rcx
	leaq	-1(%rbp), %rax
	movq	%rax, %rdx
	call	_ZNSt11char_traitsIcE6assignERcRKc
	nop
	addq	$48, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_disposeEv,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_disposeEv
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_disposeEv;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_disposeEv
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_disposeEv:
.LFB2046:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_is_localEv
	xorl	$1, %eax
	testb	%al, %al
	je	.L185
	movq	16(%rbp), %rax
	movq	16(%rax), %rdx
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_destroyEy
.L185:
	nop
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE16_M_get_allocatorEv,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE16_M_get_allocatorEv
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE16_M_get_allocatorEv;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE16_M_get_allocatorEv
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE16_M_get_allocatorEv:
.LFB2049:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_is_localEv,"x"
	.linkonce discard
	.align 2
	.globl	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_is_localEv
	.def	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_is_localEv;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_is_localEv
_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_is_localEv:
.LFB2051:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$40, %rsp
	.seh_stackalloc	40
	leaq	32(%rsp), %rbp
	.seh_setframe	%rbp, 32
	.seh_endprologue
	movq	%rcx, 32(%rbp)
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEv
	movq	%rax, %rbx
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_local_dataEv
	cmpq	%rax, %rbx
	sete	%al
	testb	%al, %al
	je	.L189
	movq	32(%rbp), %rax
	movq	8(%rax), %rax
	cmpq	$15, %rax
	movl	$1, %eax
	jmp	.L191
.L189:
	movl	$0, %eax
.L191:
	addq	$40, %rsp
	popq	%rbx
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6lengthEv,"x"
	.linkonce discard
	.align 2
	.globl	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6lengthEv
	.def	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6lengthEv;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6lengthEv
_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6lengthEv:
.LFB2052:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4sizeEv
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEPc,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEPc
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEPc;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEPc
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEPc:
.LFB2053:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	16(%rbp), %rax
	movq	24(%rbp), %rdx
	movq	%rdx, (%rax)
	nop
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_capacityEy,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_capacityEy
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_capacityEy;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_capacityEy
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_capacityEy:
.LFB2054:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	16(%rbp), %rax
	movq	24(%rbp), %rdx
	movq	%rdx, 16(%rax)
	nop
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_lengthEy,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_lengthEy
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_lengthEy;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_lengthEy
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_lengthEy:
.LFB2055:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	16(%rbp), %rax
	movq	24(%rbp), %rdx
	movq	%rdx, 8(%rax)
	nop
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE8max_sizeEv,"x"
	.linkonce discard
	.align 2
	.globl	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE8max_sizeEv
	.def	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE8max_sizeEv;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE8max_sizeEv
_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE8max_sizeEv:
.LFB2066:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$80, %rsp
	.seh_stackalloc	80
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movabsq	$9223372036854775807, %rax
	movq	%rax, -32(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE16_M_get_allocatorEv
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	movq	%rax, -16(%rbp)
	movq	-16(%rbp), %rax
	movq	%rax, -24(%rbp)
	movabsq	$9223372036854775807, %rax
	nop
	nop
	movq	%rax, -40(%rbp)
	leaq	-40(%rbp), %rdx
	leaq	-32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZSt3minIyERKT_S2_S2_
	movq	(%rax), %rax
	subq	$1, %rax
	addq	$80, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSERKS4_,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSERKS4_
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSERKS4_;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSERKS4_
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSERKS4_:
.LFB2105:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	24(%rbp), %rdx
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6assignERKS4_
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6assignEPKc,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6assignEPKc
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6assignEPKc;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6assignEPKc
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6assignEPKc:
.LFB2106:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$56, %rsp
	.seh_stackalloc	56
	leaq	48(%rsp), %rbp
	.seh_setframe	%rbp, 48
	.seh_endprologue
	movq	%rcx, 32(%rbp)
	movq	%rdx, 40(%rbp)
	movq	40(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt11char_traitsIcE6lengthEPKc
	movq	%rax, %rbx
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4sizeEv
	movq	%rax, %rdx
	movq	40(%rbp), %rcx
	movq	32(%rbp), %rax
	movq	%rbx, 32(%rsp)
	movq	%rcx, %r9
	movq	%rdx, %r8
	movl	$0, %edx
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_replaceEyyPKcy
	addq	$56, %rsp
	popq	%rbx
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt19__ptr_traits_ptr_toIPccLb0EE10pointer_toERc,"x"
	.linkonce discard
	.globl	_ZNSt19__ptr_traits_ptr_toIPccLb0EE10pointer_toERc
	.def	_ZNSt19__ptr_traits_ptr_toIPccLb0EE10pointer_toERc;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt19__ptr_traits_ptr_toIPccLb0EE10pointer_toERc
_ZNSt19__ptr_traits_ptr_toIPccLb0EE10pointer_toERc:
.LFB2107:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$16, %rsp
	.seh_stackalloc	16
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	movq	%rax, -16(%rbp)
	movq	-16(%rbp), %rax
	nop
	addq	$16, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt15__new_allocatorIcED2Ev,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt15__new_allocatorIcED2Ev
	.def	_ZNSt15__new_allocatorIcED2Ev;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt15__new_allocatorIcED2Ev
_ZNSt15__new_allocatorIcED2Ev:
.LFB2112:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	nop
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_destroyEy,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_destroyEy
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_destroyEy;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_destroyEy
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_destroyEy:
.LFB2117:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rsi
	.seh_pushreg	%rsi
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$64, %rsp
	.seh_stackalloc	64
	leaq	64(%rsp), %rbp
	.seh_setframe	%rbp, 64
	.seh_endprologue
	movq	%rcx, 32(%rbp)
	movq	%rdx, 40(%rbp)
	movq	40(%rbp), %rax
	leaq	1(%rax), %rsi
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEv
	movq	%rax, %rbx
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE16_M_get_allocatorEv
	movq	%rax, -8(%rbp)
	movq	%rbx, -16(%rbp)
	movq	%rsi, -24(%rbp)
	movq	-24(%rbp), %rcx
	movq	-16(%rbp), %rdx
	movq	-8(%rbp), %rax
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	_ZNSt15__new_allocatorIcE10deallocateEPcy
	nop
	nop
	addq	$64, %rsp
	popq	%rbx
	popq	%rsi
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE8capacityEv,"x"
	.linkonce discard
	.align 2
	.globl	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE8capacityEv
	.def	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE8capacityEv;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE8capacityEv
_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE8capacityEv:
.LFB2118:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$48, %rsp
	.seh_stackalloc	48
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_is_localEv
	testb	%al, %al
	je	.L213
	movq	$15, -8(%rbp)
	jmp	.L214
.L213:
	movq	16(%rbp), %rax
	movq	16(%rax), %rax
	movq	%rax, -8(%rbp)
.L214:
	cmpq	$14, -8(%rbp)
	jbe	.L215
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE8max_sizeEv
	cmpq	-8(%rbp), %rax
	jnb	.L216
.L215:
	movl	$1, %eax
	jmp	.L217
.L216:
	movl	$0, %eax
.L217:
	testb	%al, %al
	movq	-8(%rbp), %rax
	addq	$48, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section .rdata,"dr"
.LC14:
	.ascii "basic_string::_M_create\0"
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_createERyy,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_createERyy
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_createERyy;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_createERyy
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_createERyy:
.LFB2119:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$40, %rsp
	.seh_stackalloc	40
	leaq	32(%rsp), %rbp
	.seh_setframe	%rbp, 32
	.seh_endprologue
	movq	%rcx, 32(%rbp)
	movq	%rdx, 40(%rbp)
	movq	%r8, 48(%rbp)
	movq	40(%rbp), %rax
	movq	(%rax), %rbx
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE8max_sizeEv
	cmpq	%rbx, %rax
	setb	%al
	testb	%al, %al
	je	.L221
	leaq	.LC14(%rip), %rax
	movq	%rax, %rcx
	call	_ZSt20__throw_length_errorPKc
.L221:
	movq	40(%rbp), %rax
	movq	(%rax), %rax
	cmpq	%rax, 48(%rbp)
	jnb	.L222
	movq	40(%rbp), %rax
	movq	(%rax), %rdx
	movq	48(%rbp), %rax
	addq	%rax, %rax
	cmpq	%rax, %rdx
	jnb	.L222
	movq	48(%rbp), %rax
	leaq	(%rax,%rax), %rdx
	movq	40(%rbp), %rax
	movq	%rdx, (%rax)
	movq	40(%rbp), %rax
	movq	(%rax), %rbx
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE8max_sizeEv
	cmpq	%rbx, %rax
	setb	%al
	testb	%al, %al
	je	.L222
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE8max_sizeEv
	movq	40(%rbp), %rdx
	movq	%rax, (%rdx)
.L222:
	movq	40(%rbp), %rax
	movq	(%rax), %rax
	leaq	1(%rax), %rbx
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE16_M_get_allocatorEv
	movq	%rbx, %rdx
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_S_allocateERS3_y
	addq	$40, %rsp
	popq	%rbx
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_copyEPcPKcy,"x"
	.linkonce discard
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_copyEPcPKcy
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_copyEPcPKcy;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_copyEPcPKcy
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_copyEPcPKcy:
.LFB2120:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	%r8, 32(%rbp)
	cmpq	$1, 32(%rbp)
	jne	.L225
	movq	24(%rbp), %rdx
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt11char_traitsIcE6assignERcRKc
	jmp	.L227
.L225:
	movq	32(%rbp), %rcx
	movq	24(%rbp), %rdx
	movq	16(%rbp), %rax
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	_ZNSt11char_traitsIcE4copyEPcPKcy
.L227:
	nop
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_local_dataEv,"x"
	.linkonce discard
	.align 2
	.globl	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_local_dataEv
	.def	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_local_dataEv;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_local_dataEv
_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_local_dataEv:
.LFB2121:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	addq	$16, %rax
	movq	%rax, %rcx
	call	_ZNSt19__ptr_traits_ptr_toIPKcS0_Lb0EE10pointer_toERS0_
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE16_M_get_allocatorEv,"x"
	.linkonce discard
	.align 2
	.globl	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE16_M_get_allocatorEv
	.def	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE16_M_get_allocatorEv;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE16_M_get_allocatorEv
_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE16_M_get_allocatorEv:
.LFB2133:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZSt3minIyERKT_S2_S2_,"x"
	.linkonce discard
	.globl	_ZSt3minIyERKT_S2_S2_
	.def	_ZSt3minIyERKT_S2_S2_;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZSt3minIyERKT_S2_S2_
_ZSt3minIyERKT_S2_S2_:
.LFB2135:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	24(%rbp), %rax
	movq	(%rax), %rdx
	movq	16(%rbp), %rax
	movq	(%rax), %rax
	cmpq	%rax, %rdx
	jnb	.L233
	movq	24(%rbp), %rax
	jmp	.L234
.L233:
	movq	16(%rbp), %rax
.L234:
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6assignERKS4_,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6assignERKS4_
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6assignERKS4_;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6assignERKS4_
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6assignERKS4_:
.LFB2150:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$136, %rsp
	.seh_stackalloc	136
	leaq	128(%rsp), %rbp
	.seh_setframe	%rbp, 128
	.seh_endprologue
	movq	%rcx, 32(%rbp)
	movq	%rdx, 40(%rbp)
	movl	$0, %eax
	testb	%al, %al
	je	.L237
	movl	$1, %eax
	xorl	$1, %eax
	testb	%al, %al
	je	.L239
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_is_localEv
	xorl	$1, %eax
	testb	%al, %al
	je	.L239
	movq	40(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE16_M_get_allocatorEv
	movq	%rax, %rbx
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE16_M_get_allocatorEv
	movq	%rax, -24(%rbp)
	movq	%rbx, -32(%rbp)
	movl	$0, %eax
	testb	%al, %al
	je	.L239
	movl	$1, %eax
	jmp	.L241
.L239:
	movl	$0, %eax
.L241:
	testb	%al, %al
	je	.L242
	movq	40(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4sizeEv
	cmpq	$15, %rax
	setbe	%al
	testb	%al, %al
	je	.L243
	movq	32(%rbp), %rax
	movq	16(%rax), %rdx
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_destroyEy
	movq	32(%rbp), %rax
	movq	%rax, -40(%rbp)
	movq	-40(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_local_dataEv
	movq	%rax, %rdx
	nop
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEPc
	movq	32(%rbp), %rax
	movl	$0, %edx
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_set_lengthEy
	jmp	.L242
.L243:
	movq	40(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4sizeEv
	movq	%rax, -8(%rbp)
	movq	40(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE16_M_get_allocatorEv
	movq	%rax, -48(%rbp)
	leaq	-81(%rbp), %rax
	movq	%rax, -56(%rbp)
	movq	-48(%rbp), %rax
	movq	%rax, -64(%rbp)
	nop
	nop
	movq	-8(%rbp), %rax
	leaq	1(%rax), %rdx
	leaq	-81(%rbp), %rax
	movq	%rax, %rcx
.LEHB29:
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_S_allocateERS3_y
.LEHE29:
	movq	%rax, -16(%rbp)
	movq	32(%rbp), %rax
	movq	16(%rax), %rdx
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_destroyEy
	movq	-16(%rbp), %rdx
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEPc
	movq	-8(%rbp), %rdx
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_capacityEy
	movq	-8(%rbp), %rdx
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_set_lengthEy
	leaq	-81(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt15__new_allocatorIcED2Ev
	nop
.L242:
	movq	40(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE16_M_get_allocatorEv
	movq	%rax, %rbx
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE16_M_get_allocatorEv
	movq	%rax, -72(%rbp)
	movq	%rbx, -80(%rbp)
	nop
.L237:
	movq	40(%rbp), %rdx
	movq	32(%rbp), %rax
	movq	%rax, %rcx
.LEHB30:
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_assignERKS4_
	movq	32(%rbp), %rax
	jmp	.L248
.L247:
	movq	%rax, %rbx
	leaq	-81(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt15__new_allocatorIcED2Ev
	nop
	movq	%rbx, %rax
	movq	%rax, %rcx
	call	_Unwind_Resume
.LEHE30:
.L248:
	addq	$136, %rsp
	popq	%rbx
	popq	%rbp
	ret
	.seh_handler	__gxx_personality_seh0, @unwind, @except
	.seh_handlerdata
.LLSDA2150:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE2150-.LLSDACSB2150
.LLSDACSB2150:
	.uleb128 .LEHB29-.LFB2150
	.uleb128 .LEHE29-.LEHB29
	.uleb128 .L247-.LFB2150
	.uleb128 0
	.uleb128 .LEHB30-.LFB2150
	.uleb128 .LEHE30-.LEHB30
	.uleb128 0
	.uleb128 0
.LLSDACSE2150:
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6assignERKS4_,"x"
	.linkonce discard
	.seh_endproc
	.section .rdata,"dr"
.LC15:
	.ascii "basic_string::_M_replace\0"
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_replaceEyyPKcy,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_replaceEyyPKcy
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_replaceEyyPKcy;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_replaceEyyPKcy
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_replaceEyyPKcy:
.LFB2153:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$80, %rsp
	.seh_stackalloc	80
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	%r8, 32(%rbp)
	movq	%r9, 40(%rbp)
	leaq	.LC15(%rip), %r8
	movq	48(%rbp), %rcx
	movq	32(%rbp), %rdx
	movq	16(%rbp), %rax
	movq	%r8, %r9
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE15_M_check_lengthEyyPKc
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4sizeEv
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rdx
	movq	48(%rbp), %rax
	addq	%rdx, %rax
	subq	32(%rbp), %rax
	movq	%rax, -16(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE8capacityEv
	cmpq	-16(%rbp), %rax
	setnb	%al
	testb	%al, %al
	je	.L250
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEv
	movq	24(%rbp), %rdx
	addq	%rdx, %rax
	movq	%rax, -24(%rbp)
	movq	-8(%rbp), %rax
	subq	24(%rbp), %rax
	subq	32(%rbp), %rax
	movq	%rax, -32(%rbp)
	movq	40(%rbp), %rdx
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_disjunctEPKc
	movzbl	%al, %eax
	testl	%eax, %eax
	setne	%al
	testb	%al, %al
	je	.L251
	cmpq	$0, -32(%rbp)
	je	.L252
	movq	32(%rbp), %rax
	cmpq	48(%rbp), %rax
	je	.L252
	movq	-24(%rbp), %rdx
	movq	32(%rbp), %rax
	addq	%rax, %rdx
	movq	-24(%rbp), %rcx
	movq	48(%rbp), %rax
	addq	%rcx, %rax
	movq	-32(%rbp), %rcx
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_moveEPcPKcy
.L252:
	cmpq	$0, 48(%rbp)
	je	.L253
	movq	48(%rbp), %rcx
	movq	40(%rbp), %rdx
	movq	-24(%rbp), %rax
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_copyEPcPKcy
	jmp	.L253
.L251:
	movq	40(%rbp), %r9
	movq	32(%rbp), %r8
	movq	-24(%rbp), %rdx
	movq	16(%rbp), %rax
	movq	-32(%rbp), %rcx
	movq	%rcx, 40(%rsp)
	movq	48(%rbp), %rcx
	movq	%rcx, 32(%rsp)
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE15_M_replace_coldEPcyPKcyy
	jmp	.L253
.L250:
	movq	40(%rbp), %r9
	movq	32(%rbp), %r8
	movq	24(%rbp), %rdx
	movq	16(%rbp), %rax
	movq	48(%rbp), %rcx
	movq	%rcx, 32(%rsp)
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_mutateEyyPKcy
.L253:
	movq	-16(%rbp), %rdx
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_set_lengthEy
	movq	16(%rbp), %rax
	addq	$80, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_S_allocateERS3_y,"x"
	.linkonce discard
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_S_allocateERS3_y
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_S_allocateERS3_y;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_S_allocateERS3_y
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_S_allocateERS3_y:
.LFB2159:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$64, %rsp
	.seh_stackalloc	64
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, -16(%rbp)
	movq	24(%rbp), %rax
	movq	%rax, -24(%rbp)
	movq	-24(%rbp), %rdx
	movq	-16(%rbp), %rax
	movl	$0, %r8d
	movq	%rax, %rcx
	call	_ZNSt15__new_allocatorIcE8allocateEyPKv
	nop
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	addq	$64, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt19__ptr_traits_ptr_toIPKcS0_Lb0EE10pointer_toERS0_,"x"
	.linkonce discard
	.globl	_ZNSt19__ptr_traits_ptr_toIPKcS0_Lb0EE10pointer_toERS0_
	.def	_ZNSt19__ptr_traits_ptr_toIPKcS0_Lb0EE10pointer_toERS0_;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt19__ptr_traits_ptr_toIPKcS0_Lb0EE10pointer_toERS0_
_ZNSt19__ptr_traits_ptr_toIPKcS0_Lb0EE10pointer_toERS0_:
.LFB2160:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$16, %rsp
	.seh_stackalloc	16
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	movq	%rax, -16(%rbp)
	movq	-16(%rbp), %rax
	nop
	addq	$16, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_assignERKS4_,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_assignERKS4_
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_assignERKS4_;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_assignERKS4_
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_assignERKS4_:
.LFB2178:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$88, %rsp
	.seh_stackalloc	88
	leaq	80(%rsp), %rbp
	.seh_setframe	%rbp, 80
	.seh_endprologue
	movq	%rcx, 32(%rbp)
	movq	%rdx, 40(%rbp)
	movq	40(%rbp), %rax
	movq	%rax, -32(%rbp)
	movq	-32(%rbp), %rax
	cmpq	%rax, 32(%rbp)
	setne	%al
	testb	%al, %al
	je	.L267
	movq	40(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6lengthEv
	movq	%rax, -8(%rbp)
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE8capacityEv
	movq	%rax, -16(%rbp)
	movq	-8(%rbp), %rax
	cmpq	%rax, -16(%rbp)
	jnb	.L265
	movq	-8(%rbp), %rax
	movq	%rax, -40(%rbp)
	movq	-16(%rbp), %rcx
	leaq	-40(%rbp), %rdx
	movq	32(%rbp), %rax
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_createERyy
	movq	%rax, -24(%rbp)
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_disposeEv
	movq	-24(%rbp), %rdx
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEPc
	movq	-40(%rbp), %rdx
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_capacityEy
.L265:
	cmpq	$0, -8(%rbp)
	je	.L266
	movq	40(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEv
	movq	%rax, %rbx
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEv
	movq	-8(%rbp), %rdx
	movq	%rdx, %r8
	movq	%rbx, %rdx
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_copyEPcPKcy
.L266:
	movq	-8(%rbp), %rdx
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_set_lengthEy
.L267:
	nop
	addq	$88, %rsp
	popq	%rbx
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE15_M_check_lengthEyyPKc,"x"
	.linkonce discard
	.align 2
	.globl	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE15_M_check_lengthEyyPKc
	.def	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE15_M_check_lengthEyyPKc;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE15_M_check_lengthEyyPKc
_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE15_M_check_lengthEyyPKc:
.LFB2179:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$40, %rsp
	.seh_stackalloc	40
	leaq	32(%rsp), %rbp
	.seh_setframe	%rbp, 32
	.seh_endprologue
	movq	%rcx, 32(%rbp)
	movq	%rdx, 40(%rbp)
	movq	%r8, 48(%rbp)
	movq	%r9, 56(%rbp)
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE8max_sizeEv
	movq	%rax, %rbx
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4sizeEv
	movq	40(%rbp), %rdx
	subq	%rax, %rdx
	leaq	(%rbx,%rdx), %rax
	cmpq	48(%rbp), %rax
	setb	%al
	testb	%al, %al
	je	.L270
	movq	56(%rbp), %rax
	movq	%rax, %rcx
	call	_ZSt20__throw_length_errorPKc
.L270:
	nop
	addq	$40, %rsp
	popq	%rbx
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_disjunctEPKc,"x"
	.linkonce discard
	.align 2
	.globl	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_disjunctEPKc
	.def	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_disjunctEPKc;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_disjunctEPKc
_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_disjunctEPKc:
.LFB2180:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$56, %rsp
	.seh_stackalloc	56
	leaq	48(%rsp), %rbp
	.seh_setframe	%rbp, 48
	.seh_endprologue
	movq	%rcx, 32(%rbp)
	movq	%rdx, 40(%rbp)
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEv
	movq	%rax, %rcx
	movq	40(%rbp), %rdx
	leaq	-2(%rbp), %rax
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	_ZNKSt4lessIPKcEclES1_S1_
	testb	%al, %al
	jne	.L272
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEv
	movq	%rax, %rbx
	movq	32(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4sizeEv
	leaq	(%rbx,%rax), %rdx
	movq	40(%rbp), %rcx
	leaq	-1(%rbp), %rax
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	_ZNKSt4lessIPKcEclES1_S1_
	testb	%al, %al
	je	.L273
.L272:
	movl	$1, %eax
	jmp	.L274
.L273:
	movl	$0, %eax
.L274:
	addq	$56, %rsp
	popq	%rbx
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_moveEPcPKcy,"x"
	.linkonce discard
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_moveEPcPKcy
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_moveEPcPKcy;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_moveEPcPKcy
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_moveEPcPKcy:
.LFB2181:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	%r8, 32(%rbp)
	cmpq	$1, 32(%rbp)
	jne	.L277
	movq	24(%rbp), %rdx
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt11char_traitsIcE6assignERcRKc
	jmp	.L279
.L277:
	movq	32(%rbp), %rcx
	movq	24(%rbp), %rdx
	movq	16(%rbp), %rax
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	_ZNSt11char_traitsIcE4moveEPcPKcy
.L279:
	nop
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE15_M_replace_coldEPcyPKcyy,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE15_M_replace_coldEPcyPKcyy
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE15_M_replace_coldEPcyPKcyy;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE15_M_replace_coldEPcyPKcyy
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE15_M_replace_coldEPcyPKcyy:
.LFB2182:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$48, %rsp
	.seh_stackalloc	48
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	%r8, 32(%rbp)
	movq	%r9, 40(%rbp)
	cmpq	$0, 48(%rbp)
	je	.L281
	movq	48(%rbp), %rax
	cmpq	%rax, 32(%rbp)
	jb	.L281
	movq	48(%rbp), %rcx
	movq	40(%rbp), %rdx
	movq	24(%rbp), %rax
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_moveEPcPKcy
.L281:
	cmpq	$0, 56(%rbp)
	je	.L282
	movq	32(%rbp), %rax
	cmpq	48(%rbp), %rax
	je	.L282
	movq	24(%rbp), %rdx
	movq	32(%rbp), %rax
	addq	%rax, %rdx
	movq	24(%rbp), %rcx
	movq	48(%rbp), %rax
	addq	%rcx, %rax
	movq	56(%rbp), %rcx
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_moveEPcPKcy
.L282:
	movq	48(%rbp), %rax
	cmpq	%rax, 32(%rbp)
	jnb	.L286
	movq	40(%rbp), %rdx
	movq	48(%rbp), %rax
	addq	%rdx, %rax
	movq	24(%rbp), %rcx
	movq	32(%rbp), %rdx
	addq	%rcx, %rdx
	cmpq	%rax, %rdx
	jb	.L284
	movq	48(%rbp), %rcx
	movq	40(%rbp), %rdx
	movq	24(%rbp), %rax
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_moveEPcPKcy
	jmp	.L286
.L284:
	movq	24(%rbp), %rdx
	movq	32(%rbp), %rax
	addq	%rdx, %rax
	cmpq	%rax, 40(%rbp)
	jb	.L285
	movq	40(%rbp), %rax
	subq	24(%rbp), %rax
	movq	%rax, %rdx
	movq	48(%rbp), %rax
	subq	32(%rbp), %rax
	addq	%rdx, %rax
	movq	%rax, -16(%rbp)
	movq	24(%rbp), %rdx
	movq	-16(%rbp), %rax
	addq	%rax, %rdx
	movq	48(%rbp), %rcx
	movq	24(%rbp), %rax
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_copyEPcPKcy
	jmp	.L286
.L285:
	movq	24(%rbp), %rdx
	movq	32(%rbp), %rax
	addq	%rdx, %rax
	subq	40(%rbp), %rax
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rcx
	movq	40(%rbp), %rdx
	movq	24(%rbp), %rax
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_moveEPcPKcy
	movq	48(%rbp), %rax
	subq	-8(%rbp), %rax
	movq	%rax, %r8
	movq	24(%rbp), %rdx
	movq	48(%rbp), %rax
	addq	%rax, %rdx
	movq	24(%rbp), %rcx
	movq	-8(%rbp), %rax
	addq	%rcx, %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_copyEPcPKcy
.L286:
	nop
	addq	$48, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_mutateEyyPKcy,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_mutateEyyPKcy
	.def	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_mutateEyyPKcy;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_mutateEyyPKcy
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_mutateEyyPKcy:
.LFB2183:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$64, %rsp
	.seh_stackalloc	64
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	%r8, 32(%rbp)
	movq	%r9, 40(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6lengthEv
	subq	24(%rbp), %rax
	subq	32(%rbp), %rax
	movq	%rax, -8(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6lengthEv
	movq	48(%rbp), %rdx
	addq	%rdx, %rax
	subq	32(%rbp), %rax
	movq	%rax, -24(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE8capacityEv
	movq	%rax, %rcx
	leaq	-24(%rbp), %rdx
	movq	16(%rbp), %rax
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_createERyy
	movq	%rax, -16(%rbp)
	cmpq	$0, 24(%rbp)
	je	.L288
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEv
	movq	%rax, %rdx
	movq	24(%rbp), %rcx
	movq	-16(%rbp), %rax
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_copyEPcPKcy
.L288:
	cmpq	$0, 40(%rbp)
	je	.L289
	cmpq	$0, 48(%rbp)
	je	.L289
	movq	-16(%rbp), %rdx
	movq	24(%rbp), %rax
	leaq	(%rdx,%rax), %rcx
	movq	48(%rbp), %rdx
	movq	40(%rbp), %rax
	movq	%rdx, %r8
	movq	%rax, %rdx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_copyEPcPKcy
.L289:
	cmpq	$0, -8(%rbp)
	je	.L290
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEv
	movq	24(%rbp), %rcx
	movq	32(%rbp), %rdx
	addq	%rcx, %rdx
	addq	%rax, %rdx
	movq	24(%rbp), %rcx
	movq	48(%rbp), %rax
	addq	%rax, %rcx
	movq	-16(%rbp), %rax
	addq	%rcx, %rax
	movq	-8(%rbp), %rcx
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_S_copyEPcPKcy
.L290:
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_disposeEv
	movq	-16(%rbp), %rdx
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEPc
	movq	-24(%rbp), %rdx
	movq	16(%rbp), %rax
	movq	%rax, %rcx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_capacityEy
	nop
	addq	$64, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt15__new_allocatorIcE10deallocateEPcy,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt15__new_allocatorIcE10deallocateEPcy
	.def	_ZNSt15__new_allocatorIcE10deallocateEPcy;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt15__new_allocatorIcE10deallocateEPcy
_ZNSt15__new_allocatorIcE10deallocateEPcy:
.LFB2185:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	%r8, 32(%rbp)
	movq	24(%rbp), %rax
	movq	%rax, %rcx
	call	_ZdlPv
	nop
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNKSt4lessIPKcEclES1_S1_,"x"
	.linkonce discard
	.align 2
	.globl	_ZNKSt4lessIPKcEclES1_S1_
	.def	_ZNKSt4lessIPKcEclES1_S1_;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNKSt4lessIPKcEclES1_S1_
_ZNKSt4lessIPKcEclES1_S1_:
.LFB2198:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	%r8, 32(%rbp)
	movq	24(%rbp), %rdx
	movq	32(%rbp), %rax
	cmpq	%rax, %rdx
	setb	%al
	popq	%rbp
	ret
	.seh_endproc
	.section	.text$_ZNSt15__new_allocatorIcE8allocateEyPKv,"x"
	.linkonce discard
	.align 2
	.globl	_ZNSt15__new_allocatorIcE8allocateEyPKv
	.def	_ZNSt15__new_allocatorIcE8allocateEyPKv;	.scl	2;	.type	32;	.endef
	.seh_proc	_ZNSt15__new_allocatorIcE8allocateEyPKv
_ZNSt15__new_allocatorIcE8allocateEyPKv:
.LFB2199:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$48, %rsp
	.seh_stackalloc	48
	.seh_endprologue
	movq	%rcx, 16(%rbp)
	movq	%rdx, 24(%rbp)
	movq	%r8, 32(%rbp)
	movq	16(%rbp), %rax
	movq	%rax, -8(%rbp)
	movabsq	$9223372036854775807, %rax
	cmpq	24(%rbp), %rax
	setb	%al
	movzbl	%al, %eax
	testl	%eax, %eax
	setne	%al
	testb	%al, %al
	je	.L296
	call	_ZSt17__throw_bad_allocv
.L296:
	movq	24(%rbp), %rax
	movq	%rax, %rcx
	call	_Znwy
	addq	$48, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.globl	_ZTV3Log
	.section	.rdata$_ZTV3Log,"dr"
	.linkonce same_size
	.align 8
_ZTV3Log:
	.quad	0
	.quad	_ZTI3Log
	.quad	_ZN3LogD1Ev
	.quad	_ZN3LogD0Ev
	.globl	_ZTI3Log
	.section	.rdata$_ZTI3Log,"dr"
	.linkonce same_size
	.align 8
_ZTI3Log:
	.quad	_ZTVN10__cxxabiv117__class_type_infoE+16
	.quad	_ZTS3Log
	.globl	_ZTS3Log
	.section	.rdata$_ZTS3Log,"dr"
	.linkonce same_size
_ZTS3Log:
	.ascii "3Log\0"
	.globl	_ZTISt9exception
	.section	.rdata$_ZTISt9exception,"dr"
	.linkonce same_size
	.align 8
_ZTISt9exception:
	.quad	_ZTVN10__cxxabiv117__class_type_infoE+16
	.quad	_ZTSSt9exception
	.globl	_ZTSSt9exception
	.section	.rdata$_ZTSSt9exception,"dr"
	.linkonce same_size
	.align 8
_ZTSSt9exception:
	.ascii "St9exception\0"
	.data
	.align 8
.LDFCM0:
	.quad	_ZTISt9exception
	.def	__gxx_personality_seh0;	.scl	2;	.type	32;	.endef
	.ident	"GCC: (Rev8, Built by MSYS2 project) 15.2.0"
	.def	__mingw_vsnprintf;	.scl	2;	.type	32;	.endef
	.def	strlen;	.scl	2;	.type	32;	.endef
	.def	memmove;	.scl	2;	.type	32;	.endef
	.def	memcpy;	.scl	2;	.type	32;	.endef
	.def	pthread_mutex_init;	.scl	2;	.type	32;	.endef
	.def	__cxa_allocate_exception;	.scl	2;	.type	32;	.endef
	.def	__cxa_throw;	.scl	2;	.type	32;	.endef
	.def	pthread_mutex_destroy;	.scl	2;	.type	32;	.endef
	.def	pthread_mutex_lock;	.scl	2;	.type	32;	.endef
	.def	pthread_mutex_unlock;	.scl	2;	.type	32;	.endef
	.def	pthread_cond_init;	.scl	2;	.type	32;	.endef
	.def	pthread_cond_destroy;	.scl	2;	.type	32;	.endef
	.def	pthread_cond_wait;	.scl	2;	.type	32;	.endef
	.def	pthread_cond_broadcast;	.scl	2;	.type	32;	.endef
	.def	__cxa_guard_acquire;	.scl	2;	.type	32;	.endef
	.def	atexit;	.scl	2;	.type	32;	.endef
	.def	__cxa_guard_release;	.scl	2;	.type	32;	.endef
	.def	__cxa_guard_abort;	.scl	2;	.type	32;	.endef
	.def	_Unwind_Resume;	.scl	2;	.type	32;	.endef
	.def	__cxa_begin_catch;	.scl	2;	.type	32;	.endef
	.def	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc;	.scl	2;	.type	32;	.endef
	.def	_ZNSolsEPFRSoS_E;	.scl	2;	.type	32;	.endef
	.def	__cxa_end_catch;	.scl	2;	.type	32;	.endef
	.def	fputs;	.scl	2;	.type	32;	.endef
	.def	memset;	.scl	2;	.type	32;	.endef
	.def	fflush;	.scl	2;	.type	32;	.endef
	.def	fclose;	.scl	2;	.type	32;	.endef
	.def	_ZdlPv;	.scl	2;	.type	32;	.endef
	.def	_ZdaPv;	.scl	2;	.type	32;	.endef
	.def	_Znay;	.scl	2;	.type	32;	.endef
	.def	strrchr;	.scl	2;	.type	32;	.endef
	.def	memcpy;	.scl	2;	.type	32;	.endef
	.def	fopen;	.scl	2;	.type	32;	.endef
	.def	_Znwy;	.scl	2;	.type	32;	.endef
	.def	pthread_create;	.scl	2;	.type	32;	.endef
	.def	pthread_detach;	.scl	2;	.type	32;	.endef
	.def	gettimeofday;	.scl	2;	.type	32;	.endef
	.def	_ZNSolsEi;	.scl	2;	.type	32;	.endef
	.def	exit;	.scl	2;	.type	32;	.endef
	.def	_ZSt20__throw_length_errorPKc;	.scl	2;	.type	32;	.endef
	.def	_ZSt17__throw_bad_allocv;	.scl	2;	.type	32;	.endef
	.section	.rdata$.refptr._ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_, "dr"
	.p2align	3, 0
	.globl	.refptr._ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_
	.linkonce	discard
.refptr._ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_:
	.quad	_ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_
	.section	.rdata$.refptr._ZSt4cerr, "dr"
	.p2align	3, 0
	.globl	.refptr._ZSt4cerr
	.linkonce	discard
.refptr._ZSt4cerr:
	.quad	_ZSt4cerr
	.section	.rdata$.refptr._ZNSt9exceptionD1Ev, "dr"
	.p2align	3, 0
	.globl	.refptr._ZNSt9exceptionD1Ev
	.linkonce	discard
.refptr._ZNSt9exceptionD1Ev:
	.quad	_ZNSt9exceptionD1Ev
	.section	.rdata$.refptr._ZTVSt9exception, "dr"
	.p2align	3, 0
	.globl	.refptr._ZTVSt9exception
	.linkonce	discard
.refptr._ZTVSt9exception:
	.quad	_ZTVSt9exception
