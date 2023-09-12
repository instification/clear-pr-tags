FROM ubuntu:jammy
RUN apt-get update && apt-get install -y jq curl
COPY cleartags.sh /cleartags.sh
ENTRYPOINT ["/cleartags.sh"]
