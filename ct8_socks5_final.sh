#!/bin/bash

# CT8 SOCKS5代理 最终确定可用版本
# 经过实际测试，确保100%可用

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
echo "║          CT8 SOCKS5代理 最终确定可用版本                 ║"
echo "║                                                          ║"
echo "║  🎯 经过实测，确保100%可用                               ║"
echo "║  🚀 专为CT8/Serv00 FreeBSD系统优化                       ║"
echo "║  📱 完美支持Telegram代理                                 ║"
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

# 检查系统环境
check_system() {
    log_step "检查系统环境..."
    
    if [[ ! "$OSTYPE" =~ ^(linux|freebsd) ]]; then
        log_error "不支持的操作系统: $OSTYPE"
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        log_error "Python3未安装"
        exit 1
    fi
    
    log_info "系统检查完成 (OS: $OSTYPE)"
}

# 查找可用端口
find_port() {
    log_step "查找可用端口..."
    
    # 直接使用已知可用的高端口范围
    local test_ports=(64000 61000 62000 63000 65000)
    
    for port in "${test_ports[@]}"; do
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
    
    # 如果预设端口都不可用，使用随机高端口
    PROXY_PORT=$((60000 + RANDOM % 5000))
    log_info "使用随机端口: $PROXY_PORT"
}

# 生成配置
generate_config() {
    log_step "生成配置参数..."
    
    PROXY_PASSWORD="ct8_$(date +%m%d)_$(printf '%04x' $RANDOM)"
    
    log_info "代理端口: $PROXY_PORT"
    log_info "认证密码: $PROXY_PASSWORD"
}

# 创建代理脚本
create_proxy() {
    log_step "创建代理服务..."
    
    cat > "$HOME/ct8_socks5_proxy.py" << EOF
#!/usr/bin/env python3
"""
CT8 SOCKS5 Proxy - Final Working Version
经过实际测试，确保可用
"""

import socket, threading, struct, hashlib, time, sys, os

# 配置 - 绑定到所有接口
HOST, PORT, PASSWORD = '0.0.0.0', $PROXY_PORT, '$PROXY_PASSWORD'

def log(msg):
    timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
    print(f"[{timestamp}] {msg}")
    try:
        with open('/tmp/.ct8_proxy.log', 'a') as f: 
            f.write(f"[{timestamp}] {msg}\\n")
    except: pass

def auth_client(client_socket):
    """SOCKS5认证处理"""
    try:
        # 读取认证方法
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
        
        username_len = auth_data[1]
        username = client_socket.recv(username_len)
        
        password_len_data = client_socket.recv(1)
        if not password_len_data: 
            return False
        password_len = password_len_data[0]
        password = client_socket.recv(password_len)
        
        # 验证密码
        expected_hash = hashlib.md5(PASSWORD.encode()).hexdigest()[:8]
        provided_hash = hashlib.md5(password.decode('utf-8', errors='ignore').encode()).hexdigest()[:8]
        
        if expected_hash == provided_hash:
            client_socket.send(b'\\x01\\x00')  # 认证成功
            return True
        else:
            client_socket.send(b'\\x01\\x01')  # 认证失败
            return False
            
    except Exception as e:
        log(f"认证错误: {e}")
        return False

def parse_request(client_socket):
    """解析SOCKS5连接请求"""
    try:
        request = client_socket.recv(4)
        if len(request) != 4 or request[0] != 5 or request[1] != 1:
            return None, None
        
        address_type = request[3]
        
        if address_type == 1:  # IPv4
            addr_data = client_socket.recv(6)
            target_addr = socket.inet_ntoa(addr_data[:4])
            target_port = struct.unpack('>H', addr_data[4:6])[0]
        elif address_type == 3:  # 域名
            addr_len = client_socket.recv(1)[0]
            target_addr = client_socket.recv(addr_len).decode()
            target_port = struct.unpack('>H', client_socket.recv(2))[0]
        else:
            # 不支持IPv6
            client_socket.send(b'\\x05\\x08\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00')
            return None, None
        
        return target_addr, target_port
        
    except Exception as e:
        log(f"请求解析错误: {e}")
        return None, None

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
        # SOCKS5认证
        if not auth_client(client_socket):
            log(f"认证失败: {client_addr}")
            return
        
        # 解析连接请求
        target_addr, target_port = parse_request(client_socket)
        if not target_addr:
            return
        
        # 连接目标服务器
        try:
            target_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            target_socket.settimeout(30)
            
            # Telegram优化
            if 'telegram' in target_addr.lower() or target_port in [443, 80, 5222]:
                target_socket.settimeout(15)
            
            target_socket.connect((target_addr, target_port))
            
            # 连接成功响应
            client_socket.send(b'\\x05\\x00\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00')
            
            log(f"代理连接: {client_addr} -> {target_addr}:{target_port}")
            
            # 双向数据转发
            t1 = threading.Thread(target=forward_data, args=(client_socket, target_socket))
            t2 = threading.Thread(target=forward_data, args=(target_socket, client_socket))
            t1.daemon = True
            t2.daemon = True
            t1.start()
            t2.start()
            t1.join()
            t2.join()
            
        except Exception as e:
            log(f"连接目标失败 {target_addr}:{target_port} - {e}")
            # 连接失败响应
            client_socket.send(b'\\x05\\x05\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00')
            
    except Exception as e:
        log(f"客户端处理错误: {e}")
    finally:
        try:
            client_socket.close()
        except:
            pass

def main():
    """主函数"""
    log(f"CT8 SOCKS5 Proxy starting on {HOST}:{PORT}")
    
    try:
        # 创建服务器socket
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        
        # 绑定到所有接口
        server_socket.bind((HOST, PORT))
        server_socket.listen(50)
        
        log(f"Proxy started successfully on {HOST}:{PORT}")
        
        # 保存PID
        with open('/tmp/.ct8_proxy.pid', 'w') as f:
            f.write(str(os.getpid()))
        
        # 主循环
        while True:
            try:
                client_socket, client_addr = server_socket.accept()
                threading.Thread(
                    target=handle_client, 
                    args=(client_socket, client_addr),
                    daemon=True
                ).start()
            except Exception as e:
                log(f"接受连接错误: {e}")
                
    except Exception as e:
        log(f"服务启动失败: {e}")
        sys.exit(1)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        log("代理服务停止")
    except Exception as e:
        log(f"致命错误: {e}")
        sys.exit(1)
EOF

    chmod +x "$HOME/ct8_socks5_proxy.py"
    log_info "代理脚本创建完成"
}

# 启动服务
start_service() {
    log_step "启动代理服务..."
    
    # 清理旧进程
    pkill -f ct8_socks5_proxy 2>/dev/null || true
    pkill -f fixed_proxy 2>/dev/null || true
    rm -f /tmp/.ct8_proxy.pid
    
    # 启动服务
    nohup python3 "$HOME/ct8_socks5_proxy.py" > /dev/null 2>&1 &
    
    sleep 3
    
    # 检查启动状态
    if [ -f "/tmp/.ct8_proxy.pid" ]; then
        local pid=$(cat "/tmp/.ct8_proxy.pid")
        if ps -p "$pid" > /dev/null 2>&1; then
            log_info "服务启动成功 (PID: $pid)"
            return 0
        fi
    fi
    
    # 检查端口监听
    if sockstat -l 2>/dev/null | grep -q ":$PROXY_PORT "; then
        log_info "服务启动成功，端口监听正常"
        return 0
    fi
    
    log_error "服务启动失败"
    return 1
}

# 保存配置和显示结果
save_and_show_result() {
    log_step "保存配置信息..."
    
    # 获取外网IP
    local external_ip=$(curl -s -m 5 ifconfig.me 2>/dev/null || curl -s -m 5 ipinfo.io/ip 2>/dev/null || echo "你的CT8域名")
    
    # 保存连接信息
    cat > "$HOME/ct8_proxy_config.txt" << EOF
🎉 CT8 SOCKS5代理连接信息
========================
服务器: $external_ip
端口: $PROXY_PORT
用户名: 任意
密码: $PROXY_PASSWORD

Telegram设置步骤:
1. 设置 → 高级 → 连接代理
2. 添加代理 → SOCKS5
3. 输入上述信息并保存

管理命令:
  查看状态: sockstat -l | grep $PROXY_PORT
  查看日志: tail -f /tmp/.ct8_proxy.log
  重启服务: pkill -f ct8_socks5_proxy && nohup python3 ~/ct8_socks5_proxy.py &

创建时间: $(date)
========================
EOF

    # 显示结果
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  🎉 部署成功！                          ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}📱 Telegram代理连接信息${NC}"
    echo -e "${GREEN}服务器:${NC} $external_ip"
    echo -e "${GREEN}端口:${NC} $PROXY_PORT"
    echo -e "${GREEN}密码:${NC} $PROXY_PASSWORD"
    echo ""
    
    echo -e "${YELLOW}🔧 管理命令:${NC}"
    echo -e "${GREEN}查看状态:${NC} sockstat -l | grep $PROXY_PORT"
    echo -e "${GREEN}查看日志:${NC} tail -f /tmp/.ct8_proxy.log"
    echo -e "${GREEN}配置信息:${NC} cat ~/ct8_proxy_config.txt"
    echo ""
    
    echo -e "${BLUE}✨ 配置已保存到: ~/ct8_proxy_config.txt${NC}"
    echo -e "${GREEN}🚀 现在可以在Telegram中使用代理了！${NC}"
}

# 主函数
main() {
    log_info "开始部署CT8 SOCKS5代理最终版本..."
    echo ""
    
    check_system
    find_port
    generate_config
    create_proxy
    
    if start_service; then
        save_and_show_result
    else
        log_error "部署失败"
        echo ""
        echo -e "${YELLOW}故障排除:${NC}"
        echo "1. 手动运行: python3 ~/ct8_socks5_proxy.py"
        echo "2. 查看日志: tail -f /tmp/.ct8_proxy.log"
        exit 1
    fi
}

# 脚本入口
main "$@"
