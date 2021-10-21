ENTRY( Reset_Handler )

_Minimum_Stack_Size = 0x100 ;

MEMORY
{
  RAM (xrw) : ORIGIN = 0x20000000, LENGTH = 64K
  EXTSRAM (xrw) : ORIGIN = 0x60000000, LENGTH = 0
  FLASH (rx) : ORIGIN = 0x8000000, LENGTH = 512K
  FLASHB1 (rx) : ORIGIN = 0x00000000, LENGTH = 0
  EXTMEMB0 (rx) : ORIGIN = 0x00000000, LENGTH = 0
  EXTMEMB1 (rx) : ORIGIN = 0x00000000, LENGTH = 0
  EXTMEMB2 (rx) : ORIGIN = 0x00000000, LENGTH = 0
  EXTMEMB3 (rx) : ORIGIN = 0x00000000, LENGTH = 0
}

/* MSP 栈顶地址初值 */
_estack = 0x20010000;

/* 节区定义 */

SECTIONS
{
    /* .isr_vector 中断向量表装入物理地址 0 处 */
    .isr_vector :
    {
        . = ALIGN(4);
        KEEP(*(.isr_vector))            /* 中断向量表 */
        . = ALIGN(4);
    } >FLASH

    /* 所有 .text 节, 装入代码段 */
    .text :
    {
        . = ALIGN(4);

        *(.text)                   /* remaining code */
        *(.text.*)                 /* remaining code */
        *(.rodata)                 /* read-only data (constants) */
        *(.rodata*)
        *(.glue_7)                 /*.glue_7用于ARM代码调用Thumb代码*/
        *(.glue_7t)                /*.glue_7t用于Thumb代码调用ARM代码*/

        . = ALIGN(4);
        _etext = .;
        /* .data 节的初值存储地址 */
        _sidata = _etext;
    } >FLASH

    /* 有初值的数据段, 启动代码需要把初值从 flash 中复制到 RAM 中 */
    .data  : AT ( _sidata )
    {
        . = ALIGN(4);
        /* 为启动代码提供 .data 节的执行地址 (开头) */
        _sdata = . ;

        *(.data)
        *(.data.*)

        . = ALIGN(4);
        /* 为启动代码提供 .data 节的执行地址 (结尾) */
        _edata = . ;
    } >RAM

    /* 无初值的数据段 */
    . = ALIGN(4);
    .bss :
    {
        _sbss = .;
        __bss_start__ = _sbss;
        *(.bss)
        *(.bss*)
        *(COMMON)

        . = ALIGN(4);
        _ebss = .;
        __bss_end__ = _ebss;
    } >RAM

    PROVIDE ( end = _ebss );
    PROVIDE ( _end = _ebss );

    /* 为栈预留的空间, 仅用于检查 RAM 空间是否足够, 实际栈不在这里 */
    ._usrstack :
    {
        . = ALIGN(4);
        _susrstack = . ;

        . = . + _Minimum_Stack_Size ;

        . = ALIGN(4);
        _eusrstack = . ;
    } >RAM

    /* this is the FLASH Bank1 */
    /* the C or assembly source must explicitly place the code or data there
    using the "section" attribute */
    .b1text :
    {
        *(.b1text)                   /* remaining code */
        *(.b1rodata)                 /* read-only data (constants) */
        *(.b1rodata*)
    } >FLASHB1

    /* this is the EXTMEM */
    /* the C or assembly source must explicitly place the code or data there
    using the "section" attribute */

    /* EXTMEM Bank0 */
    .eb0text :
    {
        *(.eb0text)                   /* remaining code */
        *(.eb0rodata)                 /* read-only data (constants) */
        *(.eb0rodata*)
    } >EXTMEMB0

    /* EXTMEM Bank1 */
    .eb1text :
    {
        *(.eb1text)                   /* remaining code */
        *(.eb1rodata)                 /* read-only data (constants) */
        *(.eb1rodata*)
    } >EXTMEMB1

    /* EXTMEM Bank2 */
    .eb2text :
    {
        *(.eb2text)                   /* remaining code */
        *(.eb2rodata)                 /* read-only data (constants) */
        *(.eb2rodata*)
    } >EXTMEMB2

    /* EXTMEM Bank0 */
    .eb3text :
    {
        *(.eb3text)                   /* remaining code */
        *(.eb3rodata)                 /* read-only data (constants) */
        *(.eb3rodata*)
    } >EXTMEMB3



    /* 以下仅是调试信息 */

    /* remove the debugging information from the standard libraries */
    DISCARD :
    {
     libc.a ( * )
     libm.a ( * )
     libgcc.a ( * )
    }

    /* Stabs debugging sections.  */
    .stab          0 : { *(.stab) }
    .stabstr       0 : { *(.stabstr) }
    .stab.excl     0 : { *(.stab.excl) }
    .stab.exclstr  0 : { *(.stab.exclstr) }
    .stab.index    0 : { *(.stab.index) }
    .stab.indexstr 0 : { *(.stab.indexstr) }
    .comment       0 : { *(.comment) }
    /* DWARF debug sections.
       Symbols in the DWARF debugging sections are relative to the beginning
       of the section so we begin them at 0.  */
    /* DWARF 1 */
    .debug          0 : { *(.debug) }
    .line           0 : { *(.line) }
    /* GNU DWARF 1 extensions */
    .debug_srcinfo  0 : { *(.debug_srcinfo) }
    .debug_sfnames  0 : { *(.debug_sfnames) }
    /* DWARF 1.1 and DWARF 2 */
    .debug_aranges  0 : { *(.debug_aranges) }
    .debug_pubnames 0 : { *(.debug_pubnames) }
    /* DWARF 2 */
    .debug_info     0 : { *(.debug_info .gnu.linkonce.wi.*) }
    .debug_abbrev   0 : { *(.debug_abbrev) }
    .debug_line     0 : { *(.debug_line) }
    .debug_frame    0 : { *(.debug_frame) }
    .debug_str      0 : { *(.debug_str) }
    .debug_loc      0 : { *(.debug_loc) }
    .debug_macinfo  0 : { *(.debug_macinfo) }
    /* SGI/MIPS DWARF 2 extensions */
    .debug_weaknames 0 : { *(.debug_weaknames) }
    .debug_funcnames 0 : { *(.debug_funcnames) }
    .debug_typenames 0 : { *(.debug_typenames) }
    .debug_varnames  0 : { *(.debug_varnames) }
}