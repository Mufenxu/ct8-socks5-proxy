# 旧部署清理指南

## 🧹 完全清理旧部署

### 一键清理命令

在CT8/Serv00服务器上运行：

```bash
curl -sL https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/cleanup_old_deployments.sh | bash
```

### 手动清理命令

如果你更喜欢手动清理，可以逐步执行：

#### 1. 停止所有相关进程

```bash
# 停止所有可能的代理进程
pkill -f pip-cache 2>/dev/null || true
pkill -f pip-wheel 2>/dev/null || true  
pkill -f ct8_socks5 2>/dev/null || true
pkill -f socks5_proxy 2>/dev/null || true
pkill -f fixed_proxy 2>/dev/null || true
pkill -f nginx-cache 2>/dev/null || true

# 检查是否还有相关进程
ps aux | grep -E "(cache|proxy|socks)" | grep -v grep
```

#### 2. 删除所有相关文件

```bash
# 删除服务文件
rm -rf ~/.cache/pip/pip-cache-*
rm -rf ~/.cache/pip/pip-wheel-*
rm -f ~/.cache/pip/pip-*.log
rm -f ~/.cache/pip/connection.txt
rm -f ~/.cache/pip/wheel-connection.txt

# 删除配置文件
rm -rf ~/.config/systemd/nginx*
rm -rf ~/.config/systemd/pip*

# 删除保活脚本
rm -f ~/.local/share/applications/pip-maintenance.sh
rm -f ~/.local/share/applications/pip-wheel-maintenance.sh

# 删除临时文件
rm -f /tmp/.pip-*
rm -f /tmp/.proxy*
rm -f /tmp/.nginx*

# 删除主目录下的代理文件
rm -f ~/socks5_proxy.py
rm -f ~/fixed_proxy.py
rm -f ~/proxy_info.txt
rm -f ~/*proxy*.py
rm -f ~/*socks*.py
```

#### 3. 清理定时任务

```bash
# 查看当前定时任务
crontab -l

# 删除相关定时任务
crontab -l | grep -v maintenance | grep -v proxy | grep -v cache | crontab -

# 验证清理结果
crontab -l
```

#### 4. 检查清理结果

```bash
# 检查进程
ps aux | grep -E "(cache|proxy|socks)" | grep -v grep

# 检查端口
sockstat -l | grep -E ':(6[0-9]{4}|65[0-9]{3})'

# 检查文件
find ~/.cache ~/.config ~/.local -name "*cache*" -o -name "*proxy*" -o -name "*socks*" 2>/dev/null

# 检查定时任务
crontab -l | grep -E "(maintenance|proxy|cache)"
```

## 🔍 问题排查

### 如果进程杀不死

```bash
# 强制终止
sudo pkill -9 -f proxy 2>/dev/null || true
sudo pkill -9 -f socks 2>/dev/null || true
sudo pkill -9 -f cache 2>/dev/null || true

# 查找顽固进程
ps aux | grep python | grep -E "(cache|proxy|socks)"
```

### 如果文件删不掉

```bash
# 检查文件权限
ls -la ~/.cache/pip/
ls -la ~/.config/systemd/

# 强制删除
chmod -R 755 ~/.cache/pip/ 2>/dev/null || true
rm -rf ~/.cache/pip/pip-* 2>/dev/null || true

# 清空目录
find ~/.cache/pip/ -name "*" -type f -delete 2>/dev/null || true
```

### 如果定时任务清理失败

```bash
# 备份现有定时任务
crontab -l > ~/crontab_backup.txt

# 完全清空定时任务
crontab -r

# 恢复非代理相关的任务（如果有）
# 手动编辑 ~/crontab_backup.txt，删除代理相关行
# crontab ~/crontab_backup.txt
```

## ⚠️ 重要提醒

### 清理前确认

1. **保存重要数据** - 确保没有重要的个人文件会被误删
2. **记录配置** - 如果有其他重要的定时任务，请先备份
3. **检查进程** - 确认要删除的进程确实是代理服务

### 清理后验证

```bash
# 完整验证脚本
echo "=== 进程检查 ==="
ps aux | grep -E "(cache|proxy|socks)" | grep -v grep || echo "✅ 无相关进程"

echo -e "\n=== 文件检查 ==="
find ~/ -maxdepth 3 -name "*cache*" -o -name "*proxy*" -o -name "*socks*" 2>/dev/null || echo "✅ 无相关文件"

echo -e "\n=== 端口检查 ==="
sockstat -l | grep -E ':(6[0-9]{4}|65[0-9]{3})' || echo "✅ 无高端口监听"

echo -e "\n=== 定时任务检查 ==="
crontab -l | grep -E "(maintenance|proxy|cache)" || echo "✅ 无相关定时任务"

echo -e "\n🎉 清理验证完成！"
```

## 🚀 清理后部署新版本

清理完成后，立即部署终极安全版本：

```bash
curl -sL https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/ct8_ultimate_stealth.sh | bash
```

---

💡 **提示**：建议使用一键清理脚本，它会自动处理所有情况并提供详细的清理报告！
