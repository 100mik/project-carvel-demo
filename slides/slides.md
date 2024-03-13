---
theme:
  name: catppuccin-latte
  override:
    default:
      margin:
        percent: 2
    footer:
      style: empty
title: Project Carvel
sub_title: Composable Tools for Application Management
author: Daniel Garnier-Moiroux & Soumik Majumder
---

About us
===

<!-- column_layout: [1, 1] -->

<!-- column: 0 -->
<!-- new_lines: 1 -->

## Soumik Majumder

Software engineer @ Broadcom, Tanzu

- @100mik
- github.com/100mik

<!-- column: 1 -->
<!-- new_lines: 1 -->

## Daniel Garnier-Moiroux

Software engineer @ Broadcom, Tanzu-Spring

- @kehrlann
- @kehrlann@hachyderm.io
- github.com/Kehrlann
- https://garnier.wf

<!-- end_slide -->

On the menu
===

- What's carvel?
  - https://carvel.dev
- ytt
- kapp
- kbld
- imgpkg
- kapp-controller

<!-- end_slide -->

App CRD
===


```yaml
apiVersion: kappctrl.k14s.io/v1alpha1
kind: App
metadata:
  name: simple-app
  namespace: default
spec:
  cluster: # deploy to another cluster

  fetch: # where to pull files from
    - inline: # directly in the resource
    - image: # pulls content from Docker/OCI registry
    - imgpkgBundle: # pulls imgpkg bundle from Docker/OCI registry (v0.17.0+)
    - http: # uses http library to fetch file
    - git: # uses git to clone repository
    - helmChart: # uses helm fetch to fetch specified chart

  template: # how to template the files
    - ytt: # use ytt to template configuration
    - kbld: # use kbld to resolve image references to use digests
    - helmTemplate: # use helm template command to render helm chart
    - cue: # use cue to template configuration
    - sops: # use sops to decrypt *.sops.yml files (optional; v0.11.0+)

  deploy: # how to deploy
    - kapp: # use kapp to deploy resources
```
