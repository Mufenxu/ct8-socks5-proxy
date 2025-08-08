# 🐧 FreeBSD系统支持说明

## 🎯 **CT8/Serv00 FreeBSD兼容性**

CT8和Serv00服务器使用的是 **FreeBSD 14.1** 系统，我们的脚本已经完全适配！

## ✅ **已支持的FreeBSD特性**

### **系统检测**
- 自动识别FreeBSD系统
- 兼容FreeBSD和Linux双系统

### **包管理器适配**
```bash
# FreeBSD系统使用pkg包管理器
pkg install python3    # 安装Python3
pkg install curl       # 安装curl
```

### **路径兼容**
- 支持FreeBSD的用户目录结构
- 兼容FreeBSD的进程管理
- 适配FreeBSD的网络工具

## 🚀 **在CT8/Serv00上部署**

### **一键部署命令**
```bash
bash <(curl -sL https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/quick_deploy.sh)
```

### **预期输出**
```
╔══════════════════════════════════════════════════════════╗
║          CT8 SOCKS5代理 GitHub一键部署工具               ║
║                                                          ║
║  🚀 从GitHub自动下载并部署Telegram代理                   ║
║  🔒 隐蔽安全，专为CT8免费服务器优化                       ║
║  ⚡ 版本: 1.0.0                                      ║
╚══════════════════════════════════════════════════════════╝

[INFO] 开始GitHub一键部署...
[STEP] 检查网络连接...
[INFO] 网络连接正常
[STEP] 检查系统环境...
[INFO] 系统环境检查完成
[STEP] 创建工作目录...
[INFO] 工作目录: /home/serv/.ct8_proxy
[INFO] 配置目录: /home/serv/.config/systemd
[STEP] 从GitHub下载项目文件...
...
```

## 🔧 **FreeBSD特定优化**

### **进程管理**
```bash
# FreeBSD进程查看
ps aux | grep nginx-cache

# FreeBSD网络端口查看  
sockstat -l | grep 808
```

### **服务管理**
```bash
# 查看服务状态
~/ct8_manager

# 手动重启
pkill -f nginx-cache
~/.config/systemd/keepalive.sh
```

### **日志查看**
```bash
# 实时日志
tail -f /tmp/.nginx_cache.log

# 保活日志
tail -f /tmp/.nginx_maintenance.log
```

## 📊 **FreeBSD vs Linux 差异**

| 特性 | Linux | FreeBSD | 支持状态 |
|------|-------|---------|----------|
| 包管理器 | apt/yum | pkg | ✅ 已适配 |
| 进程管理 | systemd | rc.d | ✅ 使用通用方案 |
| 网络工具 | netstat | sockstat | ✅ 兼容处理 |
| 用户目录 | /home | /home | ✅ 无差异 |
| Python3 | python3 | python3 | ✅ 无差异 |

## 🛠️ **故障排除**

### **常见问题**

1. **Python3未安装**
   ```bash
   pkg install python3
   ```

2. **curl未安装**
   ```bash
   pkg install curl
   ```

3. **权限问题**
   ```bash
   chmod +x ~/.config/systemd/nginx_cache.py
   ```

4. **端口被占用**
   ```bash
   sockstat -l | grep 8080
   pkill -f nginx-cache
   ```

### **调试模式**
```bash
# 手动运行查看详细错误
python3 ~/.config/systemd/nginx_cache.py
```

## 📝 **更新日志**

### v1.0.1 - FreeBSD支持
- ✅ 添加FreeBSD系统检测
- ✅ 适配pkg包管理器
- ✅ 优化FreeBSD网络工具
- ✅ 完善错误提示信息

## 🎉 **兼容性确认**

✅ **CT8** - FreeBSD 14.1  
✅ **Serv00** - FreeBSD 14.1  
✅ **其他FreeBSD** - 版本12+  
✅ **Linux** - Ubuntu/Debian/CentOS  

---

**现在可以在CT8/Serv00上愉快地使用一键部署了！** 🚀
