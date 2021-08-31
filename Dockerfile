FROM registry.access.redhat.com/ubi7/ubi

VOLUME /tmp/secrets
ENTRYPOINT ["bash", "test.sh"]
