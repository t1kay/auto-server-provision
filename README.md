# 🚀 Auto Server Provision

[![CI](https://github.com/t1kay/auto-server-provision/actions/workflows/ci.yml/badge.svg)](https://github.com/t1kay/auto-server-provision/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Dự án này dùng **Ansible** để tự động cài đặt và cấu hình server Ubuntu.
Chỉ cần chạy **một lệnh**, server sẽ được cài sẵn: user quản trị, bảo mật SSH, firewall, fail2ban, Docker và Nginx.

🎬 **Video demo:** https://youtu.be/d0qSQEahTS8

---

## Dự án làm gì?

Playbook chạy lần lượt 4 bước (role):

| Bước | Role | Việc làm |
|---|---|---|
| 1 | `common` | Cài gói cơ bản, tạo user `devops` có quyền sudo, đặt hostname và múi giờ |
| 2 | `security` | Chặn đăng nhập root, bật firewall UFW, bật fail2ban chống dò mật khẩu |
| 3 | `docker` | Cài Docker Engine và Docker Compose |
| 4 | `nginx` | Cài Nginx, tạo trang web mẫu và tự kiểm tra trang có chạy không |

Ngoài ra còn có `scripts/preflight.sh` để **kiểm tra server trước khi cài** (OS, RAM, ổ đĩa, SSH, Python).

Chạy lại playbook nhiều lần vẫn an toàn — lần thứ 2 sẽ không thay đổi gì (`changed=0`).

---

## Cách nhanh nhất: chạy thử bằng Docker

Không cần máy ảo, không cần cài Ansible. Chỉ cần **Git** và **Docker Desktop** (đang mở).

**1. Tải code về**

```bash
git clone https://github.com/t1kay/auto-server-provision.git
```

```bash
cd auto-server-provision
```

**2. Bật 3 container** (1 máy điều khiển + 2 server `web01`, `db01`)

```bash
docker compose up -d --build
```

Lần đầu mất vài phút. Kiểm tra bằng `docker compose ps` — cả 3 container phải ở trạng thái `Up`.

**3. Kiểm tra server trước khi cài** (không bắt buộc)

```bash
docker exec -it ansible-control bash scripts/preflight.sh t1kayyyy@web01 t1kayyyy@db01
```

**4. Chạy cài đặt**

```bash
docker exec -it ansible-control ansible-playbook -i inventories/docker/hosts.ini playbooks/site.yml
```

Xem dòng `PLAY RECAP` ở cuối: thấy `failed=0` là thành công.

**5. Xem kết quả**

Mở trình duyệt: http://localhost:8080

**6. Tắt khi xong**

```bash
docker compose down
```

> **Lưu ý:** Trong Docker, các phần cần quyền hệ thống (firewall, fail2ban, hostname, múi giờ) sẽ được **tự động bỏ qua**. Nếu khởi động lại container thì Nginx không tự bật lại — chỉ cần chạy lại bước 4.

---

## Chạy trên máy ảo (VMware)

Dùng cách này nếu muốn chạy **đầy đủ** mọi tính năng (gồm firewall, fail2ban).

### Chuẩn bị 3 máy ảo Ubuntu 22.04

| Máy | Vai trò | IP |
|---|---|---|
| ubuntu-control | Máy chạy Ansible | 192.168.209.10 |
| web01 | Web server | 192.168.209.11 |
| db01 | Database server | 192.168.209.21 |

Mạng: VMnet **Host-only** (192.168.209.0/24).

> Ví dụ dưới dùng user `t1kayyyy`. Nếu bạn dùng user hoặc IP khác, hãy sửa trong lệnh **và** trong file `inventories/dev/hosts.ini`.

### Bước 1 — Cài Ansible trên `ubuntu-control`

Cài bằng `pip` (bản `apt install ansible` quá cũ, sẽ bị lỗi):

```bash
sudo apt update && sudo apt install -y git python3 python3-pip
```

```bash
python3 -m pip install --user "ansible==10.7.0"
```

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

### Bước 2 — Cho phép `ubuntu-control` SSH vào 2 server

```bash
ssh-keygen -t ed25519
```

```bash
ssh-copy-id t1kayyyy@192.168.209.11
```

```bash
ssh-copy-id t1kayyyy@192.168.209.21
```

### Bước 3 — Cho phép dùng sudo không cần mật khẩu

Đăng nhập vào **từng** server (`web01`, `db01`) và chạy:

```bash
echo "t1kayyyy ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/t1kayyyy
```

### Bước 4 — Tải code và kiểm tra kết nối

```bash
git clone https://github.com/t1kay/auto-server-provision.git && cd auto-server-provision
```

```bash
ansible-galaxy collection install -r requirements.yml
```

```bash
ansible all -m ping
```

Thấy `"ping": "pong"` ở cả `web01` và `db01` là được.

### Bước 5 — Chạy cài đặt

```bash
ansible-playbook playbooks/site.yml
```

Kiểm tra: `curl http://192.168.209.11:8080`

---

## Các môi trường

Có 3 bộ cấu hình trong thư mục `inventories/`:

| | Dev | Prod | Docker |
|---|---|---|---|
| Port Nginx | 8080 | 80 | 8080 |
| Nén gzip, giới hạn request | Tắt | Bật | Tắt |
| Đăng nhập SSH bằng mật khẩu | Cho phép | Cấm (chỉ dùng key) | Cấm |
| Firewall + fail2ban | Bật | Bật (chặt hơn) | Bỏ qua |

Mặc định chạy **dev**. Muốn chọn môi trường khác thì thêm `-i`:

```bash
ansible-playbook -i inventories/prod/hosts.ini playbooks/site.yml
```

> ⚠️ File `inventories/prod/hosts.ini` đang dùng **cùng IP với dev** để demo. Hãy sửa thành server thật trước khi chạy prod, và chắc chắn bạn đã đăng nhập được bằng SSH key (prod cấm mật khẩu).

---

## Mẹo hay dùng

**Chỉ chạy một phần** bằng `--tags`:

```bash
ansible-playbook playbooks/site.yml --tags nginx
```

Các tag có sẵn: `common`, `security`, `docker`, `nginx`, `packages`, `users`, `system`, `ssh`, `firewall`, `fail2ban`, `verify`.

**Xem trước thay đổi** mà không áp dụng (chỉ dùng sau lần chạy thật đầu tiên):

```bash
ansible-playbook playbooks/site.yml --check --diff
```

**Đổi cấu hình**: giá trị mặc định nằm trong `roles/<tên-role>/defaults/main.yml`. Muốn đổi cho từng môi trường thì sửa `inventories/<môi-trường>/group_vars/all.yml`.

---

## Cấu trúc thư mục

```
auto-server-provision/
├── playbooks/site.yml     # Playbook chính
├── roles/                 # common, security, docker, nginx
├── inventories/           # dev, prod, docker (danh sách server + cấu hình)
├── scripts/preflight.sh   # Kiểm tra server trước khi cài
├── docker/                # File dựng môi trường Docker để chạy thử
└── docker-compose.yml
```

---

## Gặp lỗi?

| Lỗi | Cách sửa |
|---|---|
| `couldn't resolve module ... deb822_repository` | Ansible quá cũ. Cài lại bằng `pip` (Bước 1). |
| `UNREACHABLE` hoặc `Permission denied (publickey)` | Chưa chạy `ssh-copy-id`, hoặc sai user/IP trong `hosts.ini`. |
| `Missing sudo password` | Chưa làm Bước 3 (sudo không mật khẩu). |
| `curl` không ra trang web | Dev/Docker dùng port **8080**, prod dùng **80**. |
| Docker: `Connection refused` khi mở trang | Nginx chưa chạy. Chạy lại lệnh cài đặt. |
| Docker: `Cannot connect to the Docker daemon` | Docker Desktop chưa mở. |
| Docker: port 8080/2221/2222 bị chiếm | Tắt chương trình đang dùng port, hoặc đổi port trong `docker-compose.yml`. |
| Docker: lỗi lạ sau khi cập nhật code | Build lại: `docker compose build --no-cache` rồi `docker compose up -d`. |

> ⚠️ Các bản cũ của repo từng commit một SSH private key (`docker/ssh/id_rsa`). Key đó vẫn còn trong lịch sử git — **đừng dùng nó cho server thật**. Bản hiện tại tự sinh key mới mỗi khi dựng môi trường Docker.

---

## License

MIT — xem file [LICENSE](LICENSE).
