# Troubleshooting Log

> Tổng hợp các lỗi quan trọng gặp phải trong quá trình thực hiện project, và bài học rút ra.

---

## Lỗi 1: Ansible role 'common' not found

**Ngày gặp:** Day 3–4

**Triệu chứng:**

```bash
ansible-playbook -i inventory.ini playbooks/site.yml
# → ERROR! the role 'common' was not found in
#   /home/t1kayyyy/auto-server-provision/auto-server-provision/playbooks/roles:...
```

**Nguyên nhân:**

Hai vấn đề xảy ra cùng lúc:

1. **Role path sai:** Ansible mặc định tìm roles **relative theo vị trí playbook** (`playbooks/roles/`), nhưng folder `roles/` nằm ở project root.

```
auto-server-provision/
├── playbooks/
│   └── site.yml          ← Ansible tìm roles ở: playbooks/roles/ ❌
├── roles/
│   └── common/           ← Roles thực tế nằm ở đây ✅
```

2. **Clone lồng nhau:** Clone repo bên trong repo cũ, tạo ra path `auto-server-provision/auto-server-provision/`.

**Cách fix:**

Tạo `ansible.cfg` ở project root để chỉ định đường dẫn:
```ini
[defaults]
inventory = inventory.ini
roles_path = roles
host_key_checking = False
```

Xóa thư mục lồng và clone lại sạch:
```bash
cd ~
rm -rf auto-server-provision
git clone https://github.com/t1kay/auto-server-provision.git
```

**Bài học:**
- Luôn tạo `ansible.cfg` ở project root để control `roles_path`, `inventory`
- Khi `git clone`, chú ý đang đứng ở thư mục nào — path lồng nhau (`a/a/`) là dấu hiệu clone sai vị trí
- Dùng `ansible-playbook --syntax-check` để verify trước khi chạy thật

---

## Lỗi 2: Timeout waiting for privilege escalation (sudo)

**Ngày gặp:** Day 3–4

**Triệu chứng:**

```bash
ansible-playbook playbooks/site.yml
# → fatal: [web01]: FAILED! => {"msg": "Timeout (12s) waiting for privilege escalation prompt: "}
```

**Nguyên nhân:**

Playbook dùng `become: true` (chạy lệnh với sudo). User `t1kayyyy` trên VM cần password cho sudo, nhưng Ansible không có password → chờ prompt → timeout.

**Cách fix:**

Cấu hình **passwordless sudo** trên mỗi VM:
```bash
echo "t1kayyyy ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/t1kayyyy
sudo chmod 440 /etc/sudoers.d/t1kayyyy
```

**Bài học:**
- `become: true` = Ansible chạy lệnh qua `sudo` → cần quyền sudo không hỏi password
- **Passwordless sudo** là best practice cho Ansible automation — cấu hình qua `/etc/sudoers.d/`
- Luôn dùng `visudo` hoặc `validate: "visudo -cf %s"` khi sửa sudoers — viết sai = mất quyền sudo hoàn toàn
- Nên setup passwordless sudo **ngay khi tạo VM**, trước khi viết playbook

---

## Lỗi 3: DNS failure — `systemd-resolved` gửi query sai interface

**Ngày gặp:** Day 3–4 (tạm thời) → Day 5–6 (lặp lại rõ ràng)

**Triệu chứng:**

```bash
git pull
# → fatal: Could not resolve host: github.com

# Nhưng internet vẫn có:
ping -c 2 8.8.8.8
# → 64 bytes from 8.8.8.8: time=42.3 ms  ← OK!
```

**Nguyên nhân:**

Ubuntu dùng `systemd-resolved` (`127.0.0.53`) làm DNS proxy, gắn DNS server theo **từng network interface**. Trong Netplan, `nameservers` khai báo dưới `ens37` (Host-only) thay vì `ens33` (NAT):

```yaml
# ❌ Sai — DNS gắn vào interface không có internet
ens37:                              # Host-only
  addresses: [192.168.209.10/24]
  nameservers:
    addresses: [8.8.8.8]           # DNS query gửi qua ens37 → timeout
```

```
App → 127.0.0.53 (systemd-resolved) → gửi qua ens37 (Host-only) → ❌ không có internet
                                      lẽ ra phải gửi qua ens33 (NAT) → ✅ có internet
```

`ping 8.8.8.8` vẫn OK vì **kernel routing** tự chọn interface đúng, nhưng `systemd-resolved` thì gắn cứng theo interface config.

**Cách fix:**

Chuyển `nameservers` sang interface NAT:
```yaml
# ✅ Đúng — DNS gắn vào interface có internet
ens33:
  dhcp4: true
  nameservers:
    addresses: [8.8.8.8]
ens37:
  addresses: [192.168.209.10/24]
```

```bash
sudo nano /etc/netplan/00-installer-config.yaml
sudo netplan apply
```

**Bài học:**
- `ping IP` thành công **≠** DNS hoạt động — đó là 2 tầng khác nhau (Network vs DNS)
- Khi VM có **multi-interface** (NAT + Host-only), phải chú ý service nào gắn với interface nào
- DNS cache có thể **che giấu lỗi config** — lỗi chỉ hiện sau khi restart VM
- `systemd-resolved` không dùng kernel routing table — nó gửi DNS query qua interface được chỉ định trong Netplan

---

## Lỗi 4: Nginx 403 Forbidden khi Verify

**Ngày gặp:** Day 8–10

**Triệu chứng:**
```json
"msg": "Status code was 403 and not [200]: HTTP Error 403: Forbidden",
"url": "http://localhost:8080"
```

**Nguyên nhân:**
Nginx mặc định tìm kiếm các file index (`index.html`, `index.htm`) trong thư mục root (`/var/www/html`). Khi cài đặt nginx thông thường, Ubuntu tạo file `index.nginx-debian.html` thay vì `index.html`. Do cấu hình Nginx chỉ tìm kiếm `index.html`, Nginx trả về lỗi `403 Forbidden` do thư mục không có file index mặc định và autoindex bị tắt.

**Cách fix:**
Thêm task trong `roles/common/tasks/main.yml` để tự động tạo và deploy một trang landing page custom sử dụng template [index.html.j2](file:///d:/auto-server-provision/roles/common/templates/index.html.j2) được thiết kế hiện đại, nhằm hiển thị đầy đủ thông tin server đã provision thành công.

---

## Lỗi 5: HTTP Status 000 & Could not resolve hostname web01

**Ngày gặp:** Day 8–10

**Triệu chứng:**
```bash
HTTP Status: 000
ssh: Could not resolve hostname web01: Temporary failure in name resolution
```

**Nguyên nhân:**
1. **Lỗi `hostname web01`**: OS của control node (`ubuntu-control`) không tự phân giải được tên `web01` vì chưa cấu hình trong `/etc/hosts` (Ansible kết nối được do ta đã chỉ định `ansible_host=192.168.209.11` trong inventory file).
2. **Lỗi `HTTP Status: 000`**: Do cổng `8080` bị chặn bởi UFW firewall trên host `web01`. Role `security` mặc định chỉ cho phép cổng `22` và `80`, trong khi môi trường `dev` chạy Nginx trên cổng `8080`.

**Cách fix:**
1. **Phân giải hostname**: Thêm ánh xạ IP vào `/etc/hosts` trên control node hoặc SSH trực tiếp bằng IP thay vì hostname (`ssh t1kayyyy@192.168.209.11`).
2. **Cho phép port 8080**: Khai báo biến `ufw_allowed_ports` đè trong `inventories/dev/group_vars/all.yml` để mở port `8080` cho môi trường dev.

---

## Tổng hợp

| # | Lỗi | Bài học cốt lõi |
|---|------|-----------------|
| 1 | Role not found | Luôn tạo `ansible.cfg` để control paths, chú ý vị trí `git clone` |
| 2 | Sudo timeout | Setup passwordless sudo **trước** khi viết playbook |
| 3 | DNS sai interface | Multi-interface: ping OK ≠ DNS OK, service gắn theo interface |
| 4 | Nginx 403 Forbidden | Đảm bảo trang index mặc định tương thích hoặc tự deploy index.html riêng |
| 5 | HTTP Status 000 & Hostname resolution | 1. SSH từ shell cần DNS/hosts hoặc dùng trực tiếp IP. <br>2. Đảm bảo Firewall mở đúng cổng ứng với từng môi trường |

---

*Cập nhật lần cuối: 2026-05-27*
