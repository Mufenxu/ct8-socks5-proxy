#!/bin/bash

# CT8 SOCKS5代理一键安装脚本
# 适配CT8免费服务器环境

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 全局变量
SCRIPT_VERSION="1.0.0"
WORK_DIR="$HOME/.config/systemd"
GITHUB_REPO="your-repo/ct8-socks5"  # 替换为实际仓库
BASE_URL="https://raw.githubusercontent.com/$GITHUB_REPO/main"

# 显示横幅
show_banner() {
    clear
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║               CT8 SOCKS5 代理安装工具                    ║"
    echo "║                                                          ║"
    echo "║  专为CT8免费服务器设计的隐蔽Telegram代理                  ║"
    echo "║  版本: $SCRIPT_VERSION                                      ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# 检查系统环境
check_system() {
    log_step "检查系统环境..."
    
    # 检查操作系统
    if [[ ! "$OSTYPE" =~ ^(linux|freebsd) ]]; then
        log_error "不支持的操作系统: $OSTYPE"
        log_error "此脚本支持Linux和FreeBSD系统（如CT8/Serv00服务器）"
        exit 1
    fi
    
    # 检查Python3
    if ! command -v python3 &> /dev/null; then
        log_error "Python3未安装，请先安装Python3"
        exit 1
    fi
    
    # 检查网络连接
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        log_warn "网络连接可能存在问题"
    fi
    
    # 检查磁盘空间
    local disk_free=$(df "$HOME" | awk 'NR==2 {print $4}')
    if [ "$disk_free" -lt 10240 ]; then  # 小于10MB
        log_warn "磁盘空间不足"
    fi
    
    log_info "系统环境检查完成"
}

# 安装依赖
install_dependencies() {
    log_step "安装必要组件..."
    
    # 创建工作目录
    mkdir -p "$WORK_DIR"
    
    # 检查并安装setproctitle（可选）
    if python3 -c "import setproctitle" 2>/dev/null; then
        log_info "setproctitle已安装"
    else
        log_warn "setproctitle未安装，进程隐藏功能将受限"
        
        # 尝试用pip安装
        if command -v pip3 &> /dev/null; then
            log_info "尝试安装setproctitle..."
            pip3 install --user setproctitle 2>/dev/null || log_warn "setproctitle安装失败，将跳过"
        fi
    fi
    
    log_info "依赖安装完成"
}

# 准备脚本文件
prepare_scripts() {
    log_step "准备代理脚本..."
    
    # 检查当前目录是否有脚本文件（本地安装）
    if [ -f "ct8_socks5.py" ] && [ -f "ct8_manager.sh" ]; then
        log_info "检测到本地文件，使用本地安装模式..."
        
        # 复制文件到工作目录
        cp ct8_socks5.py "$WORK_DIR/nginx_cache.py"
        chmod +x "$WORK_DIR/nginx_cache.py"
        
        if [ -f "ct8_manager.sh" ]; then
            cp ct8_manager.sh "$HOME/ct8_manager"
            chmod +x "$HOME/ct8_manager"
        fi
        
        log_info "本地脚本安装完成"
        return 0
    fi
    
    # GitHub模式：从网络下载
    log_info "本地文件未找到，将从GitHub下载..."
    
    # GitHub仓库配置
    local github_repo="Mufenxu/ct8-socks5-proxy"
    local raw_url="https://raw.githubusercontent.com/$github_repo/main"
    
    # 检查网络连接
    if ! curl -s --connect-timeout 5 "$raw_url/README.md" > /dev/null; then
        log_error "无法连接到GitHub，请检查网络或使用本地安装"
        exit 1
    fi
    
    # 下载必要文件
    log_info "从GitHub下载文件..."
    
    if curl -sL "$raw_url/ct8_socks5.py" -o "$WORK_DIR/nginx_cache.py"; then
        chmod +x "$WORK_DIR/nginx_cache.py"
        log_info "✓ 代理脚本下载完成"
    else
        log_error "✗ 代理脚本下载失败"
        exit 1
    fi
    
    if curl -sL "$raw_url/ct8_manager.sh" -o "$HOME/ct8_manager"; then
        chmod +x "$HOME/ct8_manager"
        log_info "✓ 管理工具下载完成"
    else
        log_warn "管理工具下载失败，将跳过"
    fi
    
    log_info "GitHub文件下载完成"
}

# 配置参数
configure_proxy() {
    log_step "配置代理参数..."
    
    # 生成随机端口
    local random_port=$((8000 + RANDOM % 1000))
    while netstat -tuln 2>/dev/null | grep -q ":$random_port "; do
        random_port=$((8000 + RANDOM % 1000))
    done
    
    # 生成随机密码
    local random_password="tg_$(date +%m%d)_$(openssl rand -hex 4 2>/dev/null || echo $(date +%s | tail -c 5))"
    
    # 更新配置
    if [ -f "$WORK_DIR/nginx_cache.py" ]; then
        sed -i "s/PROXY_PORT_PLACEHOLDER/$random_port/g" "$WORK_DIR/nginx_cache.py"
        sed -i "s/PROXY_PASSWORD_PLACEHOLDER/$random_password/g" "$WORK_DIR/nginx_cache.py"
        
        log_info "代理端口: $random_port"
        log_info "认证密码: $random_password"
        
        # 保存配置信息
        cat > "$WORK_DIR/config.txt" << EOF
CT8 SOCKS5代理配置信息
========================
安装时间: $(date)
代理端口: $random_port
认证密码: $random_password
配置文件: $WORK_DIR/nginx_cache.py
管理工具: $HOME/ct8_manager
========================
EOF
        
    else
        log_error "配置文件不存在"
        exit 1
    fi
}

# 创建保活脚本
create_keepalive() {
    log_step "创建保活机制..."
    
    cat > "$WORK_DIR/keepalive.sh" << 'KEEPALIVE_EOF'
#!/bin/bash

# CT8 SOCKS5 保活脚本
SCRIPT_PATH="$HOME/.config/systemd/nginx_cache.py"
LOCK_FILE="/tmp/.nginx_cache.lock"
LOG_FILE="/tmp/.nginx_maintenance.log"

check_and_restart() {
    if [ -f "$LOCK_FILE" ]; then
        local pid=$(cat "$LOCK_FILE")
        if ! ps -p "$pid" > /dev/null 2>&1; then
            echo "[$(date)] 服务异常停止，正在重启..." >> "$LOG_FILE"
            rm -f "$LOCK_FILE"
            nohup python3 "$SCRIPT_PATH" > /dev/null 2>&1 &
            echo $! > "$LOCK_FILE"
        fi
    else
        echo "[$(date)] 服务未运行，正在启动..." >> "$LOG_FILE"
        nohup python3 "$SCRIPT_PATH" > /dev/null 2>&1 &
        echo $! > "$LOCK_FILE"
    fi
}

check_and_restart
KEEPALIVE_EOF

    chmod +x "$WORK_DIR/keepalive.sh"
    
    # 添加到crontab
    if ! crontab -l 2>/dev/null | grep -q "keepalive.sh"; then
        (crontab -l 2>/dev/null; echo "*/5 * * * * $WORK_DIR/keepalive.sh >/dev/null 2>&1") | crontab -
        log_info "保活机制已设置（每5分钟检查一次）"
    else
        log_warn "保活任务已存在"
    fi
}

# 启动服务
start_service() {
    log_step "启动代理服务..."
    
    # 停止可能存在的旧进程
    pkill -f "nginx-cache" 2>/dev/null || true
    sleep 2
    
    # 启动新服务
    nohup python3 "$WORK_DIR/nginx_cache.py" > /dev/null 2>&1 &
    local pid=$!
    echo "$pid" > "/tmp/.nginx_cache.lock"
    
    sleep 3
    if ps -p "$pid" > /dev/null 2>&1; then
        log_info "服务启动成功 (PID: $pid)"
        return 0
    else
        log_error "服务启动失败"
        return 1
    fi
}

# 显示安装结果
show_result() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                     安装完成！                          ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # 读取配置
    if [ -f "$WORK_DIR/config.txt" ]; then
        local port=$(grep "代理端口:" "$WORK_DIR/config.txt" | cut -d' ' -f2)
        local password=$(grep "认证密码:" "$WORK_DIR/config.txt" | cut -d' ' -f2)
        local server_ip=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "你的CT8域名")
        
        echo -e "${CYAN}=== 连接信息 ===${NC}"
        echo -e "${GREEN}服务器地址:${NC} $server_ip"
        echo -e "${GREEN}SOCKS5端口:${NC} $port"
        echo -e "${GREEN}用户名:${NC} 任意"
        echo -e "${GREEN}密码:${NC} $password"
        echo ""
        
        echo -e "${CYAN}=== Telegram设置 ===${NC}"
        echo "1. 打开Telegram → 设置 → 高级 → 连接代理"
        echo "2. 添加代理 → SOCKS5"
        echo "3. 输入上述服务器信息"
        echo ""
        
        echo -e "${CYAN}=== 管理命令 ===${NC}"
        echo -e "${GREEN}管理工具:${NC} ~/ct8_manager"
        echo -e "${GREEN}查看状态:${NC} ps aux | grep nginx-cache"
        echo -e "${GREEN}查看日志:${NC} tail -f /tmp/.nginx_cache.log"
        echo -e "${GREEN}重启服务:${NC} $WORK_DIR/keepalive.sh"
        echo ""
        
        echo -e "${YELLOW}注意事项:${NC}"
        echo "• 服务会自动保活，每5分钟检查一次"
        echo "• 建议定期更换密码提高安全性"
        echo "• 仅用于合法用途，遵守当地法律法规"
        echo ""
        
        # 保存连接信息到文件
        cat > "$HOME/ct8_proxy_info.txt" << EOF
CT8 SOCKS5代理连接信息
====================
服务器: $server_ip
端口: $port
用户名: 任意
密码: $password

安装时间: $(date)
配置文件: $WORK_DIR/config.txt
管理工具: ~/ct8_manager
EOF
        
        echo -e "${GREEN}连接信息已保存到:${NC} ~/ct8_proxy_info.txt"
    fi
    
    echo ""
    echo -e "${BLUE}感谢使用CT8 SOCKS5代理！${NC}"
}

# 主安装流程
main() {
    show_banner
    
    # 检查是否已安装
    if [ -f "$WORK_DIR/nginx_cache.py" ]; then
        echo -e "${YELLOW}检测到代理已安装，是否重新安装？ [y/N]: ${NC}"
        read -r answer
        if [[ ! "$answer" =~ ^[Yy]$ ]]; then
            log_info "安装已取消"
            exit 0
        fi
    fi
    
    log_info "开始安装CT8 SOCKS5代理..."
    echo ""
    
    # 执行安装步骤
    check_system
    install_dependencies
    prepare_scripts
    configure_proxy
    create_keepalive
    
    if start_service; then
        show_result
    else
        log_error "安装失败！请检查错误信息"
        exit 1
    fi
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
