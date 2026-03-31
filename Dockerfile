FROM registry.fedoraproject.org/fedora:latest

RUN cat > /etc/yum.repos.d/fedora.repo <<'EOF'
[fedora]
name=Fedora $releasever - $basearch
baseurl=https://mirror.yandex.ru/fedora/linux/releases/$releasever/Everything/$basearch/os/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
EOF

RUN cat > /etc/yum.repos.d/fedora-updates.repo <<'EOF'
[fedora-updates]
name=Fedora $releasever - Updates - $basearch
baseurl=https://mirror.yandex.ru/fedora/linux/updates/$releasever/Everything/$basearch/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
EOF

RUN dnf -y update && \
    dnf -y install sudo git openssh-server bash-completion curl wget gcc make python3 nodejs && \
    dnf clean all

RUN useradd -m -s /bin/bash devuser && \
    echo "devuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/devuser && \
    chmod 0440 /etc/sudoers.d/devuser && \
    mkdir -p /workspace && chown devuser:devuser /workspace

USER devuser
WORKDIR /workspace
