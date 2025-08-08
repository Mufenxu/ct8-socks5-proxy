#!/bin/bash

# CT8 旧部署完全清理工具
# 删除所有可能的代理服务和痕迹

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║              CT8 旧部署完全清理工具                       ║"
echo "║                                                          ║"
echo "║  🧹 删除所有旧的代理服务和痕迹                           ║"
echo "║  🔒 为新的终极安全版本做准备                             ║"
echo "║  ⚠️  此操作不可逆，请确认后执行                           ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 确认清理操作
confirm_cleanup() {
    echo -e "${YELLOW}⚠️  警告：此操作将删除所有旧的代理服务！${NC}"
    echo ""
    echo "将要清理的内容："
    echo "• 所有相关进程"
    echo "• 服务文件和脚本"
    echo "• 日志文件"
    echo "• 配置文件"
    echo "• 定时任务"
    echo "• PID文件和临时文件"
    echo ""
    
    read -p "确认清理所有旧部署？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "操作已取消"
        exit 0
    fi
}

# 停止所有相关进程
stop_all_processes() {
    log_step "停止所有相关进程..."
    
    # 停止各种可能的进程名
    local process_patterns=(
        "pip-cache"
        "pip-wheel" 
        "ct8_socks5"
        "socks5_proxy"
        "fixed_proxy"
        "nginx-cache"
        "nginx_cache"
        "python.*socks"
        "python.*proxy"
    )
    
    local stopped=0
    
    for pattern in "${process_patterns[@]}"; do
        local pids=$(pgrep -f "$pattern" 2>/dev/null || true)
        if [ ! -z "$pids" ]; then
            echo "  终止进程: $pattern (PIDs: $pids)"
            pkill -f "$pattern" 2>/dev/null || true
            stopped=$((stopped + 1))
        fi
    done
    
    # 额外检查可疑的python进程
    local suspicious_pids=$(ps aux | grep python | grep -E "(cache|proxy|socks|wheel)" | grep -v grep | awk '{print $2}' || true)
    if [ ! -z "$suspicious_pids" ]; then
        echo "  终止可疑Python进程: $suspicious_pids"
        echo "$suspicious_pids" | xargs -r kill 2>/dev/null || true
        stopped=$((stopped + 1))
    fi
    
    if [ $stopped -eq 0 ]; then
        log_info "未发现运行中的代理进程"
    else
        log_info "已停止 $stopped 个相关进程"
        sleep 2  # 等待进程完全停止
    fi
}

# 清理文件和目录
cleanup_files() {
    log_step "清理所有相关文件..."
    
    local cleaned=0
    
    # 清理主要目录
    local dirs_to_clean=(
        "$HOME/.cache/pip"
        "$HOME/.config/systemd"
        "$HOME/.local/share/applications"
        "$HOME/proxy"
        "$HOME/socks5"
    )
    
    for dir in "${dirs_to_clean[@]}"; do
        if [ -d "$dir" ]; then
            # 清理代理相关文件，保留其他文件
            find "$dir" -name "*cache*" -type f -delete 2>/dev/null || true
            find "$dir" -name "*proxy*" -type f -delete 2>/dev/null || true
            find "$dir" -name "*socks*" -type f -delete 2>/dev/null || true
            find "$dir" -name "*wheel*" -type f -delete 2>/dev/null || true
            find "$dir" -name "pip-*" -type f -delete 2>/dev/null || true
            find "$dir" -name "ct8*" -type f -delete 2>/dev/null || true
            find "$dir" -name "*maintenance*" -type f -delete 2>/dev/null || true
            cleaned=$((cleaned + 1))
        fi
    done
    
    # 清理临时文件
    local temp_patterns=(
        "/tmp/.pip-*"
        "/tmp/.proxy*"
        "/tmp/.nginx*"
        "/tmp/.socks*"
        "/tmp/*cache*"
    )
    
    for pattern in "${temp_patterns[@]}"; do
        rm -f $pattern 2>/dev/null || true
    done
    
    # 清理主目录下的代理文件
    local home_files=(
        "$HOME/socks5_proxy.py"
        "$HOME/fixed_proxy.py" 
        "$HOME/proxy_info.txt"
        "$HOME/connection.txt"
        "$HOME/*socks*.py"
        "$HOME/*proxy*.py"
        "$HOME/*cache*.py"
    )
    
    for file_pattern in "${home_files[@]}"; do
        rm -f $file_pattern 2>/dev/null || true
    done
    
    log_info "已清理所有相关文件和目录"
}

# 清理定时任务
cleanup_crontab() {
    log_step "清理定时任务..."
    
    # 检查是否有相关的定时任务
    local cron_patterns=(
        "maintenance"
        "proxy"
        "socks"
        "cache"
        "pip-"
        "ct8"
    )
    
    local has_cron=false
    local temp_cron="/tmp/crontab_backup_$(date +%s)"
    
    # 备份当前定时任务
    crontab -l > "$temp_cron" 2>/dev/null || touch "$temp_cron"
    
    # 检查是否有相关任务
    for pattern in "${cron_patterns[@]}"; do
        if grep -q "$pattern" "$temp_cron" 2>/dev/null; then
            has_cron=true
            break
        fi
    done
    
    if [ "$has_cron" = true ]; then
        echo "  发现相关定时任务，正在清理..."
        
        # 创建清理后的定时任务
        local clean_cron="/tmp/crontab_clean_$(date +%s)"
        cp "$temp_cron" "$clean_cron"
        
        # 删除匹配的行
        for pattern in "${cron_patterns[@]}"; do
            grep -v "$pattern" "$clean_cron" > "$clean_cron.tmp" 2>/dev/null || true
            mv "$clean_cron.tmp" "$clean_cron" 2>/dev/null || true
        done
        
        # 应用清理后的定时任务
        crontab "$clean_cron" 2>/dev/null || true
        rm -f "$clean_cron"
        
        log_info "已清理相关定时任务"
    else
        log_info "未发现相关定时任务"
    fi
    
    rm -f "$temp_cron"
}

# 检查端口占用
check_ports() {
    log_step "检查端口占用..."
    
    local suspicious_ports=()
    
    # 检查常见的代理端口
    if command -v sockstat &> /dev/null; then
        # FreeBSD
        suspicious_ports=($(sockstat -l | grep -E ':(6[0-9]{4}|65[0-9]{3})' | awk '{print $6}' | cut -d: -f2 | sort -u))
    elif command -v netstat &> /dev/null; then
        # Linux
        suspicious_ports=($(netstat -tlnp | grep -E ':(6[0-9]{4}|65[0-9]{3})' | awk '{print $4}' | cut -d: -f2 | sort -u))
    fi
    
    if [ ${#suspicious_ports[@]} -gt 0 ]; then
        echo "  发现高端口监听: ${suspicious_ports[*]}"
        echo "  注意：这些可能是其他服务的端口，请手动检查"
        
        for port in "${suspicious_ports[@]}"; do
            if command -v sockstat &> /dev/null; then
                echo "    端口 $port: $(sockstat -l | grep ":$port " | head -1)"
            else
                echo "    端口 $port: $(netstat -tlnp | grep ":$port " | head -1)"
            fi
        done
    else
        log_info "未发现可疑端口占用"
    fi
}

# 验证清理结果
verify_cleanup() {
    log_step "验证清理结果..."
    
    local issues=0
    
    # 检查进程
    local remaining_processes=$(pgrep -f "pip-cache|pip-wheel|socks|proxy" 2>/dev/null | wc -l)
    if [ "$remaining_processes" -gt 0 ]; then
        log_warn "仍有 $remaining_processes 个相关进程在运行"
        issues=$((issues + 1))
    fi
    
    # 检查主要文件
    local remaining_files=0
    if [ -d "$HOME/.cache/pip" ]; then
        remaining_files=$(find "$HOME/.cache/pip" -name "*cache*" -o -name "*proxy*" -o -name "*socks*" | wc -l)
    fi
    
    if [ "$remaining_files" -gt 0 ]; then
        log_warn "仍有 $remaining_files 个相关文件未清理"
        issues=$((issues + 1))
    fi
    
    # 检查定时任务
    local remaining_cron=$(crontab -l 2>/dev/null | grep -E "maintenance|proxy|socks|cache" | wc -l)
    if [ "$remaining_cron" -gt 0 ]; then
        log_warn "仍有 $remaining_cron 个相关定时任务"
        issues=$((issues + 1))
    fi
    
    if [ $issues -eq 0 ]; then
        log_info "✅ 清理完成，未发现残留"
    else
        log_warn "⚠️ 发现 $issues 个潜在问题，可能需要手动处理"
    fi
}

# 显示清理报告
show_cleanup_report() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  🧹 清理完成报告                         ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}已清理的内容：${NC}"
    echo "• ✅ 所有代理相关进程"
    echo "• ✅ 服务文件和脚本"
    echo "• ✅ 日志和配置文件"
    echo "• ✅ 临时文件和PID文件"
    echo "• ✅ 相关定时任务"
    echo ""
    
    echo -e "${YELLOW}建议操作：${NC}"
    echo "• 🔄 重启系统以确保完全清理（可选）"
    echo "• 🚀 部署新的终极安全版本："
    echo "  curl -sL https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/ct8_ultimate_stealth.sh | bash"
    echo ""
    
    echo -e "${GREEN}🎉 旧部署已完全清理，可以安全部署新版本！${NC}"
}

# 主函数
main() {
    confirm_cleanup
    echo ""
    log_info "开始清理旧部署..."
    echo ""
    
    stop_all_processes
    cleanup_files
    cleanup_crontab
    check_ports
    verify_cleanup
    show_cleanup_report
}

# 执行主函数
main "$@"
