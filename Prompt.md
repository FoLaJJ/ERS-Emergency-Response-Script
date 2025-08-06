# ERS-Emergency-Response-Script
一个给自己用的挖矿应急响应shell script脚本 for Ubuntu

提示词如下：
```txt
# 目标
现在要求你用Shell Script脚本程序完成在ubuntu系统上的挖矿应急响应脚本。

# 要求
- 要求逐项检查下面的选项并且打印出来，而且要有不同颜色的标注，而且要注意错误处理； 
- 尽量解耦合，可以多个文件进行运行，注意语法问题和文件调用；
- 初步先完成ubuntu系统上，后面需要拓展至其他服务器系统，请保留一定的接口自适应；
- 保证美观，为了保证应急响应人员的一览全局，应该将所有的信息都输出出来，而不是覆盖前面的信息；
- 要有一定的文字说明，直接全部英语说明，在某次运行中的结果应该如下，并且应该要一些表格输出在bash中要美观舒服！
目前检查任务：用户信息
目前运行命令：cat /etc/passwd
目前运行结果：xxxxxxxxxx
- 日志文件生成进一个result文件夹中并且要分模块保存为log文件；

# 任务
## 收集信息
- 检查用户信息，检查影子用户或者距今最新建的几个用户；排除可以SSH链接的账户；排除UID是0的超级权限用户；检查SSH公钥；
- 检查命令是否被篡改，alias别名是否启用，可以安装busybox应用程序保证命令的纯净；
- 检查可疑IP和端口号，查看日志中的爆破行为的可疑IP出现次数；查看端口监听；
- 查看可疑进程、查看占用率高的进程，可以安装并使用unhide查看隐藏进程；
- 查看自启动任务，或者systemctl list-unit-files查看可疑任务；
- 查看计划任务，是否有可疑的信息；
- 查看其他日志文件或者history信息，查看攻击者具体的攻击手段；
- 还有什么ubuntu系统上必须检查的东西都可以加进去。

## 小小提示
下面是我收集到的一些命令，可以作为参考，不确保正确与否，请你进行额外的思考！
cat /etc/passwd
cat /etc/shadow
cat /etc/passwd | grep -v 'nologin\|false'
cat /etc/passwd | awk -F: '$3==0 {print $1}'
cat /root/.ssh/authorized_keys
alias
find / -name *bashrc* -type f -exec ls -lctr --full-time {} \+ 2>/dev/null
cat /var/log/auth.log | grep "sshd" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort | uniq -c | sort -nr
netstat -anp | grep ESTAB
ps -aux
pstree -asp
apt install unhide
unhide proc
ps -ef | awk '{print}' | sort | uniq > 1
ps -ef | awk '{print}' | sort | uniq > 2
diff 1 2
cat /etc/rc.d/rc.local
ll /etc/systemd/system/
ll /etc/systemd/system/multi-user.target.wants/ #该目录是存放多用户模式下启动服务的符号链接的地方。
systemctl list-unit-files --type=service | grep enabled
cron
```