FROM node:alpine
LABEL maintainer="jebentier@gmail.com"

USER root

RUN apk update && apk add --no-cache git && \
    npm install -g --unsafe-perm \
        resume-cli \
        yamljs \
        jsonresume-theme-stackoverflow \
        jsonresume-theme-onepage

WORKDIR /resume
RUN mkdir dist
COPY resume.yml .

COPY render_resume.sh /usr/local/bin
ENTRYPOINT ["render_resume.sh"]
CMD ["yml"]
