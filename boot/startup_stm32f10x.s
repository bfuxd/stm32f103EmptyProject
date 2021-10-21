/**
 * 文件名: startup_stm32f10x.s
 * 作  者: 
 * 版  本: 
 * 日  期: 2020/9/17
 * 说  明: 用于 STM32F10x 的
 *       1.初始化堆栈指针 SP
 *       2.初始化程序计数器 PC
 *       3.设定中断向量表
 *       4.配置时钟系统
 *       5.跳转到C语言 main
 * 复位后 CortexM3 处理器处于线程模式, 优先级为 Privileged, 堆栈设置为 MSP
 */

    .include "startup_stm32f10x_RCC.h"
    .syntax unified
    .cpu cortex-m3
    .fpu softvfp
    .thumb

/* 初始化的变量(.data 段)的加载地址(定义在链接脚本中) */
.word  _sidata
/* 初始化的变量(.data 段)的执行地址(定义在链接脚本中) */
.word  _sdata
/* 初始化的变量(.data 段)的结束地址(定义在链接脚本中) */
.word  _edata
/* 无初始值的变量(.bss 段)的起始地址(定义在链接脚本中) */
.word  _sbss
/* 无初始值的变量(.bss 段)的结束地址(定义在链接脚本中) */
.word  _ebss

/* 以下是复位异常执行的代码，仅完成必要的初始化，随后跳转到 C(main()) 程序执行 */
    .section  .text,"ax",%progbits
    .weak  Reset_Handler
    .type  Reset_Handler, %function
Reset_Handler:
/* 关闭所有中断并清除标志 */
    ldr   r0, =RCC_CIR
    ldr   r1, [r0]
    bic   r1, 0x009f0000
    str   r1, [r0]
/* 开启外部晶振 */
    ldr   r0, =RCC_CR
    ldr   r1, [r0]
    orr   r1, r1, #0x00010000
    str   r1, [r0]
/* 等待外部时钟稳定 */
    ldr   r2, =0x00001000
0:
    subs  r2, r2, #1
    beq   2f
    ldr   r1, [r0]
    ands  r1, r1, #0x00020000
    beq   0b
1:
/* 设置时钟周期与FLASH访问周期比率 =2 */
    ldr   r0, =FLASH_ACR
    ldr   r1, [r0]
    and   r1, r1, #0xfffffffc
    orr   r1, r1, #0x00000002
    str   r1, [r0]
/* 软件必须保证APB1时钟频率不超过36MHz, 这里二分频 */
    ldr   r0, =RCC_CFGR
    ldr   r1, [r0]
    orr   r1, r1, #0x00000400
    str   r1, [r0]
#ifdef STM32F10X_CL
    // TODO: STM32F10X_CL 系列还有额外的初始化工作
#else
/* 配置 PLL: PLLCLK = HSE * 9 = 72 MHz */
    ldr   r1, [r0]
    and   r1, r1, #0xffc0ffff
    orr   r1, r1, #0x001d0000
    str   r1, [r0]
#endif
/* 开启 PLL 并等稳定 */
    ldr   r0, =RCC_CR
    ldr   r1, [r0]
    orr   r1, r1, #0x01000000
    str   r1, [r0]
0:
    ldr   r1, [r0]
    tst   r1, #0x02000000
    beq   0b
/* 选择 PLL 作系统时钟源 */
    ldr   r0, =RCC_CFGR
    ldr   r1, [r0]
    bic   r1, #0x00000003
    orr   r1, r1, #0x00000002
    str   r1, [r0]
0:
    ldr   r1, [r0]
    and   r1, r1, 0x0000000c
    cmp   r1, #0x00000008
    bne   0b
2:
/* 从 Flsah 复制初始值到 SRAM */
    movs  r0, #0
    ldr   r1, =_sidata
    ldr   r2, =_sdata
    ldr   r3, =_edata
CopyDataLoop:
    cmp   r2, r3
    bcs   FillZerobss
    ldr   r4, [r1, r0]
    str   r4, [r2, r0]
    add   r1, r1, #4
    add   r2, r2, #4
    b     CopyDataLoop

/* 初始化 bss 段 */
FillZerobss:
    movs  r0, #0
    ldr   r1, =_sbss
    ldr   r2, =_ebss
FillZeroLoop:
    cmp   r1, r2
    bcs   Init
    str   r0, [r1], #4
    b     FillZeroLoop

/* 跳转到 C */
Init:
    bl    main

/* 缺省中断处理，保留系统状态以供调试器检查 */
Default_Handler:
    b     .

/* Cortex M3 的中断向量表，必须保证这些代码编译到物理地址 0x00000000 处 */
    .section    .isr_vector,"a",%progbits
    .type    g_pfnVectors, %object
    .size    g_pfnVectors, .-g_pfnVectors

g_pfnVectors:
    .word    _estack
    .word    Reset_Handler
    .word    NMI_Handler
    .word    HardFault_Handler
    .word    MemManage_Handler
    .word    BusFault_Handler
    .word    UsageFault_Handler
    .word    0
    .word    0
    .word    0
    .word    0
    .word    SVC_Handler
    .word    DebugMon_Handler
    .word    0
    .word    PendSV_Handler
    .word    SysTick_Handler
    .word    WWDG_IRQHandler
    .word    PVD_IRQHandler
    .word    TAMPER_IRQHandler
    .word    RTC_IRQHandler
    .word    FLASH_IRQHandler
    .word    RCC_IRQHandler
    .word    EXTI0_IRQHandler
    .word    EXTI1_IRQHandler
    .word    EXTI2_IRQHandler
    .word    EXTI3_IRQHandler
    .word    EXTI4_IRQHandler
    .word    DMA1_Channel1_IRQHandler
    .word    DMA1_Channel2_IRQHandler
    .word    DMA1_Channel3_IRQHandler
    .word    DMA1_Channel4_IRQHandler
    .word    DMA1_Channel5_IRQHandler
    .word    DMA1_Channel6_IRQHandler
    .word    DMA1_Channel7_IRQHandler
    .word    ADC1_2_IRQHandler
    .word    USB_HP_CAN1_TX_IRQHandler
    .word    USB_LP_CAN1_RX0_IRQHandler
    .word    CAN1_RX1_IRQHandler
    .word    CAN1_SCE_IRQHandler
    .word    EXTI9_5_IRQHandler
    .word    TIM1_BRK_IRQHandler
    .word    TIM1_UP_IRQHandler
    .word    TIM1_TRG_COM_IRQHandler
    .word    TIM1_CC_IRQHandler
    .word    TIM2_IRQHandler
    .word    TIM3_IRQHandler
    .word    TIM4_IRQHandler
    .word    I2C1_EV_IRQHandler
    .word    I2C1_ER_IRQHandler
    .word    I2C2_EV_IRQHandler
    .word    I2C2_ER_IRQHandler
    .word    SPI1_IRQHandler
    .word    SPI2_IRQHandler
    .word    USART1_IRQHandler
    .word    USART2_IRQHandler
    .word    USART3_IRQHandler
    .word    EXTI15_10_IRQHandler
    .word    RTCAlarm_IRQHandler
    .word    USBWakeUp_IRQHandler

  .weak    NMI_Handler
    .thumb_set NMI_Handler,Default_Handler
    
  .weak    HardFault_Handler
    .thumb_set HardFault_Handler,Default_Handler
    
  .weak    MemManage_Handler
    .thumb_set MemManage_Handler,Default_Handler
    
  .weak    BusFault_Handler
    .thumb_set BusFault_Handler,Default_Handler

    .weak    UsageFault_Handler
    .thumb_set UsageFault_Handler,Default_Handler

    .weak    SVC_Handler
    .thumb_set SVC_Handler,Default_Handler

    .weak    DebugMon_Handler
    .thumb_set DebugMon_Handler,Default_Handler

    .weak    PendSV_Handler
    .thumb_set PendSV_Handler,Default_Handler

    .weak    SysTick_Handler
    .thumb_set SysTick_Handler,Default_Handler

    .weak    WWDG_IRQHandler
    .thumb_set WWDG_IRQHandler,Default_Handler

    .weak    PVD_IRQHandler
    .thumb_set PVD_IRQHandler,Default_Handler

    .weak    TAMPER_IRQHandler
    .thumb_set TAMPER_IRQHandler,Default_Handler

    .weak    RTC_IRQHandler
    .thumb_set RTC_IRQHandler,Default_Handler

    .weak    FLASH_IRQHandler
    .thumb_set FLASH_IRQHandler,Default_Handler

    .weak    RCC_IRQHandler
    .thumb_set RCC_IRQHandler,Default_Handler

    .weak    EXTI0_IRQHandler
    .thumb_set EXTI0_IRQHandler,Default_Handler

    .weak    EXTI1_IRQHandler
    .thumb_set EXTI1_IRQHandler,Default_Handler

    .weak    EXTI2_IRQHandler
    .thumb_set EXTI2_IRQHandler,Default_Handler

    .weak    EXTI3_IRQHandler
    .thumb_set EXTI3_IRQHandler,Default_Handler

    .weak    EXTI4_IRQHandler
    .thumb_set EXTI4_IRQHandler,Default_Handler

    .weak    DMA1_Channel1_IRQHandler
    .thumb_set DMA1_Channel1_IRQHandler,Default_Handler

    .weak    DMA1_Channel2_IRQHandler
    .thumb_set DMA1_Channel2_IRQHandler,Default_Handler

    .weak    DMA1_Channel3_IRQHandler
    .thumb_set DMA1_Channel3_IRQHandler,Default_Handler

    .weak    DMA1_Channel4_IRQHandler
    .thumb_set DMA1_Channel4_IRQHandler,Default_Handler

    .weak    DMA1_Channel5_IRQHandler
    .thumb_set DMA1_Channel5_IRQHandler,Default_Handler

    .weak    DMA1_Channel6_IRQHandler
    .thumb_set DMA1_Channel6_IRQHandler,Default_Handler

    .weak    DMA1_Channel7_IRQHandler
    .thumb_set DMA1_Channel7_IRQHandler,Default_Handler

    .weak    ADC1_2_IRQHandler
    .thumb_set ADC1_2_IRQHandler,Default_Handler

    .weak    USB_HP_CAN1_TX_IRQHandler
    .thumb_set USB_HP_CAN1_TX_IRQHandler,Default_Handler

    .weak    USB_LP_CAN1_RX0_IRQHandler
    .thumb_set USB_LP_CAN1_RX0_IRQHandler,Default_Handler

    .weak    CAN1_RX1_IRQHandler
    .thumb_set CAN1_RX1_IRQHandler,Default_Handler

    .weak    CAN1_SCE_IRQHandler
    .thumb_set CAN1_SCE_IRQHandler,Default_Handler

    .weak    EXTI9_5_IRQHandler
    .thumb_set EXTI9_5_IRQHandler,Default_Handler

    .weak    TIM1_BRK_IRQHandler
    .thumb_set TIM1_BRK_IRQHandler,Default_Handler

    .weak    TIM1_UP_IRQHandler
    .thumb_set TIM1_UP_IRQHandler,Default_Handler

    .weak    TIM1_TRG_COM_IRQHandler
    .thumb_set TIM1_TRG_COM_IRQHandler,Default_Handler

    .weak    TIM1_CC_IRQHandler
    .thumb_set TIM1_CC_IRQHandler,Default_Handler

    .weak    TIM2_IRQHandler
    .thumb_set TIM2_IRQHandler,Default_Handler

    .weak    TIM3_IRQHandler
    .thumb_set TIM3_IRQHandler,Default_Handler

    .weak    TIM4_IRQHandler
    .thumb_set TIM4_IRQHandler,Default_Handler

    .weak    I2C1_EV_IRQHandler
    .thumb_set I2C1_EV_IRQHandler,Default_Handler

    .weak    I2C1_ER_IRQHandler
    .thumb_set I2C1_ER_IRQHandler,Default_Handler

    .weak    I2C2_EV_IRQHandler
    .thumb_set I2C2_EV_IRQHandler,Default_Handler

    .weak    I2C2_ER_IRQHandler
    .thumb_set I2C2_ER_IRQHandler,Default_Handler

    .weak    SPI1_IRQHandler
    .thumb_set SPI1_IRQHandler,Default_Handler

    .weak    SPI2_IRQHandler
    .thumb_set SPI2_IRQHandler,Default_Handler

    .weak    USART1_IRQHandler
    .thumb_set USART1_IRQHandler,Default_Handler

    .weak    USART2_IRQHandler
    .thumb_set USART2_IRQHandler,Default_Handler

    .weak    USART3_IRQHandler
    .thumb_set USART3_IRQHandler,Default_Handler

    .weak    EXTI15_10_IRQHandler
    .thumb_set EXTI15_10_IRQHandler,Default_Handler

    .weak    RTCAlarm_IRQHandler
    .thumb_set RTCAlarm_IRQHandler,Default_Handler

    .weak    USBWakeUp_IRQHandler
    .thumb_set USBWakeUp_IRQHandler,Default_Handler

    .end
