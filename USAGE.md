# 📋 CT8 SOCKS5代理使用指南

## 🚀 快速开始

### 一键部署
```bash
curl -sL https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/ct8_socks5_final.sh | bash
```

### 预期输出
```
╔══════════════════════════════════════════════════════════╗
║                  🎉 部署成功！                          ║
╚══════════════════════════════════════════════════════════╝

📱 Telegram代理连接信息
服务器: 你的IP地址
端口: 生成的端口
密码: 生成的密码
```

## 📱 Telegram配置

### 设置步骤
1. 打开Telegram
2. **设置** → **高级** → **连接代理**
3. **添加代理** → **SOCKS5**
4. 输入部署输出的信息：
   - 服务器：你的CT8服务器IP
   - 端口：生成的端口号
   - 用户名：任意（如：user）
   - 密码：部署时显示的密码
5. **保存**并**启用**

### 连接验证
- 成功后Telegram会显示"通过代理连接"
- 消息发送速度会有明显改善

## 🛠️ 日常管理

### 常用命令
```bash
# 查看代理状态
sockstat -l | grep [你的端口]

# 查看连接日志
tail -f /tmp/.ct8_proxy.log

# 查看配置信息
cat ~/ct8_proxy_config.txt

# 重启代理服务
pkill -f ct8_socks5_proxy && nohup python3 ~/ct8_socks5_proxy.py &
```

### 状态检查
```bash
# 检查进程是否运行
ps aux | grep ct8_socks5_proxy

# 检查端口监听
sockstat -l | grep [端口号]

# 查看最近日志
tail -10 /tmp/.ct8_proxy.log
```

## 🔧 故障排除

### 1. 代理无法连接
```bash
# 检查服务是否运行
ps aux | grep ct8_socks5_proxy

# 如果没有运行，手动启动
python3 ~/ct8_socks5_proxy.py
```

### 2. 端口被占用
```bash
# 查看端口占用
sockstat -l | grep [端口号]

# 重新部署（会自动选择新端口）
curl -sL https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/ct8_socks5_final.sh | bash
```

### 3. 权限错误
- 确保使用60000以上的高端口
- 重新运行部署脚本会自动处理

### 4. Telegram连接失败
- 检查服务器IP是否正确
- 确认端口号和密码无误
- 验证代理类型选择为SOCKS5

## 📊 性能优化

### 监控连接
```bash
# 实时监控连接
tail -f /tmp/.ct8_proxy.log

# 查看当前连接数
netstat -an | grep [端口号] | wc -l
```

### 定期维护
```bash
# 每周重启代理（可选）
pkill -f ct8_socks5_proxy && nohup python3 ~/ct8_socks5_proxy.py &

# 清理旧日志（可选）
> /tmp/.ct8_proxy.log
```

## 🔒 安全建议

1. **定期更换密码**
   - 重新运行部署脚本会生成新密码
   
2. **监控日志**
   - 定期检查 `/tmp/.ct8_proxy.log`
   - 留意异常连接

3. **限制访问**
   - 只分享给信任的人
   - 不要在公共场所讨论

## 🆕 更新方法

重新运行部署命令即可更新：
```bash
curl -sL https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/ct8_socks5_final.sh | bash
```

## 📞 技术支持

如果遇到问题：
1. 查看本文档的故障排除部分
2. 检查项目GitHub页面的Issues
3. 提交新的Issue描述问题

---

**🎯 记住：此代理仅供个人合法使用，请遵守当地法律法规！**
