# Project Plan: Automated Linux Server Provisioning
> Ansible + Bash · 2 tuần · Apply Intern DevOps

---

## Mục tiêu project

Tự động hóa việc cài đặt và cấu hình Linux server bằng Ansible và Bash scripting. Kết quả cuối là một GitHub repo public có thể demo trong buổi phỏng vấn intern DevOps.

---

## Kiến trúc hệ thống

```
Windows (máy bạn)
└── VMware Workstation
    ├── ubuntu-control  (1GB RAM, IP: 192.168.56.10)  ← Ansible chạy ở đây
    ├── web01           (512MB RAM, IP: 192.168.56.11)
    └── db01            (512MB RAM, IP: 192.168.56.21)
```

**Tech stack:** Ansible · Bash · VMware · Ubuntu Server 22.04 · GitHub

---

## Cấu trúc thư mục project

```
auto-server-provision/
├── inventory.ini
├── group_vars/
│   └── all.yml
├── roles/
│   └── common/
│       ├── tasks/main.yml
│       └── templates/nginx.conf.j2
├── playbooks/
│   └── site.yml
├── scripts/
│   └── preflight.sh
├── docs/
│   └── screenshots/
│       ├── 01-ansible-ping.png
│       ├── 02-first-playbook.png
│       ├── 03-preflight.png
│       ├── 04-ssh-hardening.png
│       ├── 05-ufw-status.png
│       ├── 06-check-mode.png
│       └── demo.gif
└── README.md
```

> Dùng [ScreenToGif](https://www.screentogif.com/) (free) để quay GIF demo ngày 10.

---

## Tuần 1

### Ngày 1–2: Setup môi trường
**Mục tiêu:** 3 VM chạy, Ansible ping thành công cả 2 managed node

Việc cần làm:
- Cài Ubuntu Server 22.04 trên VMware cho 3 VM (ubuntu-control, web01, db01)
- Gán IP tĩnh cho từng VM qua Netplan
- Cài Ansible trên ubuntu-control
- Tạo SSH key pair, copy public key sang 2 managed node
- Tạo `inventory.ini` khai báo các host theo group
- Chạy `ansible all -m ping` thành công
- Init git repo, push lên GitHub

Kiến thức học được:
- Ansible architecture: control node vs managed node
- SSH key-based authentication
- Ansible inventory và group
- Cơ bản về Linux networking (IP tĩnh, Netplan)

Cần capture:
- Screenshot `ansible all -m ping` ra 3 dòng `SUCCESS` → lưu `docs/screenshots/01-ansible-ping.png`
- Screenshot `ip addr` của ubuntu-control thấy IP tĩnh `192.168.56.10`

### Ngày 3–4: Playbook đầu tiên
**Mục tiêu:** Chạy được playbook tự động cấu hình server

Việc cần làm:
- Viết playbook cài nginx và git trên webservers
- Tạo user `devops` với sudo trên tất cả node
- Set hostname và timezone
- Tách thành role `roles/common/tasks/main.yml`
- Khai báo biến trong `group_vars/all.yml`

Kiến thức học được:
- Cú pháp YAML và Ansible playbook
- Ansible modules: `apt`, `user`, `hostname`, `timezone`
- Khái niệm Ansible roles
- Biến trong Ansible (group_vars)

Cần capture:
- Screenshot terminal khi playbook chạy — thấy các task `CHANGED` chạy qua từng host → lưu `docs/screenshots/02-first-playbook.png`
- Screenshot `curl http://192.168.56.11` ra trang nginx mặc định

### Ngày 5: Bash preflight script
**Mục tiêu:** Có script kiểm tra server trước khi chạy Ansible

Việc cần làm:
- Viết `scripts/preflight.sh` kiểm tra:
  - OS có phải Ubuntu không
  - RAM còn trống trên 200MB không
  - Disk còn trống trên 2GB không
  - SSH port có mở không
- Script in ra kết quả pass/fail từng mục
- Tích hợp vào quy trình: chạy script trước, nếu pass mới chạy Ansible

Kiến thức học được:
- Bash scripting cơ bản: biến, điều kiện, vòng lặp
- Các lệnh Linux: `free`, `df`, `uname`, `nc`
- Exit code và error handling trong Bash

Cần capture:
- Screenshot `preflight.sh` chạy ra output pass/fail từng mục → lưu `docs/screenshots/03-preflight.png`

---

## Tuần 2

### Ngày 6–7: Roles và SSH hardening
**Mục tiêu:** Cấu trúc code chuẩn, server được bảo mật cơ bản

Việc cần làm:
- Tách playbook thành role rõ ràng: `roles/common`, `roles/security`
- SSH hardening trong role security:
  - Disable root login (`PermitRootLogin no`)
  - Tắt password auth (`PasswordAuthentication no`)
  - Cấu hình UFW firewall: chỉ mở port 22, 80
- Cài fail2ban chống brute force

Kiến thức học được:
- Ansible roles structure (tasks, handlers, defaults)
- Ansible handlers và notify
- SSH hardening cơ bản
- UFW firewall

Cần capture:
- Screenshot SSH bị từ chối khi thử `ssh root@192.168.56.11` (show hardening hoạt động) → lưu `docs/screenshots/04-ssh-hardening.png`
- Screenshot `ufw status` thấy các rule firewall → lưu `docs/screenshots/05-ufw-status.png`

### Ngày 8–9: Variables và Jinja2 template
**Mục tiêu:** Config linh hoạt, chạy được trên nhiều môi trường

Việc cần làm:
- Tạo 2 inventory: `inventories/dev/` và `inventories/prod/`
- Dùng Jinja2 template cho `nginx.conf` (server_name, port động theo biến)
- Khai báo biến khác nhau giữa dev và prod trong `group_vars`
- Test chạy playbook với `--check` mode (dry run)

Kiến thức học được:
- Jinja2 template syntax: `{{ variable }}`, `{% if %}`, `{% for %}`
- Multi-environment với Ansible
- Ansible `--check` mode và `--diff` mode
- Idempotency — chạy nhiều lần kết quả vẫn như nhau

Cần capture:
- Screenshot chạy playbook với `--check` mode thấy `would change` → lưu `docs/screenshots/06-check-mode.png`
- Screenshot `nginx.conf` khác nhau giữa dev và prod

### Ngày 10: Demo và Documentation
**Mục tiêu:** Project hoàn chỉnh, sẵn sàng đưa vào CV

Việc cần làm:
- Chạy `ansible-lint` kiểm tra code quality, fix warning
- Viết README đầy đủ:
  - Mô tả project
  - Sơ đồ kiến trúc
  - Hướng dẫn chạy từng bước
  - Screenshot terminal
- Quay GIF demo chạy playbook từ đầu đến cuối
- Đảm bảo repo public, commit history sạch

Kiến thức học được:
- ansible-lint
- Cách viết README kỹ thuật
- Cách present project trong CV và phỏng vấn

Cần capture:
- **GIF demo** toàn bộ luồng: chạy `preflight.sh` → chạy `ansible-playbook site.yml` → verify nginx lên → xong → lưu `docs/screenshots/demo.gif`
- Dùng [ScreenToGif](https://www.screentogif.com/) để quay GIF trên Windows

---

## Deliverables cuối project

| # | Deliverable | Mô tả |
|---|---|---|
| 1 | GitHub repo public | Code đầy đủ, commit history rõ ràng |
| 2 | 3+ Ansible playbooks | site.yml, roles common + security |
| 3 | Bash preflight script | Kiểm tra server trước khi provision |
| 4 | Jinja2 template | nginx.conf động theo biến |
| 5 | README + demo GIF | Tài liệu đầy đủ để show trong CV |
| 6 | docs/screenshots/ | 6 screenshot + 1 GIF demo theo từng ngày |

---

## Setup môi trường (đã hoàn thành)

### Phần mềm cần cài trên Windows
- VMware Workstation Pro (free từ 2024)
- MobaXterm — SSH vào VM từ Windows

### Thông tin 3 VM

| VM | Role | IP | RAM |
|---|---|---|---|
| ubuntu-control | Control node (chạy Ansible) | 192.168.56.10 | 1024 MB |
| web01 | Managed node — web server | 192.168.56.11 | 512 MB |
| db01 | Managed node — db server | 192.168.56.21 | 512 MB |

- OS: Ubuntu Server 22.04 LTS
- Username: devops (hoặc tên bạn đặt lúc cài)
- Mạng: VMnet1 Host-only

---

## Tips để nổi bật khi apply

- Commit theo conventional commits: `feat:`, `fix:`, `chore:`
- README có badge + screenshot terminal thực tế
- Trong phỏng vấn kể được: "Tôi gặp vấn đề X, giải quyết bằng cách Y"
- Idempotency là điểm cộng lớn — nhắc đến trong CV và phỏng vấn
