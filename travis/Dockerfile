FROM mtmiller/octave-snapshot:latest

RUN apt-get update && apt-get install -y --no-install-recommends \
    shunit2 \
 && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/sbin/init"]
