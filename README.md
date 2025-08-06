# Mining Incident Response Script

## 概述

这是一个专为Ubuntu系统设计的挖矿应急响应脚本，用于检测和分析可能的挖矿恶意软件活动。该脚本采用模块化设计，提供全面的系统安全检查。

## 功能特性

### 🔍 调查模块

1. **用户调查 (User Investigation)**
   - 检查用户信息和影子用户
   - 检测SSH密钥和授权文件
   - 识别具有root权限的用户
   - 检查空密码和弱密码哈希

2. **命令调查 (Command Investigation)**
   - 检查命令别名设置
   - 检测命令篡改
   - 验证命令完整性
   - 安装和使用busybox确保命令纯净

3. **网络调查 (Network Investigation)**
   - 检查网络连接和监听端口
   - 检测可疑IP和爆破行为
   - 分析SSH暴力破解尝试
   - 识别挖矿池连接

4. **进程调查 (Process Investigation)**
   - 检查高CPU/内存使用率进程
   - 检测可疑挖矿进程
   - 使用unhide检测隐藏进程
   - 分析进程树和网络连接

5. **启动项调查 (Startup Investigation)**
   - 检查systemd服务
   - 分析自启动脚本
   - 检测可疑启动配置
   - 验证服务权限

6. **计划任务调查 (Cron Investigation)**
   - 检查cron任务
   - 分析定时任务
   - 检测systemd定时器
   - 识别可疑自动化脚本

7. **日志调查 (Log Investigation)**
   - 分析认证日志
   - 检查系统日志
   - 查看命令历史
   - 检测可疑活动

8. **系统调查 (System Investigation)**
   - 检查系统信息
   - 分析文件系统
   - 检测可疑文件
   - 验证系统完整性

### 🎨 输出特性

- **彩色输出**: 使用不同颜色标识不同严重级别
  - 🔴 红色: 严重问题 (CRITICAL)
  - 🟡 黄色: 警告 (WARNING)
  - 🟢 绿色: 正常 (INFO)
  - 🔵 蓝色: 信息 (CYAN)

- **结构化输出**: 每个检查项都显示当前任务、运行命令和结果

- **分模块日志记录**: 每个模块生成独立的日志文件，保存在results目录中
- **结果索引**: 自动生成结果索引文件，方便查阅所有生成的文件
- **结果保存**: 可疑项目保存到临时文件供后续分析

## 安装和使用

### 系统要求

- Ubuntu 系统
- Root 权限
- Bash shell

### 安装步骤

1. 克隆或下载脚本文件
2. 确保所有模块文件都在正确位置
3. 给脚本执行权限

```bash
chmod +x mining_incident_response.sh
```

### 运行脚本

```bash
sudo ./mining_incident_response.sh
```

## 文件结构

```
mining_incident_response/
├── mining_incident_response.sh    # 主脚本
├── modules/                       # 模块目录
│   ├── user_investigation.sh     # 用户调查模块
│   ├── command_investigation.sh  # 命令调查模块
│   ├── network_investigation.sh  # 网络调查模块
│   ├── process_investigation.sh  # 进程调查模块
│   ├── startup_investigation.sh  # 启动项调查模块
│   ├── cron_investigation.sh     # 计划任务调查模块
│   ├── log_investigation.sh      # 日志调查模块
│   └── system_investigation.sh   # 系统调查模块
├── temp/                         # 临时文件目录
├── results/                      # 结果文件目录
│   ├── user_YYYYMMDD_HHMMSS.log      # 用户调查日志
│   ├── command_YYYYMMDD_HHMMSS.log   # 命令调查日志
│   ├── network_YYYYMMDD_HHMMSS.log   # 网络调查日志
│   ├── process_YYYYMMDD_HHMMSS.log   # 进程调查日志
│   ├── startup_YYYYMMDD_HHMMSS.log   # 启动项调查日志
│   ├── cron_YYYYMMDD_HHMMSS.log      # 计划任务调查日志
│   ├── log_YYYYMMDD_HHMMSS.log       # 日志调查日志
│   ├── system_YYYYMMDD_HHMMSS.log    # 系统调查日志
│   ├── summary_YYYYMMDD_HHMMSS.txt   # 汇总报告
│   └── results_index_YYYYMMDD_HHMMSS.txt # 结果索引
└── README.md                     # 说明文档
```

## 输出示例

```
╔══════════════════════════════════════════════════════════════╗
║                MINING INCIDENT RESPONSE SCRIPT               ║
║                    Ubuntu System Investigation                ║
║                        Version 1.0                           ║
╚══════════════════════════════════════════════════════════════╝

══════════════════════════════════════════════════════════════
                    USER INVESTIGATION
══════════════════════════════════════════════════════════════

Current Task: User Information Check
Current Command: cat /etc/passwd
Current Result:
=== All Users in /etc/passwd ===
User: root UID: 0 Shell: /bin/bash
User: daemon UID: 1 Shell: /usr/sbin/nologin
...
```

## 检测项目

### 用户相关
- 检查UID为0的用户
- 检测SSH授权密钥
- 识别空密码用户
- 检查弱密码哈希

### 网络相关
- 监听端口检查
- 可疑IP检测
- SSH暴力破解分析
- 挖矿池连接识别

### 进程相关
- 高CPU使用率进程
- 可疑挖矿进程
- 隐藏进程检测
- 异常进程名称

### 文件相关
- 临时目录可疑文件
- 异常权限文件
- 隐藏文件检测
- 可疑内容文件

### 系统相关
- 自启动服务检查
- 计划任务分析
- 日志文件审查
- 系统完整性验证

## 注意事项

1. **权限要求**: 脚本需要root权限才能运行所有检查
2. **系统兼容性**: 主要针对Ubuntu系统，其他Linux发行版可能需要调整
3. **性能影响**: 某些检查可能对系统性能有轻微影响
4. **误报可能**: 某些正常活动可能被标记为可疑，需要人工判断

## 扩展性

该脚本采用模块化设计，可以轻松添加新的检查模块：

1. 在`modules/`目录下创建新的模块文件
2. 在主脚本中引用新模块
3. 确保新模块遵循相同的输出格式

## 故障排除

### 常见问题

1. **权限错误**: 确保使用sudo运行脚本
2. **模块加载失败**: 检查模块文件是否存在和可执行
3. **命令不存在**: 某些系统可能缺少特定命令，脚本会自动处理

### 日志文件

脚本运行后会生成以下日志文件：

1. **主日志文件**: `incident_response_YYYYMMDD_HHMMSS.log` - 记录所有活动
2. **模块日志文件**: 每个模块在`results/`目录下生成独立的日志文件
   - `user_YYYYMMDD_HHMMSS.log` - 用户调查日志
   - `command_YYYYMMDD_HHMMSS.log` - 命令调查日志
   - `network_YYYYMMDD_HHMMSS.log` - 网络调查日志
   - `process_YYYYMMDD_HHMMSS.log` - 进程调查日志
   - `startup_YYYYMMDD_HHMMSS.log` - 启动项调查日志
   - `cron_YYYYMMDD_HHMMSS.log` - 计划任务调查日志
   - `log_YYYYMMDD_HHMMSS.log` - 日志调查日志
   - `system_YYYYMMDD_HHMMSS.log` - 系统调查日志
3. **汇总报告**: `summary_YYYYMMDD_HHMMSS.txt` - 所有可疑项目的汇总
4. **结果索引**: `results_index_YYYYMMDD_HHMMSS.txt` - 所有生成文件的索引

这些文件可用于故障排除、审计和后续分析。

## 贡献

欢迎提交问题报告和改进建议。请确保：

1. 测试新功能
2. 遵循现有代码风格
3. 更新相关文档

## 许可证

本项目采用MIT许可证。详见LICENSE文件。

## 更新日志

### Version 1.0
- 初始版本发布
- 包含8个主要调查模块
- 支持彩色输出和日志记录
- 模块化设计架构 