# 🚀 Automated Linux Server Provisioning

[![Ansible](https://img.shields.io/badge/Ansible-2.10+-EE0000?logo=ansible&logoColor=white)](https://www.ansible.com/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04_LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Bash](https://img.shields.io/badge/Bash-5.0+-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **Tự động hóa cài đặt và cấu hình Linux server** bằng Ansible, Bash scripting và Jinja2 templates.
> Hỗ trợ multi-environment (dev/prod) với config linh hoạt.

## 🎬 Demo

[![Demo Video](https://img.youtube.com/vi/d0qSQEahTS8/maxresdefault.jpg)](https://youtu.be/d0qSQEahTS8)

---

## 📋 Mục lục

- [Demo](#-demo)
- [Kiến trúc hệ thống](#-kiến-trúc-hệ-thống)
- [Tính năng](#-tính-năng)
- [Cấu trúc project](#-cấu-trúc-project)
- [Yêu cầu](#-yêu-cầu)
- [Hướng dẫn cài đặt](#-hướng-dẫn-cài-đặt)
- [Hướng dẫn sử dụng](#-hướng-dẫn-sử-dụng)
- [Multi-environment](#-multi-environment)
- [Biến cấu hình](#-biến-cấu-hình)
- [Kiến thức áp dụng](#-kiến-thức-áp-dụng)
- [Troubleshooting](#-troubleshooting)

---

## 🏗 Kiến trúc hệ thống

Dự án hỗ trợ hai phương án chạy thử nghiệm hệ thống linh hoạt:

### 1. Môi trường VM Lab (VMware Workstation)
Giả lập đầy đủ hệ điều hành và các lớp bảo mật mạng (UFW firewall, Fail2ban).

```
┌─────────────────────────────────────────────────────────────┐
│                    Windows Host (VMware)                    │
│                                                             │
│  ┌─────────────────┐   SSH    ┌──────────────────────────┐  │
│  │  ubuntu-control  │────────▶│  web01 (webserver)        │  │
│  │  192.168.209.10  │         │  192.168.209.11           │  │
│  │                  │         │  • nginx                  │  │
│  │  • Ansible 2.10+ │         │  • UFW firewall           │  │
│  │  • Python 3      │   SSH   │  • fail2ban               │  │
│  │  • Git           │────────▶│  • SSH hardened            │  │
│  │                  │         ├──────────────────────────┤  │
│  │  RAM: 1024 MB    │         │  db01 (dbserver)          │  │
│  └─────────────────┘         │  192.168.209.21           │  │
│                               │  • UFW firewall           │  │
│          Control Node         │  • fail2ban               │  │
│                               │  • SSH hardened            │  │
│                               └──────────────────────────┘  │
│                                     Managed Nodes            │
└─────────────────────────────────────────────────────────────┘
         VMnet: Host-only (192.168.209.0/24)
```

### 2. Môi trường Container Lab (Docker Compose)
Dành cho kiểm nghiệm nhanh gọn, không đòi hỏi phần cứng mạnh hay cấu hình VM phức tạp.

```
┌─────────────────────────────────────────────────────────────┐
│                    Windows/macOS (Docker)                   │
│                                                             │
│  ┌─────────────────┐   SSH    ┌──────────────────────────┐  │
│  │ ansible-control │────────▶│  web01 (webserver)       │  │
│  │ (Ubuntu container│         │ (Ubuntu container)       │  │
│  │                  │         │  • nginx                 │  │
│  │  • Ansible       │   SSH   │  • Docker Engine (Role)  │  │
│  │  • SSH client    │────────▶│  • SSH daemon            │  │
│  │  • Mounted Code  │         │                          │  │
│  │                  │         ├──────────────────────────┤  │
│  │                  │         │  db01 (dbserver)         │  │
│  └─────────────────┘         │ (Ubuntu container)       │  │
│                               │  • Docker Engine (Role)  │  │
│          Control Node         │  • SSH daemon            │  │
│                               └──────────────────────────┘  │
│                                     Managed Nodes            │
└─────────────────────────────────────────────────────────────┘
             Docker Bridge Network: ansible-net
```

**Tech stack:** Ansible · Docker & Docker Compose · Bash · Jinja2 · UFW · fail2ban · Ubuntu Server 22.04 · VMware


---

## ✨ Tính năng

| # | Tính năng | Mô tả |
|---|-----------|-------|
| 1 | **Preflight Check** | Bash script kiểm tra server trước khi provision (OS, RAM, disk, SSH, Python) |
| 2 | **Common Setup** | Cài packages, tạo user devops với sudo, set hostname/timezone |
| 3 | **SSH Hardening** | Disable root login, disable password auth, giới hạn auth attempts |
| 4 | **UFW Firewall** | Chỉ mở port 22 (SSH) và 80 (HTTP), deny all incoming mặc định |
| 5 | **Fail2ban** | Chống brute force SSH, auto-ban IP sau 5 lần thất bại |
| 6 | **Nginx Config** | Jinja2 template với gzip, rate limiting, upstream, security headers |
| 7 | **Multi-environment** | Dev, Prod và Docker Lab (giả lập) config độc lập |
| 8 | **Automated Docker Setup** | Tự động cài đặt Docker Engine và Docker Compose lên các target node bằng Ansible role |
| 9 | **Idempotency** | Chạy bao nhiêu lần cũng cho kết quả giống nhau |

---

## 📁 Cấu trúc project

```
auto-server-provision/
├── ansible.cfg                          # Cấu hình Ansible mặc định
├── docker-compose.yml                   # Cấu hình điều phối Docker Lab
├── inventory.ini                        # Default VM inventory
├── docker/                              # Môi trường chạy Docker Lab
│   ├── Dockerfile.control               # Dockerfile cho Ansible control node
│   ├── Dockerfile.node                  # Dockerfile cho target node
│   └── ssh/                             # Khóa SSH dùng cho môi trường container lab
│       ├── id_rsa
│       └── id_rsa.pub
├── inventories/
│   ├── dev/                             # Cấu hình môi trường phát triển (VM)
│   │   ├── hosts.ini
│   │   └── group_vars/
│   │       └── all.yml
│   ├── prod/                            # Cấu hình môi trường product (VM)
│   │   ├── hosts.ini
│   │   └── group_vars/
│   │       └── all.yml
│   └── docker/                          # Cấu hình môi trường Lab giả lập (Docker)
│       ├── hosts.ini
│       └── group_vars/
│           └── all.yml
├── group_vars/
│   └── all.yml                          # Biến mặc định dùng chung
├── roles/
│   ├── common/                          # Base server configuration
│   │   ├── defaults/main.yml
│   │   ├── handlers/main.yml
│   │   ├── tasks/main.yml               # Cài Nginx, thiết lập timezone, hostname
│   │   └── templates/
│   │       └── nginx.conf.j2
│   ├── security/                        # Bảo mật và gia cố server
│   │   ├── defaults/main.yml
│   │   ├── handlers/main.yml
│   │   ├── tasks/main.yml               # Cài SSH Hardening, UFW, Fail2ban
│   │   └── templates/
│   │       └── sshd_config.j2
│   └── docker/                          # [NEW] Role cài đặt Docker
│       ├── defaults/main.yml
│       └── tasks/main.yml               # Tasks thêm repo, cài Docker Engine/Compose
├── playbooks/
│   └── site.yml                         # Playbook chính điều phối toàn bộ
├── scripts/
│   └── preflight.sh                     # Script kiểm tra trước khi cài đặt
├── docs/
│   ├── troubleshooting.md               # Lỗi gặp phải & cách sửa
│   └── screenshots/
└── README.md
```

---

## 📦 Yêu cầu

### Phần mềm trên Windows
- [VMware Workstation Pro](https://www.vmware.com/) (free từ 2024)

### VM Specifications

| VM | Role | IP | RAM |
|---|---|---|---|
| ubuntu-control | Control node (Ansible) | 192.168.209.10 | 1024 MB |
| web01 | Web server | 192.168.209.11 | 512 MB |
| db01 | DB server | 192.168.209.21 | 512 MB |

- **OS:** Ubuntu Server 22.04 LTS
- **Network:** VMnet Host-only (192.168.209.0/24)
- **Ansible:** 2.10+
- **Python:** 3.8+

---

## 🔧 Hướng dẫn cài đặt

### 1. Chuẩn bị VM

```bash
# Trên ubuntu-control — cài Ansible
sudo apt update
sudo apt install -y ansible git python3

# Tạo SSH key và copy sang managed nodes
ssh-keygen -t ed25519 -C "ansible"
ssh-copy-id t1kayyyy@192.168.209.11
ssh-copy-id t1kayyyy@192.168.209.21
```

### 2. Clone project

```bash
git clone https://github.com/t1kay/auto-server-provision.git
cd auto-server-provision
```

### 3. Cấu hình passwordless sudo trên mỗi managed node

```bash
# SSH vào web01 và db01, chạy:
echo "t1kayyyy ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/t1kayyyy
sudo chmod 440 /etc/sudoers.d/t1kayyyy
```

### 4. Verify kết nối

```bash
ansible all -m ping
```

Kết quả mong đợi:
```
web01 | SUCCESS => { "ping": "pong" }
db01  | SUCCESS => { "ping": "pong" }
```

---

## 🚀 Hướng dẫn sử dụng

### Quy trình chạy đầy đủ

```bash
# Bước 1: Kiểm tra server (preflight check)
bash scripts/preflight.sh

# Bước 2: Chạy playbook (dry run trước)
ansible-playbook playbooks/site.yml --check --diff

# Bước 3: Chạy playbook thực tế
ansible-playbook playbooks/site.yml

# Bước 4: Verify nginx
curl http://192.168.209.11
```

### Chạy theo tag

```bash
# Chỉ chạy security tasks
ansible-playbook playbooks/site.yml --tags security

# Chỉ cài packages
ansible-playbook playbooks/site.yml --tags packages

# Chỉ deploy nginx config
ansible-playbook playbooks/site.yml --tags nginx
```

### Xem thông tin environment

```bash
ansible-playbook playbooks/site.yml --tags info
```

---

## 🌍 Multi-environment

Project hỗ trợ 2 môi trường: **dev** và **prod**, mỗi môi trường có biến cấu hình riêng.

### Chạy trên Dev

```bash
ansible-playbook -i inventories/dev/hosts.ini playbooks/site.yml
```

### Chạy trên Prod

```bash
ansible-playbook -i inventories/prod/hosts.ini playbooks/site.yml
```

### Chạy trên Docker Lab (Giả lập cục bộ)

Nếu không sử dụng VMware, bạn có thể chạy thử nghiệm dự án hoàn chỉnh trên Docker bằng Docker Compose (yêu cầu máy host đã cài đặt **Docker Desktop**):

1. **Khởi động cụm Lab (Docker containers)**:
   ```bash
   docker-compose up -d --build
   ```
   Lệnh này sẽ khởi động 3 container kết nối chung mạng nội bộ `ansible-net`:
   - `ansible-control`: Node điều khiển (được cài sẵn Ansible, SSH private key và mount mã nguồn dự án).
   - `web01`: Target node giả lập webserver (Ubuntu SSH).
   - `db01`: Target node giả lập database server (Ubuntu SSH).

2. **Truy cập control node và chạy thử preflight check**:
   ```bash
   docker exec -it ansible-control bash scripts/preflight.sh
   ```

3. **Chạy Ansible Playbook**:
   Chạy lệnh sau để thực thi toàn bộ playbook trên môi trường Docker:
   ```bash
   docker exec -it ansible-control ansible-playbook -i inventories/docker/hosts.ini playbooks/site.yml
   ```
   *(Để chỉ test cài đặt Docker, thêm `--tags docker`)*

   > [!NOTE]
   > Trong môi trường Docker container, các tác vụ liên quan đến hệ thống (như thay đổi Hostname, cài đặt Timezone, đồng bộ NTP) và bảo mật (như kích hoạt UFW Firewall, chạy Fail2ban) sẽ được tự động bỏ qua để tránh lỗi phân quyền kernel đặc quyền của Docker Desktop.

4. **Kiểm tra kết quả**:
   - Truy cập trang Nginx trực tiếp từ máy host (Windows/Mac) qua port forward: [http://localhost:8080](http://localhost:8080)
   - Hoặc curl từ control node:
     ```bash
     docker exec -it ansible-control curl http://web01:8080
     ```

5. **Tắt môi trường Lab**:
   ```bash
   docker-compose down
   ```

### So sánh cấu hình các môi trường

| Setting | Dev | Prod | Docker Lab |
|---------|-----|------|------------|
| Nginx port | 8080 | 80 | 8080 |
| Server name | dev.local | example.com | docker.local |
| Gzip | ❌ Off | ✅ On | ❌ Off |
| Rate limiting | ❌ Off | ✅ On | ❌ Off |
| Workers | 1 | auto | 1 |
| SSH password auth | ✅ Yes | ❌ No | ❌ No (Chỉ dùng Key) |
| Fail2ban max retry | 10 | 3 | ❌ Bỏ qua (Skipped) |
| Fail2ban ban time | 10 min | 24 hours | ❌ Bỏ qua (Skipped) |
| Upstream servers | 1 | 2 (HA) | 1 |
| UFW Firewall | ✅ Bật | ✅ Bật | ❌ Bỏ qua (Skipped) |
| Docker Engine | ❌ Không cài | ❌ Không cài | ✅ Có cài (Installed) |


### Dry Run (Check Mode)

```bash
# Xem những gì SẼ thay đổi mà không thực sự chạy
ansible-playbook -i inventories/prod/hosts.ini playbooks/site.yml --check --diff
```

---

## ⚙️ Biến cấu hình

### Shared Defaults (`group_vars/all.yml`)

| Biến | Giá trị mặc định | Mô tả |
|------|-------------------|-------|
| `devops_user` | `devops` | User được tạo trên tất cả server |
| `server_timezone` | `Asia/Ho_Chi_Minh` | Timezone hệ thống |
| `nginx_port` | `80` | Port nginx listen |
| `nginx_enable_gzip` | `true` | Bật gzip compression |
| `nginx_enable_rate_limit` | `false` | Bật rate limiting |

### Security Defaults (`roles/security/defaults/main.yml`)

| Biến | Giá trị mặc định | Mô tả |
|------|-------------------|-------|
| `ssh_port` | `22` | SSH port |
| `ssh_permit_root_login` | `no` | Disable root SSH login |
| `ssh_password_authentication` | `no` | Disable password auth |
| `ufw_default_incoming` | `deny` | UFW default policy |
| `fail2ban_maxretry` | `5` | Max SSH failures before ban |

---

## 📚 Kiến thức áp dụng

### Ansible
- **Inventory & Groups** — Phân nhóm server theo role (webservers, dbservers)
- **Roles** — Tổ chức code theo chuẩn (tasks, handlers, defaults, templates)
- **Handlers** — Chỉ restart service khi config thực sự thay đổi (tối ưu hóa điều kiện bypass trong Docker)
- **Tags** — Chạy selective tasks, tiết kiệm thời gian khi debug (ví dụ: `--tags docker`)
- **Idempotency** — Chạy nhiều lần, kết quả giống nhau
- **Check mode** — Dry run để preview thay đổi trước khi apply

### Docker & Docker Compose
- **Containerization** — Đóng gói Ansible Control Node giúp chạy playbook ngay từ máy host mà không cần cài đặt Ansible thủ công hay dùng VM cồng kềnh.
- **Orchestration & Virtual Networking** — Dùng Docker Compose khởi tạo mạng Bridge Network để điều phối việc giả lập các node SSH đích (`web01`, `db01`), liên lạc qua hostname container.

### Jinja2 Templates
- **Variables** — `{{ nginx_port }}` cho config linh hoạt
- **Conditionals** — `{% if nginx_enable_gzip %}` bật/tắt tính năng
- **Loops** — `{% for server in nginx_upstream_servers %}` cho multiple backends
- **Filters** — `{{ value | default('fallback') }}` cho giá trị mặc định

### Bash Scripting
- **Exit codes** — Script trả về 0 (success) hoặc 1 (failure)
- **Error handling** — `set -euo pipefail` cho robust scripting
- **System commands** — `free`, `df`, `uname`, `ss` để kiểm tra hệ thống

### Linux Security
- **SSH Hardening** — Disable root, disable password, limit retries (áp dụng an toàn thông qua key auth trên Docker Lab)
- **UFW Firewall** — Default deny, whitelist only needed ports
- **Fail2ban** — Tự động ban IP brute force

---


## 📝 License

MIT License — see [LICENSE](LICENSE) for details.

---


