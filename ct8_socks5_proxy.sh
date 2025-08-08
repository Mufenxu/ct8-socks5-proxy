#!/bin/bash

# CT8 最终修正版本 - 确保成功部署

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
echo "║       CT8 隐蔽SOCKS5代理 - 最终修正版本                  ║"
echo "║                                                          ║"
echo "║  🔧 修正端口检测逻辑                                     ║"
echo "║  🛡️ 绝对安全不被检测                                     ║"
echo "║  ✅ Final Fixed Edition                                 ║"
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

# 修正的端口查找逻辑
log_step "查找可用端口..."

PROXY_PORT=""
test_ports=(63001 63101 63201 63301 63401 63501 63601 63701 63801 63901)

for port in "${test_ports[@]}"; do
    log_info "测试端口 $port..."
    
    # 使用更可靠的端口测试方法
    if timeout 3 python3 -c "
import socket
import sys
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.settimeout(2)
    s.bind(('0.0.0.0', $port))
    s.close()
    sys.exit(0)
except Exception as e:
    sys.exit(1)
" 2>/dev/null; then
        PROXY_PORT=$port
        log_info "✅ 找到可用端口: $PROXY_PORT"
        break
    else
        log_info "❌ 端口 $port 不可用"
    fi
done

# 如果预设端口都不行，使用随机查找
if [ -z "$PROXY_PORT" ]; then
    log_step "预设端口不可用，随机查找..."
    
    PROXY_PORT=$(python3 -c "
import socket
import random
import sys

for attempt in range(50):
    port = random.randint(60000, 65535)
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(('0.0.0.0', port))
        s.close()
        print(port)
        sys.exit(0)
    except:
        continue

sys.exit(1)
" 2>/dev/null)

    if [ -z "$PROXY_PORT" ]; then
        log_error "无法找到任何可用端口"
        exit 1
    fi
    
    log_info "✅ 随机找到端口: $PROXY_PORT"
fi

# 生成密码
PROXY_PASSWORD="cache_$(date +%j)_$(printf '%04x' $RANDOM)"
log_info "生成密码: $PROXY_PASSWORD"

# 创建代理脚本
log_step "创建代理服务..."

cat > "$SCRIPT_PATH" << EOF
#!/usr/bin/env python3
"""
Python Package Wheel Cache Service
Multi-protocol package distribution optimization daemon
"""

import socket, threading, struct, hashlib, time, os, random

HOST, PORT, PASSWORD = '0.0.0.0', $PROXY_PORT, '$PROXY_PASSWORD'
LOG_PATH = '$LOG_PATH'
PID_PATH = '$PID_PATH'

def log_safe(msg):
    """安全的日志记录 - 替换敏感词汇"""
    timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
    
    # 替换敏感关键词
    safe_msg = str(msg).lower()
    safe_msg = safe_msg.replace('telegram', 'pypi')
    safe_msg = safe_msg.replace('proxy', 'cache')
    safe_msg = safe_msg.replace('socks', 'wheel')
    safe_msg = safe_msg.replace('auth', 'validate')
    safe_msg = safe_msg.replace('failed', 'miss')
    
    log_line = f"[{timestamp}] wheel-cache: {safe_msg}"
    
    try:
        with open(LOG_PATH, 'a') as f:
            f.write(log_line + '\\n')
            f.flush()
    except: 
        pass

def validate_auth(token):
    """验证认证令牌"""
    try:
        expected = hashlib.sha256(PASSWORD.encode()).hexdigest()[:16]
        provided = hashlib.sha256(token.encode()).hexdigest()[:16]
        return expected == provided
    except:
        return False

def handle_auth(client):
    """处理SOCKS5认证"""
    try:
        # 读取版本和方法数量
        data = client.recv(2)
        if len(data) != 2 or data[0] != 5:
            return False
        
        # 读取认证方法
        nmethods = data[1]
        methods = client.recv(nmethods)
        
        # 发送需要用户名密码认证
        client.send(b'\\x05\\x02')
        
        # 读取认证信息
        auth_data = client.recv(2)
        if len(auth_data) != 2 or auth_data[0] != 1:
            return False
        
        # 读取用户名
        ulen = auth_data[1]
        username = client.recv(ulen)
        
        # 读取密码
        plen_data = client.recv(1)
        if not plen_data:
            return False
        plen = plen_data[0]
        password = client.recv(plen).decode('utf-8', errors='ignore')
        
        # 验证密码
        if validate_auth(password):
            client.send(b'\\x01\\x00')  # 认证成功
            log_safe("cache validation successful")
            return True
        else:
            client.send(b'\\x01\\x01')  # 认证失败
            log_safe("cache validation miss")
            return False
            
    except Exception as e:
        log_safe(f"validation timeout: {e}")
        return False

def parse_request(client):
    """解析SOCKS5请求"""
    try:
        # 读取请求头
        request = client.recv(4)
        if len(request) != 4 or request[0] != 5 or request[1] != 1:
            return None, None
        
        atyp = request[3]  # 地址类型
        
        if atyp == 1:  # IPv4
            addr_data = client.recv(6)
            target_addr = socket.inet_ntoa(addr_data[:4])
            target_port = struct.unpack('>H', addr_data[4:6])[0]
        elif atyp == 3:  # 域名
            addr_len = client.recv(1)[0]
            target_addr = client.recv(addr_len).decode()
            target_port = struct.unpack('>H', client.recv(2))[0]
        else:
            client.send(b'\\x05\\x08\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00')
            return None, None
        
        return target_addr, target_port
        
    except Exception as e:
        log_safe(f"request parse timeout: {e}")
        return None, None

def create_connection(addr, port):
    """建立目标连接"""
    try:
        target_socket = socket.socket()
        target_socket.settimeout(30)
        
        # 添加小延迟模拟缓存查找
        time.sleep(random.uniform(0.1, 0.3))
        
        # 对特殊端口调整超时
        if port in [443, 80, 8080]:
            target_socket.settimeout(20)
        
        target_socket.connect((addr, port))
        return target_socket
        
    except Exception as e:
        # 生成假的域名用于日志
        fake_domain = addr.replace('telegram', 'pypi').replace('api.', 'cache-')
        log_safe(f"upstream timeout: {fake_domain}:{port}")
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
    """处理客户端连接"""
    try:
        # 处理认证
        if not handle_auth(client_socket):
            log_safe(f"cache validation miss from {client_addr[0]}")
            return
        
        # 解析请求
        target_addr, target_port = parse_request(client_socket)
        if not target_addr:
            return
        
        # 建立目标连接
        target_socket = create_connection(target_addr, target_port)
        if not target_socket:
            # 发送连接失败响应
            client_socket.send(b'\\x05\\x05\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00')
            return
        
        # 发送连接成功响应
        client_socket.send(b'\\x05\\x00\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00')
        
        # 记录安全日志
        fake_domain = target_addr.replace('telegram', 'pypi').replace('api.', 'cache-')
        cache_result = random.choice(['hit', 'miss', 'refresh'])
        log_safe(f"cache {cache_result}: {fake_domain}:{target_port}")
        
        # 启动双向数据转发
        t1 = threading.Thread(target=forward_data, args=(client_socket, target_socket))
        t2 = threading.Thread(target=forward_data, args=(target_socket, client_socket))
        t1.daemon = t2.daemon = True
        t1.start()
        t2.start()
        t1.join()
        t2.join()
        
    except Exception as e:
        log_safe(f"client session timeout: {e}")
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
    
    # 记录启动日志
    log_safe(f"wheel cache daemon started on {HOST}:{PORT}")
    log_safe(f"cache directory: /tmp/.pip-wheel-cache")
    log_safe(f"worker threads: 50, upstream timeout: 30s")
    
    # 创建服务器套接字
    server = socket.socket()
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    try:
        server.bind((HOST, PORT))
        server.listen(50)
        log_safe(f"daemon listening on {HOST}:{PORT}")
    except Exception as e:
        log_safe(f"daemon startup failed: {e}")
        return
    
    # 写入PID文件
    try:
        with open(PID_PATH, 'w') as f:
            f.write(str(os.getpid()))
    except:
        pass
    
    # 主服务循环
    while True:
        try:
            client, addr = server.accept()
            threading.Thread(target=handle_client, args=(client, addr), daemon=True).start()
        except Exception as e:
            log_safe(f"accept timeout: {e}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        log_safe("daemon stopped by signal")
    except Exception as e:
        log_safe(f"fatal error: {e}")
EOF

chmod +x "$SCRIPT_PATH"

# 启动服务
log_step "启动服务..."

# 清理旧进程
pkill -f "pip-wheel-" 2>/dev/null || true
sleep 1

# 启动新服务
nohup python3 "$SCRIPT_PATH" > /dev/null 2>&1 &

sleep 3

# 检查启动状态
SERVICE_STARTED=""

if [ -f "$PID_PATH" ]; then
    PID=$(cat "$PID_PATH")
    if ps -p "$PID" > /dev/null 2>&1; then
        log_info "✅ 服务启动成功 (PID: $PID)"
        SERVICE_STARTED="yes"
    fi
fi

if [ -z "$SERVICE_STARTED" ]; then
    if sockstat -l | grep -q ":$PROXY_PORT "; then
        log_info "✅ 服务运行正常"
        SERVICE_STARTED="yes"
    fi
fi

if [ -z "$SERVICE_STARTED" ]; then
    log_error "❌ 服务启动失败"
    echo "故障排除:"
    echo "1. 手动运行: python3 $SCRIPT_PATH"
    echo "2. 查看日志: tail -f $LOG_PATH"
    echo "3. 检查端口: sockstat -l | grep $PROXY_PORT"
    exit 1
fi

# 创建保活脚本
log_step "设置保活机制..."

MAINTENANCE_SCRIPT="$HOME/.local/share/applications/pip-maintenance-${RANDOM_ID}.sh"

cat > "$MAINTENANCE_SCRIPT" << EOF
#!/bin/bash
# Python package wheel cache maintenance script

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

chmod +x "$MAINTENANCE_SCRIPT"

# 添加定时任务
if ! crontab -l 2>/dev/null | grep -q "pip-maintenance-${RANDOM_ID}"; then
    (crontab -l 2>/dev/null; echo "*/15 * * * * $MAINTENANCE_SCRIPT >/dev/null 2>&1") | crontab -
    log_info "✅ 保活机制已设置（每15分钟检查）"
fi

# 获取外部IP
log_step "获取服务器信息..."
EXTERNAL_IP=$(curl -s -m 5 ifconfig.me 2>/dev/null || echo "你的CT8域名")

# 保存连接信息
CONNECTION_FILE="$STEALTH_DIR/connection-${RANDOM_ID}.txt"

cat > "$CONNECTION_FILE" << EOF
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
连接信息: cat $CONNECTION_FILE

服务文件:
- 代理脚本: $SCRIPT_PATH
- 日志文件: $LOG_PATH
- PID文件: $PID_PATH
- 保活脚本: $MAINTENANCE_SCRIPT

生成时间: $(date)
============================
EOF

# 显示成功结果
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
echo "• ✅ 域名混淆: telegram → pypi"
echo "• ✅ 自动保活: 每15分钟检查"
echo "• ✅ 隐蔽路径: ~/.cache/pip/"
echo "• ✅ 随机延迟: 模拟缓存行为"
echo ""

echo -e "${CYAN}🔧 管理命令:${NC}"
echo -e "${GREEN}服务状态:${NC} ps aux | grep 'pip wheel'"
echo -e "${GREEN}查看日志:${NC} tail -f $LOG_PATH"
echo -e "${GREEN}连接信息:${NC} cat $CONNECTION_FILE"
echo -e "${GREEN}端口检查:${NC} sockstat -l | grep $PROXY_PORT"
echo ""

echo -e "${BLUE}✨ 连接信息已保存到: $CONNECTION_FILE${NC}"
echo -e "${GREEN}🎉 现在可以在Telegram中配置SOCKS5代理了！${NC}"

log_info "🎊 部署完成！享受你的隐蔽代理服务吧！"
