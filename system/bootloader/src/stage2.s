
;*******************************************************
;
;	Stage2.asm
;		Stage2 Bootloader
;
;*******************************************************

bits	16

org 0x500

jmp	main				; go to start

;*******************************************************
;	Preprocessor directives
;*******************************************************

%include "stdio.inc"			; basic i/o routines
%include "Gdt.inc"			; Gdt routines
%include "A20.inc"			; A20 enabling
%include "Fat12.inc"			; FAT12 driver. Kinda :)
%include "common.inc"

;*******************************************************
;	Data Section
;*******************************************************

LoadingMsg db 0x0D, 0x0A, "Searching for Operating System...", 0x00
msgFailure db 0x0D, 0x0A, "*** FATAL: Missing or corrupt KERNEL.SYS. Press Any Key to Reboot.", 0x0D, 0x0A, 0x0A, 0x00

main:

	;-------------------------------;
	;   Setup segments and stack	;
	;-------------------------------;

	cli	                   ; clear interrupts
	xor		ax, ax             ; null segments
	mov		ds, ax
	mov		es, ax
	mov		ax, 0x0000         ; stack begins at 0x9000-0xffff
	mov		ss, ax
	mov		sp, 0xFFFF
	sti	                   ; enable interrupts

	call	_EnableA20
	call	InstallGDT
	sti

	call	LoadRoot
   	mov    	ebx, 0
   	mov		ebp, IMAGE_RMODE_BASE
   	mov 	esi, ImageName
	call	LoadFile		; load our file
   	mov   	dword [ImageSize], ecx
	cmp		ax, 0
	je		EnterStage3
	mov		si, msgFailure
	call   	Puts16
	mov		ah, 0
	int     0x16                    ; await keypress
	int     0x19                    ; warm boot computer

	;-------------------------------;
	;   Go into pmode               ;
	;-------------------------------;

EnterStage3:

	cli	                           ; clear interrupts
	mov	eax, cr0                   ; set bit 0 in cr0--enter pmode
	or	eax, 1
	mov	cr0, eax

	jmp	CODE_DESC:Stage3

;******************************************************
;	ENTRY POINT FOR STAGE 3
;******************************************************

bits 32

BadImage db "*** FATAL: Invalid or corrupt kernel image. Halting system.", 0

Stage3:

	;-------------------------------;
	;   Set registers				;
	;-------------------------------;

	mov	ax, DATA_DESC		; set data segments to data selector (0x10)
	mov	ds, ax
	mov	ss, ax
	mov	es, ax
	mov	esp, 90000h		; stack begins from 90000h

	call	ClrScr32

CopyImage:
  	mov	eax, dword [ImageSize]
  	movzx ebx, word [bpbBytesPerSector]
  	mul	ebx
  	mov	ebx, 4
  	div	ebx
    cld
    mov esi, IMAGE_RMODE_BASE
    mov	edi, IMAGE_PMODE_BASE
    mov	ecx, eax
    rep	movsd                   ; copy image to its protected mode address

	jmp EXECUTE

; TestImage:
;   	  mov    ebx, [IMAGE_PMODE_BASE+60]
;   	  add    ebx, IMAGE_PMODE_BASE    ; ebx now points to file sig (PE00)
;   	  mov    esi, ebx
;   	  mov    edi, ImageSig
;   	  cmpsw
;   	  je     EXECUTE
;   	  mov	ebx, BadImage
;   	  call	Puts32
;   	  cli
;   	  hlt

; ImageSig db 'PE'

EXECUTE:

	;---------------------------------------;
	;   Execute Kernel
	;---------------------------------------;

    ; parse the programs header info structures to get its entry point

	; add		ebx, 24
	; mov		eax, [ebx]			; _IMAGE_FILE_HEADER is 20 bytes + size of sig (4 bytes)
	; add		ebx, 20-4			; address of entry point
	; mov		ebp, dword [ebx]		; get entry point offset in code section	
	; add		ebx, 12				; image base is offset 8 bytes from entry point
	; mov		eax, dword [ebx]		; add image base
	; add		ebp, eax

	mov eax, IMAGE_PMODE_BASE
	mov ebp, eax
	add ebp, 0x0FFFFF
	mov esp, ebp

	mov ecx, eax
	add ecx, 24
	add eax, [ecx]
	sub eax, 0x08048000

	cli
	call eax               	      ; Execute Kernel

    cli
	hlt

;-- header information format for PE files -------------------

;typedef struct _IMAGE_DOS_HEADER {  // DOS .EXE header
;    USHORT e_magic;         // Magic number (Should be MZ
;    USHORT e_cblp;          // Bytes on last page of file
;    USHORT e_cp;            // Pages in file
;    USHORT e_crlc;          // Relocations
;    USHORT e_cparhdr;       // Size of header in paragraphs
;    USHORT e_minalloc;      // Minimum extra paragraphs needed
;    USHORT e_maxalloc;      // Maximum extra paragraphs needed
;    USHORT e_ss;            // Initial (relative) SS value
;    USHORT e_sp;            // Initial SP value
;    USHORT e_csum;          // Checksum
;    USHORT e_ip;            // Initial IP value
;    USHORT e_cs;            // Initial (relative) CS value
;    USHORT e_lfarlc;        // File address of relocation table
;    USHORT e_ovno;          // Overlay number
;    USHORT e_res[4];        // Reserved words
;    USHORT e_oemid;         // OEM identifier (for e_oeminfo)
;    USHORT e_oeminfo;       // OEM information; e_oemid specific
;    USHORT e_res2[10];      // Reserved words
;    LONG   e_lfanew;        // File address of new exe header
;  } IMAGE_DOS_HEADER, *PIMAGE_DOS_HEADER;

;<<------ Real mode stub program -------->>

;<<------ Here is the file signiture, such as PE00 for NT --->>

;typedef struct _IMAGE_FILE_HEADER {
;    USHORT  Machine;
;    USHORT  NumberOfSections;
;    ULONG   TimeDateStamp;
;    ULONG   PointerToSymbolTable;
;    ULONG   NumberOfSymbols;
;    USHORT  SizeOfOptionalHeader;
;    USHORT  Characteristics;
;} IMAGE_FILE_HEADER, *PIMAGE_FILE_HEADER;

;struct _IMAGE_OPTIONAL_HEADER {
;    //
;    // Standard fields.
;    //
;    USHORT  Magic;
;    UCHAR   MajorLinkerVersion;
;    UCHAR   MinorLinkerVersion;
;    ULONG   SizeOfCode;
;    ULONG   SizeOfInitializedData;
;    ULONG   SizeOfUninitializedData;
;    ULONG   AddressOfEntryPoint;			<< IMPORTANT!
;    ULONG   BaseOfCode;
;    ULONG   BaseOfData;
;    //
;    // NT additional fields.
;    //
;    ULONG   ImageBase;
;    ULONG   SectionAlignment;
;    ULONG   FileAlignment;
;    USHORT  MajorOperatingSystemVersion;
;    USHORT  MinorOperatingSystemVersion;
;    USHORT  MajorImageVersion;
;    USHORT  MinorImageVersion;
;    USHORT  MajorSubsystemVersion;
;    USHORT  MinorSubsystemVersion;
;    ULONG   Reserved1;
;    ULONG   SizeOfImage;
;    ULONG   SizeOfHeaders;
;    ULONG   CheckSum;
;    USHORT  Subsystem;
;    USHORT  DllCharacteristics;
;    ULONG   SizeOfStackReserve;
;    ULONG   SizeOfStackCommit;
;    ULONG   SizeOfHeapReserve;
;    ULONG   SizeOfHeapCommit;
;    ULONG   LoaderFlags;
;    ULONG   NumberOfRvaAndSizes;
;    IMAGE_DATA_DIRECTORY DataDirectory[IMAGE_NUMBEROF_DIRECTORY_ENTRIES];
;} IMAGE_OPTIONAL_HEADER, *PIMAGE_OPTIONAL_HEADER;

