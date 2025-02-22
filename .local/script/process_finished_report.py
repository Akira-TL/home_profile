#!/usr/bin/env python

import smtplib, os, time, argparse
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders


# 邮箱服务器地址
mail_host = "smtp.qq.com"
# 邮箱登录名
mail_user = "2273076505@qq.com"
# 密码（部分邮箱为授权码）
mail_pass = "ikleervhcplhdhjc"
# 邮件发送方邮箱地址
sender = "2273076505@qq.com"
# 接收邮箱的地址
receivers = ["2273076505@qq.com"]


parser = argparse.ArgumentParser()
parser.add_argument(
    "--title",
    "-t",
    type=str,
    default="Prosses finished!",
    help="Input the title.",
)
parser.add_argument(
    "--msg",
    "-m",
    type=str,
    default="no_reply",
    help="The send message.",
)
# parser.add_argument(
#     "--theme",
#     type=str,
#     default="auto_send",
#     help="The send theme.",
# )
parser.add_argument(
    "--attachment_path",
    "-a",
    required=False,
    type=str,
    help="The send attachment.",
)
parser.add_argument(
    "--receivers",
    "-e",
    default=receivers[0],
    help=f"Default receiver is {receivers[0]}",
)
parser.add_argument(
    "--pid",
    "-p",
    # required=True,
    # default="123456",
    help="The fetching prosses pid.",
)
parser.add_argument(
    "--cmd",
    "-c",
    # required=False,
    default="",
    help="The command.",
)
parser.add_argument("pid", nargs="?", help="Process ID if not specified with -p")
args = parser.parse_args()


def autohalt(pid, receivers, message):
    if pid == None:
        send_message(receivers, message)
        return

    print("\033[92mProcess checking started...\033[0m")
    while True:
        ps_string = os.popen(f"ps ax | grep {pid}", "r").read()  # 这里的pid是进程号
        ps_strings = ps_string.strip().split("\n")
        # print(ps_strings)
        if len(ps_strings) <= 3:
            send_message(receivers, message)
            return
        else:
            # print('Still',len(ps_strings),'Processes, waiting 60s...')
            time.sleep(60)  # 一分钟后检查一次


def send_message(receivers, message):
    proxy_ip = (
        os.popen(
            r'last "$(whoami)" | grep -oP ".*(\d*\.\d*\.\d*\.\d*).*still logged in" | grep -oP "(\d*\.\d*\.\d*\.\d*)" | head -n 1',
            "r",
        )
        .read()
        .strip()
        .split("\n")[0]
    )
    import socks
    import socket

    # 设置代理服务器
    socks.set_default_proxy(socks.SOCKS5, proxy_ip, 7899)
    socket.socket = socks.socksocket
    error_cnt = 0
    while error_cnt < 60 * 24:
        try:
            # 连接到 SMTP 服务器
            server = smtplib.SMTP(mail_host, timeout=30)
            server.starttls()
            server.login(mail_user, mail_pass)
            server.sendmail(sender, receivers, message.as_string())
            # print(message.as_string())
            server.quit()
            print("\033[92mEmail send successfully\033[0m")
            return
        except Exception as e:
            print(f"\033[91mFailed to send email: {e}\033[0m")
            time.sleep(60)
            error_cnt += 1


if __name__ == "__main__":
    print(
        "\033[92mProcess ended in "
        + datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        + "\033[0m"
    )
    message = MIMEMultipart()
    # 邮件主题
    message["Subject"] = args.title
    # 发送方信息
    message["From"] = sender
    # 接受方信息
    message["To"] = receivers[0]
    # 添加时间戳
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    body_text = f"{args.msg} \n自动时间戳: {timestamp}"
    # 将正文内容作为 MIMEText 附加到 MIMEMultipart 对象中
    message.attach(MIMEText(body_text, "plain", "utf-8"))
    # 添加附件
    if args.attachment_path:
        attachment = MIMEBase("application", "octet-stream")
        with open(args.attachment_path, "rb") as attachment_file:
            fixed_content = (
                f"{' '.join(args.cmd.split()[1:])}\n\n".replace("\\n", "\n").encode(
                    "utf-8"
                )
                + attachment_file.read()
            )
            attachment.set_payload(fixed_content)
        with open(args.attachment_path, "wb") as attachment_file:
            attachment_file.write(fixed_content)
        encoders.encode_base64(attachment)
        attachment.add_header(
            "Content-Disposition",
            f"attachment; filename={os.path.basename(args.attachment_path)}",
        )
        message.attach(attachment)
    autohalt(args.pid, [args.receivers], message)
    # 将args.attachment_path重命名，添加最后发送的时间到末尾，并且保留文件后缀
    if args.attachment_path:
        os.rename(
            args.attachment_path,
            args.attachment_path.replace(
                os.path.splitext(args.attachment_path)[1],
                f"_{datetime.now().strftime('%Y-%m-%d_%H:%M:%S')}{os.path.splitext(args.attachment_path)[1]}",
            ),
        )
        print(
            "Log file moved to "
            + args.attachment_path.replace(
                os.path.splitext(args.attachment_path)[1],
                f"_{datetime.now().strftime('%Y-%m-%d_%H:%M:%S')}{os.path.splitext(args.attachment_path)[1]}",
            )
        )
