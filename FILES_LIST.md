# 📁 项目文件清单

## 核心文件

| 文件名 | 功能描述 | 必需 |
|--------|----------|------|
| `ct8_socks5.py` | 核心SOCKS5代理服务器 | ✅ |
| `install.sh` | 本地/GitHub安装脚本 | ✅ |
| `quick_deploy.sh` | GitHub一键部署脚本 | ✅ |
| `ct8_manager.sh` | 图形化管理工具 | ⭐ |
| `ct8_deploy.sh` | 完整部署脚本（含伪装） | ⭐ |

## 文档文件

| 文件名 | 功能描述 | 必需 |
|--------|----------|------|
| `README.md` | 项目主文档 | ✅ |
| `DEPLOY_GUIDE.md` | GitHub部署指南 | ✅ |
| `FILES_LIST.md` | 本文件清单 | ❌ |
| `LICENSE` | MIT开源协议 | ✅ |

## 配置文件

| 文件名 | 功能描述 | 必需 |
|--------|----------|------|
| `.gitignore` | Git忽略规则 | ✅ |

## 📋 上传到GitHub的文件

按优先级排序，必须上传的文件：

### 1. 核心必需文件（必须上传）
```
ct8_socks5.py
install.sh
quick_deploy.sh
README.md
LICENSE
.gitignore
```

### 2. 增强功能文件（推荐上传）
```
ct8_manager.sh
ct8_deploy.sh
DEPLOY_GUIDE.md
```

### 3. 可选文件
```
FILES_LIST.md
```

## 🔧 上传后必须修改的内容

### 1. `quick_deploy.sh` 文件
```bash
# 第12-13行，替换YOUR_USERNAME
REPO_URL="https://github.com/YOUR_USERNAME/ct8-socks5-proxy"
RAW_URL="https://raw.githubusercontent.com/YOUR_USERNAME/ct8-socks5-proxy/main"
```

### 2. `install.sh` 文件
```bash
# 第131行左右，替换YOUR_USERNAME
local github_repo="YOUR_USERNAME/ct8-socks5-proxy"
```

### 3. `README.md` 文件
```markdown
# 替换所有YOUR_USERNAME为你的GitHub用户名
[![GitHub stars](https://img.shields.io/github/stars/YOUR_USERNAME/ct8-socks5-proxy.svg)]
bash <(curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/ct8-socks5-proxy/main/quick_deploy.sh)
```

## 🎯 一键部署命令

上传完成后，用户使用的一键部署命令：
```bash
bash <(curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/ct8-socks5-proxy/main/quick_deploy.sh)
```

## 📦 文件大小统计

| 文件类型 | 数量 | 大小估算 |
|----------|------|----------|
| Python脚本 | 1 | ~12KB |
| Shell脚本 | 4 | ~45KB |
| 文档文件 | 3 | ~15KB |
| 配置文件 | 2 | ~2KB |
| **总计** | **10** | **~74KB** |

完全符合GitHub免费仓库的大小限制。

## ✅ 上传检查清单

- [ ] 创建GitHub仓库（Public）
- [ ] 上传所有核心文件
- [ ] 修改所有YOUR_USERNAME占位符
- [ ] 测试一键部署命令
- [ ] 更新README文档
- [ ] 创建第一个Release版本

## 🚀 部署流程

1. **上传文件** → GitHub仓库
2. **修改配置** → 替换用户名
3. **测试部署** → CT8服务器验证
4. **发布项目** → 分享给用户

---

所有文件准备就绪，可以开始GitHub部署！
