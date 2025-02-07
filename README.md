# OPA bundle scheduling

## Description

This repository is part of a project: **Carbon-aware workload scheduling in a multi-cloud environment**.

## How to use

Create GitHub repository secrets for the following:
- `REGISTRY_USERNAME`
- `REGISTRY_PASSWORD`
- `REGISTRY_NAMESPACE`

For individual accounts, `REGISTRY_NAMESPACE` is the same as the `REGISTRY_USERNAME` (but needs to be set).

In order to trigger the GitHub Action, you need to push a tag to the repository:
```bash
git commit --allow-empty -m "Whatever (v0.1.0)"
git tag -a 0.1.0 -m "Whatever (v0.1.0)"
git push origin main --tags
```

## Direct push to OCI registry

This alternative method is useful when you want to push the bundle directly to an OCI registry. 
Normally, using the GitHub Action in the current GitHub repository is the preferred way to push the bundle to an OCI registry.

### Prerequisites

- [OPA](https://www.openpolicyagent.org/docs/latest/#running-opa)
- [ORAS CLI](https://oras.land/docs/installation)

### Build and push the bundle manually

```bash
opa build src
```

```bash
oras login docker.io
```

```bash
oras push docker.io/<DOCKER_USERNAME>/test-opa-bundle-scheduling:1.0.0 \
--config config.json:application/vnd.oci.image.config.v1+json bundle.tar.gz:application/vnd.oci.image.layer.v1.tar+gzip

oras push docker.io/<DOCKER_USERNAME>/test-opa-bundle-scheduling:latest \
--config config.json:application/vnd.oci.image.config.v1+json bundle.tar.gz:application/vnd.oci.image.layer.v1.tar+gzip
```

## Local testing

```bash

opa build src

opa eval -b bundle.tar.gz -i test/admission_review.json --format pretty "data.system"

```

## References

- [OPA Bundles in OCI registries](https://www.openpolicyagent.org/docs/latest/management-bundles/#oci-registry)

## Data

### Azure

Azure latency data is obtained from the Azure Docs.
Raw data is available in the `raw_data` directory just for reference.

Sources:
- https://gist.github.com/lpellegr/8ed204b10c2589a1fb925a160191b974
- https://datacenters.microsoft.com/globe/explore
- https://github.com/electricitymaps/zone-finder
- https://app.electricitymaps.com/map/72h/hourly

### AWS

AWS: https://github.com/ipregistry/aws-regions-location/blob/main/aws-regions-location.csv
AWS latency data: https://cloudping.co/