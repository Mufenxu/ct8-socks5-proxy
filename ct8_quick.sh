#!/bin/bash

# CT8 SOCKS5代理 快速版本
# 直接使用已知可用的端口范围

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
echo "║           CT8 SOCKS5代理 快速部署工具                    ║"
echo "║                                                          ║"
echo "║  🚀 直接使用可用端口，秒速部署                           ║"
echo "║  🔒 隐蔽安全，专为CT8/Serv00优化                         ║"
echo "║  ⚡ 版本: 1.0.5 - Quick                              ║"
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

# 快速查找可用端口
find_available_port_quick() {
    log_step "快速查找可用端口..."
    
    # 测试已知可用的端口范围：64000, 61000, 62000, 63000, 65000
    local test_ports=(64000 61000 62000 63000 65000 60001 60002 60003)
    
    for port in "${test_ports[@]}"; do
        if python3 -c "
import socket
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind(('127.0.0.1', $port))
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
    
    log_error "预设端口都不可用，使用随机端口"
    PROXY_PORT=$((60000 + RANDOM % 5000))
}

# 生成配置参数
generate_config() {
    log_step "生成配置参数..."
    
    # 生成随机密码
    PROXY_PASSWORD="ct8_$(date +%H%M)_$(printf '%04x' $RANDOM)"
    
    log_info "代理端口: $PROXY_PORT"
    log_info "认证密码: $PROXY_PASSWORD"
}

# 创建简化代理脚本
create_simple_proxy() {
    log_step "创建代理服务..."
    
    local script_path="$HOME/socks5_proxy.py"
    
    cat > "$script_path" << EOF
#!/usr/bin/env python3
import socket, threading, struct, hashlib, time, sys, os

HOST, PORT, PASSWORD = '127.0.0.1', $PROXY_PORT, '$PROXY_PASSWORD'

def log(msg):
    print(f"[{time.strftime('%H:%M:%S')}] {msg}")
    with open('/tmp/.proxy.log', 'a') as f: f.write(f"[{time.strftime('%H:%M:%S')}] {msg}\\n")

def auth(s):
    data = s.recv(2)
    if len(data) != 2 or data[0] != 5: return False
    s.recv(data[1]); s.send(b'\\x05\\x02')
    auth = s.recv(2)
    if len(auth) != 2 or auth[0] != 1: return False
    s.recv(auth[1]); plen = s.recv(1)[0]; pwd = s.recv(plen).decode()
    ok = hashlib.md5(PASSWORD.encode()).hexdigest()[:8] == hashlib.md5(pwd.encode()).hexdigest()[:8]
    s.send(b'\\x01\\x00' if ok else b'\\x01\\x01')
    return ok

def req(s):
    r = s.recv(4)
    if len(r) != 4 or r[0] != 5 or r[1] != 1: return None, None
    if r[3] == 1:
        d = s.recv(6); return socket.inet_ntoa(d[:4]), struct.unpack('>H', d[4:6])[0]
    elif r[3] == 3:
        l = s.recv(1)[0]; return s.recv(l).decode(), struct.unpack('>H', s.recv(2))[0]
    else:
        s.send(b'\\x05\\x08\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00'); return None, None

def fwd(src, dst):
    try:
        while True:
            data = src.recv(4096)
            if not data: break
            dst.send(data)
    except: pass
    finally: 
        try: src.close(); dst.close()
        except: pass

def handle(c, a):
    try:
        if not auth(c): return
        addr, port = req(c)
        if not addr: return
        t = socket.socket()
        t.settimeout(30)
        t.connect((addr, port))
        c.send(b'\\x05\\x00\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00')
        log(f"{a} -> {addr}:{port}")
        t1 = threading.Thread(target=fwd, args=(c, t))
        t2 = threading.Thread(target=fwd, args=(t, c))
        t1.daemon = t2.daemon = True
        t1.start(); t2.start(); t1.join(); t2.join()
    except Exception as e: log(f"Error: {e}")
    finally: 
        try: c.close()
        except: pass

def main():
    log(f"SOCKS5 proxy starting on {HOST}:{PORT}")
    s = socket.socket()
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((HOST, PORT))
    s.listen(50)
    log(f"Proxy started successfully on {HOST}:{PORT}")
    with open('/tmp/.proxy.pid', 'w') as f: f.write(str(os.getpid()))
    
    while True:
        c, a = s.accept()
        threading.Thread(target=handle, args=(c, a), daemon=True).start()

if __name__ == "__main__": 
    try: main()
    except KeyboardInterrupt: log("Proxy stopped")
    except Exception as e: log(f"Fatal: {e}")
EOF

    chmod +x "$script_path"
    log_info "代理脚本创建完成"
}

# 启动服务
start_service() {
    log_step "启动代理服务..."
    
    # 清理旧进程
    pkill -f socks5_proxy 2>/dev/null || true
    rm -f /tmp/.proxy.pid /tmp/.proxy.log
    
    # 启动服务
    nohup python3 "$HOME/socks5_proxy.py" > /dev/null 2>&1 &
    
    sleep 2
    
    # 检查是否启动成功
    if [ -f "/tmp/.proxy.pid" ]; then
        local pid=$(cat "/tmp/.proxy.pid")
        if ps -p "$pid" > /dev/null 2>&1; then
            log_info "服务启动成功 (PID: $pid)"
            return 0
        fi
    fi
    
    log_error "服务启动失败"
    return 1
}

# 保存配置并显示结果
save_and_show() {
    log_step "保存配置信息..."
    
    # 获取外网IP
    local external_ip=$(curl -s -m 3 ifconfig.me 2>/dev/null || echo "你的CT8域名")
    
    # 保存配置
    cat > "$HOME/proxy_info.txt" << EOF
🎉 CT8 SOCKS5代理信息
=================
服务器: $external_ip
端口: $PROXY_PORT
用户名: 任意
密码: $PROXY_PASSWORD

Telegram设置:
1. 设置 → 高级 → 连接代理
2. SOCKS5 → 输入上述信息

管理:
  状态: ps aux | grep socks5_proxy
  日志: tail -f /tmp/.proxy.log
  重启: pkill -f socks5_proxy && nohup python3 ~/socks5_proxy.py &
EOF

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                   🎉 部署成功！                         ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}🚀 Telegram代理连接信息${NC}"
    echo -e "${GREEN}服务器:${NC} $external_ip"
    echo -e "${GREEN}端口:${NC} $PROXY_PORT"  
    echo -e "${GREEN}密码:${NC} $PROXY_PASSWORD"
    echo ""
    
    echo -e "${YELLOW}📱 Telegram设置步骤:${NC}"
    echo "1. 设置 → 高级 → 连接代理"
    echo "2. 添加代理 → SOCKS5"
    echo "3. 输入上述信息 → 保存"
    echo ""
    
    echo -e "${BLUE}✨ 配置已保存到: ~/proxy_info.txt${NC}"
    echo -e "${GREEN}🎉 享受你的Telegram代理吧！${NC}"
}

# 主函数
main() {
    log_info "开始快速部署CT8 SOCKS5代理..."
    echo ""
    
    find_available_port_quick
    generate_config
    create_simple_proxy
    
    if start_service; then
        save_and_show
    else
        log_error "部署失败！请手动运行: python3 ~/socks5_proxy.py"
        exit 1
    fi
}

# 脚本入口
main "$@"
