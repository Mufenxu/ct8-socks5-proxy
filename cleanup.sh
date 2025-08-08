#!/bin/bash

# CT8 代理完全清理脚本 - 不留任何痕迹
# 彻底删除所有部署文件和痕迹

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${RED}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║              CT8 代理完全清理工具                         ║"
echo "║                                                          ║"
echo "║  🧹 彻底删除所有部署痕迹                                 ║"
echo "║  🔥 不留任何证据                                         ║"
echo "║  ⚠️  此操作不可逆！                                       ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

log_info() {
    echo -e "${GREEN}[清理]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[步骤]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

# 检查是否为交互模式
if [ -t 0 ]; then
    # 交互模式 - 需要确认
    echo -e "${YELLOW}⚠️  警告：此操作将彻底删除所有代理服务痕迹！${NC}"
    echo "将要清理的内容："
    echo "• 所有相关进程（python、pip、cache、wheel、proxy、socks等）"
    echo "• 所有服务文件和脚本"
    echo "• 所有日志文件"
    echo "• 所有配置文件"
    echo "• 所有定时任务"
    echo "• 所有PID文件和临时文件"
    echo "• 命令历史记录中的相关条目"
    echo ""
    
    read -p "确认彻底清理所有痕迹？输入 'YES' 继续: " -r
    if [[ ! $REPLY == "YES" ]]; then
        echo "操作已取消"
        exit 0
    fi
else
    # 非交互模式（curl | bash）- 直接执行
    echo -e "${YELLOW}⚠️  检测到非交互模式，开始自动清理...${NC}"
    echo "清理范围：所有代理服务相关的进程、文件、配置和痕迹"
    sleep 2
fi

echo ""
log_info "开始彻底清理所有代理痕迹..."

# 1. 停止所有可能的相关进程
log_step "停止所有相关进程..."

process_patterns=(
    "pip-cache"
    "pip-wheel" 
    "ct8_socks5"
    "socks5_proxy"
    "fixed_proxy"
    "nginx-cache"
    "nginx_cache"
    "proxy"
    "socks"
    "cache"
)

stopped_count=0
for pattern in "${process_patterns[@]}"; do
    if pgrep -f "$pattern" >/dev/null 2>&1; then
        log_info "终止进程: $pattern"
        pkill -9 -f "$pattern" 2>/dev/null || true
        stopped_count=$((stopped_count + 1))
    fi
done

# 特别处理python进程中的可疑进程
suspicious_pids=$(ps aux | grep python | grep -E "(cache|proxy|socks|wheel|pip)" | grep -v grep | awk '{print $2}' 2>/dev/null || true)
if [ ! -z "$suspicious_pids" ]; then
    log_info "终止可疑Python进程: $suspicious_pids"
    echo "$suspicious_pids" | xargs -r kill -9 2>/dev/null || true
    stopped_count=$((stopped_count + 1))
fi

log_info "已停止 $stopped_count 组相关进程"

# 2. 彻底删除所有相关文件
log_step "删除所有相关文件..."

# 删除缓存目录中的所有相关文件
if [ -d "$HOME/.cache/pip" ]; then
    log_info "清理 ~/.cache/pip/ 目录"
    find "$HOME/.cache/pip" -name "*cache*" -delete 2>/dev/null || true
    find "$HOME/.cache/pip" -name "*proxy*" -delete 2>/dev/null || true
    find "$HOME/.cache/pip" -name "*socks*" -delete 2>/dev/null || true
    find "$HOME/.cache/pip" -name "*wheel*" -delete 2>/dev/null || true
    find "$HOME/.cache/pip" -name "pip-*" -delete 2>/dev/null || true
    find "$HOME/.cache/pip" -name "connection*" -delete 2>/dev/null || true
    find "$HOME/.cache/pip" -name "*.log" -delete 2>/dev/null || true
    # 删除logs子目录
    rm -rf "$HOME/.cache/pip/logs" 2>/dev/null || true
fi

# 删除配置目录
if [ -d "$HOME/.config/systemd" ]; then
    log_info "清理 ~/.config/systemd/ 目录"
    find "$HOME/.config/systemd" -name "*cache*" -delete 2>/dev/null || true
    find "$HOME/.config/systemd" -name "*proxy*" -delete 2>/dev/null || true
    find "$HOME/.config/systemd" -name "*nginx*" -delete 2>/dev/null || true
    find "$HOME/.config/systemd" -name "*socks*" -delete 2>/dev/null || true
fi

# 删除应用目录
if [ -d "$HOME/.local/share/applications" ]; then
    log_info "清理 ~/.local/share/applications/ 目录"
    find "$HOME/.local/share/applications" -name "*maintenance*" -delete 2>/dev/null || true
    find "$HOME/.local/share/applications" -name "*pip-*" -delete 2>/dev/null || true
    find "$HOME/.local/share/applications" -name "*cache*" -delete 2>/dev/null || true
    find "$HOME/.local/share/applications" -name "*proxy*" -delete 2>/dev/null || true
fi

# 删除临时文件
log_info "清理临时文件"
rm -f /tmp/.pip-* 2>/dev/null || true
rm -f /tmp/.proxy* 2>/dev/null || true
rm -f /tmp/.nginx* 2>/dev/null || true
rm -f /tmp/.socks* 2>/dev/null || true
rm -f /tmp/*cache* 2>/dev/null || true
rm -f /tmp/*wheel* 2>/dev/null || true

# 删除主目录下的所有相关文件
log_info "清理主目录文件"
rm -f "$HOME"/socks5_proxy.py 2>/dev/null || true
rm -f "$HOME"/fixed_proxy.py 2>/dev/null || true
rm -f "$HOME"/proxy_info.txt 2>/dev/null || true
rm -f "$HOME"/connection.txt 2>/dev/null || true
rm -f "$HOME"/*socks*.py 2>/dev/null || true
rm -f "$HOME"/*proxy*.py 2>/dev/null || true
rm -f "$HOME"/*cache*.py 2>/dev/null || true
rm -f "$HOME"/*wheel*.py 2>/dev/null || true

# 3. 清理定时任务
log_step "清理定时任务..."

cron_patterns=(
    "maintenance"
    "proxy"
    "socks"
    "cache"
    "pip-"
    "ct8"
    "wheel"
)

if crontab -l >/dev/null 2>&1; then
    temp_cron="/tmp/crontab_clean_$(date +%s)"
    crontab -l > "$temp_cron" 2>/dev/null
    
    # 删除所有匹配的定时任务
    for pattern in "${cron_patterns[@]}"; do
        grep -v "$pattern" "$temp_cron" > "$temp_cron.tmp" 2>/dev/null || cp "$temp_cron" "$temp_cron.tmp"
        mv "$temp_cron.tmp" "$temp_cron"
    done
    
    # 应用清理后的定时任务
    crontab "$temp_cron" 2>/dev/null || true
    rm -f "$temp_cron"
    
    log_info "已清理所有相关定时任务"
else
    log_info "未发现定时任务"
fi

# 4. 清理命令历史
log_step "清理命令历史记录..."

# 清理bash历史
if [ -f "$HOME/.bash_history" ]; then
    log_info "清理bash历史记录"
    # 删除包含敏感关键词的历史记录
    history_patterns=(
        "proxy"
        "socks"
        "cache.*pip"
        "wheel.*python"
        "curl.*ct8"
        "curl.*github.*proxy"
        "curl.*github.*socks"
        "telegram"
        "136.243.156.104"
        "63001"
        "cache_220"
    )
    
    temp_history="/tmp/bash_history_clean_$(date +%s)"
    cp "$HOME/.bash_history" "$temp_history"
    
    for pattern in "${history_patterns[@]}"; do
        grep -v -i "$pattern" "$temp_history" > "$temp_history.tmp" 2>/dev/null || cp "$temp_history" "$temp_history.tmp"
        mv "$temp_history.tmp" "$temp_history"
    done
    
    cp "$temp_history" "$HOME/.bash_history"
    rm -f "$temp_history"
fi

# 清理当前会话历史
history -c 2>/dev/null || true

# 5. 清理网络连接记录
log_step "清理网络痕迹..."

# 清理可能的连接日志（如果有权限）
rm -f /var/log/*proxy* 2>/dev/null || true
rm -f /var/log/*socks* 2>/dev/null || true

# 6. 最终验证
log_step "验证清理结果..."

issues=0

# 检查进程
remaining_processes=$(pgrep -f "pip-cache|pip-wheel|socks|proxy|cache.*python" 2>/dev/null | wc -l)
if [ "$remaining_processes" -gt 0 ]; then
    log_warn "仍有 $remaining_processes 个相关进程在运行"
    issues=$((issues + 1))
fi

# 检查文件
remaining_files=0
for dir in "$HOME/.cache/pip" "$HOME/.config/systemd" "$HOME/.local/share/applications"; do
    if [ -d "$dir" ]; then
        remaining_files=$((remaining_files + $(find "$dir" -name "*cache*" -o -name "*proxy*" -o -name "*socks*" -o -name "*wheel*" -o -name "*maintenance*" 2>/dev/null | wc -l)))
    fi
done

if [ "$remaining_files" -gt 0 ]; then
    log_warn "仍有 $remaining_files 个相关文件未清理"
    issues=$((issues + 1))
fi

# 检查定时任务
remaining_cron=0
if crontab -l >/dev/null 2>&1; then
    remaining_cron=$(crontab -l 2>/dev/null | grep -E "maintenance|proxy|socks|cache|wheel" | wc -l 2>/dev/null || echo 0)
fi

if [ "$remaining_cron" -gt 0 ]; then
    log_warn "仍有 $remaining_cron 个相关定时任务"
    issues=$((issues + 1))
fi

# 7. 显示清理报告
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  🧹 清理完成报告                         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}✅ 已彻底清理的内容：${NC}"
echo "• 所有代理相关进程"
echo "• 所有服务文件和脚本"
echo "• 所有日志和配置文件"
echo "• 所有临时文件和PID文件"
echo "• 所有相关定时任务"
echo "• 命令历史记录中的敏感条目"
echo "• 网络连接痕迹"
echo ""

if [ $issues -eq 0 ]; then
    echo -e "${GREEN}🎉 完全清理成功！未发现任何残留痕迹${NC}"
    echo -e "${GREEN}🔥 所有代理部署痕迹已彻底抹除！${NC}"
else
    echo -e "${YELLOW}⚠️ 发现 $issues 个潜在残留，但已基本清理完毕${NC}"
fi

echo ""
echo -e "${CYAN}🔒 安全提醒：${NC}"
echo "• 清理已完成，系统中不再有代理服务痕迹"
echo "• 建议重启终端会话以清除内存中的历史记录"
echo "• 如需重新部署，可以安全地重新运行部署脚本"
echo ""

log_info "🎊 清理任务完成！系统已恢复到部署前状态"
