#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import glob
import json
import re
from datetime import datetime
from flask import Flask, render_template, request, jsonify, send_from_directory
import threading
import time

app = Flask(__name__)

# 配置
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RESULTS_DIR = os.path.join(SCRIPT_DIR, "results")
TEMP_DIR = os.path.join(SCRIPT_DIR, "temp")

def get_log_files():
    """获取所有日志文件"""
    log_files = []
    
    # 获取主日志文件
    main_logs = glob.glob(os.path.join(SCRIPT_DIR, "incident_response_*.log"))
    for log in main_logs:
        timestamp = os.path.basename(log).replace("incident_response_", "").replace(".log", "")
        log_files.append({
            "type": "main",
            "name": "主日志文件",
            "path": os.path.relpath(log, SCRIPT_DIR),  # 使用相对路径
            "timestamp": timestamp,
            "size": os.path.getsize(log) if os.path.exists(log) else 0
        })
    
    # 获取模块日志文件
    if os.path.exists(RESULTS_DIR):
        module_logs = glob.glob(os.path.join(RESULTS_DIR, "*_*.log"))
        for log in module_logs:
            filename = os.path.basename(log)
            parts = filename.replace(".log", "").split("_")
            if len(parts) >= 2:
                module_name = parts[0]
                timestamp = "_".join(parts[1:])
                
                # 模块名称映射
                module_names = {
                    "user": "用户调查",
                    "command": "命令调查", 
                    "network": "网络调查",
                    "process": "进程调查",
                    "startup": "启动项调查",
                    "cron": "计划任务调查",
                    "log": "日志调查",
                    "system": "系统调查"
                }
                
                display_name = module_names.get(module_name, module_name)
                
                log_files.append({
                    "type": "module",
                    "name": display_name,
                    "path": os.path.relpath(log, SCRIPT_DIR),  # 使用相对路径
                    "timestamp": timestamp,
                    "size": os.path.getsize(log) if os.path.exists(log) else 0
                })
    
    # 按时间戳排序
    log_files.sort(key=lambda x: x["timestamp"], reverse=True)
    return log_files

def parse_log_content(file_path):
    """解析日志文件内容"""
    if not os.path.exists(file_path):
        return [{"type": "error", "content": f"文件不存在: {file_path}", "level": "error"}]
    
    content = []
    try:
        # 尝试不同的编码
        encodings = ['utf-8', 'gbk', 'gb2312', 'latin-1']
        file_content = None
        
        for encoding in encodings:
            try:
                with open(file_path, 'r', encoding=encoding) as f:
                    file_content = f.readlines()
                break
            except UnicodeDecodeError:
                continue
        
        if file_content is None:
            return [{"type": "error", "content": f"无法读取文件编码: {file_path}", "level": "error"}]
            
        for line in file_content:
            line = line.strip()
            if not line:
                continue
                
            # 解析不同类型的日志行
            parsed_line = parse_log_line(line)
            content.append(parsed_line)
            
    except Exception as e:
        content.append({
            "type": "error",
            "content": f"读取文件错误: {str(e)}",
            "level": "error"
        })
    
    return content

def parse_log_line(line):
    """解析单行日志"""
    # 匹配时间戳格式 [INFO] 2025-08-06 12:25:28: message
    timestamp_pattern = r'\[(INFO|WARNING|ERROR|CRITICAL)\]\s+(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}):\s+(.+)'
    match = re.match(timestamp_pattern, line)
    
    if match:
        level = match.group(1)
        timestamp = match.group(2)
        message = match.group(3)
        
        return {
            "type": "log",
            "level": level.lower(),
            "timestamp": timestamp,
            "content": message
        }
    
    # 匹配任务信息 === Task Name ===
    task_pattern = r'^=== (.+) ===$'
    match = re.match(task_pattern, line)
    if match:
        return {
            "type": "task",
            "content": match.group(1)
        }
    
    # 匹配命令信息
    if line.startswith("Command:") or line.startswith("Current Task:") or line.startswith("Current Command:"):
        return {
            "type": "command",
            "content": line
        }
    
    # 匹配结果信息
    if line.startswith("Result:"):
        return {
            "type": "result",
            "content": line
        }
    
    # 匹配警告信息
    if "WARNING:" in line or "CRITICAL:" in line:
        return {
            "type": "warning",
            "content": line,
            "level": "critical" if "CRITICAL:" in line else "warning"
        }
    
    # 匹配成功信息
    if "SUCCESS:" in line or ("No " in line and "found" in line):
        return {
            "type": "success",
            "content": line,
            "level": "success"
        }
    
    # 默认作为普通信息
    return {
        "type": "info",
        "content": line
    }

def get_suspicious_items():
    """获取可疑项目"""
    suspicious_items = []
    
    # 检查临时目录中的可疑文件
    if os.path.exists(TEMP_DIR):
        for file in os.listdir(TEMP_DIR):
            if file.startswith("suspicious_"):
                file_path = os.path.join(TEMP_DIR, file)
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    suspicious_items.append({
                        "type": file.replace("suspicious_", "").replace(".txt", ""),
                        "file": file,
                        "content": content
                    })
                except Exception as e:
                    suspicious_items.append({
                        "type": file.replace("suspicious_", "").replace(".txt", ""),
                        "file": file,
                        "content": f"读取文件错误: {str(e)}"
                    })
    
    return suspicious_items

@app.route('/')
def index():
    """主页"""
    log_files = get_log_files()
    suspicious_items = get_suspicious_items()
    
    return render_template('index.html', 
                         log_files=log_files, 
                         suspicious_items=suspicious_items)

@app.route('/api/log/<path:file_path>')
def get_log_content(file_path):
    """获取日志文件内容"""
    try:
        # 安全检查
        if '..' in file_path or file_path.startswith('/'):
            return jsonify({"error": "Invalid path"}), 400
        
        # 构建完整路径
        full_path = os.path.join(SCRIPT_DIR, file_path)
        
        # 检查文件是否存在
        if not os.path.exists(full_path):
            return jsonify({"error": f"File not found: {file_path}"}), 404
        
        # 检查文件是否可读
        if not os.access(full_path, os.R_OK):
            return jsonify({"error": f"File not readable: {file_path}"}), 403
        
        content = parse_log_content(full_path)
        return jsonify({"content": content})
        
    except Exception as e:
        return jsonify({"error": f"Server error: {str(e)}"}), 500

@app.route('/api/files')
def get_files():
    """获取文件列表"""
    try:
        log_files = get_log_files()
        return jsonify({"files": log_files})
    except Exception as e:
        return jsonify({"error": f"Server error: {str(e)}"}), 500

@app.route('/api/suspicious')
def get_suspicious():
    """获取可疑项目"""
    try:
        suspicious_items = get_suspicious_items()
        return jsonify({"items": suspicious_items})
    except Exception as e:
        return jsonify({"error": f"Server error: {str(e)}"}), 500

if __name__ == '__main__':
    print("启动Web查看器...")
    print(f"脚本目录: {SCRIPT_DIR}")
    print(f"结果目录: {RESULTS_DIR}")
    print(f"临时目录: {TEMP_DIR}")
    print(f"访问地址: http://localhost:5000")
    print("按 Ctrl+C 停止服务器")
    
    app.run(host='0.0.0.0', port=5000, debug=False) 