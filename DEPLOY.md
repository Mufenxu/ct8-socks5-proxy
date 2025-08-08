# 部署说明

## 🚀 GitHub一键部署

### 标准部署命令

在CT8/Serv00服务器上运行：

```bash
curl -sL https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/ct8_ultimate_stealth.sh | bash
```

### 部署过程

部署脚本会自动完成以下步骤：

1. ✅ **系统环境检查** - 验证FreeBSD/Linux兼容性
2. ✅ **创建隐蔽目录** - 建立伪装的文件结构
3. ✅ **智能端口扫描** - 自动找到可用的高端口
4. ✅ **生成隐蔽配置** - 创建随机密码和伪装标识
5. ✅ **部署代理服务** - 安装伪装的pip缓存服务
6. ✅ **设置保活机制** - 配置隐蔽的定时重启任务
7. ✅ **启动服务验证** - 确认服务正常运行

### 预期输出

```
╔══════════════════════════════════════════════════════════╗
║      CT8 包管理缓存服务 部署工具 - 终极安全版            ║
║                                                          ║
║  🛡️ 绝对安全，100%防检测                                 ║
║  🥷 终极隐蔽模式，所有漏洞已修复                         ║
║  🔒 Ultimate Security Edition                           ║
╚══════════════════════════════════════════════════════════╝

[INFO] 开始部署最终隐蔽代理服务...
[STEP] 检查系统环境...
[INFO] 系统检查完成
[STEP] 创建隐蔽目录结构...
[INFO] 隐蔽目录创建完成
[STEP] 智能端口扫描中...
[INFO] 🎯 找到可用端口: 63533 (范围: 63000-64000)
[STEP] 生成隐蔽配置...
[INFO] 配置参数生成完成
[INFO] 服务端口: 63533
[INFO] 认证令牌: cache_220_0f6c
[STEP] 创建最终隐蔽缓存服务...
[INFO] 最终隐蔽服务创建完成
[STEP] 创建隐蔽启动服务...
[INFO] 隐蔽保活机制已设置（每10分钟检查）
[STEP] 启动隐蔽服务...
[INFO] 隐蔽服务启动成功 (PID: 12345)

╔══════════════════════════════════════════════════════════╗
║              🥷 最终隐蔽部署成功！                       ║
╚══════════════════════════════════════════════════════════╝

🔒 最终隐蔽代理连接信息
服务器: your-server-ip
端口: 63533  
密码: cache_220_0f6c
```

## 🛠️ 手动部署（备用方案）

如果一键部署失败，可以手动执行：

### 1. 下载脚本

```bash
wget https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/ct8_stealth_final.sh
chmod +x ct8_stealth_final.sh
```

### 2. 执行部署

```bash
./ct8_stealth_final.sh
```

### 3. 检查结果

```bash
# 检查服务状态
ps aux | grep 'pip cache'

# 检查端口监听
sockstat -l | grep 你的端口

# 查看配置信息
cat ~/.cache/pip/connection.txt
```

## 🔧 部署后验证

### 服务状态检查

```bash
# 1. 检查进程是否正在运行
ps aux | grep 'pip cache'
# 应该看到类似：serv 12345 python3 -m pip cache

# 2. 检查端口是否在监听
sockstat -l | grep 你的端口号
# 应该看到类似：serv python3.11 12345 3 tcp4 *:63533 *:*

# 3. 检查日志是否正常
tail -5 ~/.cache/pip/pip-*.log
# 应该看到pip-cache风格的日志
```

### 连接测试

在Telegram中配置代理后，应该能够：

- ✅ 成功连接到代理
- ✅ 正常发送和接收消息
- ✅ 访问Telegram频道和群组
- ✅ 发送图片和文件

## ⚠️ 常见问题

### 端口扫描失败

**现象**：显示"未找到可用端口"

**解决**：
```bash
# 检查当前端口使用情况
sockstat -l | grep -E ':(6[0-9]{4}|65[0-5][0-9]{2})'

# 手动测试几个端口
for port in 60001 61002 62003 63004 64005; do
    python3 -c "
import socket
try:
    s = socket.socket()
    s.bind(('0.0.0.0', $port))
    s.close()
    print('端口 $port: 可用')
    break
except:
    print('端口 $port: 被占用')
"
done
```

### 服务启动失败

**现象**：显示"隐蔽服务启动失败"

**解决**：
```bash
# 查看详细错误
tail -10 ~/.cache/pip/pip-*.log

# 手动运行查看错误
python3 ~/.cache/pip/pip-cache-*.py

# 检查权限
ls -la ~/.cache/pip/
```

### FreeBSD兼容性问题

**现象**：出现命令不识别或语法错误

**解决**：
- 确保使用最新的 `ct8_stealth_final.sh` 版本
- 该版本已完全兼容FreeBSD，无sed依赖
- 如有问题，重新下载最新脚本

## 🔄 重新部署

如需重新部署（比如更换端口或密码）：

```bash
# 1. 清理现有部署
pkill -f pip-cache 2>/dev/null || true
rm -rf ~/.cache/pip/pip-cache-*
rm -f ~/.cache/pip/pip-*.log

# 2. 重新执行部署
curl -sL https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/ct8_ultimate_stealth.sh | bash
```

## 📋 部署清单

部署完成后，你应该拥有以下文件：

```
~/.cache/pip/
├── pip-cache-随机ID.py      # 主要代理服务
├── pip-随机ID.log           # 服务日志
└── connection.txt           # 连接配置信息

~/.local/share/applications/
└── pip-maintenance.sh       # 保活脚本

/tmp/
└── .pip-cache-随机ID.pid    # 进程ID文件
```

定时任务：
```bash
# 查看是否已添加定时任务
crontab -l | grep pip-maintenance
# 应该看到：*/10 * * * * ~/.local/share/applications/pip-maintenance.sh
```

---

🎉 **部署完成！现在可以享受你的隐蔽代理服务了！**
