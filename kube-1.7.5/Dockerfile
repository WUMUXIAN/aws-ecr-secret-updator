FROM python:2.7-alpine3.7
MAINTAINER Wu Muxian <mw@tectusdreamlab.com>

# install aws cli
RUN pip install awscli --upgrade

# install kubectl
RUN wget https://storage.googleapis.com/kubernetes-release/release/v1.7.0/bin/linux/amd64/kubectl -O kubectl
RUN chmod +x kubectl

# add entrypoint.sh
ADD entrypoint.sh entrypoint.sh
RUN chmod +x entrypoint.sh

# run
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
