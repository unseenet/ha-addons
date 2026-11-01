<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/unseenet/unseenet/main/assets/logo-dark.svg">
    <img src="https://raw.githubusercontent.com/unseenet/unseenet/main/assets/logo-light.svg" alt="Unseenet" width="360">
  </picture>
</p>

<h1 align="center">unseenet-haos-addons</h1>

<p align="center"><b>Run a node of the Unseenet network on your Home Assistant machine, with a few clicks.</b><br>
It joins the one, shared Unseenet - it is not a chat server of your own.</p>

<p align="center">
  <a href="https://github.com/unseenet/unseenet-haos-addons/releases"><img src="https://img.shields.io/github/v/release/unseenet/unseenet-haos-addons?include_prereleases&label=release" alt="Release"></a>
  <a href="https://github.com/unseenet/unseenet-haos-addons/actions/workflows/ci.yml"><img src="https://github.com/unseenet/unseenet-haos-addons/actions/workflows/ci.yml/badge.svg" alt="ci"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-blue" alt="Apache-2.0"></a>
</p>

> **Pre-alpha.** Nothing is stable yet, and Unseenet has not had a security
> review. Do not rely on it to protect anyone yet.

## What it is

[Unseenet](https://unseenet.org) is a discussion network in the spirit of old
Usenet and BBSes: chat, threaded discussion, feeds and private posts, on nodes
anyone can run, linked over Tor onion services. Every node is an onion service,
so running one needs **no public IP, no port forwarding and no domain** - a
Home Assistant machine on your home network is enough.

**This joins the existing network.** A node is not a private chat server for
your household or your friends: like a Usenet server of old, it becomes one
more node of the one Unseenet network. It finds other nodes by itself, stores
the groups everybody writes in and passes posts on, so that people anywhere can
read and write through it - and your node keeps working for the network even
when other nodes go away. The more nodes run by different people in different
places, the harder the network is to stop. Privacy inside the network comes
from end-to-end encryption (closed groups and private posts) and Tor, not from
running your own server.

This repository holds Home Assistant add-ons (now also called *apps*) built on
the project's own signed container images:

| Add-on | What it runs | Image |
|---|---|---|
| [Unseenet node](unseenet-node/) | A node: stores groups and exchanges them with other nodes | `ghcr.io/unseenet/node` |
| [Unseenet council replica](unseenet-replica/) *(experimental)* | A replica of a council registrar ([UN-RFC 0054](https://unseenet.org/spec/un-rfc-0054/)) | `ghcr.io/unseenet/replica` |

Both are for amd64 and aarch64 (a Raspberry Pi 4 or 5, a NUC, a VM). Gateways
and bots may follow. A web entrance is not meant for a home machine - it is a
public web service.

## Install

1. In Home Assistant: **Settings → Add-ons → Add-on Store → ⋮ → Repositories**,
   and add `https://github.com/unseenet/unseenet-haos-addons`.
2. Open **Unseenet node**, install it, set a **passphrase** in its
   Configuration tab, and start it.
3. Its log shows the node's key and, once Tor is running, its onion address -
   give both to the operators you peer with.

Each add-on's Documentation tab ([node](unseenet-node/DOCS.md),
[replica](unseenet-replica/DOCS.md)) tells the rest.

## How it is built

Each add-on is the project's image plus a small start-up script
(`rootfs/usr/local/bin/unseenet-addon`) that reads the add-on's options,
hands the passphrase on in a file on tmpfs and starts the image's own
entrypoint. The Supervisor builds that thin layer on your machine from the
pinned image in `build.yaml`; there are no separate add-on images to trust.
The service runs as the image's user `unseenet`, never as root.

`tests/smoke.sh` builds the add-ons and starts them against fake options, as
the CI does on every pull request. Versioning: each add-on has its own
version in `config.yaml` and its own `CHANGELOG.md`; which core it runs is
the image pinned in `build.yaml`.

## More

- How Unseenet works: <https://unseenet.org/guide/>
- Running a node, and what an operator can and cannot see:
  <https://unseenet.org/guide/node/>
- The core, protocol and images: <https://github.com/unseenet/unseenet>

Apache-2.0. The Unseenet logo is CC BY 4.0 (see [NOTICE](NOTICE)).
