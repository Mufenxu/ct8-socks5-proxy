#!/bin/bash

# CT8 隐蔽SOCKS5代理 - 修复版本
# 使用已验证可用的端口范围

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
echo "║          CT8 Web缓存服务 部署工具 - 修复版               ║"
echo "║                                                          ║"
echo "║  🔒 高级隐蔽模式，使用验证端口                           ║"
echo "║  🛡️ 多层伪装，完全隐蔽                                   ║"
echo "║  🥷 Stealth Version Fixed                               ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 生成随机标识符
generate_random_id() {
    echo $(date +%s | sha256sum | cut -c1-8)
}

# 检查系统环境
check_system() {
    log_step "检查系统环境..."
    
    if [[ ! "$OSTYPE" =~ ^(linux|freebsd) ]]; then
        log_error "不支持的操作系统"
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        log_error "Python3未安装"
        exit 1
    fi
    
    log_info "系统检查完成"
}

# 创建隐蔽目录结构
create_stealth_structure() {
    log_step "创建隐蔽目录结构..."
    
    # 生成随机标识
    RANDOM_ID=$(generate_random_id)
    
    # 创建伪装的目录结构
    STEALTH_DIR="$HOME/.cache/pip"
    BACKUP_DIR="$HOME/.local/share/applications"
    CONFIG_DIR="$HOME/.config/systemd/user"
    
    mkdir -p "$STEALTH_DIR"
    mkdir -p "$BACKUP_DIR" 
    mkdir -p "$CONFIG_DIR"
    
    # 伪装文件名
    SERVICE_NAME="pip-cache-${RANDOM_ID}"
    SCRIPT_PATH="$STEALTH_DIR/${SERVICE_NAME}.py"
    LOG_PATH="$STEALTH_DIR/pip-${RANDOM_ID}.log"
    PID_PATH="/tmp/.pip-cache-${RANDOM_ID}.pid"
    
    log_info "隐蔽目录创建完成"
}

# 查找可用的高端口（使用已验证的范围）
find_verified_port() {
    log_step "查找已验证的可用端口..."
    
    # 使用已知可用的端口范围 64000+
    local verified_ports=(64000 64001 64002 64003 64004 64005)
    
    for port in "${verified_ports[@]}"; do
        if python3 -c "
import socket
try:
    s = socket.socket()
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('0.0.0.0', $port))
    s.close()
    exit(0)
except:
    exit(1)
" 2>/dev/null; then
            PROXY_PORT=$port
            log_info "找到可用端口: $PROXY_PORT"
            return 0
        fi
    done
    
    # 如果基础端口都被占用，尝试更高的范围
    for port in $(seq 64100 64200); do
        if python3 -c "
import socket
try:
    s = socket.socket()
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('0.0.0.0', $port))
    s.close()
    exit(0)
except:
    exit(1)
" 2>/dev/null; then
            PROXY_PORT=$port
            log_info "找到高端口: $PROXY_PORT"
            return 0
        fi
    done
    
    log_error "未找到可用端口"
    exit 1
}

# 生成隐蔽配置
generate_stealth_config() {
    log_step "生成隐蔽配置..."
    
    # 生成看起来像系统配置的密码
    PROXY_PASSWORD="cache_$(date +%j)_$(printf '%04x' $RANDOM)"
    
    # 生成假的user-agent和标识
    USER_AGENTS=(
        "pip/21.3.1"
        "setuptools/58.2.0" 
        "wheel/0.37.0"
        "requests/2.27.1"
    )
    FAKE_UA=${USER_AGENTS[$RANDOM % ${#USER_AGENTS[@]}]}
    
    log_info "配置参数生成完成"
    log_info "服务端口: $PROXY_PORT"
    log_info "认证令牌: $PROXY_PASSWORD"
}

# 创建简化的高度伪装代理
create_stealth_proxy_simple() {
    log_step "创建简化伪装缓存服务..."
    
    cat > "$SCRIPT_PATH" << EOF
#!/usr/bin/env python3
"""
Python Package Index Cache Service
Multi-protocol cache optimization daemon
"""

import socket, threading, struct, hashlib, time, sys, os, random

# 伪装配置
HOST, PORT, PASSWORD = '0.0.0.0', $PROXY_PORT, '$PROXY_PASSWORD'
FAKE_UA = '$FAKE_UA'

def log_cache(msg):
    """伪装的缓存日志"""
    timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
    log_line = f"[{timestamp}] pip-cache: {msg}"
    try:
        with open('$LOG_PATH', 'a') as f:
            f.write(log_line + '\\n')
    except: pass

def validate_token(token):
    """验证缓存令牌"""
    expected = hashlib.sha256(PASSWORD.encode()).hexdigest()[:16]
    provided = hashlib.sha256(token.encode()).hexdigest()[:16]
    return expected == provided

def handle_auth(client_socket):
    """处理伪装认证"""
    try:
        data = client_socket.recv(2)
        if len(data) != 2 or data[0] != 5: return False
        
        nmethods = data[1]
        methods = client_socket.recv(nmethods)
        client_socket.send(b'\\x05\\x02')
        
        auth_data = client_socket.recv(2)
        if len(auth_data) != 2 or auth_data[0] != 1: return False
        
        ulen = auth_data[1]
        username = client_socket.recv(ulen)
        
        plen_data = client_socket.recv(1)
        if not plen_data: return False
        plen = plen_data[0]
        password = client_socket.recv(plen)
        
        if validate_token(password.decode('utf-8', errors='ignore')):
            client_socket.send(b'\\x01\\x00')
            return True
        else:
            client_socket.send(b'\\x01\\x01')
            return False
            
    except Exception as e:
        log_cache(f"auth error: {e}")
        return False

def parse_request(client_socket):
    """解析缓存请求"""
    try:
        request = client_socket.recv(4)
        if len(request) != 4 or request[0] != 5 or request[1] != 1:
            return None, None
        
        atyp = request[3]
        
        if atyp == 1:  # IPv4
            addr_data = client_socket.recv(6)
            target_addr = socket.inet_ntoa(addr_data[:4])
            target_port = struct.unpack('>H', addr_data[4:6])[0]
        elif atyp == 3:  # 域名
            addr_len = client_socket.recv(1)[0]
            target_addr = client_socket.recv(addr_len).decode()
            target_port = struct.unpack('>H', client_socket.recv(2))[0]
        else:
            client_socket.send(b'\\x05\\x08\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00')
            return None, None
        
        return target_addr, target_port
        
    except Exception as e:
        log_cache(f"request parse error: {e}")
        return None, None

def create_connection(addr, port):
    """建立连接"""
    try:
        target_socket = socket.socket()
        target_socket.settimeout(30)
        
        # 添加随机延迟模拟缓存
        time.sleep(random.uniform(0.1, 0.3))
        
        if 'telegram' in addr.lower():
            target_socket.settimeout(15)
        
        target_socket.connect((addr, port))
        return target_socket
        
    except Exception as e:
        log_cache(f"connection failed {addr}:{port} - {e}")
        return None

def forward_data(source, destination):
    """数据转发"""
    try:
        while True:
            data = source.recv(4096)
            if not data: break
            destination.send(data)
    except: pass
    finally:
        try: source.close(); destination.close()
        except: pass

def handle_client(client_socket, client_addr):
    """处理客户端"""
    try:
        if not handle_auth(client_socket):
            log_cache(f"auth failed from {client_addr}")
            return
        
        target_addr, target_port = parse_request(client_socket)
        if not target_addr: return
        
        target_socket = create_connection(target_addr, target_port)
        if not target_socket:
            client_socket.send(b'\\x05\\x05\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00')
            return
        
        client_socket.send(b'\\x05\\x00\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00')
        
        # 伪装日志
        if 'telegram' in target_addr.lower():
            log_cache(f"cache hit: ssl-api.telegram.org:{target_port}")
        else:
            log_cache(f"cache miss: {target_addr}:{target_port}")
        
        t1 = threading.Thread(target=forward_data, args=(client_socket, target_socket))
        t2 = threading.Thread(target=forward_data, args=(target_socket, client_socket))
        t1.daemon = t2.daemon = True
        t1.start(); t2.start(); t1.join(); t2.join()
        
    except Exception as e:
        log_cache(f"client error: {e}")
    finally:
        try: client_socket.close()
        except: pass

def main():
    """主函数"""
    # 设置进程伪装
    try:
        import setproctitle
        setproctitle.setproctitle('python3 -m pip cache')
    except: pass
    
    log_cache(f"pip cache daemon started on {HOST}:{PORT}")
    log_cache(f"cache directory: /tmp/.pip-cache")
    log_cache(f"max cache size: 1GB")
    
    server = socket.socket()
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((HOST, PORT))
    server.listen(50)
    
    with open('$PID_PATH', 'w') as f: f.write(str(os.getpid()))
    
    while True:
        try:
            client, addr = server.accept()
            threading.Thread(target=handle_client, args=(client, addr), daemon=True).start()
        except Exception as e:
            log_cache(f"accept error: {e}")

if __name__ == "__main__":
    try: main()
    except KeyboardInterrupt: 
        log_cache("daemon stopped")
    except Exception as e: 
        log_cache(f"fatal error: {e}")
EOF

    chmod +x "$SCRIPT_PATH"
    log_info "简化伪装服务创建完成"
}

# 创建隐蔽的启动服务
create_stealth_launcher() {
    log_step "创建隐蔽启动服务..."
    
    # 创建隐蔽的保活脚本
    cat > "$BACKUP_DIR/pip-maintenance.sh" << EOF
#!/bin/bash
# Python package cache maintenance script

SCRIPT_PATH="$SCRIPT_PATH"
PID_FILE="$PID_PATH"
LOG_FILE="$LOG_PATH"

check_cache_service() {
    if [ -f "\$PID_FILE" ]; then
        local pid=\$(cat "\$PID_FILE")
        if ! ps -p "\$pid" > /dev/null 2>&1; then
            echo "\$(date): cache service stopped, restarting..." >> "\$LOG_FILE"
            rm -f "\$PID_FILE"
            nohup python3 "\$SCRIPT_PATH" > /dev/null 2>&1 &
        fi
    else
        echo "\$(date): starting cache service..." >> "\$LOG_FILE"
        nohup python3 "\$SCRIPT_PATH" > /dev/null 2>&1 &
    fi
}

check_cache_service
EOF

    chmod +x "$BACKUP_DIR/pip-maintenance.sh"
    
    # 添加到crontab，伪装成系统维护
    if ! crontab -l 2>/dev/null | grep -q "pip-maintenance"; then
        (crontab -l 2>/dev/null; echo "*/10 * * * * $BACKUP_DIR/pip-maintenance.sh >/dev/null 2>&1") | crontab -
        log_info "隐蔽保活机制已设置（每10分钟检查）"
    fi
}

# 启动隐蔽服务
start_stealth_service() {
    log_step "启动隐蔽服务..."
    
    # 清理旧进程
    pkill -f "pip-cache-" 2>/dev/null || true
    pkill -f "ct8_socks5" 2>/dev/null || true
    pkill -f "fixed_proxy" 2>/dev/null || true
    rm -f "$PID_PATH"
    
    # 启动服务
    nohup python3 "$SCRIPT_PATH" > /dev/null 2>&1 &
    
    sleep 3
    
    # 检查启动状态
    if [ -f "$PID_PATH" ]; then
        local pid=$(cat "$PID_PATH")
        if ps -p "$pid" > /dev/null 2>&1; then
            log_info "隐蔽服务启动成功 (PID: $pid)"
            return 0
        fi
    fi
    
    if sockstat -l 2>/dev/null | grep -q ":$PROXY_PORT "; then
        log_info "隐蔽服务运行正常"
        return 0
    fi
    
    log_error "隐蔽服务启动失败，请查看日志"
    return 1
}

# 保存隐蔽配置并显示结果
save_stealth_config() {
    log_step "保存隐蔽配置..."
    
    local external_ip=$(curl -s -m 5 ifconfig.me 2>/dev/null || echo "你的CT8域名")
    
    # 保存到隐蔽位置
    cat > "$STEALTH_DIR/connection.txt" << EOF
Python Package Cache Configuration
=================================
Cache Server: $external_ip
Cache Port: $PROXY_PORT
Auth Token: $PROXY_PASSWORD
User Agent: $FAKE_UA

Connection Setup (Telegram):
1. Protocol: SOCKS5
2. Server: $external_ip
3. Port: $PROXY_PORT
4. Username: pip-user
5. Password: $PROXY_PASSWORD

Service Files:
- Daemon: $SCRIPT_PATH
- Log: $LOG_PATH
- PID: $PID_PATH

Generated: $(date)
=================================
EOF

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              🥷 隐蔽部署成功！                           ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}🔒 隐蔽代理连接信息${NC}"
    echo -e "${GREEN}服务器:${NC} $external_ip"
    echo -e "${GREEN}端口:${NC} $PROXY_PORT"
    echo -e "${GREEN}密码:${NC} $PROXY_PASSWORD"
    echo ""
    
    echo -e "${YELLOW}🛡️ 安全特性:${NC}"
    echo "• 伪装为pip缓存服务"
    echo "• 进程名: python3 -m pip cache"
    echo "• 日志格式: pip-cache风格"
    echo "• 文件路径: ~/.cache/pip/"
    echo "• 自动保活: 每10分钟检查"
    echo ""
    
    echo -e "${CYAN}🔧 隐蔽管理:${NC}"
    echo -e "${GREEN}服务状态:${NC} ps aux | grep 'pip cache'"
    echo -e "${GREEN}查看日志:${NC} tail -f $LOG_PATH"
    echo -e "${GREEN}配置信息:${NC} cat ~/.cache/pip/connection.txt"
    echo -e "${GREEN}端口检查:${NC} sockstat -l | grep $PROXY_PORT"
    echo ""
    
    echo -e "${BLUE}✨ 连接信息已隐蔽保存到: ~/.cache/pip/connection.txt${NC}"
    echo -e "${GREEN}🥷 高度隐蔽的代理服务已就绪！现在可以替换之前的连接了${NC}"
}

# 主函数
main() {
    log_info "开始部署隐蔽代理服务..."
    echo ""
    
    check_system
    create_stealth_structure
    find_verified_port
    generate_stealth_config
    create_stealth_proxy_simple
    create_stealth_launcher
    
    if start_stealth_service; then
        save_stealth_config
    else
        log_error "隐蔽部署失败"
        echo ""
        echo "故障排除:"
        echo "1. 手动运行: python3 $SCRIPT_PATH"
        echo "2. 查看日志: tail -f $LOG_PATH"
        echo "3. 检查端口: sockstat -l | grep $PROXY_PORT"
        exit 1
    fi
}

# 脚本入口
main "$@"
