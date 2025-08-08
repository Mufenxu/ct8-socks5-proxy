#!/bin/bash

# CT8 SOCKS5代理 GitHub一键部署脚本
# 使用方法: bash <(curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/ct8-socks5-proxy/main/quick_deploy.sh)

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 项目配置
REPO_URL="https://github.com/Mufenxu/ct8-socks5-proxy"
RAW_URL="https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main"
PROJECT_NAME="ct8-socks5-proxy"
VERSION="1.0.0"

# 显示横幅
show_banner() {
    clear
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║          CT8 SOCKS5代理 GitHub一键部署工具               ║"
    echo "║                                                          ║"
    echo "║  🚀 从GitHub自动下载并部署Telegram代理                   ║"
    echo "║  🔒 隐蔽安全，专为CT8免费服务器优化                       ║"
    echo "║  ⚡ 版本: $VERSION                                      ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

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

# 检查网络连接
check_network() {
    log_step "检查网络连接..."
    
    if ! curl -s --connect-timeout 10 "https://raw.githubusercontent.com/Mufenxu/ct8-socks5-proxy/main/README.md" > /dev/null; then
        log_error "无法连接到GitHub，请检查网络连接"
        exit 1
    fi
    
    log_info "网络连接正常"
}

# 检查系统环境
check_system() {
    log_step "检查系统环境..."
    
    # 检查操作系统
    if [[ ! "$OSTYPE" =~ ^linux ]]; then
        log_error "不支持的操作系统: $OSTYPE"
        log_error "此脚本仅支持Linux系统（如CT8服务器）"
        exit 1
    fi
    
    # 检查Python3
    if ! command -v python3 &> /dev/null; then
        log_error "Python3未安装"
        log_error "请先安装Python3: apt update && apt install python3"
        exit 1
    fi
    
    # 检查curl
    if ! command -v curl &> /dev/null; then
        log_error "curl未安装"
        log_error "请先安装curl: apt update && apt install curl"
        exit 1
    fi
    
    # 检查磁盘空间
    local disk_free=$(df "$HOME" | awk 'NR==2 {print $4}')
    if [ "$disk_free" -lt 51200 ]; then  # 小于50MB
        log_warn "磁盘空间不足，可能影响安装"
    fi
    
    log_info "系统环境检查完成"
}

# 创建工作目录
create_workspace() {
    log_step "创建工作目录..."
    
    # 创建项目目录
    local install_dir="$HOME/.ct8_proxy"
    local work_dir="$HOME/.config/systemd"
    
    mkdir -p "$install_dir"
    mkdir -p "$work_dir"
    
    cd "$install_dir"
    
    log_info "工作目录: $install_dir"
    log_info "配置目录: $work_dir"
}

# 下载项目文件
download_files() {
    log_step "从GitHub下载项目文件..."
    
    local files=(
        "ct8_socks5.py"
        "ct8_deploy.sh"
        "ct8_manager.sh"
        "install.sh"
        "README.md"
    )
    
    for file in "${files[@]}"; do
        log_info "下载: $file"
        if curl -sL "$RAW_URL/$file" -o "$file"; then
            chmod +x "$file" 2>/dev/null || true
            log_info "✓ $file 下载完成"
        else
            log_error "✗ $file 下载失败"
            exit 1
        fi
    done
    
    log_info "所有文件下载完成"
}

# 运行安装脚本
run_installation() {
    log_step "开始安装代理服务..."
    
    if [ -f "install.sh" ]; then
        chmod +x install.sh
        ./install.sh
    else
        log_error "安装脚本不存在"
        exit 1
    fi
}

# 显示部署结果
show_deployment_result() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  🎉 GitHub部署成功！                     ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}=== 项目信息 ===${NC}"
    echo -e "${GREEN}项目地址:${NC} $REPO_URL"
    echo -e "${GREEN}安装目录:${NC} $HOME/.ct8_proxy"
    echo -e "${GREEN}管理工具:${NC} $HOME/ct8_manager"
    echo ""
    
    echo -e "${CYAN}=== 常用命令 ===${NC}"
    echo -e "${GREEN}查看状态:${NC} ~/ct8_manager"
    echo -e "${GREEN}查看连接信息:${NC} cat ~/ct8_proxy_info.txt"
    echo -e "${GREEN}重新部署:${NC} bash <(curl -sL $RAW_URL/quick_deploy.sh)"
    echo ""
    
    echo -e "${CYAN}=== 更新方式 ===${NC}"
    echo "当有新版本时，重新运行一键部署命令即可自动更新"
    echo ""
    
    echo -e "${YELLOW}⭐ 如果觉得有用，请给项目点个Star: $REPO_URL${NC}"
}

# 错误处理
error_handler() {
    echo ""
    log_error "部署过程中出现错误！"
    echo ""
    echo -e "${YELLOW}故障排除建议:${NC}"
    echo "1. 检查网络连接是否正常"
    echo "2. 确认CT8服务器支持外网访问"
    echo "3. 检查Python3是否正确安装"
    echo "4. 查看错误日志了解具体问题"
    echo ""
    echo -e "${CYAN}获取帮助:${NC}"
    echo "- 项目地址: $REPO_URL"
    echo "- 提交Issue: $REPO_URL/issues"
    echo ""
    exit 1
}

# 主函数
main() {
    # 设置错误处理
    trap error_handler ERR
    
    show_banner
    
    log_info "开始GitHub一键部署..."
    echo ""
    
    # 执行部署步骤
    check_network
    check_system
    create_workspace
    download_files
    run_installation
    show_deployment_result
    
    log_info "部署完成！享受你的CT8 Telegram代理吧！"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
