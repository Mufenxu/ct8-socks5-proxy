#!/usr/bin/env python3
"""
CT8专用隐蔽SOCKS5代理
- 适配CT8环境限制
- 流量伪装和进程隐藏
- 专为Telegram优化
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
from datetime import datetime

# 配置参数
CONFIG = {
    'HOST': '0.0.0.0',
    'PORT': 8080,  # 使用常见端口避免检测
    'PASSWORD': 'tg_proxy_2024',  # 修改为你的密码
    'ALLOWED_IPS': ['127.0.0.1'],  # 允许的IP列表，留空允许所有
    'MAX_CONNECTIONS': 50,
    'TIMEOUT': 300,
    'LOG_LEVEL': logging.WARNING,  # 减少日志输出
    'FAKE_SERVER_NAME': 'nginx',  # 伪装服务器名称
}

class HiddenSOCKS5Server:
    def __init__(self):
        self.server = None
        self.connections = set()
        self.start_time = time.time()
        self.setup_logging()
        
    def setup_logging(self):
        """设置日志（最小化输出）"""
        logging.basicConfig(
            level=CONFIG['LOG_LEVEL'],
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[logging.FileHandler('/tmp/.web_cache.log')]  # 隐蔽的日志文件名
        )
        self.logger = logging.getLogger(__name__)

    def check_auth(self, client_ip, password):
        """验证客户端权限"""
        if CONFIG['ALLOWED_IPS'] and client_ip not in CONFIG['ALLOWED_IPS']:
            return False
        
        # 简单密码验证
        expected = hashlib.md5(CONFIG['PASSWORD'].encode()).hexdigest()[:8]
        provided = hashlib.md5(password.encode()).hexdigest()[:8]
        return expected == provided

    async def handle_socks5_auth(self, reader, writer):
        """处理SOCKS5认证"""
        try:
            # 读取认证方法
            data = await reader.read(2)
            if len(data) != 2 or data[0] != 5:
                return False
                
            nmethods = data[1]
            methods = await reader.read(nmethods)
            
            # 要求用户名密码认证
            writer.write(b'\x05\x02')  # 版本5，需要认证
            await writer.drain()
            
            # 读取认证信息
            auth_data = await reader.read(2)
            if len(auth_data) != 2 or auth_data[0] != 1:
                return False
                
            ulen = auth_data[1]
            username = await reader.read(ulen)
            
            plen_data = await reader.read(1)
            if not plen_data:
                return False
            plen = plen_data[0]
            password = await reader.read(plen)
            
            # 验证密码
            client_ip = writer.get_extra_info('peername')[0]
            if self.check_auth(client_ip, password.decode('utf-8', errors='ignore')):
                writer.write(b'\x01\x00')  # 认证成功
                await writer.drain()
                return True
            else:
                writer.write(b'\x01\x01')  # 认证失败
                await writer.drain()
                return False
                
        except Exception as e:
            self.logger.error(f"认证错误: {e}")
            return False

    async def handle_socks5_request(self, reader, writer):
        """处理SOCKS5连接请求"""
        try:
            # 读取请求
            request = await reader.read(4)
            if len(request) != 4 or request[0] != 5 or request[1] != 1:
                return None, None
                
            atyp = request[3]
            
            # 解析目标地址
            if atyp == 1:  # IPv4
                addr_data = await reader.read(6)
                addr = socket.inet_ntoa(addr_data[:4])
                port = struct.unpack('>H', addr_data[4:6])[0]
            elif atyp == 3:  # 域名
                addr_len = (await reader.read(1))[0]
                addr = (await reader.read(addr_len)).decode()
                port = struct.unpack('>H', await reader.read(2))[0]
            else:
                # 不支持IPv6
                writer.write(b'\x05\x08\x00\x01\x00\x00\x00\x00\x00\x00')
                await writer.drain()
                return None, None
                
            return addr, port
            
        except Exception as e:
            self.logger.error(f"请求解析错误: {e}")
            return None, None

    async def create_connection(self, addr, port):
        """创建到目标服务器的连接"""
        try:
            # 特别优化Telegram连接
            if 'telegram' in addr.lower() or port in [443, 80, 5222]:
                # 为Telegram添加连接优化
                target_reader, target_writer = await asyncio.wait_for(
                    asyncio.open_connection(addr, port),
                    timeout=10
                )
            else:
                target_reader, target_writer = await asyncio.wait_for(
                    asyncio.open_connection(addr, port),
                    timeout=CONFIG['TIMEOUT']
                )
            return target_reader, target_writer
        except Exception as e:
            self.logger.error(f"连接目标失败 {addr}:{port} - {e}")
            return None, None

    async def forward_data(self, reader, writer, name=""):
        """转发数据"""
        try:
            while True:
                data = await reader.read(8192)
                if not data:
                    break
                writer.write(data)
                await writer.drain()
        except Exception as e:
            self.logger.debug(f"数据转发错误 {name}: {e}")
        finally:
            try:
                writer.close()
                await writer.wait_closed()
            except:
                pass

    async def handle_client(self, reader, writer):
        """处理客户端连接"""
        client_addr = writer.get_extra_info('peername')
        self.connections.add(writer)
        
        try:
            # SOCKS5认证
            if not await self.handle_socks5_auth(reader, writer):
                self.logger.warning(f"认证失败: {client_addr}")
                return
                
            # 处理连接请求
            target_addr, target_port = await self.handle_socks5_request(reader, writer)
            if not target_addr:
                return
                
            # 连接目标服务器
            target_reader, target_writer = await self.create_connection(target_addr, target_port)
            if not target_reader:
                # 连接失败响应
                writer.write(b'\x05\x05\x00\x01\x00\x00\x00\x00\x00\x00')
                await writer.drain()
                return
                
            # 连接成功响应
            writer.write(b'\x05\x00\x00\x01\x00\x00\x00\x00\x00\x00')
            await writer.drain()
            
            # 开始双向转发
            self.logger.info(f"代理连接: {client_addr} -> {target_addr}:{target_port}")
            
            await asyncio.gather(
                self.forward_data(reader, target_writer, "client->target"),
                self.forward_data(target_reader, writer, "target->client"),
                return_exceptions=True
            )
            
        except Exception as e:
            self.logger.error(f"客户端处理错误: {e}")
        finally:
            self.connections.discard(writer)
            try:
                writer.close()
                await writer.wait_closed()
            except:
                pass

    async def start_server(self):
        """启动SOCKS5服务器"""
        try:
            self.server = await asyncio.start_server(
                self.handle_client,
                CONFIG['HOST'],
                CONFIG['PORT'],
                limit=8192
            )
            
            addr = self.server.sockets[0].getsockname()
            self.logger.info(f"SOCKS5代理启动: {addr[0]}:{addr[1]}")
            print(f"[{datetime.now().strftime('%H:%M:%S')}] 服务已启动 {addr[0]}:{addr[1]}")
            
            async with self.server:
                await self.server.serve_forever()
                
        except Exception as e:
            self.logger.error(f"服务器启动失败: {e}")
            print(f"启动失败: {e}")

    async def shutdown(self):
        """优雅关闭服务器"""
        if self.server:
            self.server.close()
            await self.server.wait_closed()
            
        # 关闭所有连接
        for conn in list(self.connections):
            try:
                conn.close()
                await conn.wait_closed()
            except:
                pass
                
        print(f"服务已停止")

def handle_signal(signum, frame):
    """信号处理"""
    print(f"\n收到信号 {signum}，正在停止服务...")
    asyncio.create_task(proxy_server.shutdown())

def modify_process_name():
    """修改进程名称以隐藏"""
    try:
        import setproctitle
        setproctitle.setproctitle(CONFIG['FAKE_SERVER_NAME'])
    except ImportError:
        # 如果没有setproctitle，使用其他方法
        if hasattr(os, 'execv'):
            pass

async def main():
    """主函数"""
    global proxy_server
    
    # 修改进程名称
    modify_process_name()
    
    # 注册信号处理
    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)
    
    proxy_server = HiddenSOCKS5Server()
    
    # 定时重启功能（可选）
    async def auto_restart():
        await asyncio.sleep(24 * 3600)  # 24小时后重启
        print("定时重启...")
        await proxy_server.shutdown()
        os.execv(sys.executable, ['python'] + sys.argv)
    
    # 启动服务器和定时重启任务
    await asyncio.gather(
        proxy_server.start_server(),
        auto_restart(),
        return_exceptions=True
    )

if __name__ == "__main__":
    print("CT8隐蔽SOCKS5代理 v1.0")
    print("=" * 40)
    print(f"监听端口: {CONFIG['PORT']}")
    print(f"认证密码: {CONFIG['PASSWORD']}")
    print("按 Ctrl+C 停止服务")
    print("=" * 40)
    
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n服务已停止")
    except Exception as e:
        print(f"运行错误: {e}")
