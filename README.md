# 🚀 Automated Linux Server Provisioning

[![Ansible](https://img.shields.io/badge/ansible--core-2.15+-EE0000?logo=ansible&logoColor=white)](https://www.ansible.com/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04_LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Bash](https://img.shields.io/badge/Bash-5.0+-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![CI](https://github.com/t1kay/auto-server-provision/actions/workflows/ci.yml/badge.svg)](https://github.com/t1kay/auto-server-provision/actions/workflows/ci.yml)
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
- [Chất lượng code & CI](#-chất-lượng-code--ci)
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
│  │  • Ansible 2.15+ │         │  • UFW firewall           │  │
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
| 1 | **Preflight Check** | Bash script kiểm tra server trước khi provision (OS, RAM, disk, SSH, Python), chạy local hoặc remote qua SSH |
| 2 | **Common Setup** | Cài packages, tạo user devops với sudo, set hostname/timezone |
| 3 | **SSH Hardening** | Disable root login, disable password auth, giới hạn auth attempts |
| 4 | **UFW Firewall** | Deny all incoming mặc định; luôn mở `ssh_port` trước khi bật firewall (không tự khoá mình) + port riêng từng env |
| 5 | **Fail2ban** | Chống brute force SSH, auto-ban IP sau 5 lần thất bại |
| 6 | **Nginx Role** | Jinja2 template với gzip, rate limiting, upstream, security headers; tự health-check sau khi deploy |
| 7 | **Multi-environment** | Dev, Prod và Docker Lab (giả lập) config độc lập |
| 8 | **Automated Docker Setup** | Tự động cài đặt Docker Engine và Docker Compose lên các target node bằng Ansible role |
| 9 | **Idempotency** | Chạy lần 2 cho kết quả `changed=0` |
| 10 | **CI** | GitHub Actions chạy yamllint, ansible-lint (profile `production`), syntax-check mọi inventory, shellcheck |
| 11 | **No secrets in git** | SSH key của Docker Lab được sinh lúc khởi động container, không commit vào repo |

---

## 📁 Cấu trúc project

```
auto-server-provision/
├── ansible.cfg                  # Mặc định dùng inventory dev
├── requirements.yml             # Ansible collections cần thiết (community.general)
├── docker-compose.yml           # Docker Lab: 1 control + 2 node
├── .github/workflows/ci.yml     # CI: yamllint, ansible-lint, syntax-check, shellcheck
├── .ansible-lint / .yamllint    # Cấu hình linter
├── docker/
│   ├── Dockerfile.control       # Ansible control node (Ansible cài qua pip, pin version)
│   ├── Dockerfile.node          # Target node (Ubuntu + sshd)
│   ├── control-entrypoint.sh    # Sinh SSH key cho lab vào volume dùng chung
│   └── node-entrypoint.sh       # Nhận public key từ volume rồi chạy sshd
├── inventories/
│   ├── dev/                     # VM dev   — hosts.ini + group_vars (chỉ chứa giá trị override)
│   ├── prod/                    # VM prod
│   └── docker/                  # Docker Lab
├── playbooks/
│   └── site.yml                 # common → security → docker → nginx
├── roles/
│   ├── common/                  # Packages, user devops + sudo, hostname, timezone, NTP
│   ├── security/                # SSH hardening, UFW, fail2ban (templates: sshd_config, jail.local)
│   ├── docker/                  # Docker Engine + Compose plugin
│   └── nginx/                   # Nginx config, landing page, health check (chỉ webservers)
└── scripts/
    └── preflight.sh             # Kiểm tra server trước khi provision
```

---

## 📦 Yêu cầu

Chọn **một** trong hai cách chạy:

### Cách 1 — Docker Lab (nhanh, không cần VM)
- [Git](https://git-scm.com/downloads)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows/macOS) hoặc Docker Engine + Compose plugin (Linux)
- Port **8080**, **2221**, **2222** trên máy host còn trống
- **Không cần** cài Ansible trên máy host — container `ansible-control` đã có sẵn

👉 Làm theo phần [Chạy trên Docker Lab](#chạy-trên-docker-lab-giả-lập-cục-bộ), bỏ qua phần *Hướng dẫn cài đặt* (dành cho VM).

### Cách 2 — VM Lab (VMware, đầy đủ UFW/fail2ban/hostname/timezone)
- [VMware Workstation Pro](https://www.vmware.com/) (free từ 2024)

#### VM Specifications

| VM | Role | IP | RAM |
|---|---|---|---|
| ubuntu-control | Control node (Ansible) | 192.168.209.10 | 1024 MB |
| web01 | Web server | 192.168.209.11 | 512 MB |
| db01 | DB server | 192.168.209.21 | 512 MB |

- **OS:** Ubuntu Server 22.04 LTS
- **Network:** VMnet Host-only (192.168.209.0/24)
- **Ansible:** ansible-core 2.15+ (cài qua pip, xem bên dưới — bản `apt install ansible` của Ubuntu 22.04 là 2.10, **quá cũ**, role `docker` sẽ lỗi)
- **Python:** 3.10+ trên control node (Ubuntu 22.04 có sẵn 3.10), Python 3 trên managed nodes

---

## 🔧 Hướng dẫn cài đặt

> Phần này dành cho **VM Lab**. Dùng Docker Lab thì chuyển thẳng tới [Chạy trên Docker Lab](#chạy-trên-docker-lab-giả-lập-cục-bộ).

> [!IMPORTANT]
> Các lệnh dưới đây dùng user `t1kayyyy` và IP `192.168.209.x`. Nếu VM của bạn dùng user/IP khác, thay trong lệnh **và** sửa `ansible_user` / `ansible_host` trong `inventories/dev/hosts.ini` (và `prod/hosts.ini`).

### 1. Chuẩn bị VM

```bash
# Trên ubuntu-control — cài Ansible (pin cùng version với Docker Lab)
sudo apt update
sudo apt install -y git python3 python3-pip
python3 -m pip install --user "ansible==10.7.0"   # ansible-core 2.17, kèm community.general
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
ansible --version

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
# Bước 0: Cài collections cần thiết
ansible-galaxy collection install -r requirements.yml

# Bước 1: Kiểm tra server (preflight check) — chạy remote qua SSH
bash scripts/preflight.sh t1kayyyy@192.168.209.11 t1kayyyy@192.168.209.21

# Bước 2: Chạy playbook
ansible-playbook playbooks/site.yml

# Bước 3: Verify nginx (inventory mặc định là dev → port 8080)
curl http://192.168.209.11:8080

# Từ lần chạy sau: dry run trước khi apply thay đổi
ansible-playbook playbooks/site.yml --check --diff
```

### Chạy theo tag

```bash
# Chỉ chạy security tasks
ansible-playbook playbooks/site.yml --tags security

# Chỉ cài packages
ansible-playbook playbooks/site.yml --tags packages

# Chỉ deploy nginx
ansible-playbook playbooks/site.yml --tags nginx

# Chỉ chạy health check của nginx
ansible-playbook playbooks/site.yml --tags verify
```

Tags theo role: `common`, `security`, `docker`, `nginx`. Tags theo chức năng: `packages`, `users`, `system`, `ssh`, `firewall`, `fail2ban`, `verify`.

---

## 🌍 Multi-environment

Project hỗ trợ 3 môi trường: **dev**, **prod** và **docker** (lab). Giá trị mặc định nằm trong `roles/*/defaults/main.yml`; `inventories/<env>/group_vars/all.yml` chỉ chứa những gì **khác** mặc định.

### Chạy trên Dev

```bash
ansible-playbook -i inventories/dev/hosts.ini playbooks/site.yml
```

### Chạy trên Prod

```bash
ansible-playbook -i inventories/prod/hosts.ini playbooks/site.yml
```

> [!WARNING]
> `inventories/prod/hosts.ini` hiện trỏ tới **cùng IP với dev** (để demo trên lab). Sửa IP/user thành server prod thật trước khi chạy. Prod tắt SSH password auth — đảm bảo đã đăng nhập được bằng SSH key, nếu không sẽ tự khoá mình.

### Chạy trên Docker Lab (Giả lập cục bộ)

Nếu không sử dụng VMware, bạn có thể chạy thử nghiệm dự án hoàn chỉnh trên Docker bằng Docker Compose (yêu cầu máy host đã cài **Git** và **Docker Desktop** đang chạy). Mọi lệnh đều chạy từ **một terminal** trên máy host, tại thư mục project.

0. **Clone project** (Compose build image và mount code từ thư mục này):
   ```bash
   git clone https://github.com/t1kay/auto-server-provision.git
   cd auto-server-provision
   ```

1. **Khởi động cụm Lab (Docker containers)**:
   ```bash
   docker compose up -d --build
   docker compose ps          # 3 container phải ở trạng thái Up
   ```
   Lần đầu mất vài phút (tải image Ubuntu, cài Ansible). Đã build từ bản cũ thì build lại: `docker compose build --no-cache`.

   Lệnh này sẽ khởi động 3 container kết nối chung mạng nội bộ `ansible-net`:
   - `ansible-control`: Node điều khiển (cài sẵn Ansible, mount mã nguồn dự án). Khi khởi động lần đầu, container tự sinh SSH key pair vào volume `lab-keys`.
   - `web01`: Target node giả lập webserver (Ubuntu SSH) — đọc public key từ volume `lab-keys` rồi khởi động sshd.
   - `db01`: Target node giả lập database server (Ubuntu SSH).

2. **Truy cập control node và chạy thử preflight check**:
   ```bash
   docker exec -it ansible-control bash scripts/preflight.sh t1kayyyy@web01 t1kayyyy@db01
   ```

3. **Chạy Ansible Playbook**:
   Chạy lệnh sau để thực thi toàn bộ playbook trên môi trường Docker:
   ```bash
   docker exec -it ansible-control ansible-playbook -i inventories/docker/hosts.ini playbooks/site.yml
   ```
   *(Để chỉ test cài đặt Docker, thêm `--tags docker`)*

   Lần đầu mất vài phút (cài Docker Engine lên node). Xem `PLAY RECAP` cuối output: phải là `failed=0`. Chạy lại lần 2 phải ra `changed=0` (idempotency).

   > [!NOTE]
   > Trong môi trường Docker container, các tác vụ liên quan đến hệ thống (như thay đổi Hostname, cài đặt Timezone, đồng bộ NTP) và bảo mật (như kích hoạt UFW Firewall, chạy Fail2ban) sẽ được tự động bỏ qua để tránh lỗi phân quyền kernel đặc quyền của Docker Desktop.
   >
   > Container không có systemd: sau khi container **khởi động lại** (restart Docker Desktop, `docker compose restart`...) chỉ có sshd chạy — nginx sẽ không tự bật lại. Chạy lại playbook (bước 3) là xong. Tương tự, Docker Engine được cài nhưng daemon không chạy trong lab, và cấu hình SSH hardening chỉ có hiệu lực từ lần container khởi động lại.

4. **Kiểm tra kết quả**:
   - Truy cập trang Nginx trực tiếp từ máy host (Windows/Mac) qua port forward: [http://localhost:8080](http://localhost:8080)
   - Hoặc curl từ control node:
     ```bash
     docker exec -it ansible-control curl http://web01:8080
     ```

5. **Tắt môi trường Lab**:
   ```bash
   docker compose down        # giữ SSH key
   docker compose down -v     # xoá luôn volume lab-keys (key mới ở lần up sau)
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
| Docker Engine | ✅ Cài + chạy | ✅ Cài + chạy | ⚠️ Chỉ cài package (daemon không chạy — không có systemd) |


### Dry Run (Check Mode)

```bash
# Xem những gì SẼ thay đổi mà không thực sự chạy
ansible-playbook -i inventories/prod/hosts.ini playbooks/site.yml --check --diff
```

> [!NOTE]
> Check mode chỉ dùng được **sau lần chạy thật đầu tiên**. Trên server mới, check mode không thực sự thêm apt repo của Docker hay tạo group `docker`, nên các task phía sau sẽ báo lỗi dù lần chạy thật không sao.

---

## ⚙️ Biến cấu hình

### Common (`roles/common/defaults/main.yml`)

| Biến | Giá trị mặc định | Mô tả |
|------|-------------------|-------|
| `devops_user` | `devops` | User được tạo trên tất cả server |
| `server_timezone` | `Asia/Ho_Chi_Minh` | Timezone hệ thống |
| `common_packages` | vim, curl, git, ... | Packages cài trên mọi node |
| `is_container_lab` | `false` | `true` ở Docker Lab: bỏ qua hostname/timezone/restart service |

### Nginx (`roles/nginx/defaults/main.yml`)

| Biến | Giá trị mặc định | Mô tả |
|------|-------------------|-------|
| `nginx_port` | `80` | Port nginx listen |
| `nginx_server_name` | `_` | `server_name` (mặc định nhận mọi host) |
| `nginx_root` | `/var/www/html` | Thư mục web root |
| `nginx_worker_processes` | `auto` | Số worker process |
| `nginx_worker_connections` | `768` | Số connection mỗi worker |
| `nginx_enable_gzip` | `true` | Bật gzip compression |
| `nginx_enable_rate_limit` | `false` | Bật rate limiting |
| `nginx_upstream_servers` | `[]` | Backend cho `/api/` (`host:port`) |
| `nginx_custom_headers` | `[]` | Header thêm, dạng `- { name: X-Foo, value: bar }` |
| `nginx_verify` | `true` | Health check `http://localhost:<port>` sau khi deploy |

### Security Defaults (`roles/security/defaults/main.yml`)

| Biến | Giá trị mặc định | Mô tả |
|------|-------------------|-------|
| `ssh_port` | `22` | SSH port |
| `ssh_permit_root_login` | `no` | Disable root SSH login |
| `ssh_password_authentication` | `no` | Disable password auth |
| `ssh_max_auth_tries` | `3` | Số lần thử đăng nhập tối đa mỗi kết nối |
| `ufw_default_incoming` | `deny` | UFW default policy |
| `ufw_allowed_ports` | `[80/tcp]` | Port mở thêm (SSH luôn được mở theo `ssh_port`) |
| `fail2ban_maxretry` | `5` | Max SSH failures before ban |
| `fail2ban_bantime` | `3600` | Thời gian ban (giây) |
| `fail2ban_findtime` | `600` | Cửa sổ đếm số lần thất bại (giây) |
| `skip_ssh_hardening` / `skip_firewall` / `skip_fail2ban` | `false` | Bỏ qua từng phần (Docker Lab bật `skip_firewall`, `skip_fail2ban`) |

---

## 🧪 Chất lượng code & CI

Mỗi lần push, GitHub Actions chạy:

```bash
yamllint .
ansible-lint                     # profile: production
ansible-playbook -i inventories/<env>/hosts.ini playbooks/site.yml --syntax-check   # dev, prod, docker
shellcheck scripts/*.sh docker/*.sh
```

Chạy local: `pip install ansible-core ansible-lint yamllint`, `ansible-galaxy collection install -r requirements.yml` (cần cho syntax-check), cài [shellcheck](https://github.com/koalaman/shellcheck#installing) rồi chạy các lệnh trên.

> [!WARNING]
> Các phiên bản cũ của repo từng commit SSH private key của Docker Lab (`docker/ssh/id_rsa`). Key đó vẫn còn trong git history — coi như đã lộ và **không dùng nó cho bất kỳ server thật nào**. Từ bản này, key được sinh tự động khi chạy lab.

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
- **Role defaults** — Giá trị mặc định đặt trong `roles/*/defaults`, env chỉ override phần khác biệt

### Bash Scripting
- **Exit codes** — Script trả về 0 (success) hoặc 1 (failure)
- **Error handling** — `set -euo pipefail` cho robust scripting
- **System commands** — `free`, `df`, `uname`, `ss` để kiểm tra hệ thống

### Linux Security
- **SSH Hardening** — Disable root, disable password, limit retries (áp dụng an toàn thông qua key auth trên Docker Lab)
- **UFW Firewall** — Default deny, whitelist only needed ports
- **Fail2ban** — Tự động ban IP brute force

---

## 🛠 Troubleshooting

| Triệu chứng | Nguyên nhân / cách xử lý |
|---|---|
| `couldn't resolve module/action 'ansible.builtin.deb822_repository'` | Ansible quá cũ (thường do `apt install ansible`). Cài lại bằng pip như phần [Hướng dẫn cài đặt](#-hướng-dẫn-cài-đặt). |
| `UNREACHABLE` / `Permission denied (publickey)` | Chưa `ssh-copy-id` sang node, hoặc sai `ansible_user` trong `inventories/<env>/hosts.ini`. |
| `Missing sudo password` | Chưa cấu hình passwordless sudo (bước 3 phần cài đặt). |
| `--check` báo lỗi ở task Docker trên server mới | Bình thường — xem ghi chú ở phần Dry Run. Chạy thật một lần trước. |
| `curl` VM không trả về trang | Dev/Docker dùng port **8080**, prod dùng **80**. |
| Docker Lab: `No package matching 'vim'` | Image node cũ (build trước bản sửa). Build lại: `docker compose build --no-cache` rồi `docker compose up -d`. |
| Docker Lab: `curl web01:8080` báo `Connection refused` | Nginx chưa chạy: playbook chưa chạy xong (xem `PLAY RECAP`) hoặc container vừa khởi động lại. Chạy lại playbook. |
| Docker Lab: preflight báo `Permission denied (publickey)` | Node chưa nhận key — đợi ~10 giây sau `up` rồi thử lại; vẫn lỗi thì `docker compose down -v` rồi `up -d` lại. |
| Docker Lab: `Cannot connect to the Docker daemon` | Docker Desktop chưa mở / chưa chạy xong. |
| Docker Lab: port 8080/2221/2222 đã bị dùng | Tắt chương trình đang chiếm port, hoặc đổi `ports` trong `docker-compose.yml`. |

---

## 📝 License

MIT License — see [LICENSE](LICENSE) for details.

---


