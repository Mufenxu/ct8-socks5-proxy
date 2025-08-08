# 使用指南

## 📋 快速开始

### 1. 一键部署

在CT8/Serv00服务器上执行：

```bash
curl -sL https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/ct8_stealth_final.sh | bash
```

### 2. 记录连接信息

部署成功后会显示：

```
🔒 最终隐蔽代理连接信息
服务器: your-server-ip
端口: 63533
密码: cache_220_0f6c
```

### 3. 配置Telegram

1. 打开Telegram → 设置 → 高级 → 连接代理
2. 添加代理 → SOCKS5
3. 填入连接信息：
   - 服务器：你的服务器IP
   - 端口：显示的端口号
   - 用户名：pip-user  
   - 密码：显示的密码

## 🔧 服务管理

### 查看服务状态

```bash
# 检查伪装进程
ps aux | grep 'pip cache'

# 检查端口监听
sockstat -l | grep 你的端口号
```

### 查看日志

```bash
# 实时查看日志
tail -f ~/.cache/pip/pip-*.log

# 查看最近日志
cat ~/.cache/pip/pip-*.log | tail -20
```

### 服务控制

```bash
# 手动重启（如果服务停止）
~/.local/share/applications/pip-maintenance.sh

# 停止服务
pkill -f "pip-cache-"

# 清理所有相关文件
rm -rf ~/.cache/pip/pip-cache-*
rm -f ~/.cache/pip/pip-*.log
```

### 查看连接配置

```bash
# 查看完整配置信息
cat ~/.cache/pip/connection.txt
```

## 🛠️ 故障排除

### 连接不上代理

1. **检查服务状态**：
   ```bash
   ps aux | grep 'pip cache'
   sockstat -l | grep 端口号
   ```

2. **查看错误日志**：
   ```bash
   tail -f ~/.cache/pip/pip-*.log
   ```

3. **手动重启服务**：
   ```bash
   ~/.local/share/applications/pip-maintenance.sh
   ```

### 服务无法启动

1. **检查端口占用**：
   ```bash
   sockstat -l | grep -E ':(6[0-9]{4}|65[0-5][0-9]{2})'
   ```

2. **测试端口可用性**：
   ```bash
   python3 -c "
   import socket
   s = socket.socket()
   s.bind(('0.0.0.0', 你的端口))
   s.close()
   print('端口可用')
   "
   ```

3. **重新部署**：
   ```bash
   # 清理旧部署
   pkill -f pip-cache 2>/dev/null || true
   rm -rf ~/.cache/pip/pip-cache-*
   
   # 重新部署
   curl -sL https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/ct8_stealth_final.sh | bash
   ```

### Telegram连接问题

1. **检查代理设置**：
   - 协议：SOCKS5
   - 用户名：pip-user
   - 密码：确保正确输入

2. **测试代理连接**：
   ```bash
   # 在本地测试代理（如果你有curl支持socks5）
   curl --socks5 你的服务器:端口 --proxy-user pip-user:密码 https://httpbin.org/ip
   ```

## 🔐 安全提示

### 定期检查

```bash
# 每周检查服务状态
ps aux | grep 'pip cache'

# 查看最近的连接日志
tail -20 ~/.cache/pip/pip-*.log
```

### 更新密码

如需更换密码，重新部署即可：

```bash
# 停止当前服务
pkill -f pip-cache

# 清理旧配置
rm -rf ~/.cache/pip/pip-cache-*

# 重新部署（会生成新密码）
curl -sL https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/ct8_stealth_final.sh | bash
```

### 隐蔽性检查

```bash
# 检查进程名是否正确伪装
ps aux | grep python3 | grep cache

# 检查文件是否在正确位置
ls -la ~/.cache/pip/

# 检查定时任务
crontab -l | grep pip-maintenance
```

## 📊 性能优化

### 连接优化

- Telegram连接超时：15秒
- 其他连接超时：30秒
- 缓冲区大小：4096字节
- 连接池：最大50个并发

### 资源使用

```bash
# 查看内存使用
ps aux | grep 'pip cache' | awk '{print $4, $11}'

# 查看进程数
ps aux | grep 'pip cache' | wc -l
```

## 🆘 紧急情况

### 完全清理

如果需要完全移除所有痕迹：

```bash
# 停止所有相关进程
pkill -f pip-cache 2>/dev/null || true
pkill -f ct8_socks5 2>/dev/null || true

# 删除所有文件
rm -rf ~/.cache/pip/pip-cache-*
rm -f ~/.cache/pip/pip-*.log
rm -f ~/.cache/pip/connection.txt
rm -f ~/.local/share/applications/pip-maintenance.sh
rm -f /tmp/.pip-cache-*

# 清理定时任务
crontab -l | grep -v pip-maintenance | crontab -

echo "✅ 所有痕迹已清理完毕"
```

---

💡 **提示**：保存好你的连接信息，重新部署后密码会改变！