# 🚀 GitHub一键部署指南

本指南将教你如何将CT8 SOCKS5代理项目上传到GitHub并实现一键部署。

## 📋 准备工作

### 1. 创建GitHub账号
- 访问 [GitHub](https://github.com) 注册账号
- 验证邮箱地址

### 2. 安装Git（如果本地需要）
```bash
# Windows
# 下载Git安装包：https://git-scm.com/download/win

# Linux/CT8服务器
sudo apt update && sudo apt install git

# macOS
brew install git
```

## 🎯 部署步骤

### 第一步：创建GitHub仓库

1. **登录GitHub**，点击右上角的 "+" → "New repository"

2. **仓库设置**：
   - Repository name: `ct8-socks5-proxy`
   - Description: `CT8专用隐蔽SOCKS5代理 - Telegram专用`
   - 选择 `Public` （公开仓库，方便一键部署）
   - 勾选 `Add a README file`
   - License: 选择 `MIT License`

3. **点击 "Create repository"**

### 第二步：上传项目文件

**方法1：通过GitHub网页上传（推荐）**

1. 在新创建的仓库页面，点击 `uploading an existing file`

2. 将以下文件拖拽到上传区域：
   ```
   ct8_socks5.py
   ct8_deploy.sh
   ct8_manager.sh
   install.sh
   quick_deploy.sh
   README.md
   LICENSE
   .gitignore
   DEPLOY_GUIDE.md
   ```

3. 在底部填写提交信息：
   - Commit title: `Initial commit - CT8 SOCKS5 Proxy`
   - 点击 `Commit changes`

**方法2：使用Git命令行**

```bash
# 克隆仓库
git clone https://github.com/YOUR_USERNAME/ct8-socks5-proxy.git
cd ct8-socks5-proxy

# 复制项目文件到仓库目录
cp /path/to/your/files/* .

# 添加文件到Git
git add .

# 提交更改
git commit -m "Initial commit - CT8 SOCKS5 Proxy"

# 推送到GitHub
git push origin main
```

### 第三步：修改配置

1. **编辑 `quick_deploy.sh` 文件**，替换以下内容：
   ```bash
   # 将 YOUR_USERNAME 替换为你的GitHub用户名
   REPO_URL="https://github.com/YOUR_USERNAME/ct8-socks5-proxy"
   RAW_URL="https://raw.githubusercontent.com/YOUR_USERNAME/ct8-socks5-proxy/main"
   ```

2. **编辑 `install.sh` 文件**，找到并替换：
   ```bash
   # 第131行左右
   local github_repo="YOUR_USERNAME/ct8-socks5-proxy"
   ```

3. **编辑 `README.md` 文件**，替换所有的 `YOUR_USERNAME`

4. **提交修改**：
   ```bash
   git add .
   git commit -m "Update GitHub URLs"
   git push origin main
   ```

### 第四步：测试部署

1. **复制一键部署命令**：
   ```bash
   bash <(curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/ct8-socks5-proxy/main/quick_deploy.sh)
   ```

2. **在CT8服务器上测试**：
   ```bash
   # SSH连接到CT8服务器
   ssh your_username@your_ct8_domain.ct8.pl
   
   # 运行一键部署命令
   bash <(curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/ct8-socks5-proxy/main/quick_deploy.sh)
   ```

## 🎉 完成！

现在你的项目已经支持GitHub一键部署了！

### 使用方法

**用户只需要在CT8服务器上运行一条命令：**
```bash
bash <(curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/ct8-socks5-proxy/main/quick_deploy.sh)
```

### 分享给其他人

你可以将以下信息分享给需要的人：

```
🚀 CT8专用Telegram代理一键部署

特点：
✅ 隐蔽安全，伪装为系统服务
✅ 自动保活，24小时稳定运行
✅ 专为Telegram优化
✅ 一条命令搞定部署

使用方法：
1. SSH连接到CT8服务器
2. 运行以下命令：

bash <(curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/ct8-socks5-proxy/main/quick_deploy.sh)

项目地址：https://github.com/YOUR_USERNAME/ct8-socks5-proxy
```

## 🔧 高级功能

### 自动更新

当你更新项目代码后，用户重新运行一键部署命令即可自动更新到最新版本。

### 版本管理

1. **创建新版本**：
   ```bash
   git tag -a v1.0.1 -m "Version 1.0.1 - Bug fixes"
   git push origin v1.0.1
   ```

2. **发布Release**：
   - 在GitHub仓库页面点击 "Releases"
   - 点击 "Create a new release"
   - 填写版本信息和更新日志

### 监控统计

在GitHub仓库页面可以看到：
- ⭐ Star数量（用户喜欢程度）
- 👁️ Watch数量（关注用户）
- 🍴 Fork数量（被复制次数）
- 📊 访问统计

## ⚠️ 注意事项

1. **仓库必须是Public**才能支持一键部署
2. **及时更新README**，包含最新的使用说明
3. **回复用户Issues**，提供技术支持
4. **定期更新代码**，修复bugs和添加新功能
5. **遵守GitHub服务条款**，不上传违禁内容

## 📞 支持

如果遇到问题：
1. 查看项目README
2. 搜索已有Issues
3. 提交新Issue描述问题
4. 等待社区帮助

---

🎉 **恭喜！你已经学会了如何将项目部署到GitHub并实现一键安装！**
