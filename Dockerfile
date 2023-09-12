FROM ubuntu:jammy
RUN apt-get update && apt-get -y upgrade && apt-get install -y jq
COPY cleartags.sh /cleartags.sh

ENTRYPOINT ["/cleartags.sh"]
