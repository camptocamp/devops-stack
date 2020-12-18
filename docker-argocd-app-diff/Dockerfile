FROM argoproj/argocd:v1.7.7

ENV PACKAGE_TO_INSTALL="curl vim"

# Install Yq
USER 0
ENV YQ_VERISON=3.4.1
ENV YQ_SHA=e51dbbed00221ff695b6e6f90a41b872fa919fbdc9961f8b6e56a270953ff47d

RUN apt-get update && \
    apt-get install -y ${PACKAGE_TO_INSTALL} && \
    rm -rf /var/lib/apt/lists/* && \
    curl -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/${YQ_VERISON}/yq_linux_amd64 && \
    [ $(sha256sum /usr/local/bin/yq | cut -f1 -d' ') = ${YQ_SHA} ]

ADD *.sh /usr/local/bin/

ENTRYPOINT ["/usr/loca/bin/entrypoint.sh"]
CMD ["/usr/local/bin/app-diff.sh"]
