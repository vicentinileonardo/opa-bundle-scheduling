# OPA bundle scheduling

## Direct push to OCI registry

```bash
opa build src
```

```bash
oras login docker.io
```

```bash
oras push docker.io/leovice/test-opa-bundle-scheduling:1.0.0 \
--config config.json:application/vnd.oci.image.config.v1+json bundle.tar.gz:application/vnd.oci.image.layer.v1.tar+gzip

oras push docker.io/leovice/test-opa-bundle-scheduling:latest \
--config config.json:application/vnd.oci.image.config.v1+json bundle.tar.gz:application/vnd.oci.image.layer.v1.tar+gzip
```
