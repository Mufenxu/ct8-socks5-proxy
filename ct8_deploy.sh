#!/bin/bash

# CT8专用SOCKS5代理一键部署脚本
# 隐蔽性和安全性优化

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
PROXY_PORT=${PROXY_PORT:-8080}
PROXY_PASSWORD=${PROXY_PASSWORD:-"tg_proxy_$(date +%m%d)"}
WORK_DIR="$HOME/.config/systemd"
FAKE_NAME="nginx-cache"
PYTHON_SCRIPT="$WORK_DIR/nginx_cache.py"
KEEPALIVE_SCRIPT="$WORK_DIR/keepalive.sh"
LOG_FILE="/tmp/.web_cache.log"

# 函数定义
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查环境
check_environment() {
    log_info "检查CT8环境..."
    
    # 检查Python
    if ! command -v python3 &> /dev/null; then
        log_error "Python3未安装"
        exit 1
    fi
    
    # 检查端口是否被占用
    if netstat -tuln 2>/dev/null | grep -q ":$PROXY_PORT "; then
        log_warn "端口 $PROXY_PORT 已被占用，尝试使用其他端口"
        PROXY_PORT=$((PROXY_PORT + 1))
    fi
    
    # 创建工作目录
    mkdir -p "$WORK_DIR"
    
    log_info "环境检查完成"
}

# 生成伪装的Python脚本
create_disguised_script() {
    log_info "创建伪装脚本..."
    
    # 修改原脚本，添加更多伪装
    cat > "$PYTHON_SCRIPT" << 'PYTHON_EOF'
#!/usr/bin/env python3
"""
Nginx Cache Management System
Version: 2.1.3
"""

import asyncio
import socket
import struct
import logging
import os
import sys
import signal
import time
import random
import hashlib
import json
from datetime import datetime

# 伪装的配置文件
CACHE_CONFIG = {
    'bind_address': '0.0.0.0',
    'cache_port': PROXY_PORT_PLACEHOLDER,
    'auth_token': 'PROXY_PASSWORD_PLACEHOLDER',
    'allowed_clients': [],
    'max_cache_size': 50,
    'cache_timeout': 300,
    'log_level': 30,
    'service_name': 'nginx-cache-daemon',
}

class NginxCacheProxy:
    """Nginx缓存代理服务"""
    
    def __init__(self):
        self.server = None
        self.active_connections = set()
        self.start_time = time.time()
        self.cache_stats = {'hits': 0, 'misses': 0, 'errors': 0}
        self.setup_logging()
        
    def setup_logging(self):
        """设置系统日志"""
        log_format = '%(asctime)s [%(levelname)s] nginx-cache: %(message)s'
        logging.basicConfig(
            level=CACHE_CONFIG['log_level'],
            format=log_format,
            handlers=[
                logging.FileHandler('/tmp/.nginx_cache.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger('nginx-cache')

    def validate_client(self, client_ip, auth_data):
        """验证客户端访问权限"""
        if CACHE_CONFIG['allowed_clients'] and client_ip not in CACHE_CONFIG['allowed_clients']:
            return False
        
        # Token验证
        expected_token = hashlib.md5(CACHE_CONFIG['auth_token'].encode()).hexdigest()[:8]
        provided_token = hashlib.md5(auth_data.encode()).hexdigest()[:8]
        return expected_token == provided_token

    async def handle_cache_auth(self, reader, writer):
        """处理缓存认证协议"""
        try:
            # 读取协议头
            protocol_data = await reader.read(2)
            if len(protocol_data) != 2 or protocol_data[0] != 5:
                return False
                
            method_count = protocol_data[1]
            methods = await reader.read(method_count)
            
            # 要求认证
            writer.write(b'\x05\x02')
            await writer.drain()
            
            # 读取认证信息
            auth_header = await reader.read(2)
            if len(auth_header) != 2 or auth_header[0] != 1:
                return False
                
            username_len = auth_header[1]
            username = await reader.read(username_len)
            
            password_len_data = await reader.read(1)
            if not password_len_data:
                return False
            password_len = password_len_data[0]
            password = await reader.read(password_len)
            
            # 验证缓存访问权限
            client_ip = writer.get_extra_info('peername')[0]
            if self.validate_client(client_ip, password.decode('utf-8', errors='ignore')):
                writer.write(b'\x01\x00')
                await writer.drain()
                self.cache_stats['hits'] += 1
                return True
            else:
                writer.write(b'\x01\x01')
                await writer.drain()
                self.cache_stats['misses'] += 1
                return False
                
        except Exception as e:
            self.logger.error(f"Cache auth error: {e}")
            self.cache_stats['errors'] += 1
            return False

    async def parse_cache_request(self, reader, writer):
        """解析缓存请求"""
        try:
            request_header = await reader.read(4)
            if len(request_header) != 4 or request_header[0] != 5 or request_header[1] != 1:
                return None, None
                
            address_type = request_header[3]
            
            # 解析目标地址
            if address_type == 1:  # IPv4
                addr_data = await reader.read(6)
                target_addr = socket.inet_ntoa(addr_data[:4])
                target_port = struct.unpack('>H', addr_data[4:6])[0]
            elif address_type == 3:  # Domain
                addr_len = (await reader.read(1))[0]
                target_addr = (await reader.read(addr_len)).decode()
                target_port = struct.unpack('>H', await reader.read(2))[0]
            else:
                # 不支持IPv6缓存
                writer.write(b'\x05\x08\x00\x01\x00\x00\x00\x00\x00\x00')
                await writer.drain()
                return None, None
                
            return target_addr, target_port
            
        except Exception as e:
            self.logger.error(f"Request parsing error: {e}")
            return None, None

    async def establish_upstream_connection(self, addr, port):
        """建立上游连接"""
        try:
            # 特殊优化Telegram服务器连接
            connection_timeout = 15 if 'telegram' in addr.lower() or port in [443, 80, 5222, 25, 143] else CACHE_CONFIG['cache_timeout']
            
            upstream_reader, upstream_writer = await asyncio.wait_for(
                asyncio.open_connection(addr, port),
                timeout=connection_timeout
            )
            return upstream_reader, upstream_writer
        except Exception as e:
            self.logger.error(f"Upstream connection failed {addr}:{port} - {e}")
            return None, None

    async def relay_data_stream(self, source_reader, dest_writer, direction=""):
        """数据流中继"""
        try:
            total_bytes = 0
            while True:
                data_chunk = await source_reader.read(8192)
                if not data_chunk:
                    break
                dest_writer.write(data_chunk)
                await dest_writer.drain()
                total_bytes += len(data_chunk)
                
            self.logger.debug(f"Data relay completed {direction}: {total_bytes} bytes")
        except Exception as e:
            self.logger.debug(f"Data relay error {direction}: {e}")
        finally:
            try:
                dest_writer.close()
                await dest_writer.wait_closed()
            except:
                pass

    async def handle_cache_client(self, reader, writer):
        """处理缓存客户端请求"""
        client_endpoint = writer.get_extra_info('peername')
        self.active_connections.add(writer)
        
        try:
            # 缓存认证流程
            if not await self.handle_cache_auth(reader, writer):
                self.logger.warning(f"Cache auth failed: {client_endpoint}")
                return
                
            # 解析缓存请求
            target_addr, target_port = await self.parse_cache_request(reader, writer)
            if not target_addr:
                return
                
            # 建立上游连接
            upstream_reader, upstream_writer = await self.establish_upstream_connection(target_addr, target_port)
            if not upstream_reader:
                # 连接失败响应
                writer.write(b'\x05\x05\x00\x01\x00\x00\x00\x00\x00\x00')
                await writer.drain()
                return
                
            # 连接成功响应
            writer.write(b'\x05\x00\x00\x01\x00\x00\x00\x00\x00\x00')
            await writer.drain()
            
            # 开始双向数据中继
            self.logger.info(f"Cache proxy: {client_endpoint} -> {target_addr}:{target_port}")
            
            await asyncio.gather(
                self.relay_data_stream(reader, upstream_writer, "downstream"),
                self.relay_data_stream(upstream_reader, writer, "upstream"),
                return_exceptions=True
            )
            
        except Exception as e:
            self.logger.error(f"Client handling error: {e}")
            self.cache_stats['errors'] += 1
        finally:
            self.active_connections.discard(writer)
            try:
                writer.close()
                await writer.wait_closed()
            except:
                pass

    async def start_cache_service(self):
        """启动缓存服务"""
        try:
            self.server = await asyncio.start_server(
                self.handle_cache_client,
                CACHE_CONFIG['bind_address'],
                CACHE_CONFIG['cache_port'],
                limit=8192
            )
            
            service_addr = self.server.sockets[0].getsockname()
            self.logger.info(f"Nginx cache service started: {service_addr[0]}:{service_addr[1]}")
            
            # 输出启动信息（伪装格式）
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] nginx-cache: service started on {service_addr[0]}:{service_addr[1]}")
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] nginx-cache: cache size limit {CACHE_CONFIG['max_cache_size']}MB")
            
            async with self.server:
                await self.server.serve_forever()
                
        except Exception as e:
            self.logger.error(f"Service startup failed: {e}")
            print(f"nginx-cache: startup error - {e}")

    async def shutdown_service(self):
        """关闭缓存服务"""
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] nginx-cache: shutting down...")
        
        if self.server:
            self.server.close()
            await self.server.wait_closed()
            
        # 关闭所有活动连接
        for connection in list(self.active_connections):
            try:
                connection.close()
                await connection.wait_closed()
            except:
                pass
                
        # 输出统计信息
        uptime = int(time.time() - self.start_time)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] nginx-cache: service stopped")
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] nginx-cache: uptime {uptime}s, hits {self.cache_stats['hits']}, misses {self.cache_stats['misses']}")

def signal_handler(signum, frame):
    """系统信号处理"""
    print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] nginx-cache: received signal {signum}")
    asyncio.create_task(cache_service.shutdown_service())

def update_process_title():
    """更新进程标题"""
    try:
        import setproctitle
        setproctitle.setproctitle(CACHE_CONFIG['service_name'])
    except ImportError:
        pass

async def main():
    """主服务函数"""
    global cache_service
    
    # 更新进程标题
    update_process_title()
    
    # 注册信号处理器
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    cache_service = NginxCacheProxy()
    
    # 定时服务重启（24小时）
    async def schedule_restart():
        await asyncio.sleep(24 * 3600)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] nginx-cache: scheduled restart")
        await cache_service.shutdown_service()
        os.execv(sys.executable, ['python3'] + sys.argv)
    
    # 启动服务和定时任务
    await asyncio.gather(
        cache_service.start_cache_service(),
        schedule_restart(),
        return_exceptions=True
    )

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
    except Exception as e:
        print(f"nginx-cache: fatal error - {e}")
PYTHON_EOF

    # 替换配置变量
    sed -i "s/PROXY_PORT_PLACEHOLDER/$PROXY_PORT/g" "$PYTHON_SCRIPT"
    sed -i "s/PROXY_PASSWORD_PLACEHOLDER/$PROXY_PASSWORD/g" "$PYTHON_SCRIPT"
    
    chmod +x "$PYTHON_SCRIPT"
    log_info "伪装脚本创建完成"
}

# 创建保活脚本
create_keepalive_script() {
    log_info "创建保活监控脚本..."
    
    cat > "$KEEPALIVE_SCRIPT" << 'KEEPALIVE_EOF'
#!/bin/bash

# Nginx Cache Service 保活脚本
# 伪装为系统维护脚本

SCRIPT_PATH="PYTHON_SCRIPT_PLACEHOLDER"
LOG_FILE="/tmp/.nginx_maintenance.log"
LOCK_FILE="/tmp/.nginx_cache.lock"
MAX_RESTART=5
RESTART_COUNT=0

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] nginx-maintenance: $1" | tee -a "$LOG_FILE"
}

check_service_status() {
    if [ -f "$LOCK_FILE" ]; then
        local pid=$(cat "$LOCK_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0  # 服务运行中
        else
            rm -f "$LOCK_FILE"
            return 1  # 服务已停止
        fi
    else
        return 1  # 锁文件不存在
    fi
}

start_service() {
    if check_service_status; then
        return 0  # 服务已运行
    fi
    
    log_message "starting cache service..."
    nohup python3 "$SCRIPT_PATH" > /dev/null 2>&1 &
    local service_pid=$!
    echo "$service_pid" > "$LOCK_FILE"
    
    sleep 3
    if ps -p "$service_pid" > /dev/null 2>&1; then
        log_message "service started successfully (PID: $service_pid)"
        RESTART_COUNT=0
        return 0
    else
        log_message "service startup failed"
        rm -f "$LOCK_FILE"
        return 1
    fi
}

# 主监控循环
while true; do
    if ! check_service_status; then
        if [ $RESTART_COUNT -lt $MAX_RESTART ]; then
            log_message "service not running, attempting restart ($((RESTART_COUNT + 1))/$MAX_RESTART)"
            if start_service; then
                log_message "service restarted successfully"
            else
                RESTART_COUNT=$((RESTART_COUNT + 1))
                log_message "restart attempt failed ($RESTART_COUNT/$MAX_RESTART)"
                if [ $RESTART_COUNT -ge $MAX_RESTART ]; then
                    log_message "max restart attempts reached, stopping monitoring"
                    break
                fi
            fi
        fi
    fi
    
    # 每60秒检查一次
    sleep 60
done
KEEPALIVE_EOF

    # 替换路径变量
    sed -i "s|PYTHON_SCRIPT_PLACEHOLDER|$PYTHON_SCRIPT|g" "$KEEPALIVE_SCRIPT"
    chmod +x "$KEEPALIVE_SCRIPT"
    
    log_info "保活脚本创建完成"
}

# 添加到crontab
setup_crontab() {
    log_info "设置定时任务..."
    
    # 检查是否已存在
    if crontab -l 2>/dev/null | grep -q "nginx-cache"; then
        log_warn "定时任务已存在，跳过设置"
        return
    fi
    
    # 添加到crontab
    (crontab -l 2>/dev/null; echo "*/5 * * * * $KEEPALIVE_SCRIPT >/dev/null 2>&1") | crontab -
    
    log_info "定时任务设置完成（每5分钟检查一次）"
}

# 启动服务
start_proxy_service() {
    log_info "启动SOCKS5代理服务..."
    
    # 先停止可能存在的旧进程
    pkill -f "nginx-cache" 2>/dev/null || true
    sleep 2
    
    # 启动新服务
    nohup python3 "$PYTHON_SCRIPT" > /dev/null 2>&1 &
    local pid=$!
    echo "$pid" > "/tmp/.nginx_cache.lock"
    
    sleep 3
    if ps -p "$pid" > /dev/null 2>&1; then
        log_info "服务启动成功 (PID: $pid)"
        log_info "监听端口: $PROXY_PORT"
        log_info "认证密码: $PROXY_PASSWORD"
        return 0
    else
        log_error "服务启动失败"
        return 1
    fi
}

# 显示连接信息
show_connection_info() {
    echo ""
    echo -e "${BLUE}=== CT8 SOCKS5代理连接信息 ===${NC}"
    echo -e "${GREEN}服务器地址:${NC} $(hostname -I | awk '{print $1}' 2>/dev/null || echo '你的CT8域名')"
    echo -e "${GREEN}SOCKS5端口:${NC} $PROXY_PORT"
    echo -e "${GREEN}认证密码:${NC} $PROXY_PASSWORD"
    echo -e "${GREEN}协议类型:${NC} SOCKS5 (用户名密码认证)"
    echo ""
    echo -e "${YELLOW}Telegram代理设置:${NC}"
    echo "1. 打开Telegram设置 > 高级 > 代理"
    echo "2. 添加代理 > SOCKS5"
    echo "3. 输入上述服务器信息"
    echo ""
    echo -e "${BLUE}==================================${NC}"
}

# 主函数
main() {
    echo -e "${BLUE}CT8专用SOCKS5代理部署工具${NC}"
    echo "=================================="
    
    check_environment
    create_disguised_script
    create_keepalive_script
    setup_crontab
    
    if start_proxy_service; then
        show_connection_info
        log_info "部署完成！代理已在后台运行"
        log_info "日志文件: $LOG_FILE"
        log_info "管理脚本: $KEEPALIVE_SCRIPT"
    else
        log_error "部署失败！"
        exit 1
    fi
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
