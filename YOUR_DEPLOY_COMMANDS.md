# 🎯 Mufenxu 的CT8代理部署命令

## 📋 你的专属部署信息

### **GitHub仓库地址**
```
https://github.com/Mufenxu/ct8-socks5-proxy
```

### **一键部署命令**
```bash
bash <(curl -sL https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/quick_deploy.sh)
```

## 🚀 **立即行动清单**

### ✅ **第一步：创建GitHub仓库**
1. 访问 [GitHub.com](https://github.com) 并登录
2. 点击右上角 "+" → "New repository"
3. 仓库设置：
   - **Repository name**: `ct8-socks5-proxy`
   - **Description**: `CT8专用隐蔽SOCKS5代理 - Telegram专用，安全隐蔽，一键部署`
   - **Visibility**: `Public` ⚠️ **必须选择Public**
   - **Initialize**: 勾选 `Add a README file`
   - **License**: 选择 `MIT License`
4. 点击 **"Create repository"**

### ✅ **第二步：上传文件**
在新仓库页面，点击 "uploading an existing file"，上传以下文件：

**核心文件（必须上传）：**
```
ct8_socks5.py       ← 核心代理服务器
install.sh          ← 安装脚本  
quick_deploy.sh     ← 一键部署脚本
README.md           ← 项目说明
LICENSE             ← 开源协议
.gitignore          ← Git配置
```

**增强文件（推荐上传）：**
```
ct8_manager.sh      ← 管理工具
ct8_deploy.sh       ← 完整部署脚本
DEPLOY_GUIDE.md     ← 部署指南
FILES_LIST.md       ← 文件清单
```

### ✅ **第三步：测试部署**
上传完成后，在任意CT8服务器上测试：
```bash
bash <(curl -sL https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/quick_deploy.sh)
```

## 📱 **分享给用户的命令**

当你完成GitHub部署后，可以将这个命令分享给需要的人：

```markdown
🚀 **CT8专用Telegram代理一键部署**

特点：
✅ 隐蔽安全，伪装为nginx缓存服务
✅ 自动保活，24小时稳定运行  
✅ 专为Telegram优化，连接稳定
✅ 一条命令搞定，无需技术基础

**使用方法：**
1. SSH连接到你的CT8/Serv00服务器
2. 复制粘贴下面命令并回车：

bash <(curl -sL https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/quick_deploy.sh)

3. 等待安装完成，获取连接信息
4. 在Telegram中设置SOCKS5代理即可

项目地址：https://github.com/Mufenxu/ct8-socks5-proxy
```

## 🛠️ **管理命令**

部署完成后的管理命令：
```bash
# 查看服务状态
~/ct8_manager

# 查看连接信息  
cat ~/ct8_proxy_info.txt

# 重启服务
pkill -f nginx-cache && ~/.config/systemd/keepalive.sh

# 查看日志
tail -f /tmp/.nginx_cache.log
```

## 🔄 **更新部署**

当你更新代码后，用户重新运行一键部署命令即可自动更新：
```bash
bash <(curl -sL https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/quick_deploy.sh)
```

## 🎉 **完成！**

所有配置已经为你的GitHub用户名 `Mufenxu` 定制完成！

现在你可以：
1. 将文件上传到GitHub
2. 测试一键部署命令
3. 分享给需要的用户

---

**项目地址**: https://github.com/Mufenxu/ct8-socks5-proxy  
**一键部署**: `bash <(curl -sL https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/quick_deploy.sh)`
