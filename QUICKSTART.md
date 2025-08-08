# 快速开始

## 🚀 一键部署

```bash
curl -sL https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/ct8_socks5_proxy.sh | bash
```

## 📱 Telegram设置

1. **设置** → **高级** → **连接代理**
2. **添加代理** → **SOCKS5**
3. 填入部署后显示的连接信息：
   - 服务器：你的服务器IP
   - 端口：显示的端口号
   - 用户名：wheel-user
   - 密码：显示的密码

## 🔧 常用命令

```bash
# 查看服务状态
ps aux | grep 'pip wheel'

# 查看连接信息
cat ~/.cache/pip/connection-*.txt

# 查看日志
tail -f ~/.cache/pip/wheel-*.log
```

## 🛠️ 问题排除

如果连接失败：

1. **检查服务**：`ps aux | grep 'pip wheel'`
2. **检查端口**：`sockstat -l | grep 你的端口`
3. **重新部署**：重新运行部署命令

---

就是这么简单！🎉
