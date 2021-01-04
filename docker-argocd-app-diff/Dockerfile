FROM argoproj/argocd:v1.8.1

ENV PACKAGE_TO_INSTALL="curl vim"

# Install Yq
USER 0
ENV YQ_VERISON=3.4.1
ENV YQ_SHA=adbc6dd027607718ac74ceac15f74115ac1f3caef68babfb73246929d4ffb23c

RUN apt-get update && \
    apt-get install -y ${PACKAGE_TO_INSTALL} && \
    rm -rf /var/lib/apt/lists/* && \
    curl -L -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/${YQ_VERISON}/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq && \
    [ $(sha256sum /usr/local/bin/yq | cut -f1 -d' ') = ${YQ_SHA} ]

ADD *.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/local/bin/app-diff.sh"]
