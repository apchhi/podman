**Podman — это daemonless инструмент для запуска и управления OCI‑контейнерами, совместимый с Docker‑CLI; для работы достаточно установленного `podman`, базовых прав (root или rootless), и доступа к реестрам/томам; ниже — сжатое руководство для `README.md` с ключевыми командами и требованиями.**   [Podman](https://docs.podman.io/en/latest/index.html)  [Podman](https://podman.io/docs/documentation)

---

# Что такое Podman
**Podman** — это **бездемоновый (daemonless)**, Linux‑native инструмент для создания, запуска и управления OCI‑контейнерами и подами; CLI во многом совместим с Docker, поэтому многие команды и сценарии переносятся легко.   [Podman](https://docs.podman.io/en/latest/index.html)

---

# Что нужно для работы с Podman
- **Операционная система:** Linux (Fedora, RHEL, CentOS, Ubuntu и др.) или WSL2 на Windows.   [Podman](https://podman.io/docs/documentation)  
- **Пакет `podman`** установлен через пакетный менеджер дистрибутива или официальные инструкции.   [Podman](https://podman.io/docs/documentation)  
- **Права:** можно запускать контейнеры **от root** или в **rootless** режиме (непривилегированный пользователь).   [Podman](https://docs.podman.io/en/latest/index.html)  
- **Реестры и сети:** доступ к реестрам (Docker Hub, quay.io, приватные реестры) и базовые сетевые настройки (bridge, host, port mapping).   [Podman](https://podman.io/docs/documentation)  
- **Хранилище:** понимание томов (volumes) и bind‑mounts для сохранения данных между перезапусками.   [Podman](https://podman.io/docs)

---

# Быстрый набор команд (для README.md)
**Запуск контейнера**
```bash
podman run -it --rm registry.fedoraproject.org/fedora:latest bash
```

**Списки**
```bash
podman ps        # активные контейнеры
podman ps -a     # все контейнеры
podman images    # образы
```

**Управление**
```bash
podman stop <id>
podman rm <id>
podman rmi <image_id>
```

**Сборка образа**
```bash
podman build -t myimage:latest -f Dockerfile .
```

**Работа с реестром**
```bash
podman login registry.example.com
podman push myimage:latest registry.example.com/myrepo/myimage:latest
podman pull registry.example.com/myrepo/myimage:latest
```


**Кратко:** **Ниже — расширенный набор практических команд и шаблонов для `README.md`, которые покрывают установку, rootless‑режим, сборку/запуск образов, работу с томами и сетями, управление подами, отладку и безопасную зачистку окружения.** Эти команды подходят для Linux (включая WSL2 на Windows) и опираются на официальную документацию Podman.   [Podman](https://podman.io/docs/documentation)  [Podman](https://docs.podman.io/en/latest/Commands.html)

---

### Установка и проверка
- **Установить (Fedora/Ubuntu/Debian):**
```bash
# Fedora
sudo dnf install -y podman

# Ubuntu
sudo apt update
sudo apt install -y podman
```
- **Проверить версию:**
```bash
podman --version
podman info
```
(Подробности в официальной документации).   [Podman](https://podman.io/docs/documentation)

---

### Rootless (непривилегированный) режим
- **Создать namespace для rootless:**
```bash
# Убедитесь, что у пользователя есть записи в /etc/subuid и /etc/subgid
podman system migrate
```
- **Запуск контейнера как обычный пользователь:**
```bash
podman run --rm -it alpine sh
```
Rootless имеет ограничения по сети и монтированию; см. руководство по rootless.   [Podman](https://docs.podman.io/en/latest/Tutorials.html)  [Podman](https://docs.podman.io/en/latest/Commands.html)

---

### Сборка и запуск образа
- **Сборка:**
```bash
podman build -t myapp:latest -f Dockerfile .
```
- **Запуск с пробросом портов и томом:**
```bash
podman run -d --name myapp \
  -p 8080:80 \
  -v /srv/myapp/data:/data:Z \
  myapp:latest
```
- **Запуск с переменными окружения и ограничениями ресурсов:**
```bash
podman run -d --name db \
  -e POSTGRES_PASSWORD=secret \
  --memory=512m --cpus=1 \
  postgres:15
```
(Флаги `:Z`/`:z` для SELinux).   [Podman](https://docs.podman.io/en/latest/Commands.html)

---

### Тома, бэкап и восстановление
- **Создать том:**
```bash
podman volume create myvol
podman run -v myvol:/data --name tmp alpine sh -c "echo hi > /data/hi"
```
- **Бэкап тома:**
```bash
podman run --rm -v myvol:/data -v $(pwd):/backup alpine \
  tar czf /backup/myvol.tgz -C /data .
```
- **Восстановление:**
```bash
podman run --rm -v myvol:/data -v $(pwd):/backup alpine \
  tar xzf /backup/myvol.tgz -C /data
```

---

### Поды и сеть
- **Создать под и запустить несколько контейнеров в нём:**
```bash
podman pod create --name webpod -p 8080:80
podman run -d --pod webpod nginx
podman run -d --pod webpod myapp
```
(Поды упрощают сетевую изоляцию и совместное использование namespace).   [Podman](https://docs.podman.io/en/latest/Commands.html)

---

### Отладка и управление
```bash
podman ps -a
podman logs <container>
podman exec -it <container> /bin/bash
podman inspect <container|image>
podman commit <container> myimage:snapshot
```

---

### Работа с реестром
```bash
podman login registry.example.com
podman tag myimage registry.example.com/repo/myimage:tag
podman push registry.example.com/repo/myimage:tag
podman pull registry.example.com/repo/myimage:tag
```

---

### Полная очистка
1) Остановить все контейнеры:
```bash
podman ps -q | xargs -r podman stop
```
2) Удалить все контейнеры:
```bash
podman ps -a -q | xargs -r podman rm -f
```
3) Удалить все образы:
```bash
podman images -q | xargs -r podman rmi -f
```
4) Очистить неиспользуемые объекты:
```bash
podman image prune -a -f
podman container prune -f
podman volume prune -f
podman system prune --all -f
```
5) Проверить:
```bash
podman ps -a
podman images
podman volume ls
```

---

**Полезно:** для подробных примеров и туториалов смотрите официальную документацию и раздел Tutorials.   [Podman](https://podman.io/docs/documentation)  [Podman](https://docs.podman.io/en/latest/Tutorials.html)

---

# Rootless и безопасность
- **Rootless режим** позволяет запускать контейнеры без прав root, повышая безопасность на хосте; многие команды работают одинаково, но есть ограничения по сети и монтированию.   [Podman](https://docs.podman.io/en/latest/index.html)  
- Для production рассмотрите интеграцию с системами управления образами и политиками безопасности (SELinux, seccomp).

---

# Ресурсы и помощь
- **Официальная документация Podman** — установка, руководство по началу работы, man‑страницы и troubleshooting.   [Podman](https://podman.io/docs/documentation)  [Podman](https://podman.io/docs)
