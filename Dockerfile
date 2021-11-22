FROM python:3.9.7-slim-buster AS builder

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    sshpass curl zip unzip gnupg curl jq less wget openssh-client && \
    curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip && \
    unzip awscliv2.zip && \
    ./aws/install && \
    apt --purge autoremove -y zip gnupg curl && \
    apt-get remove --purge ${builds_deps} -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists && \
    cd / && rm -rf /work && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/ && \
    pip --no-cache-dir  install pip --upgrade && \
    pip install ansible boto3


FROM python:3.9.7-slim-buster AS app

COPY --from=builder /usr/local/aws-cli /usr/local/aws-cli
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/lib/python3.9 /usr/local/lib/python3.9

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends openssh-client sshpass && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists && \
    cd / && rm -rf /work && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

WORKDIR /work

RUN mkdir /etc/ansible/ /ansible
RUN echo "[local]" >> /etc/ansible/hosts && \
    echo "localhost" >> /etc/ansible/hosts

RUN mkdir -p /ansible/playbooks
WORKDIR /ansible/playbooks

ENV ANSIBLE_GATHERING smart
ENV ANSIBLE_HOST_KEY_CHECKING false
ENV ANSIBLE_RETRY_FILES_ENABLED false
ENV ANSIBLE_ROLES_PATH /ansible/playbooks/roles
ENV ANSIBLE_SSH_PIPELINING True
ENV PATH /ansible/bin:$PATH
ENV PYTHONPATH /ansible/lib

ENTRYPOINT ["ansible-playbook"]