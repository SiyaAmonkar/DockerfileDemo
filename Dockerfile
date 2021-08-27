FROM registry.access.redhat.com/ubi7/ubi


ENV CONDA_HOME=${CONDA_HOME:-/opt/conda}
ENV PATH=$CONDA_HOME/bin:$PATH

ENV OPEN_CE_CONDA_BUILD=3.21.4

ENV CICD_GROUP=cicd
ARG GROUP_ID=1500
ENV BUILD_USER=builder
ARG BUILD_ID=1084

ARG OC_PASS
ARG OC_USER
ARG OC_CLUSTER
ARG ARGO_PROJECT=open-ce-ci

RUN export ARCH="$(uname -m)" && \
    yum repolist && yum install -y rsync openssh-clients && \
    # Create CICD Group
    groupadd --non-unique --gid ${GROUP_ID} ${CICD_GROUP} && \
    # Adduser Builder
    useradd -b /home --non-unique --create-home --gid ${GROUP_ID} --groups wheel \
    --uid ${BUILD_ID} --comment "User for Building" ${BUILD_USER} && \
    curl -o /tmp/anaconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-${ARCH}.sh && \
    chmod +x /tmp/anaconda.sh && \
    /bin/bash /tmp/anaconda.sh -f -b -p /opt/conda && \
    rm -f /tmp/anaconda.sh && \
    $CONDA_HOME/bin/conda install -y conda-build=${OPEN_CE_CONDA_BUILD} networkx git junit-xml patch && \
    $CONDA_HOME/bin/conda config --system --add envs_dirs $CONDA_HOME/envs && \
    $CONDA_HOME/bin/conda config --system --add pkgs_dirs $CONDA_HOME/pkgs && \
    $CONDA_HOME/bin/conda config --system --set always_yes true && \
    $CONDA_HOME/bin/conda config --system --set auto_update_conda false && \
    $CONDA_HOME/bin/conda config --system --set notify_outdated_conda false && \
    $CONDA_HOME/bin/conda --version && \
    mkdir -p $CONDA_HOME/conda-bld && \
    mkdir -p $HOME/.cache && \
    echo "export PYTHONPATH=${PYTHONPATH}:$HOME/open_ce" >> ${HOME}/.bashrc && \
    chown -R ${BUILD_USER}:${CICD_GROUP} ${CONDA_HOME}

USER ${BUILD_USER}
RUN export PATH="${PATH}" && \
    echo "PATH="${PATH}"" >> ${HOME}/.profile && \
    mkdir -p $HOME/.cache && \
    echo ". $CONDA_HOME/etc/profile.d/conda.sh" >> ${HOME}/.bashrc && \
    echo "export PYTHONPATH=${PYTHONPATH}:$HOME/open_ce" >> ${HOME}/.bashrc && \
    echo "conda activate base" >> ${HOME}/.bashrc

RUN export ARCH="$(uname -m)" && \
    curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz -o oc.tar.gz \
    tar -xvzf oc.tar.gz && \ 
    chmod +x oc && \
    mkdir -p $HOME/bin && \
    mv ./oc $HOME/bin/oc && \ 
    PATH=$HOME/bin:$PATH \
    echo "$(echo -ne 'nameserver 9.3.89.109\n'; cat /etc/resolv.conf)" > /etc/resolv.conf \
    echo ${OC_PASS} | oc login -u ${OC_USER} ${OC_CLUSTER} -n ${ARGO_PROJECT} --insecure-skip-tls-verify=true \
    curl -sL https://github.com/argoproj/argo-workflows/releases/download/v2.11.0/argo-linux-${ARCH}.gz -o argo-linux.gz \
    gunzip argo-linux.gz && chmod +x argo-linux && mv ./argo-linux $HOME/bin/argo \
