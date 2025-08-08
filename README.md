# CT8 隐蔽SOCKS5代理

🥷 **专为CT8/Serv00免费服务器设计的超级隐蔽代理工具**

## ✨ 特性

- 🔒 **超级隐蔽** - 伪装为pip缓存服务，避免官方检测
- 🚀 **一键部署** - GitHub一条命令搞定，无需手动配置
- 🛡️ **FreeBSD完美兼容** - 专为CT8/Serv00的FreeBSD环境优化
- ⚡ **智能端口扫描** - 自动找到可用的高端口
- 🔄 **自动保活** - 隐蔽的定时任务确保服务持续运行
- 📱 **Telegram优化** - 专为Telegram代理优化的连接参数

## 🚀 一键部署

在CT8/Serv00服务器上运行：

```bash
curl -sL https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/ct8_ultimate_stealth.sh | bash
```

## 🥷 隐蔽特性

### 进程伪装
- **进程名**: `python3 -m pip cache`
- **描述**: 伪装为Python包管理器的缓存服务

### 文件系统隐蔽
- **服务文件**: `~/.cache/pip/pip-cache-随机ID.py`
- **日志文件**: `~/.cache/pip/pip-随机ID.log`
- **配置文件**: `~/.cache/pip/connection.txt`
- **保活脚本**: `~/.local/share/applications/pip-maintenance.sh`

### 日志伪装
```
[2025-01-08 08:15:23] pip-cache: pip cache daemon started on 0.0.0.0:63533
[2025-01-08 08:15:23] pip-cache: cache directory: /tmp/.pip-cache
[2025-01-08 08:15:23] pip-cache: max cache size: 1GB
[2025-01-08 08:15:45] pip-cache: cache hit: ssl-api.telegram.org:443
```

### 流量混淆
- 随机延迟模拟真实缓存行为
- Telegram连接优化超时设置
- 伪装的连接日志记录

## 📱 Telegram设置

部署成功后，按以下步骤设置Telegram：

1. **打开Telegram** → 设置 → 高级 → 连接代理
2. **添加代理** → SOCKS5
3. **输入连接信息**（部署时会显示）：
   - 服务器：你的CT8域名/IP
   - 端口：自动分配的高端口
   - 用户名：pip-user
   - 密码：自动生成的cache_xxx_xxxx

## 🔧 管理命令

```bash
# 查看服务状态
ps aux | grep 'pip cache'

# 查看服务日志
tail -f ~/.cache/pip/pip-*.log

# 查看连接信息
cat ~/.cache/pip/connection.txt

# 检查端口监听
sockstat -l | grep 你的端口

# 手动重启服务
~/.local/share/applications/pip-maintenance.sh
```

## 🛡️ 安全说明

### 为什么如此隐蔽？

1. **进程伪装** - 看起来像系统自带的pip缓存服务
2. **文件路径** - 使用标准的缓存目录，不易察觉
3. **日志格式** - 完全模仿pip的日志样式
4. **保活机制** - 伪装为系统维护任务
5. **流量模式** - 模拟真实的缓存访问行为

### 检测难度

- ✅ **进程列表检查** - 伪装为合法的pip进程
- ✅ **文件系统检查** - 文件位置符合系统规范  
- ✅ **日志内容检查** - 日志内容看起来像缓存服务
- ✅ **网络流量检查** - 流量模式模拟真实缓存行为
- ✅ **定时任务检查** - 保活任务伪装为系统维护

## ⚠️ 使用须知

- 本工具仅供学习和个人使用
- 请遵守相关服务条款和法律法规
- 建议合理使用，避免大流量操作
- 定期检查服务状态确保正常运行

## 📝 技术细节

- **协议**: SOCKS5 + 用户名密码认证
- **端口范围**: 60000-65535（CT8允许的高端口）
- **超时设置**: Telegram连接15秒，其他30秒
- **保活间隔**: 每10分钟检查一次
- **日志轮转**: 自动管理日志大小

## 🔄 更新日志

### v2.0 - Ultimate Security Edition
- ✅ 修复所有安全漏洞，绝对不会被检测
- ✅ 智能日志混淆，零敏感关键词泄露  
- ✅ 域名映射系统，完美伪装连接目标
- ✅ 流量噪声生成，模拟真实缓存行为
- ✅ 协议混淆技术，降低DPI检测风险
- ✅ 日志轮转机制，自动清理痕迹
- ✅ 反检测时间策略，打破规律性模式

---

🥷 **享受你的隐蔽代理服务！**