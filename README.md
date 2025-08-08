# CT8专用隐蔽SOCKS5代理

⭐ **专为CT8免费服务器设计的Telegram代理解决方案，注重隐蔽性和安全性。**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/YOUR_USERNAME/ct8-socks5-proxy.svg)](https://github.com/YOUR_USERNAME/ct8-socks5-proxy/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/YOUR_USERNAME/ct8-socks5-proxy.svg)](https://github.com/YOUR_USERNAME/ct8-socks5-proxy/issues)

## 🔒 安全特性

- **进程伪装**: 伪装为nginx缓存服务，避免检测
- **端口混淆**: 使用常见服务端口(8080/8443)
- **流量加密**: SOCKS5协议+密码认证
- **访问控制**: IP白名单+密码双重验证
- **自动保活**: 定时监控和重启机制
- **日志隐蔽**: 使用系统风格的日志格式

## 🚀 GitHub一键部署（推荐）

```bash
# CT8服务器上运行（一条命令搞定）
bash <(curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/ct8-socks5-proxy/main/quick_deploy.sh)
```

## 📦 手动部署

```bash
# 克隆项目
git clone https://github.com/YOUR_USERNAME/ct8-socks5-proxy.git
cd ct8-socks5-proxy

# 运行安装脚本
./install.sh
```

### 自定义配置部署

```bash
# 自定义端口和密码
PROXY_PORT=8443 PROXY_PASSWORD="my_secret_pass" ./ct8_deploy.sh
```

## 📱 Telegram配置

1. 打开Telegram设置
2. 进入 **高级** > **连接代理**
3. 添加代理 > **SOCKS5**
4. 输入以下信息：
   - **服务器**: 你的CT8域名或IP
   - **端口**: 8080 (或自定义端口)
   - **用户名**: 任意
   - **密码**: 部署时显示的密码

## 🛠️ 管理命令

### 查看服务状态
```bash
ps aux | grep nginx-cache
netstat -tuln | grep 8080
```

### 查看日志
```bash
tail -f /tmp/.nginx_cache.log
tail -f /tmp/.nginx_maintenance.log
```

### 重启服务
```bash
pkill -f nginx-cache
~/.config/systemd/keepalive.sh
```

### 停止服务
```bash
pkill -f nginx-cache
crontab -l | grep -v nginx-cache | crontab -
```

## 🔧 高级配置

### 修改配置参数

编辑 `~/.config/systemd/nginx_cache.py`:

```python
CACHE_CONFIG = {
    'cache_port': 8080,           # 监听端口
    'auth_token': 'your_password', # 认证密码
    'allowed_clients': [],         # IP白名单(空=允许所有)
    'max_cache_size': 50,         # 最大连接数
    'cache_timeout': 300,         # 连接超时(秒)
}
```

### 添加IP白名单

```python
'allowed_clients': ['1.2.3.4', '5.6.7.8'],  # 只允许指定IP
```

### 修改伪装名称

```python
'service_name': 'your-fake-name',  # 进程名称
```

## 🔍 故障排除

### 服务无法启动
1. 检查端口是否被占用: `netstat -tuln | grep 8080`
2. 查看错误日志: `tail /tmp/.nginx_cache.log`
3. 手动启动测试: `python3 ~/.config/systemd/nginx_cache.py`

### 连接失败
1. 确认防火墙设置
2. 检查CT8面板端口配置
3. 验证密码是否正确

### 频繁断连
1. 检查网络稳定性
2. 适当增加超时时间
3. 查看日志了解断连原因

## 📊 性能优化

### 针对Telegram优化
- 自动识别Telegram流量
- 优化连接超时设置
- 减少握手延迟

### 内存使用优化
- 限制同时连接数
- 定期清理无效连接
- 24小时自动重启

## ⚠️ 注意事项

1. **定期更新密码**: 建议每月更换认证密码
2. **监控日志**: 定期检查访问日志，发现异常及时处理
3. **备份配置**: 保存好配置文件，便于迁移
4. **遵守法规**: 仅用于合法用途，遵守当地法律法规

## 🛡️ 安全建议

- 使用强密码，包含字母数字特殊字符
- 定期更换端口和密码
- 设置IP白名单限制访问
- 监控异常连接和流量
- 不要在公共场所使用

## 📝 更新日志

### v1.0.0
- 初始版本发布
- 基础SOCKS5代理功能
- 进程伪装和自动保活
- Telegram优化

## 🤝 贡献

欢迎提交Issue和Pull Request来改进项目。

## 📄 许可证

MIT License - 仅供学习和个人使用

## ⚡ 免责声明

本项目仅供学习交流使用，使用者需遵守当地法律法规，作者不承担任何责任。
