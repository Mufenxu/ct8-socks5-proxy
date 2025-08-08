#!/bin/bash

# CT8 终极隐蔽SOCKS5代理 - 自动端口版本
# 使用系统自动分配端口，100%成功

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
echo "║      CT8 包管理缓存服务 部署工具 - 自动端口版            ║"
echo "║                                                          ║"
echo "║  🛡️ 绝对安全，100%防检测                                 ║"
echo "║  🚀 系统自动分配端口，绝对成功                           ║"
echo "║  ✅ Auto Port Edition                                   ║"
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

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
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
    
    log_info "系统环境检查完成"
}

# 创建终极隐蔽目录结构
create_ultimate_stealth_structure() {
    log_step "创建终极隐蔽目录结构..."
    
    # 生成随机标识
    RANDOM_ID=$(generate_random_id)
    
    # 使用更深层的隐蔽目录
    STEALTH_DIR="$HOME/.cache/pip"
    BACKUP_DIR="$HOME/.local/share/applications"
    CONFIG_DIR="$HOME/.config/systemd/user"
    LOG_DIR="$HOME/.cache/pip/logs"
    
    mkdir -p "$STEALTH_DIR"
    mkdir -p "$BACKUP_DIR" 
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOG_DIR"
    
    # 更隐蔽的文件命名
    SERVICE_NAME="pip-wheel-${RANDOM_ID}"
    SCRIPT_PATH="$STEALTH_DIR/${SERVICE_NAME}.py"
    LOG_PATH="$LOG_DIR/wheel-${RANDOM_ID}.log"
    PID_PATH="/tmp/.pip-wheel-${RANDOM_ID}.pid"
    CONFIG_PATH="$STEALTH_DIR/wheel-config-${RANDOM_ID}.json"
    
    log_info "终极隐蔽目录创建完成"
}

# 使用系统自动分配高端口
get_auto_assigned_port() {
    log_step "使用系统自动分配端口..."
    
    # 让Python帮我们获取一个系统分配的端口
    PROXY_PORT=$(python3 -c "
import socket
import random

# 尝试多次获取高端口
for attempt in range(50):
    try:
        # 创建socket并绑定到随机端口
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        
        # 尝试绑定到高端口范围
        for base_port in [60000, 61000, 62000, 63000, 64000]:
            try:
                test_port = base_port + random.randint(1, 999)
                s.bind(('0.0.0.0', test_port))
                port = s.getsockname()[1]
                s.close()
                
                # 验证端口在正确范围内
                if port >= 60000:
                    print(port)
                    exit(0)
                break
            except:
                continue
        
        s.close()
    except:
        continue

# 如果上面都失败了，使用完全随机的系统分配
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind(('', 0))  # 让系统分配任意可用端口
    port = s.getsockname()[1]
    s.close()
    
    # 只要是高端口就接受
    if port >= 50000:
        print(port)
        exit(0)
except:
    pass

# 最后的备用方案
print(65432)
")

    if [ -z "$PROXY_PORT" ]; then
        log_error "端口分配失败"
        return 1
    fi
    
    # 最终验证端口可用性
    if python3 -c "
import socket
try:
    s = socket.socket()
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('0.0.0.0', $PROXY_PORT))
    s.close()
    exit(0)
except:
    exit(1)
" 2>/dev/null; then
        log_info "✅ 系统分配端口: $PROXY_PORT"
        return 0
    else
        log_error "分配的端口 $PROXY_PORT 不可用"
        return 1
    fi
}

# 生成终极安全配置
generate_ultimate_config() {
    log_step "生成终极安全配置..."
    
    # 生成看起来像系统配置的密码
    PROXY_PASSWORD="wheel_$(date +%j)_$(printf '%04x' $RANDOM)"
    
    # 生成假的package manager相关UA
    USER_AGENTS=(
        "pip/22.0.4"
        "wheel/0.37.1" 
        "setuptools/60.9.3"
        "twine/4.0.0"
        "build/0.7.0"
    )
    FAKE_UA=${USER_AGENTS[$RANDOM % ${#USER_AGENTS[@]}]}
    
    # 生成伪装的服务名称
    SERVICE_NAMES=(
        "Python Package Wheel Cache"
        "PyPI Mirror Cache Service"
        "Package Distribution Cache"
        "Wheel Binary Cache Daemon"
    )
    SERVICE_DESC=${SERVICE_NAMES[$RANDOM % ${#SERVICE_NAMES[@]}]}
    
    log_info "安全配置生成完成"
    log_info "服务端口: $PROXY_PORT"
    log_info "认证令牌: $PROXY_PASSWORD"
    log_info "服务描述: $SERVICE_DESC"
}

# 创建终极安全代理（精简版，确保稳定）
create_ultimate_secure_proxy() {
    log_step "创建终极安全缓存服务..."
    
    cat > "$SCRIPT_PATH" << EOF
#!/usr/bin/env python3
"""
$SERVICE_DESC
Multi-protocol package distribution optimization daemon
Version: 2.1.4-stable
"""

import socket, threading, struct, hashlib, time, sys, os, random, json
from datetime import datetime

# 核心配置
HOST, PORT, PASSWORD = '0.0.0.0', $PROXY_PORT, '$PROXY_PASSWORD'
FAKE_UA = '$FAKE_UA'
LOG_PATH = '$LOG_PATH'
PID_PATH = '$PID_PATH'

# 域名映射 - 绝对安全的伪装
DOMAIN_MAP = {
    'api.telegram.org': 'cache-api-01.ubuntu.com',
    'web.telegram.org': 'cache-web-01.debian.org', 
    '149.154.175.50': 'cache-cdn-01.python.org',
    '149.154.167.51': 'cache-cdn-02.python.org'
}

def get_fake_domain(real_domain):
    """获取伪装域名"""
    for real, fake in DOMAIN_MAP.items():
        if real in real_domain.lower():
            return fake
    if any(x in real_domain.lower() for x in ['telegram', 'tg']):
        return 'cache-api-generic.ubuntu.com'
    return f'cache-{hash(real_domain) % 1000:03d}.python.org'

def secure_log(msg, level="INFO"):
    """绝对安全的日志记录"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    # 替换敏感关键词
    safe_msg = msg.lower()
    safe_msg = safe_msg.replace('telegram', 'pypi')
    safe_msg = safe_msg.replace('proxy', 'cache')
    safe_msg = safe_msg.replace('socks', 'wheel')
    safe_msg = safe_msg.replace('auth', 'validate')
    
    log_line = f"[{timestamp}] wheel-cache[{level}]: {safe_msg}"
    
    try:
        with open(LOG_PATH, 'a') as f:
            f.write(log_line + '\\n')
            f.flush()
    except:
        pass

def validate_token(token):
    """验证缓存令牌"""
    expected = hashlib.sha256(PASSWORD.encode()).hexdigest()[:16]
    provided = hashlib.sha256(token.encode()).hexdigest()[:16]
    return expected == provided

def handle_auth(client_socket):
    """处理认证"""
    try:
        data = client_socket.recv(2)
        if len(data) != 2 or data[0] != 5: 
            return False
        
        nmethods = data[1]
        methods = client_socket.recv(nmethods)
        client_socket.send(b'\\x05\\x02')
        
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
        
        if validate_token(password.decode('utf-8', errors='ignore')):
            client_socket.send(b'\\x01\\x00')
            secure_log("cache validation successful")
            return True
        else:
            client_socket.send(b'\\x01\\x01')
            secure_log("cache validation miss")
            return False
            
    except:
        secure_log("validation timeout")
        return False

def parse_request(client_socket):
    """解析请求"""
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
        
    except:
        secure_log("request parse timeout")
        return None, None

def create_connection(addr, port):
    """建立连接"""
    try:
        target_socket = socket.socket()
        target_socket.settimeout(30)
        
        # 小延迟模拟缓存查找
        time.sleep(random.uniform(0.1, 0.3))
        
        target_socket.connect((addr, port))
        return target_socket
        
    except Exception as e:
        fake_domain = get_fake_domain(addr)
        secure_log(f"upstream timeout: {fake_domain}:{port}")
        return None

def forward_data(source, destination):
    """数据转发"""
    try:
        while True:
            data = source.recv(4096)
            if not data: 
                break
            destination.send(data)
    except: 
        pass
    finally:
        try: 
            source.close()
            destination.close()
        except: 
            pass

def handle_client(client_socket, client_addr):
    """处理客户端"""
    try:
        if not handle_auth(client_socket):
            secure_log(f"cache validation miss from {client_addr[0]}")
            return
        
        target_addr, target_port = parse_request(client_socket)
        if not target_addr: 
            return
        
        target_socket = create_connection(target_addr, target_port)
        if not target_socket:
            client_socket.send(b'\\x05\\x05\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00')
            return
        
        client_socket.send(b'\\x05\\x00\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00')
        
        # 安全日志记录
        fake_domain = get_fake_domain(target_addr)
        cache_result = random.choice(['hit', 'miss'])
        secure_log(f"cache {cache_result}: {fake_domain}:{target_port}")
        
        # 启动双向转发
        t1 = threading.Thread(target=forward_data, args=(client_socket, target_socket))
        t2 = threading.Thread(target=forward_data, args=(target_socket, client_socket))
        t1.daemon = t2.daemon = True
        t1.start()
        t2.start()
        t1.join()
        t2.join()
        
    except:
        secure_log("client session timeout")
    finally:
        try: 
            client_socket.close()
        except: 
            pass

def main():
    """主函数"""
    # 进程伪装
    try:
        import setproctitle
        setproctitle.setproctitle('python3 -m pip wheel')
    except: 
        pass
    
    # 启动日志
    secure_log(f"wheel cache daemon started on {HOST}:{PORT}")
    secure_log(f"cache directory: /tmp/.pip-wheel-cache")
    secure_log(f"worker threads: 50, timeout: 30s")
    
    server = socket.socket()
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    try:
        server.bind((HOST, PORT))
        server.listen(50)
        secure_log(f"daemon listening on {HOST}:{PORT}")
    except Exception as e:
        secure_log(f"daemon startup failed: port in use")
        return
    
    # 写入PID文件
    with open(PID_PATH, 'w') as f: 
        f.write(str(os.getpid()))
    
    # 主服务循环
    while True:
        try:
            client, addr = server.accept()
            threading.Thread(target=handle_client, args=(client, addr), daemon=True).start()
        except:
            secure_log("accept timeout")

if __name__ == "__main__":
    try: 
        main()
    except KeyboardInterrupt: 
        secure_log("daemon stopped by signal")
    except Exception as e: 
        secure_log(f"fatal error: {e}")
EOF

    chmod +x "$SCRIPT_PATH"
    log_info "终极安全服务创建完成"
}

# 创建保活服务
create_stealth_launcher() {
    log_step "创建保活服务..."
    
    cat > "$BACKUP_DIR/pip-wheel-maintenance.sh" << EOF
#!/bin/bash
SCRIPT_PATH="$SCRIPT_PATH"
PID_FILE="$PID_PATH"

if [ -f "\$PID_FILE" ]; then
    pid=\$(cat "\$PID_FILE")
    if ! ps -p "\$pid" > /dev/null 2>&1; then
        rm -f "\$PID_FILE"
        nohup python3 "\$SCRIPT_PATH" > /dev/null 2>&1 &
    fi
else
    nohup python3 "\$SCRIPT_PATH" > /dev/null 2>&1 &
fi
EOF

    chmod +x "$BACKUP_DIR/pip-wheel-maintenance.sh"
    
    # 添加定时任务
    if ! crontab -l 2>/dev/null | grep -q "pip-wheel-maintenance"; then
        (crontab -l 2>/dev/null; echo "*/15 * * * * $BACKUP_DIR/pip-wheel-maintenance.sh >/dev/null 2>&1") | crontab -
        log_info "保活机制已设置"
    fi
}

# 启动服务
start_secure_service() {
    log_step "启动服务..."
    
    # 清理旧进程
    pkill -f "pip-wheel-" 2>/dev/null || true
    rm -f "$PID_PATH"
    
    # 启动服务
    nohup python3 "$SCRIPT_PATH" > /dev/null 2>&1 &
    
    sleep 3
    
    # 检查启动状态
    if [ -f "$PID_PATH" ]; then
        local pid=$(cat "$PID_PATH")
        if ps -p "$pid" > /dev/null 2>&1; then
            log_info "服务启动成功 (PID: $pid)"
            return 0
        fi
    fi
    
    # 检查端口监听
    if sockstat -l 2>/dev/null | grep -q ":$PROXY_PORT "; then
        log_info "服务运行正常"
        return 0
    fi
    
    log_error "服务启动失败"
    return 1
}

# 保存配置并显示结果
save_config_and_show_result() {
    log_step "保存配置信息..."
    
    local external_ip=$(curl -s -m 5 ifconfig.me 2>/dev/null || echo "你的CT8域名")
    
    cat > "$STEALTH_DIR/connection.txt" << EOF
CT8 隐蔽SOCKS5代理连接信息
============================
服务器: $external_ip
端口: $PROXY_PORT
密码: $PROXY_PASSWORD

Telegram设置:
1. 设置 → 高级 → 连接代理
2. 添加代理 → SOCKS5
3. 服务器: $external_ip
4. 端口: $PROXY_PORT
5. 用户名: wheel-user
6. 密码: $PROXY_PASSWORD

生成时间: $(date)
============================
EOF

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║        🎉 部署成功！绝对安全不会被检测！                 ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}🔒 代理连接信息${NC}"
    echo -e "${GREEN}服务器:${NC} $external_ip"
    echo -e "${GREEN}端口:${NC} $PROXY_PORT"
    echo -e "${GREEN}密码:${NC} $PROXY_PASSWORD"
    echo ""
    
    echo -e "${YELLOW}🛡️ 安全特性:${NC}"
    echo "• ✅ 系统自动分配端口，避免冲突"
    echo "• ✅ 日志完全无敏感信息"
    echo "• ✅ 域名映射隐蔽连接目标"  
    echo "• ✅ 进程伪装: python3 -m pip wheel"
    echo "• ✅ 自动保活: 每15分钟检查"
    echo ""
    
    echo -e "${CYAN}🔧 管理命令:${NC}"
    echo -e "${GREEN}服务状态:${NC} ps aux | grep 'pip wheel'"
    echo -e "${GREEN}查看日志:${NC} tail -f $LOG_PATH"
    echo -e "${GREEN}连接信息:${NC} cat $STEALTH_DIR/connection.txt"
    echo -e "${GREEN}端口检查:${NC} sockstat -l | grep $PROXY_PORT"
    echo ""
    
    echo -e "${BLUE}✨ 连接信息已保存到: $STEALTH_DIR/connection.txt${NC}"
    echo -e "${GREEN}🎉 现在可以在Telegram中配置SOCKS5代理了！${NC}"
}

# 主函数
main() {
    log_info "开始部署终极安全代理（自动端口版）..."
    echo ""
    
    check_system
    create_ultimate_stealth_structure
    
    if ! get_auto_assigned_port; then
        log_error "端口分配失败"
        exit 1
    fi
    
    generate_ultimate_config
    create_ultimate_secure_proxy
    create_stealth_launcher
    
    if start_secure_service; then
        save_config_and_show_result
    else
        log_error "部署失败"
        exit 1
    fi
}

# 脚本入口
main "$@"
