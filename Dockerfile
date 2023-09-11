FROM ubuntu:jammy

COPY cleartags.sh /cleartags.sh

ENTRYPOINT ["/cleartags.sh"]
