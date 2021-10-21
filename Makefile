# 输出文件名(不包含后缀)
TARGET       = template
# 输出文件路径
OBJ_DIR      = ./output

# C 源文件
SRCS         = ./src/main.c
# 汇编源文件
ASMS         = ./boot/startup_stm32f10x.s

# 包含路径
INCLUDES     = -I./boot/ -I./cmsis/ -I./inc/
# 宏定义
DEFINES      = 
# 架构
CORE         = -mcpu=cortex-m3
# 编译优化等级
OPTIMIZATION = -O0
# 链接脚本
LD_FILE      = .\stm32f10x.ld

# 编译参数
CCFLAGS := $(CORE) -g -fomit-frame-pointer -fno-common -Wall -mthumb -mno-thumb-interwork\
           $(OPTIMIZATION) $(INCLUDES) $(DEFINES)
# -ffunction-sections 每个函数单独成节
# -fdata-sections 每个数据单独成节

# 链接参数
LDFLAGS := -T $(LD_FILE) $(CORE) -Wl,-Map="$(OBJ_DIR)\$(TARGET).map" -nostartfiles
# --specs=nosys.specs 链接编译器自带的 malloc 等
# -Wl,-gc-sections 移除未使用的节, 配合 -ffunction-sections -fdata-sections 使用

OBJS    := $(SRCS:%.c=$(OBJ_DIR)/%.o) $(ASMS:%.s=$(OBJ_DIR)/%.o)

# 编译器
AR      = arm-none-eabi-ar
CC      = arm-none-eabi-gcc
CXX     = arm-none-eabi-g++
NM      = arm-none-eabi-nm
CPP     = arm-none-eabi-cpp
OBJCOPY = arm-none-eabi-objcopy
OBJDUMP = arm-none-eabi-objdump
SIZE    = arm-none-eabi-size

# 以下一般无需修改. 如果编译环境是 Windows NT 则执行对应命令, 否则执行 Linux 命令

ifeq ($(OS),Windows_NT) 

.PHONY: clean

$(OBJ_DIR)/$(TARGET).elf:$(OBJS)
	@$(CC) $(LDFLAGS) -o $@ $^
	@$(OBJCOPY) -O binary $@ $(OBJ_DIR)/$(TARGET).bin
	@$(OBJCOPY) -O ihex $@ $(OBJ_DIR)/$(TARGET).hex
	@echo LD $@
	@$(SIZE) --format=gnu $@

%.d:%.c

INCLUDE_FILES := $(SRCS:%.c=$(OBJ_DIR)/%.d)
-include $(INCLUDE_FILES)

${OBJ_DIR}/%.o:%.c Makefile
	@if not exist $(subst /,\, $(@D)) (md $(subst /,\, $(@D)))
	@$(CC) $(CCFLAGS) -MMD -c $< -o $@
	@echo CC $@

${OBJ_DIR}/%.o:%.s Makefile
	@if not exist $(subst /,\, $(@D)) (md $(subst /,\, $(@D)))
	@$(CC) $(CCFLAGS) -MMD -c $< -o $@
	@echo CC $@

clean:
	@rd /s /q $(subst /,\,${OBJ_DIR})
	@md $(subst /,\,${OBJ_DIR})

else

.PHONY: clean

$(OBJ_DIR)/$(TARGET).elf:$(OBJS)
	@$(CC) $(LDFLAGS) -o $@ $^
	@$(OBJCOPY) -O binary $@ $(OBJ_DIR)/$(TARGET).bin
	@$(OBJCOPY) -O ihex $@ $(OBJ_DIR)/$(TARGET).hex
	@echo LD $@
	@$(SIZE) --format=gnu $@

%.d:%.c

INCLUDE_FILES := $(SRCS:%.c=$(OBJ_DIR)/%.d)
-include $(INCLUDE_FILES)

${OBJ_DIR}/%.o:%.c Makefile
	@-mkdir -p $(@D)
	@$(CC) $(CCFLAGS) -MMD -c $< -o $@
	@echo CC $@

${OBJ_DIR}/%.o:%.s Makefile
	@-mkdir -p $(@D)
	@$(CC) $(CCFLAGS) -MMD -c $< -o $@
	@echo CC $@

clean:
	rm -rf ${OBJ_DIR}/*

endif
