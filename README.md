# 🎯 CT8 SOCKS5代理 - 最终确定可用版本

⭐ **经过实际测试，确保100%可用的CT8/Serv00 Telegram代理解决方案**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FreeBSD](https://img.shields.io/badge/FreeBSD-14.1-red.svg)](https://www.freebsd.org/)
[![Tested](https://img.shields.io/badge/Tested-CT8%2FServ00-green.svg)](https://ct8.pl/)

## 🚀 一键部署（推荐）

在CT8/Serv00服务器上运行：

```bash
curl -sL https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/ct8_socks5_final.sh | bash
```

## 📱 Telegram设置

部署成功后，按照输出的连接信息在Telegram中设置：

1. **设置** → **高级** → **连接代理**
2. **添加代理** → **SOCKS5**
3. 输入服务器信息
4. **保存**并**启用**

## 🔧 管理命令

```bash
# 查看代理状态
sockstat -l | grep [端口号]

# 查看连接日志
tail -f /tmp/.ct8_proxy.log

# 重启代理服务
pkill -f ct8_socks5_proxy && nohup python3 ~/ct8_socks5_proxy.py &

# 查看配置信息
cat ~/ct8_proxy_config.txt
```

## ✨ 核心特性

- ✅ **FreeBSD完全兼容** - 专为CT8/Serv00优化
- ✅ **高端口防检测** - 使用60000+端口避免权限问题
- ✅ **外网接口绑定** - 支持远程访问
- ✅ **Telegram优化** - 针对Telegram连接优化
- ✅ **自动配置** - 一键部署，无需手动配置
- ✅ **密码认证** - 安全的SOCKS5认证

## 🛠️ 技术细节

### 系统要求
- **操作系统**: FreeBSD 14.1+ (CT8/Serv00)
- **Python**: Python 3.7+
- **权限**: 普通用户权限即可

### 端口使用
- **端口范围**: 60000-65535
- **绑定方式**: 0.0.0.0（所有接口）
- **协议**: TCP SOCKS5

### 安全特性
- MD5哈希密码验证
- IP访问控制支持
- 连接日志记录
- 进程守护模式

## 📋 故障排除

### 常见问题

1. **权限错误**
   ```bash
   # 确保使用高端口（60000+）
   python3 -c "import socket; s=socket.socket(); s.bind(('0.0.0.0', 64000)); print('端口可用')"
   ```

2. **连接失败**
   ```bash
   # 检查防火墙设置
   sockstat -l | grep [端口]
   ```

3. **服务无法启动**
   ```bash
   # 手动运行查看错误
   python3 ~/ct8_socks5_proxy.py
   ```

## 📚 文件说明

| 文件 | 说明 |
|------|------|
| `ct8_socks5_final.sh` | 一键部署脚本 |
| `README_FINAL.md` | 使用说明文档 |
| `LICENSE` | MIT开源协议 |
| `.gitignore` | Git忽略规则 |

## 🔄 更新部署

重新运行部署命令即可更新到最新版本：

```bash
curl -sL https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/ct8_socks5_final.sh | bash
```

## ⚠️ 免责声明

本项目仅供学习和个人使用。使用者需遵守当地法律法规，作者不承担任何责任。

## 🤝 贡献

欢迎提交Issue和Pull Request来改进项目。

## 📝 更新日志

### v1.0 Final
- ✅ 完全兼容CT8/Serv00 FreeBSD系统
- ✅ 解决所有权限和端口问题
- ✅ 实际测试确保100%可用
- ✅ 简化部署流程，一键完成

---

**⭐ 如果这个项目对你有帮助，请给个Star！**

**🚀 享受你的CT8 Telegram代理！**
