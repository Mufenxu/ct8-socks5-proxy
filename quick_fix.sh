#!/bin/bash

# CT8 SOCKS5代理 快速修复版本
# 直接在服务器上运行，不依赖GitHub

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
echo "║          CT8 SOCKS5代理 快速修复部署工具                 ║"
echo "║                                                          ║"
echo "║  🚀 直接部署，无需GitHub依赖                             ║"
echo "║  🔒 隐蔽安全，专为CT8/Serv00优化                         ║"
echo "║  ⚡ 版本: 1.0.1                                      ║"
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
        if [[ "$OSTYPE" =~ ^freebsd ]]; then
            log_error "FreeBSD系统请使用: pkg install python3"
        else
            log_error "Linux系统请使用: apt update && apt install python3"
        fi
        exit 1
    fi
    
    log_info "系统环境检查完成"
}

# 创建工作目录
setup_directories() {
    log_step "创建工作目录..."
    
    local work_dir="$HOME/.config/systemd"
    mkdir -p "$work_dir"
    
    log_info "工作目录: $work_dir"
}

# 创建核心代理脚本
create_proxy_script() {
    log_step "创建代理服务脚本..."
    
    local script_path="$HOME/.config/systemd/nginx_cache.py"
    
    cat > "$script_path" << 'PYTHON_SCRIPT_EOF'
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
    'cache_port': 8080,
    'auth_token': 'tg_proxy_2024',
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
    
    # 启动服务
    await cache_service.start_cache_service()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
    except Exception as e:
        print(f"nginx-cache: fatal error - {e}")
PYTHON_SCRIPT_EOF

    chmod +x "$script_path"
    log_info "代理脚本创建完成"
}

# 配置参数
configure_proxy() {
    log_step "配置代理参数..."
    
    # 生成随机端口
    local random_port=$((8000 + RANDOM % 1000))
    while netstat -tuln 2>/dev/null | grep -q ":$random_port " || sockstat -l 2>/dev/null | grep -q ":$random_port "; do
        random_port=$((8000 + RANDOM % 1000))
    done
    
    # 生成随机密码
    local random_password="tg_$(date +%m%d)_$(openssl rand -hex 4 2>/dev/null || echo $(date +%s | tail -c 5))"
    
    # 更新配置
    local script_path="$HOME/.config/systemd/nginx_cache.py"
    if [ -f "$script_path" ]; then
        sed -i "s/'cache_port': 8080/'cache_port': $random_port/g" "$script_path"
        sed -i "s/'auth_token': 'tg_proxy_2024'/'auth_token': '$random_password'/g" "$script_path"
        
        log_info "代理端口: $random_port"
        log_info "认证密码: $random_password"
        
        # 保存配置信息
        cat > "$HOME/.config/systemd/config.txt" << EOF
CT8 SOCKS5代理配置信息
========================
安装时间: $(date)
代理端口: $random_port
认证密码: $random_password
配置文件: $script_path
========================
EOF
        
        # 保存连接信息
        local server_ip=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "你的CT8域名")
        cat > "$HOME/ct8_proxy_info.txt" << EOF
CT8 SOCKS5代理连接信息
====================
服务器: $server_ip
端口: $random_port
用户名: 任意
密码: $random_password

安装时间: $(date)
配置文件: $script_path
EOF
        
    else
        log_error "配置文件不存在"
        exit 1
    fi
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
            echo $! > "$LOCK_FILE"
        fi
    else
        echo "[$(date)] 服务未运行，正在启动..." >> "$LOG_FILE"
        nohup python3 "$SCRIPT_PATH" > /dev/null 2>&1 &
        echo $! > "$LOCK_FILE"
    fi
}

check_and_restart
KEEPALIVE_EOF

    chmod +x "$keepalive_script"
    
    # 添加到crontab
    if ! crontab -l 2>/dev/null | grep -q "keepalive.sh"; then
        (crontab -l 2>/dev/null; echo "*/5 * * * * $keepalive_script >/dev/null 2>&1") | crontab -
        log_info "保活机制已设置（每5分钟检查一次）"
    else
        log_warn "保活任务已存在"
    fi
}

# 启动服务
start_service() {
    log_step "启动代理服务..."
    
    local script_path="$HOME/.config/systemd/nginx_cache.py"
    
    # 停止可能存在的旧进程
    pkill -f "nginx-cache" 2>/dev/null || true
    sleep 2
    
    # 启动新服务
    nohup python3 "$script_path" > /dev/null 2>&1 &
    local pid=$!
    echo "$pid" > "/tmp/.nginx_cache.lock"
    
    sleep 3
    if ps -p "$pid" > /dev/null 2>&1; then
        log_info "服务启动成功 (PID: $pid)"
        return 0
    else
        log_error "服务启动失败"
        return 1
    fi
}

# 显示结果
show_result() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                     部署成功！                          ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # 读取配置
    if [ -f "$HOME/ct8_proxy_info.txt" ]; then
        local port=$(grep "端口:" "$HOME/ct8_proxy_info.txt" | cut -d' ' -f2)
        local password=$(grep "密码:" "$HOME/ct8_proxy_info.txt" | cut -d' ' -f2)
        local server_ip=$(grep "服务器:" "$HOME/ct8_proxy_info.txt" | cut -d' ' -f2)
        
        echo -e "${CYAN}=== 连接信息 ===${NC}"
        echo -e "${GREEN}服务器地址:${NC} $server_ip"
        echo -e "${GREEN}SOCKS5端口:${NC} $port"
        echo -e "${GREEN}用户名:${NC} 任意"
        echo -e "${GREEN}密码:${NC} $password"
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
        echo ""
        
        echo -e "${GREEN}连接信息已保存到:${NC} ~/ct8_proxy_info.txt"
    fi
    
    echo ""
    echo -e "${BLUE}CT8 SOCKS5代理部署完成！${NC}"
}

# 主函数
main() {
    log_info "开始快速部署CT8 SOCKS5代理..."
    echo ""
    
    check_system
    setup_directories
    create_proxy_script
    configure_proxy
    create_keepalive
    
    if start_service; then
        show_result
    else
        log_error "部署失败！"
        exit 1
    fi
}

# 脚本入口
main "$@"
