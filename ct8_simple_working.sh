#!/bin/bash

# CT8 简化工作版本 - 一定能成功
# 使用最简单可靠的方法

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
echo "║      CT8 隐蔽SOCKS5代理 - 简化可靠版本                   ║"
echo "║                                                          ║"
echo "║  🚀 简化逻辑，确保成功                                   ║"
echo "║  🛡️ 保持安全，避免检测                                   ║"
echo "║  ✅ Simple & Reliable Edition                           ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 生成随机ID
RANDOM_ID=$(date +%s | tail -c 6)

# 文件路径
STEALTH_DIR="$HOME/.cache/pip"
SCRIPT_NAME="pip-wheel-${RANDOM_ID}.py"
SCRIPT_PATH="$STEALTH_DIR/$SCRIPT_NAME"
LOG_PATH="$STEALTH_DIR/wheel-${RANDOM_ID}.log"
PID_PATH="/tmp/.pip-wheel-${RANDOM_ID}.pid"

# 创建目录
mkdir -p "$STEALTH_DIR"

# 简单端口查找
log_step "查找可用端口..."

# 直接尝试一些端口，找到第一个可用的
PROXY_PORT=""
for port in 63001 63101 63201 63301 63401 63501 63601 63701 63801 63901; do
    if python3 -c "
import socket
try:
    s = socket.socket()
    s.bind(('0.0.0.0', $port))
    s.close()
    exit(0)
except:
    exit(1)
" 2>/dev/null; then
        PROXY_PORT=$port
        break
    fi
done

if [ -z "$PROXY_PORT" ]; then
    log_error "未找到可用端口"
    exit 1
fi

log_info "使用端口: $PROXY_PORT"

# 生成密码
PROXY_PASSWORD="cache_$(date +%j)_$(printf '%04x' $RANDOM)"
log_info "生成密码: $PROXY_PASSWORD"

# 创建代理脚本
log_step "创建代理服务..."

cat > "$SCRIPT_PATH" << EOF
#!/usr/bin/env python3
import socket, threading, struct, hashlib, time, os

HOST, PORT, PASSWORD = '0.0.0.0', $PROXY_PORT, '$PROXY_PASSWORD'
LOG_PATH = '$LOG_PATH'
PID_PATH = '$PID_PATH'

def log_safe(msg):
    timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
    # 替换敏感词
    safe_msg = msg.replace('telegram', 'pypi').replace('proxy', 'cache').replace('socks', 'wheel')
    log_line = f"[{timestamp}] wheel-cache: {safe_msg}"
    try:
        with open(LOG_PATH, 'a') as f:
            f.write(log_line + '\\n')
    except: pass

def validate_auth(token):
    expected = hashlib.sha256(PASSWORD.encode()).hexdigest()[:16]
    provided = hashlib.sha256(token.encode()).hexdigest()[:16]
    return expected == provided

def handle_auth(client):
    try:
        data = client.recv(2)
        if len(data) != 2 or data[0] != 5: return False
        
        nmethods = data[1]
        client.recv(nmethods)
        client.send(b'\\x05\\x02')
        
        auth = client.recv(2)
        if len(auth) != 2 or auth[0] != 1: return False
        
        ulen = auth[1]
        client.recv(ulen)
        
        plen = client.recv(1)[0]
        password = client.recv(plen).decode('utf-8', errors='ignore')
        
        if validate_auth(password):
            client.send(b'\\x01\\x00')
            log_safe("cache validation successful")
            return True
        else:
            client.send(b'\\x01\\x01')
            return False
    except:
        return False

def parse_request(client):
    try:
        request = client.recv(4)
        if len(request) != 4 or request[0] != 5 or request[1] != 1:
            return None, None
        
        atyp = request[3]
        if atyp == 1:  # IPv4
            addr_data = client.recv(6)
            addr = socket.inet_ntoa(addr_data[:4])
            port = struct.unpack('>H', addr_data[4:6])[0]
        elif atyp == 3:  # Domain
            addr_len = client.recv(1)[0]
            addr = client.recv(addr_len).decode()
            port = struct.unpack('>H', client.recv(2))[0]
        else:
            return None, None
        
        return addr, port
    except:
        return None, None

def forward_data(source, destination):
    try:
        while True:
            data = source.recv(4096)
            if not data: break
            destination.send(data)
    except: pass
    finally:
        try: source.close(); destination.close()
        except: pass

def handle_client(client, addr):
    try:
        if not handle_auth(client):
            log_safe(f"cache validation failed from {addr[0]}")
            return
        
        target_addr, target_port = parse_request(client)
        if not target_addr: return
        
        try:
            target = socket.socket()
            target.settimeout(30)
            target.connect((target_addr, target_port))
        except:
            client.send(b'\\x05\\x05\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00')
            return
        
        client.send(b'\\x05\\x00\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00')
        
        # 记录安全日志
        fake_domain = target_addr.replace('telegram', 'pypi').replace('api.', 'cache-')
        log_safe(f"cache hit: {fake_domain}:{target_port}")
        
        t1 = threading.Thread(target=forward_data, args=(client, target))
        t2 = threading.Thread(target=forward_data, args=(target, client))
        t1.daemon = t2.daemon = True
        t1.start(); t2.start()
        t1.join(); t2.join()
        
    except:
        log_safe("client session timeout")
    finally:
        try: client.close()
        except: pass

def main():
    try:
        import setproctitle
        setproctitle.setproctitle('python3 -m pip wheel')
    except: pass
    
    log_safe(f"wheel cache daemon started on {HOST}:{PORT}")
    
    server = socket.socket()
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((HOST, PORT))
    server.listen(50)
    
    with open(PID_PATH, 'w') as f:
        f.write(str(os.getpid()))
    
    log_safe(f"daemon listening on {HOST}:{PORT}")
    
    while True:
        try:
            client, addr = server.accept()
            threading.Thread(target=handle_client, args=(client, addr), daemon=True).start()
        except:
            log_safe("accept timeout")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        log_safe("daemon stopped")
    except Exception as e:
        log_safe(f"fatal error: {e}")
EOF

chmod +x "$SCRIPT_PATH"

# 启动服务
log_step "启动服务..."

# 清理旧进程
pkill -f "pip-wheel-" 2>/dev/null || true

# 启动新服务
nohup python3 "$SCRIPT_PATH" > /dev/null 2>&1 &

sleep 3

# 检查启动状态
if [ -f "$PID_PATH" ]; then
    PID=$(cat "$PID_PATH")
    if ps -p "$PID" > /dev/null 2>&1; then
        log_info "服务启动成功 (PID: $PID)"
        SERVICE_STARTED=true
    fi
fi

if [ -z "$SERVICE_STARTED" ]; then
    if sockstat -l | grep -q ":$PROXY_PORT "; then
        log_info "服务运行正常"
        SERVICE_STARTED=true
    fi
fi

if [ -z "$SERVICE_STARTED" ]; then
    log_error "服务启动失败"
    exit 1
fi

# 创建保活脚本
cat > "$HOME/.local/share/applications/pip-maintenance-${RANDOM_ID}.sh" << EOF
#!/bin/bash
if [ -f "$PID_PATH" ]; then
    pid=\$(cat "$PID_PATH")
    if ! ps -p "\$pid" > /dev/null 2>&1; then
        rm -f "$PID_PATH"
        nohup python3 "$SCRIPT_PATH" > /dev/null 2>&1 &
    fi
else
    nohup python3 "$SCRIPT_PATH" > /dev/null 2>&1 &
fi
EOF

chmod +x "$HOME/.local/share/applications/pip-maintenance-${RANDOM_ID}.sh"

# 添加定时任务
if ! crontab -l 2>/dev/null | grep -q "pip-maintenance-${RANDOM_ID}"; then
    (crontab -l 2>/dev/null; echo "*/20 * * * * $HOME/.local/share/applications/pip-maintenance-${RANDOM_ID}.sh >/dev/null 2>&1") | crontab -
fi

# 获取外部IP
EXTERNAL_IP=$(curl -s -m 5 ifconfig.me 2>/dev/null || echo "你的CT8域名")

# 保存连接信息
cat > "$STEALTH_DIR/connection.txt" << EOF
CT8 隐蔽SOCKS5代理连接信息
============================
服务器: $EXTERNAL_IP
端口: $PROXY_PORT
密码: $PROXY_PASSWORD

Telegram设置:
1. 设置 → 高级 → 连接代理
2. 添加代理 → SOCKS5
3. 服务器: $EXTERNAL_IP
4. 端口: $PROXY_PORT
5. 用户名: wheel-user
6. 密码: $PROXY_PASSWORD

管理命令:
查看状态: ps aux | grep 'pip wheel'
查看日志: tail -f $LOG_PATH
检查端口: sockstat -l | grep $PROXY_PORT

生成时间: $(date)
============================
EOF

# 显示结果
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                🎉 部署成功！                             ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}🔒 SOCKS5代理连接信息${NC}"
echo -e "${GREEN}服务器:${NC} $EXTERNAL_IP"
echo -e "${GREEN}端口:${NC} $PROXY_PORT"
echo -e "${GREEN}密码:${NC} $PROXY_PASSWORD"
echo ""

echo -e "${YELLOW}🛡️ 安全特性:${NC}"
echo "• ✅ 进程伪装: python3 -m pip wheel"
echo "• ✅ 日志混淆: 所有敏感词已替换"
echo "• ✅ 自动保活: 每20分钟检查"
echo "• ✅ 隐蔽路径: ~/.cache/pip/"
echo ""

echo -e "${BLUE}✨ 连接信息已保存到: $STEALTH_DIR/connection.txt${NC}"
echo -e "${GREEN}🎉 现在可以在Telegram中配置SOCKS5代理了！${NC}"

log_info "部署完成"
