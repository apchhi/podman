# Dev Container

`.devcontainer` — каталог с конфигурацией для Visual Studio Code Dev Containers (Remote - Containers). Он описывает, как собрать и запустить контейнер разработки, какие расширения и настройки установить, какие команды выполнить после создания контейнера и под каким пользователем работать. Размещается в корне репозитория рядом с исходным кодом: `./.devcontainer/`.

## Быстрый старт
1. Откройте проект в VS Code.
2. Установите расширение "Dev Containers" (Remote - Containers).
3. Command Palette → Dev Containers: Reopen in Container.
4. При первом запуске VS Code соберёт образ и запустит контейнер; терминал будет внутри контейнера.

## Что будет в репозитории
```
/README.md
/.devcontainer/
  ├─ devcontainer.json
  ├─ Dockerfile
  ├─ README.md
  └─ .dockerignore
```

## Что обычно лежит в .devcontainer
- `devcontainer.json` — главный манифест Dev Container.
- `Dockerfile` или `docker-compose.yml` — инструкции для сборки образа / описания окружения.
- `.dockerignore` — что исключить из контекста сборки.
- `README.md` — документация по конфигурации.
- Доп. скрипты/файлы инициализации.

---

## Подробно: devcontainer.json (ключевые поля)
- **name** — читаемое имя конфигурации.
- **build** — объект сборки:
  - `dockerfile` — имя Dockerfile (в .devcontainer).
  - `context` — путь контекста сборки (обычно `..`).
  - `args` — аргументы сборки.
- **image** — использовать готовый образ (либо `image`, либо `build`; при локальной сборке предпочтительнее `build`).
- **workspaceFolder** — путь внутри контейнера, где откроется проект (например `/workspace`).
- **workspaceMount** — bind‑маунт локальной папки в контейнер; рекомендуется:
  ```
  "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached"
  ```
- **runArgs** — дополнительные аргументы при запуске контейнера (например `["--name","dev-container"]`).
- **remoteUser** — пользователь внутри контейнера (должен быть создан в Dockerfile).
- **postCreateCommand** — команда, выполняемая один раз после создания контейнера.
- **postStartCommand** — команда при каждом старте контейнера.
- **settings** — настройки VS Code для контейнера (напр., терминал).
- **extensions** — список расширений, которые будут установлены в контейнере.
- **forwardPorts** — порты для проброса.
- **mounts** — дополнительные монтирования (docker socket, кеши).
- **containerEnv** — переменные окружения внутри контейнера.
- **features** — Dev Container features для автоматической установки инструментов.

Типичные ошибки:
- Указывать `remoteUser`, которого нет в Dockerfile.
- Неправильный `workspaceMount` (используйте `${localWorkspaceFolder}`).
- Конфликт `image` и `build` — лучше явно использовать один подход.
- Проблемы с правами на `workspaceFolder` — chown в Dockerfile решает это.

---

## Подробно: Dockerfile (рекомендации)
1. FROM — выбирайте стабильный базовый образ (например `registry.fedoraproject.org/fedora:latest`).
2. Репозитории — при необходимости задайте рабочие зеркала перед вызовом менеджера пакетов.
3. Установка пакетов — объединяйте RUN команды:
   ```dockerfile
   RUN dnf -y update && \
       dnf -y install sudo git ... && \
       dnf clean all
   ```
4. Очистка кешей — уменьшает размер образа.
5. Создание пользователя:
   ```dockerfile
   RUN useradd -m -s /bin/bash devuser && \
       echo "devuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/devuser && \
       chmod 0440 /etc/sudoers.d/devuser
   ```
6. Права и рабочая директория:
   ```dockerfile
   RUN mkdir -p /workspace && chown devuser:devuser /workspace
   USER devuser
   WORKDIR /workspace
   ```
7. SELinux — при монтировании с Fedora хоста используйте `:Z` или `:z`.
8. Добавьте `.dockerignore` чтобы исключить ненужные файлы из контекста.

Полезные директивы: `ARG`, `LABEL`, `EXPOSE`, `ENTRYPOINT`, `CMD`.

---

## Рекомендации по структуре README
- Короткое руководство в корневом README (этот раздел).
- Подробная техническая документация в `.devcontainer/README.md`:
  - Как запустить Dev Container.
  - Как пересобрать образ (Rebuild Container).
  - Описание полей devcontainer.json.
  - Описание Dockerfile и установленных пакетов.
  - Права и пользователи.
  - Примечания по Podman (если используется Podman вместо Docker).
  - Советы по бэкапу томов и отладке.

---

## Команды: сборка, запуск, очистка (Podman)
Из каталога проекта (где лежит `.devcontainer/Dockerfile`):

- Собрать образ:
  ```
  podman build -t localhost/fedora-dev:latest -f .devcontainer/Dockerfile .
  ```
  Точка (`.`) — это контекст сборки (каталог, файлы которого доступны для COPY/ADD). Указывайте контекст так, чтобы все файлы, требуемые Dockerfile, были в нём.

- Запустить контейнер (монтировать проект в /workspace):
  ```
  podman run -d --name dev-container -v /home/user/code/python/nachin:/workspace:Z localhost/fedora-dev:latest sleep infinity
  ```
  `:Z` — для SELinux на Fedora хоста; уберите, если не нужно.

- Остановить и удалить контейнер:
  ```
  podman stop dev-container
  podman rm dev-container
  ```

- Удалить образ:
  ```
  podman rmi localhost/fedora-dev:latest
  ```

- Полная очистка (внимание: удаляет всё):
  ```
  podman ps -q | xargs -r podman stop
  podman ps -a -q | xargs -r podman rm -f
  podman images -q | xargs -r podman rmi -f
  podman image prune -a -f
  podman system prune --all -f
  ```

---

## SELinux и права
- На Fedora хоста добавляйте `:Z` к bind‑маунтам: `-v /host/path:/workspace:Z`.
- Если появились проблемы с правами, в Dockerfile сделайте `chown devuser:devuser /workspace` перед переключением на `USER devuser`.

---

## Как VS Code использует контейнер
- UI VS Code запускается на хосте.
- VS Code Server (фоновые службы), расширения и терминал запускаются внутри контейнера.
- Терминал (Ctrl+`) будет bash в контейнере, команды выполняются в изолированном окружении контейнера.

---

## Отладка и часто используемые команды
- Просмотреть логи контейнера:
  ```
  podman logs dev-container
  ```
- Выполнить команду в контейнере:
  ```
  podman exec -it dev-container /bin/bash
  ```
- Проверить образы и контейнеры:
  ```
  podman images
  podman ps -a
  ```

---

## Советы по безопасности
- Не храните пароли в Dockerfile.
- Для SSH‑доступа используйте публичные ключи (добавьте `authorized_keys` после запуска контейнера), либо задавайте пароль безопасно через exec, а не в образе.
- Отключайте gpgcheck только при крайней необходимости; предпочтительно добавить нужные GPG‑ключи в образ.

---
Использовать podman exec

Если контейнер уже запущен (проверь podman ps), можно выполнить команду:
```bash

podman exec -it dev-container /bin/bash
```

или, если в образе нет bash:
```bash

podman exec -it dev-container /bin/sh
```

Это откроет интерактивную оболочку внутри контейнера.
2. Использовать podman attach

Если контейнер запущен с процессом, который поддерживает ввод/вывод (например bash или sleep infinity), можно подключиться:
```bash

podman attach dev-container
```
