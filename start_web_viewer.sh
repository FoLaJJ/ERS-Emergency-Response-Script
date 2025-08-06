#!/bin/bash

# 挖矿事件响应日志Web查看器启动脚本

echo "🔍 挖矿事件响应日志Web查看器"
echo "================================"

# 检查Python是否安装
if ! command -v python3 &> /dev/null; then
    echo "❌ 错误: 未找到Python3"
    echo "请先安装Python3:"
    echo "  Ubuntu/Debian: sudo apt install python3 python3-pip python3-venv"
    echo "  CentOS/RHEL: sudo yum install python3 python3-pip python3-venv"
    exit 1
fi

# 检查venv模块是否可用
if ! python3 -c "import venv" &> /dev/null; then
    echo "❌ 错误: Python venv模块不可用"
    echo "请安装python3-venv:"
    echo "  Ubuntu/Debian: sudo apt install python3-venv"
    echo "  CentOS/RHEL: sudo yum install python3-venv"
    exit 1
fi

# 虚拟环境目录
VENV_DIR="venv"
VENV_ACTIVATE="$VENV_DIR/bin/activate"

# 创建虚拟环境（如果不存在）
if [ ! -d "$VENV_DIR" ]; then
    echo "📦 创建虚拟环境..."
    python3 -m venv "$VENV_DIR"
    if [ $? -ne 0 ]; then
        echo "❌ 创建虚拟环境失败"
        exit 1
    fi
    echo "✅ 虚拟环境创建成功"
fi

# 激活虚拟环境
echo "🔧 激活虚拟环境..."
source "$VENV_ACTIVATE"
if [ $? -ne 0 ]; then
    echo "❌ 激活虚拟环境失败"
    exit 1
fi

# 检查Flask是否安装
if ! python3 -c "import flask" &> /dev/null; then
    echo "📦 在虚拟环境中安装Flask..."
    pip3 install flask
    if [ $? -ne 0 ]; then
        echo "❌ 安装Flask失败"
        echo "请手动安装: pip3 install flask"
        exit 1
    fi
    echo "✅ Flask安装成功"
else
    echo "✅ Flask已安装"
fi

# 检查是否有日志文件
if [ ! -d "results" ] && [ ! -f "incident_response_*.log" ]; then
    echo "⚠️  警告: 未找到日志文件"
    echo "请先运行调查脚本: ./mining_incident_response.sh"
    echo ""
fi

echo "🚀 启动Web服务器..."
echo "📱 访问地址: http://localhost:5000"
echo "🔄 按 Ctrl+C 停止服务器"
echo ""

# 启动Web服务器
python3 web_viewer.py 