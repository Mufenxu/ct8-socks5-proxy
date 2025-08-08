#!/bin/bash

# CT8 SOCKS5代理 快速修复版本 v3
# 修复权限问题：改为绑定本地接口

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 显示横幅
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║          CT8 SOCKS5代理 快速修复部署工具 v3              ║"
echo "║                                                          ║"
echo "║  🚀 修复权限问题，绑定本地接口                           ║"
echo "║  🔒 隐蔽安全，专为CT8/Serv00优化                         ║"
echo "║  ⚡ 版本: 1.0.3                                      ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

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
        exit 1
    fi
    
    # 检查Python3
    if ! command -v python3 &> /dev/null; then
        log_error "Python3未安装"
        exit 1
    fi
    
    # 获取本地IP地址
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1")
    if [ "$LOCAL_IP" = "" ]; then
        LOCAL_IP="127.0.0.1"
    fi
    
    log_info "系统环境检查完成 (OS: $OSTYPE)"
    log_info "本地IP地址: $LOCAL_IP"
}

# 创建工作目录
setup_directories() {
    log_step "创建工作目录..."
    
    local work_dir="$HOME/.config/systemd"
    mkdir -p "$work_dir"
    
    log_info "工作目录: $work_dir"
}

# 生成配置参数
generate_config() {
    log_step "生成配置参数..."
    
    # 生成随机端口
    PROXY_PORT=$((8000 + RANDOM % 1000))
    
    # 检查端口是否被占用
    while netstat -an 2>/dev/null | grep -q ":$PROXY_PORT " || sockstat -l 2>/dev/null | grep -q ":$PROXY_PORT "; do
        PROXY_PORT=$((8000 + RANDOM % 1000))
    done
    
    # 生成随机密码
    PROXY_PASSWORD="tg_$(date +%m%d)_$(printf '%04x' $RANDOM)"
    
    log_info "生成端口: $PROXY_PORT"
    log_info "生成密码: $PROXY_PASSWORD"
    log_info "绑定地址: $LOCAL_IP (本地接口)"
}

# 创建简化版代理脚本
create_proxy_script() {
    log_step "创建代理服务脚本..."
    
    local script_path="$HOME/.config/systemd/nginx_cache.py"
    
    # 创建简化版本，使用同步方式避免异步库问题
    cat > "$script_path" << EOF
#!/usr/bin/env python3
"""
Nginx Cache Proxy - 简化同步版本
适配CT8/Serv00权限限制
"""

import socket
import threading
import struct
import hashlib
import time
import sys
import signal
import os

# 配置
HOST = '$LOCAL_IP'  # 绑定到本地IP而不是0.0.0.0
PORT = $PROXY_PORT
PASSWORD = '$PROXY_PASSWORD'
MAX_CONNECTIONS = 50

def log_message(msg):
    """日志记录"""
    timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
    log_line = f"[{timestamp}] nginx-cache: {msg}"
    print(log_line)
    try:
        with open('/tmp/.nginx_cache.log', 'a') as f:
            f.write(log_line + '\\n')
    except:
        pass

def validate_auth(password):
    """验证密码"""
    expected = hashlib.md5(PASSWORD.encode()).hexdigest()[:8]
    provided = hashlib.md5(password.encode()).hexdigest()[:8]
    return expected == provided

def handle_socks5_auth(client_socket):
    """处理SOCKS5认证"""
    try:
        # 读取认证方法选择
        data = client_socket.recv(2)
        if len(data) != 2 or data[0] != 5:
            return False
        
        nmethods = data[1]
        methods = client_socket.recv(nmethods)
        
        # 要求用户名密码认证
        client_socket.send(b'\\x05\\x02')
        
        # 读取认证信息
        auth_data = client_socket.recv(2)
        if len(auth_data) != 2 or auth_data[0] != 1:
            return False
        
        ulen = auth_data[1]
        username = client_socket.recv(ulen)
        
        plen_data = client_socket.recv(1)
        if not plen_data:
            return False
        plen = plen_data[0]
        password = client_socket.recv(plen)
        
        # 验证密码
        if validate_auth(password.decode('utf-8', errors='ignore')):
            client_socket.send(b'\\x01\\x00')  # 认证成功
            return True
        else:
            client_socket.send(b'\\x01\\x01')  # 认证失败
            return False
            
    except Exception as e:
        log_message(f"认证错误: {e}")
        return False

def handle_socks5_request(client_socket):
    """处理SOCKS5连接请求"""
    try:
        request = client_socket.recv(4)
        if len(request) != 4 or request[0] != 5 or request[1] != 1:
            return None, None
        
        atyp = request[3]
        
        if atyp == 1:  # IPv4
            addr_data = client_socket.recv(6)
            addr = socket.inet_ntoa(addr_data[:4])
            port = struct.unpack('>H', addr_data[4:6])[0]
        elif atyp == 3:  # 域名
            addr_len = client_socket.recv(1)[0]
            addr = client_socket.recv(addr_len).decode()
            port = struct.unpack('>H', client_socket.recv(2))[0]
        else:
            # 不支持IPv6
            client_socket.send(b'\\x05\\x08\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00')
            return None, None
        
        return addr, port
        
    except Exception as e:
        log_message(f"请求解析错误: {e}")
        return None, None

def forward_data(source, destination, direction=""):
    """数据转发"""
    try:
        while True:
            data = source.recv(4096)
            if not data:
                break
            destination.send(data)
    except Exception as e:
        pass
    finally:
        try:
            source.close()
            destination.close()
        except:
            pass

def handle_client(client_socket, client_addr):
    """处理客户端连接"""
    try:
        # SOCKS5认证
        if not handle_socks5_auth(client_socket):
            log_message(f"认证失败: {client_addr}")
            return
        
        # 处理连接请求
        target_addr, target_port = handle_socks5_request(client_socket)
        if not target_addr:
            return
        
        # 连接目标服务器
        try:
            target_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            target_socket.settimeout(30)
            
            # 特别优化Telegram连接
            if 'telegram' in target_addr.lower() or target_port in [443, 80, 5222]:
                target_socket.settimeout(15)
            
            target_socket.connect((target_addr, target_port))
            
            # 连接成功响应
            client_socket.send(b'\\x05\\x00\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00')
            
            log_message(f"代理连接: {client_addr} -> {target_addr}:{target_port}")
            
            # 开始双向数据转发
            t1 = threading.Thread(target=forward_data, args=(client_socket, target_socket, "client->target"))
            t2 = threading.Thread(target=forward_data, args=(target_socket, client_socket, "target->client"))
            t1.daemon = True
            t2.daemon = True
            t1.start()
            t2.start()
            t1.join()
            t2.join()
            
        except Exception as e:
            log_message(f"连接目标失败 {target_addr}:{target_port} - {e}")
            # 连接失败响应
            client_socket.send(b'\\x05\\x05\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00')
            
    except Exception as e:
        log_message(f"客户端处理错误: {e}")
    finally:
        try:
            client_socket.close()
        except:
            pass

def signal_handler(signum, frame):
    """信号处理"""
    log_message(f"收到信号 {signum}，正在停止服务...")
    sys.exit(0)

def main():
    """主函数"""
    # 注册信号处理
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    log_message(f"nginx-cache service starting on {HOST}:{PORT}")
    
    try:
        # 创建服务器socket
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        
        # 绑定到本地IP
        server_socket.bind((HOST, PORT))
        server_socket.listen(MAX_CONNECTIONS)
        
        log_message(f"service started successfully on {HOST}:{PORT}")
        log_message(f"cache size limit 50MB")
        
        # 保存PID
        with open('/tmp/.nginx_cache.lock', 'w') as f:
            f.write(str(os.getpid()))
        
        # 主循环
        while True:
            try:
                client_socket, client_addr = server_socket.accept()
                client_thread = threading.Thread(
                    target=handle_client, 
                    args=(client_socket, client_addr)
                )
                client_thread.daemon = True
                client_thread.start()
            except Exception as e:
                log_message(f"接受连接错误: {e}")
                
    except Exception as e:
        log_message(f"Service startup failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        log_message("服务正常停止")
    except Exception as e:
        log_message(f"致命错误: {e}")
        sys.exit(1)
EOF

    chmod +x "$script_path"
    log_info "代理脚本创建完成"
}

# 保存配置信息
save_config() {
    log_step "保存配置信息..."
    
    # 保存配置信息
    cat > "$HOME/.config/systemd/config.txt" << EOF
CT8 SOCKS5代理配置信息
========================
安装时间: $(date)
绑定地址: $LOCAL_IP
代理端口: $PROXY_PORT
认证密码: $PROXY_PASSWORD
配置文件: $HOME/.config/systemd/nginx_cache.py
========================
EOF
    
    # 保存连接信息
    cat > "$HOME/ct8_proxy_info.txt" << EOF
CT8 SOCKS5代理连接信息
====================
服务器: $LOCAL_IP
端口: $PROXY_PORT
用户名: 任意
密码: $PROXY_PASSWORD

安装时间: $(date)
注意: 请确保客户端能访问服务器IP $LOCAL_IP
配置文件: $HOME/.config/systemd/nginx_cache.py

管理命令: 
  查看状态: ps aux | grep nginx-cache
  查看日志: tail -f /tmp/.nginx_cache.log
  重启服务: pkill -f nginx-cache && nohup python3 ~/.config/systemd/nginx_cache.py &
EOF
    
    log_info "配置信息已保存"
}

# 创建保活脚本
create_keepalive() {
    log_step "创建保活机制..."
    
    local keepalive_script="$HOME/.config/systemd/keepalive.sh"
    
    cat > "$keepalive_script" << 'KEEPALIVE_EOF'
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
        fi
    else
        echo "[$(date)] 服务未运行，正在启动..." >> "$LOG_FILE"
        nohup python3 "$SCRIPT_PATH" > /dev/null 2>&1 &
    fi
}

check_and_restart
KEEPALIVE_EOF

    chmod +x "$keepalive_script"
    
    # 添加到crontab（如果不存在）
    if ! crontab -l 2>/dev/null | grep -q "keepalive.sh"; then
        (crontab -l 2>/dev/null; echo "*/5 * * * * $keepalive_script >/dev/null 2>&1") | crontab -
        log_info "保活机制已设置（每5分钟检查一次）"
    else
        log_info "保活任务已存在"
    fi
}

# 启动服务
start_service() {
    log_step "启动代理服务..."
    
    local script_path="$HOME/.config/systemd/nginx_cache.py"
    
    # 停止可能存在的旧进程
    pkill -f "nginx-cache" 2>/dev/null || true
    rm -f "/tmp/.nginx_cache.lock"
    sleep 2
    
    # 启动新服务
    nohup python3 "$script_path" > /dev/null 2>&1 &
    local start_pid=$!
    
    sleep 3
    
    # 检查服务是否真正启动
    if [ -f "/tmp/.nginx_cache.lock" ]; then
        local pid=$(cat "/tmp/.nginx_cache.lock")
        if ps -p "$pid" > /dev/null 2>&1; then
            log_info "服务启动成功 (PID: $pid)"
            return 0
        fi
    fi
    
    # 如果lock文件方法失败，尝试检查端口
    if netstat -an 2>/dev/null | grep -q ":$PROXY_PORT " || sockstat -l 2>/dev/null | grep -q ":$PROXY_PORT "; then
        log_info "服务启动成功，端口 $PROXY_PORT 正在监听"
        return 0
    fi
    
    log_error "服务启动失败，请检查日志: tail -f /tmp/.nginx_cache.log"
    return 1
}

# 显示结果
show_result() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                   🎉 部署成功！                         ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}=== 连接信息 ===${NC}"
    echo -e "${GREEN}服务器地址:${NC} $LOCAL_IP"
    echo -e "${GREEN}SOCKS5端口:${NC} $PROXY_PORT"
    echo -e "${GREEN}用户名:${NC} 任意"
    echo -e "${GREEN}密码:${NC} $PROXY_PASSWORD"
    echo ""
    
    echo -e "${CYAN}=== Telegram设置 ===${NC}"
    echo "1. 打开Telegram → 设置 → 高级 → 连接代理"
    echo "2. 添加代理 → SOCKS5"
    echo "3. 输入上述服务器信息"
    echo ""
    
    echo -e "${CYAN}=== 管理命令 ===${NC}"
    echo -e "${GREEN}查看状态:${NC} ps aux | grep nginx-cache"
    echo -e "${GREEN}查看日志:${NC} tail -f /tmp/.nginx_cache.log"
    echo -e "${GREEN}重启服务:${NC} ~/.config/systemd/keepalive.sh"
    echo -e "${GREEN}端口检查:${NC} sockstat -l | grep $PROXY_PORT"
    echo ""
    
    echo -e "${YELLOW}注意事项:${NC}"
    echo "• 服务绑定到本地IP: $LOCAL_IP"
    echo "• 确保客户端能访问此IP地址"
    echo "• 服务会自动保活，每5分钟检查一次"
    echo "• 连接信息已保存到: ~/ct8_proxy_info.txt"
    echo ""
    
    echo -e "${BLUE}CT8 SOCKS5代理部署完成！${NC}"
}

# 主函数
main() {
    log_info "开始快速部署CT8 SOCKS5代理..."
    echo ""
    
    check_system
    setup_directories
    generate_config
    create_proxy_script
    save_config
    create_keepalive
    
    if start_service; then
        show_result
    else
        log_error "部署失败！"
        echo ""
        echo -e "${YELLOW}故障排除:${NC}"
        echo "1. 查看详细错误: python3 ~/.config/systemd/nginx_cache.py"
        echo "2. 查看日志: tail -f /tmp/.nginx_cache.log"
        echo "3. 检查端口: sockstat -l | grep $PROXY_PORT"
        exit 1
    fi
}

# 脚本入口
main "$@"
