# Putnam

## TLDR: Quick Install

### Requirements
* [curl](https://curl.se/)
* [Git](https://git-scm.com/)
* [Nu](https://www.nushell.sh/)

### Any POSIX compatible Shell
```
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/Akkitto/putnam/refs/heads/master/static/putnam_init.sh | sh
```

## About
Putnam is a minimalistic, simple & fun GNU/Linux operating system distribution initialisation & configuration tool.

Think of it as your shell scripts for setting up your personal Linux environment, but everything is declarative and just works.  
At the same time, think of it as covering [Ansible](https://ansible.readthedocs.io/projects/ansible-core/devel/getting_started/index.html)'s use cases, but everything is simpler, quicker and more fun to configure, as it is focused on setting up a developer's workstation, rather than being a very generic & universal configuration management tool, needing lots of setup, until it can be effectively used.

All configuration is declarative as much as technically possible & reasonable, following a DevOps minded approach.

## Why Putnam?
After many years of using Linux in various forms, I realised, that I need a declarative approach of initialising a GNU/Linux operating system the way I need it to work.
If you can think of any GNU/Linux distribution, I have most likely already used it for a while, a long time ago.

Coming from Arch and Nix, my most recent explorations, I know how the "pro-centric" distributions do it and see what I would do differently.

For example, despite how great it truly is, Arch is still based on classic shell script management, as well as custom package formats, like PKGBUILD. From a DevOps mindset perspective, this is still the same old imperative approach, as pretty much all other GNU/Linux distributions keep on using.

As for NixOS, it is truly great and truly declarative. However, it has various issues, like low adoption rate, which limits the available Nix libraries & their quality, as well as, a very high learning curve for anyone coming from traditional systems, especially Debian, etc. It's not easy enough for many people to get into.
Another issue is, that it has its own language, rather than using established methods or languages. So, if you do Nix, you specialise on Nix. You can only use it within the Nix eco-system, if you don't want to get out of your way, to use it otherwise.
While Nix can theoretically be used in non-NixOS environments, I don't see it as a viable option, as, if you want to use Nix, you might as well use the operating system designed for it. Does anyone really use Nix package management on something like Debian?
Basically, if you want to use the well made declarative approach of Nix, you are pretty much stuck with NixOS. It's unflexible in this regard.

### Comparison to [Ansible](https://ansible.readthedocs.io/projects/ansible-core/devel/getting_started/index.html)
* Putnam is simpler and more minimalistic.
* Leverages [Nu](https://www.nushell.sh/), which is part of the [Rust](https://www.rust-lang.org/) eco-system, rather than [Python](https://www.python.org/).
* Complexity is much lower by specialising on initialising a developer's system, instead of being too generic by default.
* Batteries are included. For example, you don't need an extra module to set up basic stuff like [Git](https://git-scm.com/) and your programming language's packages.
* No clunkiness. Just add another YAML document, reference it, that's it. No need to write several [Ansible](https://ansible.readthedocs.io/projects/ansible-core/devel/getting_started/index.html) definitions, with tasks, roles, playbooks, group_vars, all conditional for specific targets, etc.
* No configuration spread. Functionality and implementation is inside [Nu](https://www.nushell.sh/) modules. All configuration is inside `config.yaml`. That's it. No `ansible.cfg`, `group_vars`, `ansible-playbook` CLI options, no inventory management à la [Backpack Battles](https://store.steampowered.com/app/2427700/Backpack_Battles/). Just write your `config.yaml` and run `pm sync`. That's it.
* It's more declarative. [Ansible](https://ansible.readthedocs.io/projects/ansible-core/devel/getting_started/index.html) requires you to do a lot of manual, imperative work, for specific use cases or dive deep into third party modules, taking care of that. With Putnam, it's all included, yet simple to manage & configure.

### Comparison to [Puppet](https://www.puppet.com/)
* Putnam is simpler and more minimalistic.
* Leverages [Nu](https://www.nushell.sh/), which is part of the [Rust](https://www.rust-lang.org/) eco-system, rather than [Ruby](https://www.ruby-lang.org/en/) and in tiny portions in [Clojure](https://clojure.org/).
* Complexity is much lower by specialising on initialising a developer's system, instead of being too generic by default.
* No clunkiness. Just add another YAML document, reference it, that's it.
* No configuration spread. Functionality and implementation is inside [Nu](https://www.nushell.sh/) modules. All configuration is inside `config.yaml`. That's it.
* [Not really open source anymore](https://github.com/OpenVoxProject), especially since 2025.
* Uses a [domain-specific language (DSL)](https://martinfowler.com/dsl.html), rather than a set standard, like YAML, TOML, plain JSON or any JSON superset.

### Comparison to [Chef](https://www.chef.io/)
* Putnam is simpler and more minimalistic.
* Leverages [Nu](https://www.nushell.sh/), which is part of the [Rust](https://www.rust-lang.org/) eco-system, rather than [Ruby](https://www.ruby-lang.org/en/).
* Complexity is much lower by specialising on initialising a developer's system, instead of being too generic by default.
* No clunkiness. Just add another YAML document, reference it, that's it.
* No configuration spread. Functionality and implementation is inside [Nu](https://www.nushell.sh/) modules. All configuration is inside `config.yaml`. That's it.
* Uses a [domain-specific language (DSL)](https://martinfowler.com/dsl.html), rather than a set standard, like YAML, TOML, plain JSON or any JSON superset.

## Who is this for?

This is for any technology interested GNU/Linux user, who deals regularly with Linux, usually on a daily basis.

If you fullfil any of the following...
* Linux System Administrator trying to get into the DevOps Mindset
* Linux Tinkerer constantly polishing your distribution and perhaps distro-hopping
* Curious about DevOps
* Curious about [Rust](https://www.rust-lang.org/) & [Nushell](https://www.nushell.sh/)
* Want declarative state application of your personalised experience on GNU/Linux distribution, but not NixOS, Ansible or alternate solutions, as they are too huge to begin with
* Looking for a way to keep your Linux distribition up-to-date without a huge hassle and headaches
* Developer setting up a specific personalised experience, tired of re-doing lots of configuration manually

...then this project is a solution, that might be very useful & interesting to you.

## Roadmap
Where do we want to go and what do we want to avoid?

### Goals
* [Simple Made Easy](https://www.youtube.com/watch?v=SxdOUGdseq4)
* Fun
* Modern
* Declarative
* Developer-centric
* Reliability
* Modularity
* [YAML](https://yaml.org/)|[TOML](https://toml.io/en/)|[JSON](https://www.json.org/json-en.html)|[NUON](https://www.nushell.sh/book/loading_data.html#nuon)
* All configuration must be distributable through a single file.
* Keep amount of dependencies as minimal, as possible.
* Assume, Putnam configuration is hosted in [Git](https://git-scm.com/) repository.
* Function over form, regarding desktop customisation, etc.
* Make & keep a system "running" after initial installation, the way you want, as a Dev/DevOps/Penguin.
* Anything going beyond essential developer experience establishement shall be implemented via CRDs (Plugins).
* Support custom non-structured-data scripts only where truly necessary.
* User-level first. If packages can be installed for the current user only, do that. Only install system-wide, if it's unreasonable to avoid it, like e.g. with OS package managers, like APT and Pacman.

### Non-Goals
* Implement all possible developer tools
* Implement all possible shells
* Implement all possible operating systems
* Implement very specific and niché setup scenarios
* Focus on setting up tons of servers in batches
* [XML](https://www.w3.org/XML/)|[KDL](https://kdl.dev/)|[SDL](https://sdlang.org/)
* Severely branched out & several levels deep hierarchy of configuration
* Make it as huge & clunky as [Ansible](https://ansible.readthedocs.io/projects/ansible-core/devel/getting_started/index.html)|[Puppet](https://www.puppet.com/)|[Chef](https://www.chef.io/)
* [POSIX](https://en.linuxportal.info/encyclopedia/p/posix-portable-operating-system-interface) compatibility

### Design Philosophy, Specification, Logic & Rule of Configuration
Use this list to really understand the logic of how the configuration works.  
Once you understand the logic, you don't really need to read as much documentation or spend a lot of time trying to figure out, how things work.  
For these rules to make the most sense immediately, make sure, you understand the concept of [YAML documents](https://www.yaml.info/learn/document.html), as opposed to YAML files.
* [Simplicity](https://www.youtube.com/watch?v=SxdOUGdseq4) is of utmost importance. "Simple" does not mean, there must be less things. It means, that complecting of distinct elements is enforced to stay at a minimum.
* The configuration file defaults to [YAML](https://yaml.org/), but must support common compatible structured data formats. The configuration methodology is not about having an efficient [DSL](https://martinfowler.com/dsl.html) or the "right" data format. It's about supporting structured data, which is inherently compatible with [JavaScript Object Notation (JSON)](https://developer.mozilla.org/en-US/docs/Learn_web_development/Core/Scripting/JSON), i.e. a universal format, readable by pretty much any tool and programming language out there. Your data will never be vendor-locked or hard to translate. It will remain most compatible with all tools possible.
* Each document represents one concept of state. For example, `kind: System` with `subkind: Operating` for the state of the operating system.
* Each document presents metadata, like `kind`, `subkind`, `name`, `version`, `os` and `profiles`.
* Each document presents an actual specification, i.e. "data", "content", "desired state", represented by the `spec` object of each document.
* The hierarchy of documents is as flat as feasible & reasonable.
* Most state representations in the form of documents are desired state representations. `kind: Machine` is an exception, as it is a *fact state*, rather than a *desired state*. It represents the current machine environment. Based on this environment, the correct desired states are selected, as the configuration file may contain states for different profiles & machines and the `kind: Machine` document makes the distinction.
* The `kind: Machine` *fact state* is the selector for which documents apply to the current machine and the specified user. Each *desired state* document specifies under `profile`, whether it applies to the current machine, or not, by either containing an entry conforming to the *fact state* of the current `kind: Machine` or not.
* Each concept of desired state represented through a document must be independent & isolated from other documents. I.e. it should not be necessary to specify any kind of order of execution, like steps in a task. The order is either implicit & logical - like e.g. you obviously need your operating system user first, before you can install local packages under `~/.cargo` for that specific user - or all steps should be represented inside a single document, to avoid dependencies between documents altogether.
* All documents must be valid inside a single file. It should be possible to spread documents across files, but must not ever be necessary.
* Order of documents in a file matter for ease of configuration adaption per system, without removing content from the configuration file altogether. For example, if more than a single `kind: Machine` document is provided for the current system/context/machine/environment, then the *last one* inside the configuration file is the one that counts. So, you, for example, you can have several Machine configurations & to change them for each system you use Putnam on, you only need to change the order of the configuration, rather than removing parts of the whole file, by removing documents and storing them elsewhere, which would increase complexity of usage. Same thing for `kind: User`. When several users of `name: Nobody` are defined, then only the last one counts for this system. Change order on other system, to apply another definition of the same `kind: User`.
* `kind: User` with `subkind: Root` usually represents a distinct human user of the machine. `kind: User` with `subkind: Root` and `name: Root` represents the administrative user of an operating system, i.e. `root` user on Linux. In this specific case, the `root` user is usually used by the same human as the operating system non-service user with the lowest UID.
* `kind: Config` documents are usually about distributing configuration files or setting up a program through any type of API.
* `kind: Stack` documents are about software stacks, like e.g. programming languages and its packages. They are not only setting up their stack, but also usually get third party files and do more major operations. For example, `kind: Stack` with `subkind: Rust` manages `cargo` packages for the current operating system user.
* `kind: Config`'s `spec` content usually is all about representing the target configuration state in its original schema, which is usually inside some file, in the form of YAML, which can be 1:1 translated to the target format, if possible. For example, the document of `kind: Config` with `subkind: Starship` has its `~/.config/starship.toml` configured through `spec.config.spec`, where its content is a literal representation of `starship.toml`, but, in the default case, in the form of YAML. When translating the object of `spec.config.spec` [`from yaml`](https://www.nushell.sh/commands/docs/from_yaml.html) [`to toml`](https://www.nushell.sh/commands/docs/to_toml.html), then `starship.toml` is ready to use and working. No extra structure to structure translation or raw string template necessary.

## TODO
- [x] Add simple minimalist `.gitconfig` reader/writer
- [ ] Putnam Bootstrap for Continuous Sync: Support Putnam Nu Module commands in other shells through `pm init`
- [ ] Validate YAML schema through pre-commit lint; for example, all Putnam resource names must be unique within its `kind` and `subkind`
- [ ] Support source configuration from [Git](https://git-scm.com/) repositories, like e.g. repository with Neovim configuration, incl. plugins
- [ ] Support Custom Resource Definitions (a.k.a. Plugins)
- [ ] Come up with simple concept for Secret Management
- [ ] Add SSH Key Provisioning
- [ ] Add thorough `config.yaml.sample`.
- [ ] Putnam Bootstrap for OS Initialisation: Set up Developer Experience on fresh OS from scratch

## Operating System Support
- [x] [Debian](https://wiki.debian.org/DebianReleases%C2%A0)
  - [x] 12
  - [ ] 13
- [x] [Ubuntu](https://www.releases.ubuntu.com/)
  - [x] 24.04.2
- [ ] [Arch Linux](https://archlinux.org/)

## System Support
Implementing opeating system level tool configuration.
- [ ] [WSL](https://ubuntu.com/desktop/wsl)
- [ ] [SystemD](https://systemd.io/)

## Stack Support
Implementing tech stack configuration & package stacks.
- [x] [Rust](https://www.rust-lang.org/)
- [ ] [Nim](https://nim-lang.org/)
- [ ] [Go](https://go.dev/)
- [ ] [Ruby](https://www.ruby-lang.org/en/)
- [ ] [Docker](https://www.docker.com/)

## Shell Support
Implement shell configuration & package stacks.
- [ ] [Nu](https://www.nushell.sh/)
- [ ] [Bash](https://www.gnu.org/software/bash/manual/bash.html)
- [ ] [Zsh](https://wiki.archlinux.org/title/Zsh)
- [ ] [PowerShell](https://blog.netwrix.com/what-is-powershell-guide)
- [ ] [Elvish](https://elv.sh/)
- [ ] [Ion](https://doc.redox-os.org/ion-manual/)
- [ ] [Tcsh](https://www.tcsh.org/)
- [ ] [Xonsh](https://xon.sh/)

## Editor Support
Implement editor configuration & package stacks.
- [ ] [Helix](https://helix-editor.com/)
- [ ] [Neovim](https://neovim.io/)
- [ ] [Emacs](https://www.gnu.org/software/emacs/)
- [ ] [Micro](https://micro-editor.github.io/)
- [ ] [Nano](https://www.nano-editor.org/)
- [ ] [Visual Studio Code](https://code.visualstudio.com/)
- [ ] [VSCodium](https://vscodium.com/)
- [ ] [Lapce](https://lap.dev/lapce/)
- [ ] [Zed](https://zed.dev/)
- [ ] [Cursor](https://cursor.com/)

## Licence
Copyright © 2025  [Daniel Braniewski](https://brani.dev/)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.