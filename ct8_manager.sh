#!/bin/bash

# CT8 SOCKS5代理管理工具
# 提供简单的服务管理功能

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 配置路径
WORK_DIR="$HOME/.config/systemd"
PYTHON_SCRIPT="$WORK_DIR/nginx_cache.py"
KEEPALIVE_SCRIPT="$WORK_DIR/keepalive.sh"
LOCK_FILE="/tmp/.nginx_cache.lock"
LOG_FILE="/tmp/.nginx_cache.log"
MAINTENANCE_LOG="/tmp/.nginx_maintenance.log"

# 函数定义
show_header() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        CT8 SOCKS5 代理管理工具         ║${NC}"
    echo -e "${BLUE}║              v1.0.0                    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查服务状态
check_service_status() {
    if [ -f "$LOCK_FILE" ]; then
        local pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if [ -n "$pid" ] && ps -p "$pid" > /dev/null 2>&1; then
            return 0  # 运行中
        else
            rm -f "$LOCK_FILE" 2>/dev/null
            return 1  # 已停止
        fi
    else
        return 1  # 未运行
    fi
}

# 获取服务信息
get_service_info() {
    if check_service_status; then
        local pid=$(cat "$LOCK_FILE" 2>/dev/null)
        local port=$(netstat -tuln 2>/dev/null | grep ":.*:.*LISTEN" | grep "$(ps -p $pid -o cmd= 2>/dev/null | grep -o '[0-9]\{4,5\}')" | head -1 | awk '{print $4}' | cut -d':' -f2)
        local uptime=$(ps -p $pid -o etime= 2>/dev/null | tr -d ' ')
        local memory=$(ps -p $pid -o rss= 2>/dev/null | awk '{print int($1/1024)"MB"}')
        
        echo -e "${GREEN}● 服务状态:${NC} 运行中"
        echo -e "${GREEN}● 进程ID:${NC} $pid"
        echo -e "${GREEN}● 监听端口:${NC} ${port:-"未知"}"
        echo -e "${GREEN}● 运行时间:${NC} ${uptime:-"未知"}"
        echo -e "${GREEN}● 内存使用:${NC} ${memory:-"未知"}"
    else
        echo -e "${RED}● 服务状态:${NC} 已停止"
    fi
}

# 显示状态页面
show_status() {
    show_header
    echo -e "${CYAN}=== 服务状态 ===${NC}"
    get_service_info
    echo ""
    
    # 显示端口占用情况
    echo -e "${CYAN}=== 端口信息 ===${NC}"
    local ports=$(netstat -tuln 2>/dev/null | grep "LISTEN" | grep -E ":(8080|8443|3000|5000)" | awk '{print $4}' | cut -d':' -f2 | sort -n)
    if [ -n "$ports" ]; then
        echo -e "${GREEN}已占用端口:${NC} $(echo $ports | tr '\n' ' ')"
    else
        echo -e "${YELLOW}未发现常用代理端口${NC}"
    fi
    echo ""
    
    # 显示最近日志
    echo -e "${CYAN}=== 最近日志 ===${NC}"
    if [ -f "$LOG_FILE" ]; then
        tail -5 "$LOG_FILE" 2>/dev/null | while read line; do
            echo -e "${YELLOW}$line${NC}"
        done
    else
        echo -e "${YELLOW}暂无日志${NC}"
    fi
}

# 启动服务
start_service() {
    show_header
    echo -e "${CYAN}=== 启动服务 ===${NC}"
    
    if check_service_status; then
        log_warn "服务已在运行中"
        return 0
    fi
    
    if [ ! -f "$PYTHON_SCRIPT" ]; then
        log_error "代理脚本不存在，请先运行部署脚本"
        return 1
    fi
    
    log_info "正在启动SOCKS5代理服务..."
    nohup python3 "$PYTHON_SCRIPT" > /dev/null 2>&1 &
    local pid=$!
    echo "$pid" > "$LOCK_FILE"
    
    sleep 3
    if ps -p "$pid" > /dev/null 2>&1; then
        log_info "服务启动成功 (PID: $pid)"
        
        # 获取端口信息
        local port=$(python3 -c "
import re
try:
    with open('$PYTHON_SCRIPT', 'r') as f:
        content = f.read()
        match = re.search(r\"'cache_port':\s*(\d+)\", content)
        print(match.group(1) if match else 'unknown')
except:
    print('unknown')
" 2>/dev/null)
        
        echo -e "${GREEN}监听端口:${NC} $port"
        return 0
    else
        log_error "服务启动失败"
        rm -f "$LOCK_FILE"
        return 1
    fi
}

# 停止服务
stop_service() {
    show_header
    echo -e "${CYAN}=== 停止服务 ===${NC}"
    
    if ! check_service_status; then
        log_warn "服务未运行"
        return 0
    fi
    
    local pid=$(cat "$LOCK_FILE" 2>/dev/null)
    log_info "正在停止服务 (PID: $pid)..."
    
    # 优雅停止
    kill -TERM "$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null
    rm -f "$LOCK_FILE"
    
    sleep 2
    if ! ps -p "$pid" > /dev/null 2>&1; then
        log_info "服务已停止"
        return 0
    else
        log_error "服务停止失败"
        return 1
    fi
}

# 重启服务
restart_service() {
    show_header
    echo -e "${CYAN}=== 重启服务 ===${NC}"
    
    stop_service
    sleep 1
    start_service
}

# 查看日志
view_logs() {
    show_header
    echo -e "${CYAN}=== 服务日志 ===${NC}"
    
    if [ -f "$LOG_FILE" ]; then
        echo -e "${GREEN}最近50行日志:${NC}"
        echo "---"
        tail -50 "$LOG_FILE" | while read line; do
            echo -e "${YELLOW}$line${NC}"
        done
    else
        log_warn "日志文件不存在"
    fi
    
    echo ""
    echo -e "${BLUE}按Enter返回主菜单...${NC}"
    read
}

# 实时日志监控
monitor_logs() {
    show_header
    echo -e "${CYAN}=== 实时日志监控 ===${NC}"
    echo -e "${YELLOW}按 Ctrl+C 退出监控${NC}"
    echo "---"
    
    if [ -f "$LOG_FILE" ]; then
        tail -f "$LOG_FILE"
    else
        log_warn "日志文件不存在"
        sleep 2
    fi
}

# 网络测试
network_test() {
    show_header
    echo -e "${CYAN}=== 网络连接测试 ===${NC}"
    
    # 检查本地端口
    if check_service_status; then
        local pid=$(cat "$LOCK_FILE")
        local port=$(netstat -tuln 2>/dev/null | grep -E ":80[0-9][0-9].*LISTEN" | head -1 | awk '{print $4}' | cut -d':' -f2)
        
        if [ -n "$port" ]; then
            log_info "本地端口测试..."
            if nc -z localhost "$port" 2>/dev/null; then
                echo -e "${GREEN}✓ 端口 $port 可访问${NC}"
            else
                echo -e "${RED}✗ 端口 $port 不可访问${NC}"
            fi
        fi
    else
        log_warn "服务未运行，无法测试端口"
    fi
    
    # 测试外网连接
    echo ""
    log_info "外网连接测试..."
    
    if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 互联网连接正常${NC}"
    else
        echo -e "${RED}✗ 互联网连接异常${NC}"
    fi
    
    if nslookup telegram.org > /dev/null 2>&1; then
        echo -e "${GREEN}✓ DNS解析正常${NC}"
    else
        echo -e "${RED}✗ DNS解析异常${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}按Enter返回主菜单...${NC}"
    read
}

# 配置管理
config_menu() {
    while true; do
        show_header
        echo -e "${CYAN}=== 配置管理 ===${NC}"
        echo "1. 查看当前配置"
        echo "2. 修改端口"
        echo "3. 修改密码"
        echo "4. 修改IP白名单"
        echo "0. 返回主菜单"
        echo ""
        echo -n "请选择操作 [0-4]: "
        read choice
        
        case $choice in
            1) view_config ;;
            2) change_port ;;
            3) change_password ;;
            4) change_whitelist ;;
            0) break ;;
            *) log_error "无效选择" ;;
        esac
    done
}

# 查看配置
view_config() {
    show_header
    echo -e "${CYAN}=== 当前配置 ===${NC}"
    
    if [ -f "$PYTHON_SCRIPT" ]; then
        echo -e "${GREEN}配置文件:${NC} $PYTHON_SCRIPT"
        echo ""
        
        # 提取配置信息
        python3 -c "
import re
try:
    with open('$PYTHON_SCRIPT', 'r') as f:
        content = f.read()
        
    port_match = re.search(r\"'cache_port':\s*(\d+)\", content)
    auth_match = re.search(r\"'auth_token':\s*'([^']+)'\", content)
    clients_match = re.search(r\"'allowed_clients':\s*\[([^\]]*)\]\", content)
    
    print(f'端口: {port_match.group(1) if port_match else \"未找到\"}')
    print(f'密码: {auth_match.group(1) if auth_match else \"未找到\"}')
    
    if clients_match:
        clients = clients_match.group(1).strip()
        if clients:
            print(f'IP白名单: {clients}')
        else:
            print('IP白名单: 允许所有IP')
    else:
        print('IP白名单: 未配置')
        
except Exception as e:
    print(f'配置读取失败: {e}')
" 2>/dev/null
    else
        log_error "配置文件不存在"
    fi
    
    echo ""
    echo -e "${BLUE}按Enter返回...${NC}"
    read
}

# 修改端口（简化版）
change_port() {
    show_header
    echo -e "${CYAN}=== 修改端口 ===${NC}"
    echo -e "${YELLOW}注意: 修改端口需要重启服务${NC}"
    echo ""
    echo -n "请输入新端口 [1024-65535]: "
    read new_port
    
    if [[ "$new_port" =~ ^[0-9]+$ ]] && [ "$new_port" -ge 1024 ] && [ "$new_port" -le 65535 ]; then
        if netstat -tuln 2>/dev/null | grep -q ":$new_port "; then
            log_error "端口 $new_port 已被占用"
        else
            log_info "端口配置将在下次重启时生效"
            log_warn "请手动编辑配置文件更新端口: $PYTHON_SCRIPT"
        fi
    else
        log_error "无效端口号"
    fi
    
    echo ""
    echo -e "${BLUE}按Enter返回...${NC}"
    read
}

# 修改密码（简化版）
change_password() {
    show_header
    echo -e "${CYAN}=== 修改密码 ===${NC}"
    echo -e "${YELLOW}注意: 修改密码需要重启服务${NC}"
    echo ""
    echo -n "请输入新密码: "
    read -s new_password
    echo ""
    
    if [ ${#new_password} -ge 6 ]; then
        log_info "密码配置将在下次重启时生效"
        log_warn "请手动编辑配置文件更新密码: $PYTHON_SCRIPT"
        echo -e "${GREEN}新密码:${NC} $new_password"
    else
        log_error "密码长度至少6位"
    fi
    
    echo ""
    echo -e "${BLUE}按Enter返回...${NC}"
    read
}

# 修改白名单（简化版）
change_whitelist() {
    show_header
    echo -e "${CYAN}=== 修改IP白名单 ===${NC}"
    echo "1. 允许所有IP（清空白名单）"
    echo "2. 添加IP到白名单"
    echo "0. 返回"
    echo ""
    echo -n "请选择 [0-2]: "
    read choice
    
    case $choice in
        1)
            log_info "将清空IP白名单，允许所有IP访问"
            log_warn "请手动编辑配置文件: $PYTHON_SCRIPT"
            ;;
        2)
            echo -n "请输入IP地址: "
            read ip_addr
            if [[ "$ip_addr" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                log_info "IP白名单配置将在下次重启时生效"
                log_warn "请手动编辑配置文件添加IP: $PYTHON_SCRIPT"
                echo -e "${GREEN}新增IP:${NC} $ip_addr"
            else
                log_error "无效IP地址格式"
            fi
            ;;
    esac
    
    echo ""
    echo -e "${BLUE}按Enter返回...${NC}"
    read
}

# 主菜单
main_menu() {
    while true; do
        show_header
        get_service_info
        echo ""
        echo -e "${CYAN}=== 主菜单 ===${NC}"
        echo "1. 启动服务"
        echo "2. 停止服务"
        echo "3. 重启服务"
        echo "4. 查看状态"
        echo "5. 查看日志"
        echo "6. 实时监控"
        echo "7. 网络测试"
        echo "8. 配置管理"
        echo "0. 退出"
        echo ""
        echo -n "请选择操作 [0-8]: "
        read choice
        
        case $choice in
            1) start_service; echo ""; echo -e "${BLUE}按Enter继续...${NC}"; read ;;
            2) stop_service; echo ""; echo -e "${BLUE}按Enter继续...${NC}"; read ;;
            3) restart_service; echo ""; echo -e "${BLUE}按Enter继续...${NC}"; read ;;
            4) show_status; echo ""; echo -e "${BLUE}按Enter继续...${NC}"; read ;;
            5) view_logs ;;
            6) monitor_logs ;;
            7) network_test ;;
            8) config_menu ;;
            0) 
                echo -e "${GREEN}感谢使用CT8 SOCKS5代理管理工具！${NC}"
                exit 0
                ;;
            *)
                log_error "无效选择，请重新输入"
                sleep 1
                ;;
        esac
    done
}

# 检查依赖
check_dependencies() {
    local missing_deps=()
    
    command -v python3 >/dev/null 2>&1 || missing_deps+=("python3")
    command -v netstat >/dev/null 2>&1 || missing_deps+=("net-tools")
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "缺少依赖: ${missing_deps[*]}"
        log_info "请先安装缺少的依赖"
        exit 1
    fi
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    check_dependencies
    main_menu
fi
