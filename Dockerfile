# Ubuntu Mate desktop with Firefox, Conda and JupyterLab
FROM docker.io/library/ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

# Ubuntu 22.04 installs firefox from snap by default
# https://www.omgubuntu.co.uk/2022/04/how-to-install-firefox-deb-apt-ubuntu-22-04
# Note Firefox sandboxing may not work, to disable it see
# https://wiki.mozilla.org/Security/Sandbox#Environment_variables
RUN apt-get update -y -q && \
    apt-get install -y -q \
        curl \
        dumb-init \
        expect \
        jq \
        less \
        tigervnc-standalone-server \
        ubuntu-mate-desktop \
        vim \
        xrdp && \
    add-apt-repository -y ppa:mozillateam/ppa && \
    printf 'Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' > /etc/apt/preferences.d/firefox && \
    apt-get install -y -q --allow-downgrades firefox && \
    apt-get purge -y -q \
        blueman \
        mate-screensaver \
        update-notifier && \
    apt-get autoremove -y -q && \
    apt-get clean -y -q && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/conda/Desktop /opt/conda/icons && \
    chown -R ubuntu:ubuntu /opt/conda

USER ubuntu
WORKDIR /home/ubuntu

ARG MINIFORGE_VERSION=25.1.1-0
RUN curl -sfL https://github.com/conda-forge/miniforge/releases/download/$MINIFORGE_VERSION/Miniforge3-$MINIFORGE_VERSION-Linux-`uname -m`.sh -o Miniforge3.sh && \
    bash Miniforge3.sh -b -f -p /opt/conda && \
    rm -f Miniforge.sh
COPY --chown=ubuntu:ubuntu environment.yml /opt/conda/environment.yml
RUN /opt/conda/bin/mamba shell init -s bash && \
    /opt/conda/bin/mamba env update --file /opt/conda/environment.yml

COPY --chown=ubuntu:ubuntu jupyter_logo.svg /opt/conda/icons/jupyter_logo.svg
COPY --chown=ubuntu:ubuntu jupyterlab.desktop /opt/conda/Desktop/jupyterlab.desktop

RUN mkdir /home/ubuntu/Desktop && \
    ln -s \
        /usr/share/applications/mate-terminal.desktop \
        /usr/share/applications/firefox.desktop \
        /opt/conda/Desktop/jupyterlab.desktop \
        /home/ubuntu/Desktop

USER root

COPY start-mate.sh start-tigervnc.sh start-xrdp.sh /usr/local/bin/
COPY xrdp.ini sesman.ini passwd.expect /etc/xrdp/

ARG UBUNTU_INITIAL_PASSWORD=ubuntu123
RUN rm /etc/xrdp/cert.pem /etc/xrdp/key.pem && \
    chmod a+r /etc/xrdp/* && \
    install -o ubuntu -d /run/xrdp && \
    install -o ubuntu -d /etc/xrdp/ubuntu && \
    echo "ubuntu:$UBUNTU_INITIAL_PASSWORD" | chpasswd

# /home/ubuntu may be overwritten with a persistent volume
# Create a copy and restore on first start if necessary
RUN rsync -a /home/ubuntu/ /home/ubuntu.orig/

USER ubuntu
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

EXPOSE 3389
EXPOSE 5901
# CMD ["/usr/local/bin/start-tigervnc.sh"]
# CMD ["/usr/local/bin/start-xrdp.sh"]
