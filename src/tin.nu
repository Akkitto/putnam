# Nu Module
# Putnam Business Logic


const path_script = path self
const path_script_output = $path_script | path parse | get stem
const paths_config_static = [
  ./config.yaml
  ../x_input/config.yaml
  /opt/putnam/x_input/config.yaml
]

# Utility
module util {
  # Expand path to its absolute form and omit non-existent items.
  export def filter_existing []: list<string> -> list<string> {
    each { try { path expand --strict } }
  }

  export def "to any docs" []: list<string> -> string {
    each { |document|
      $"---\n($document | $document)"
    }
    | str join
  }

  export def "to yaml docs" []: list<any> -> string {
    each { |document|
      $"---\n($document | to yaml)"
    }
    | str join
  }

  # Add trailing path  separator to string.
  export def "path append trailing" []: string -> string {
    str replace --regex '$' (char separator)
  }

  # Source environment variables from `.env`.
  export def --env source_env [] {
    open $env.PUTNAM____INPUT__ENV
    | lines
    | where ($it | is-not-empty)
    | where $it !~ '(^[[:blank:]]+)|(^#)'
    | each { split column '=' }
    | flatten
    | transpose -ird
    | load-env
  }

  export def "get path" [
    query: string = ""                    # JSON-Path-ike query string. For example, `spec.profile`.
    --config-file(-c): string|null = null # Path to configuration file.
  ]: any -> any {
    do { |resource|
      $query
      | split words
      | compact --empty
      | reduce --fold $resource { |query, result|
        $result
        | get $query
      }
    } $in
  }
}

# Convert UNIX-like custom data formats to structured data
module convert {

  # Git Configuration Conversion
  module git {
    # Provide content of `.gitconfig` file
    export def "from gitini" [
      --strictly-structured(-s) # Convert to Nushell structure all the way through. Does not support multiline values. Each line under a section is converted to an actual key-value pair, instead of taken as-is as a string. Loses comments without `--keep-comments`. Loses trailing whitespace. Useful for processing this data structure inside nu. Unnecessary for simple conversion between generic structured data format and custom UNIX-like format. Do not enable this flag, if you need readability and simplicity
      --keep-comments(-k)       # Keep pure comment lines.
    ]: string -> record {
      lines --skip-empty
      | enumerate
      | do { |lines|
        {
          keys: ($lines | where { $in.item | str starts-with (char left_bracket) } | str trim --left --char (char left_bracket) | str trim --right --char (char right_bracket))
          values: ($lines | where { $in.item | str starts-with (char left_bracket) | not $in } | each { str trim --left } | where { $in.item | is-not-empty })
        }
      } $in
      | do { |section_content|
        $section_content
        | get keys
        | enumerate
        | each { |section|
          {
            $section.item.item: (
              $section_content
              | get values
              | where { |value|
                ($value.index > $section.item.index) and (if ((($section_content | get keys | length) - 1) > $section.index) {
                  ($value.index < ($section_content | get keys | get ($section.index + 1) | get index))
                } else {
                  true
                })
              }
              | get item
            )
          }
        }
      } $in
      | into record
      | do { |record|
        if ($strictly_structured) {
          $record
          | items { |section, content|
            { section: $section content: (
                $content
                | each { |line|
                  let regex_comment = '^([[:space:]]*[#]+)|^([[:space:]]*[;]+)'
                  if ($line =~ $regex_comment and $keep_comments) {
                    $line
                    | str replace --regex $regex_comment ''
                    | { comment: $in }
                  } else if ($line =~ $regex_comment) {
                    null
                  } else {
                    $line
                    | str replace --regex '(^[[:blank:]]*[[:alnum:]]+)[[:blank:]]*=[[:blank:]]*' '$1='
                    | split column --number 2 '='
                    | get --optional 0
                    | rename key value
                    | each { |row| { ($row.key | str trim): ($row.value | str trim) } }
                  }
                }
                | compact --empty
              )
            }
          }
          | transpose -ird
        } else {
          $record
        }
      } $in
    }

    def "from gitini strict" []: record -> record {
      let record = $in
      if ($record | items { |section, content| ($content | describe) == "list<string>" } | all {}) {
        $record
      } else {
        $record
        | items { |section, content|
          {
            section: $section
            content: (
              $content
              | each {
                transpose -d key value | each { |row|
                  if (($row.key | str trim) == "comment") {
                    '# ' | append ($row.value | str trim)
                  } else {
                    $"($row.key | str trim) = ($row.value | str trim)"
                  }
                }
              }
            )
          }
        }
        | transpose -ird
      }
    }

    # Provide data structured version of `.gitconfig` file content
    export def "to gitini" [
      --char(-c): string # Provide custom indentation string for each sections' key-value pairs. Only `'^[[:blank:]]*$'` allowed.
    ]: record -> string {
      from gitini strict
      | transpose section content
      | each { |row|
        $"[($row.section)](char newline)(
          $row.content
          | to text
          | lines
          | each { |line|
            if ($line | str trim | str starts-with '# ') {
              $line
              | str trim
              | str replace --regex '^# , ' '# '
            } else {
              $line
              | str trim --left --char (char left_bracket)
              | str trim --right --char (char right_bracket)
              | str replace ': ' ' = '
            }
            | (
              [$char]
              | compact --empty
              | where $it =~ '^[[:blank:]]*$'
              | get --optional 0
              | default ((char space) + (char space))
            ) + $in
          }
          | str join (char newline)
        )"
      }
      | str join $"(char newline)(char newline)"
    }
  }

  export use git *
}

# Load Facts from Putnam Configuration
module config {
  alias std_get = get

  use util

  export def "get file" [
    --config-file(-c): string|null = null # Path to configuration file.
  ] {
    util source_env
    let paths_config = [
      $"($env.HOME)/.config/putnam/config.yaml"
      $env.PUTNAM____INPUT__CONFIG_MASTER_PATH?
      ...$paths_config_static
    ]
    [$config_file]
    | append ($paths_config | util filter_existing)
    | compact --empty
    | first
  }

  export def get [
    --config-file(-c): string|null = null # Path to configuration file.
    --format(-f): string|null = null      # Output format. For example, "yaml" or "toml".
    --not-overriden(-o)                   # Do not apply resources of `kind: Override`.
  ] {
    let config = open (get file --config-file $config_file)
    match $not_overriden {
      true => $config
      false => (
        (
          $config
          | enumerate
          | where $it.item.kind == Override
          | where $it.item.subkind == Root
          | each { |enum_override|
            let override = $enum_override.item
            let enum_target = (
              $config
              | enumerate
              | where $it.item.kind == $override.target.kind
              | where $it.item.subkind == $override.target.subkind
              | where $it.item.name == $override.target.name
              | std_get --optional 0
            )

            let target = $enum_target.item

            match $target {
              null => $target
              _ => (
                $enum_target
                | update cells --columns [ item ] {
                  update cells --columns [ spec ] { |spec|
                    $spec
                    | merge deep --strategy $override.merge.strategy $override.spec
                  }
                }
              )
            }
          }
        )
        | reduce --fold $config { |override, config|
          $config
          | update $override.index $override.item
        }
      )
    }
    | do { |resources|
      match $format {
        null => $resources
        yaml => ($resources | util to yaml docs)
        _ => (
          $resources | each {
            let resource = ($in | to nuon)
            # REPORT: Workaround for plain `to $format` not simply working.
            (
              nu
                --no-config-file
                --no-history
                --no-std-lib
                --commands
              $"
              r##########'($resource)'##########
              | from nuon
              | to ($format | str downcase)
              "
            )
          }
          | util to any docs
        )
      }
    } $in
  }

  export def "get path" [
    query: string = ""                    # JSON-Path-ike query string. For example, `spec.profile`.
    --config-file(-c): string|null = null # Path to configuration file.
  ] {
    get --config-file $config_file
    | util get path $query --config-file $config_file
  }
}

# Load Facts from Putnam Configuration regarding Resource of `kind: Machine` with `subkind: Root`.
module machine {
  alias std_get = get

  use util
  use config

  export def "get all" [
    --config-file(-c): string|null = null # Path to configuration file.
  ] {
    config get --config-file $config_file
    | where kind == Machine
    | where subkind == Root
  }

  export def "get" [
    --config-file(-c): string|null = null # Path to configuration file.
  ] {
    get all --config-file $config_file
    | last
  }

  export def "get path" [
    query: string = ""                    # JSON-Path-ike query string. For example, `spec.profile`.
    --config-file(-c): string|null = null # Path to configuration file.
  ] {
    get --config-file $config_file
    | util get path $query --config-file $config_file
  }
}

# Load Facts from Putnam Configuration regarding Resource of `kind: Stack` with variable `subkind`.
module stack {
  alias std_get = get

  use util
  use config

  export def "get all" [
    --config-file(-c): string|null = null # Path to configuration file.
  ] {
    config get --config-file $config_file
    | where kind == Stack
  }

  export def "get" [
    subkind: string = "Rust"              # Subkind of Putnam resource.
    --config-file(-c): string|null = null # Path to configuration file.
  ] {
    get all --config-file $config_file
    | where ($it.subkind | str downcase) == ($subkind | str downcase)
  }

  export def "get first" [
    subkind: string = "Rust"              # Subkind of Putnam resource.
    --config-file(-c): string|null = null # Path to configuration file.
  ] {
    get --config-file $config_file $subkind
    | std_get --optional 0
  }

  export def "get last" [
    subkind: string = "Rust"              # Subkind of Putnam resource.
    --config-file(-c): string|null = null # Path to configuration file.
  ] {
    get --config-file $config_file $subkind
    | reverse
    | std_get --optional 0
  }

  export def "get path" [
    query: string = ""                    # JSON-Path-ike query string. For example, `spec.profile`.
    --config-file(-c): string|null = null # Path to configuration file.
  ] {
    get --config-file $config_file
    | util get path $query --config-file $config_file
  }

  export def "get subkind path" [
    subkind: string = "Rust"              # Subkind of Putnam resource.
    query: string = ""                    # JSON-Path-ike query string. For example, `spec.profile`.
    --config-file(-c): string|null = null # Path to configuration file.
  ] {
    get --config-file $config_file $subkind
    | util get path $query --config-file $config_file
  }
}

# Load Facts from Putnam Configuration regarding Resource of `kind: System` with variable `subkind`.
module system {
  alias std_get = get

  use util
  use config

  export def "get all" [
    --config-file(-c): string|null = null # Path to configuration file.
  ] {
    config get --config-file $config_file
    | where kind == System
  }

  export def "get" [
    subkind: string = "Operating"         # Subkind of Putnam resource.
    --config-file(-c): string|null = null # Path to configuration file.
  ] {
    get all --config-file $config_file
    | where ($it.subkind | str downcase) == ($subkind | str downcase)
  }

  export def "get first" [
    subkind: string = "Operating"         # Subkind of Putnam resource.
    --config-file(-c): string|null = null # Path to configuration file.
  ] {
    get --config-file $config_file $subkind
    | std_get --optional 0
  }

  export def "get last" [
    subkind: string = "Operating"         # Subkind of Putnam resource.
    --config-file(-c): string|null = null # Path to configuration file.
  ] {
    get --config-file $config_file $subkind
    | reverse
    | std_get --optional 0
  }

  export def "get path" [
    query: string = ""                    # JSON-Path-ike query string. For example, `spec.profile`.
    --config-file(-c): string|null = null # Path to configuration file.
  ] {
    get --config-file $config_file
    | util get path $query --config-file $config_file
  }

  export def "get subkind path" [
    subkind: string = "Operating"         # Subkind of Putnam resource.
    query: string = ""                    # JSON-Path-ike query string. For example, `spec.profile`.
    --config-file(-c): string|null = null # Path to configuration file.
  ] {
    get --config-file $config_file $subkind
    | util get path $query --config-file $config_file
  }
}

# Sync Data
module sync {
  use util
  use config
  use machine

  module config {
    export def rsync [
      src: string
      dst: string
      --incl: list<string> = []
      --excl: list<string> = []
      --delete
    ] {
      let incl_file = mktemp --tmpdir --suffix .txt
      let excl_file = mktemp --tmpdir --suffix .txt

      if ($incl | is-not-empty) {
        $incl
        | str join (char newline)
        | save --force $incl_file
      }

      if ($excl | is-not-empty) {
        $excl
        | str join (char newline)
        | save --force $excl_file
      }

      run-external ...([
        rsync
            --archive                     # recurse & preserve all basic metadata
            --hard-links                  # preserve hard link structure
            --acls                        # preserve POSIX ACLs
            --xattrs                      # preserve extended attributes
            --checksum                    # skip only when full-file checksums match
            --recursive                   # force recursion into included directories through `file-from`
            (if ($delete) { "--delete" }) # remove dest files not in source
            ...(if ($incl | is-not-empty) { [ $"--files-from=($incl_file)" ] } else { [] })                       # Patterns to skip
            ...(if ($excl | is-not-empty) { [ "--delete-excluded" $"--exclude-from=($excl_file)" ] } else { [] }) # Patterns to skip
            --out-format '{"change":"%i","path":"%n","size":%l,"bytes":%b,"time":"%t"}'                           # JSON per update, essentially JSONL log
          ($src | util path append trailing)
          ($dst | util path append trailing)
      ] | compact --empty)

      rm --force $incl_file
      rm --force $excl_file
    }

    export def "rootfs" [] {
      util source_env

      let now = (date now | format date '%Y%m%dT%H%M%S%z')
      let path_home_source = $"($env.PUTNAM____DATA__ROOTFS)/home/user"
      let path_home_target = $"/home/($env.USER)"
      let path_home_backup = $"($path_home_target)/.backup"
      let cmd_git = [ git -C $path_home_backup ]

      def --wrapped run_git [...args] {
        run-external ...$cmd_git ...$args
      }

      mkdir $path_home_backup
      if not ($"($path_home_backup)/.git" | path exists) {
        run_git init
      }

      let dotfiles_target_exclude = [
        .backup
        .rustup
        .cargo
        .vscode-server
        .vscode-remote-containers
        .cache
        .choosenim
        .nimble
        .kube
        .ansible
        .fly
        .ssh
        .gnupg
        .npm
        .dotnet
        .bash_history
        .terraform.d
        .bash_logout
        .lesshst
        .node_repl_history
        .sudo_as_admin_successful
        .local
        .docker
      ]

      let dotfiles_target = (
        ls --full-paths --all --threads $path_home_target
        | where name =~ '^/.+/\..+[^/]$'
        | where type != symlink
        | where { |item| not (($item.name | path basename) in $dotfiles_target_exclude) }
        | par-each { ls --all --directory --du $in.name }
        | flatten
        | sort-by --reverse size
        | get name
        | path basename
      )

      try {
        rsync --delete $path_home_target $path_home_backup --incl $dotfiles_target
      } catch { |e|
        error make --unspanned { msg: $"Unable to back up existing dot files at target destination '($path_home_target)' to '($path_home_backup)' due to '($e.msg)'." }
      }

      try {
        rsync $path_home_source $path_home_target
      } catch { |e|
        error make --unspanned { msg: $"Unable to sync defined dot files from source '($path_home_source)' to target '($path_home_target)' due to '($e.msg)'." }
      }
    }
  }

  module language {
    use std/log [ info warning ]

    module rust {
      # Rust Toolchain Management Module

      # Install rustup if not already installed
      export def "install-rustup" [] {
        if (which rustup | is-empty) {
          info "Installing rustup..."
          with-env { RUSTUP_INIT_SKIP_PATH_CHECK: "yes" } {
            curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path
          }

          let cargo_bin = ($env.HOME | path join ".cargo" "bin")
          let path_list = ($env.PATH | split row (char esep))

          if (not ($path_list | any {|p| $p == $cargo_bin })) {
            $env.PATH = ([$cargo_bin] ++ $path_list | str join (char esep))
          }

          info "✓ rustup installed successfully"
        } else {
          info "✓ rustup already installed"
        }
      }

      # Update stable toolchain to latest release
      export def "update-stable" [] {
        info "Updating stable toolchain..."
        rustup update stable --no-self-update
        let rustc_version = (^rustc --version | str trim)
        info $"✓ stable updated to: ($rustc_version)"
      }

      # Update nightly toolchain to latest
      export def "update-nightly" [] {
        info "Updating nightly toolchain..."
        rustup toolchain install nightly --force --no-self-update
        let nightly_version = (rustup run nightly rustc --version | str trim)
        info $"✓ nightly installed: ($nightly_version)"
      }

      # Update beta toolchain to latest
      export def "update-beta" [] {
        info "Updating beta toolchain..."
        rustup update beta --no-self-update
        let beta_version = (rustup run beta rustc --version | str trim)
        info $"✓ beta updated to: ($beta_version)"
      }

      # Install or update to a specific stable version (e.g., "1.75" or "1.75.0")
      export def "update-version" [version: string] {
        info $"Installing/updating Rust stable version: ($version)..."
        rustup toolchain install $version --no-self-update
        let version_info = (rustup run $version rustc --version | str trim)
        info $"✓ Version ($version) installed: ($version_info)"
      }

      # Install or update to a specific nightly date (format: YYYY-MM-DD, e.g., "2024-11-28")
      export def "update-nightly-date" [date: string] {
        let toolchain = $"nightly-($date)"
        info $"Installing nightly from ($date)..."
        rustup toolchain install $toolchain --force --no-self-update
        let nightly_info = (rustup run $toolchain rustc --version | str trim)
        info $"✓ Nightly ($date) installed: ($nightly_info)"
      }

      # Set default toolchain globally (stable, nightly, beta, or specific version)
      export def "set-default" [channel: string] {
        info $"Setting default toolchain to: ($channel)..."
        rustup default $channel
        let rustc_version = (^rustc --version | str trim)
        info $"✓ Default toolchain set to: ($rustc_version)"
      }

      # Update all installed toolchains
      export def "update-all" [] {
        info "Updating all installed toolchains..."
        rustup update --no-self-update
        info "✓ All toolchains updated"
      }

      # Update all toolchains and force-install missing components
      export def "update-all-force" [] {
        info "Updating all toolchains with force-install..."
        rustup update --no-self-update --force-non-host
        info "✓ All toolchains updated with force-install"
      }

      # Display current toolchain versions and info
      export def "show-versions" [] {
        info "=== Rust Toolchain Status ==="
        let rustc_version = (^rustc --version | str trim)
        let cargo_version = (^cargo --version | str trim)
        info $"Active rustc: ($rustc_version)"
        info $"Active cargo: ($cargo_version)"

        info "=== Installed Toolchains ==="
        rustup show
      }

      # List all installed toolchains
      export def "list-toolchains" [] {
        info "=== Installed Toolchains ==="
        rustup toolchain list
      }

      # Remove a specific toolchain
      export def "remove-toolchain" [channel: string] {
        info $"Removing toolchain: ($channel)..."
        rustup toolchain uninstall $channel
        info $"✓ Toolchain ($channel) removed"
      }

      # Install development tools (rustfmt, clippy, etc.)
      export def "install-dev-tools" [] {
        info "Installing development tools..."
        rustup component add rustfmt clippy rust-analyzer
        info "✓ Development tools installed: rustfmt, clippy, rust-analyzer"
      }

      # Install cross-compilation target (e.g., "x86_64-unknown-linux-musl", "aarch64-unknown-linux-gnu")
      export def "install-target" [target: string] {
        info $"Installing target: ($target)..."
        rustup target add $target
        info $"✓ Target ($target) installed"
      }

      # Update everything: rustup, all toolchains, components, and targets
      export def "full-update" [] {
        info "=== Starting Full Rust Update ==="

        info "[1/4] Installing rustup if missing..."
        install-rustup

        info "[2/4] Updating all toolchains..."
        rustup update --no-self-update

        info "[3/4] Installing development components..."
        rustup component add rustfmt clippy rust-analyzer

        info "[4/4] Showing final status..."
        show-versions

        info "✓ Full update completed successfully"
      }

      # Run a command with a specific toolchain (e.g., `run-with nightly cargo build`)
      export def "run-with" [toolchain: string, ...args] {
        info $"Running with ($toolchain): ($args | str join ' ')..."
        rustup run $toolchain ...$args
      }

      # Verify installation with basic tests
      export def "verify-installation" [] {
        info "=== Verifying Rust Installation ==="

        let rustc_check = (^rustc --version | str trim)
        let cargo_check = (^cargo --version | str trim)
        let rustup_check = (rustup --version | str trim)

        info $"rustc: ($rustc_check)"
        info $"cargo: ($cargo_check)"
        info $"rustup: ($rustup_check)"

        if (($rustc_check | str contains "rustc") and ($cargo_check | str contains "cargo")) {
          info "✓ Installation verified successfully"
        } else {
          info "✗ Installation verification failed"
        }
      }

      # Clean up old toolchain downloads and caches
      export def "cleanup-cache" [] {
        info "Cleaning up Rust caches..."
        # TODO: Implement non-destructive cache cleanup strategy (e.g., using 'cargo clean' / 'cargo-cache'
        # or explicit removal of ~/.rustup/tmp and ~/.rustup/downloads) based on your disk usage policy.
        info "✓ Cache cleanup placeholder executed"
      }

      # Install everything fresh from scratch (destructive - use with caution)
      export def "fresh-install" [] {
        info "WARNING: This will uninstall and reinstall rustup from scratch"
        info "Press Ctrl+C to cancel, or continue..."

        if not (which rustup | is-empty) {
          rustup self uninstall -y
        }

        with-env { RUSTUP_INIT_SKIP_PATH_CHECK: "yes" } {
          curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path
        }

        let cargo_bin = ($env.HOME | path join ".cargo" "bin")
        let path_list = ($env.PATH | split row (char esep))

        if (not ($path_list | any {|p| $p == $cargo_bin })) {
          $env.PATH = ([$cargo_bin] ++ $path_list | str join (char esep))
        }

        rustup toolchain install stable nightly
        info "✓ Fresh installation completed"
        show-versions
      }
    }

    use util
    use rust

    # Update Rust toolchain, as declared in Putnam Configuration.
    export def "rust update" [] {
      # TODO: Read from Config and update as declared.
      rust update-stable
    }

    # Show installed Rust toolchains.
    export def "rust show" [] {
      rust show-versions
    }
  }

  module package {
    # Module extending Rust Cargo functionality.
    module cargo {
      use std/util [ null-device ]

      # Install `cargo` package with feature management.
      # Provide a feature exclusion and/or inclusion list.
      # Merges your feature inclusion/exclusion list with all available features of this Rust crate by fetching its metadata from `crates.io`.
      def --wrapped "cargo install" [
        pkg_name: string = nu # Cargo package name.
        pkg_features_incl: list<string> = [] # Cargo package feature inclusion list.
        p_pkg_features_excl: list<string> = [ native-tls full stable static-link-openssl ] # Cargo package feature exclusion list.
        p_cmd_opts: list<string> = [ --locked ] # Command line options for `cargo install`.
        unlocked: bool = false # If this flag is set, the `cargo install` command will not apply the `--locked` CLI option.
        only_included: bool = false # If this flag is set, only install explicitly included features, without adding any other found package features.
        all: bool = false # If this flag is set, all available features from crates.io will be retrieved and added to be installed. (Overruled by `only_included`.)
        default: bool = false # If this flag is set, `--no-default-features` won't be added to `cargo install`'s CLI option list. (Overruled by `only_included`.)
        quiet: bool = false # If this flag is set, package installations will produce no viewable output.
        debug: bool = false # Show command to be run, rather than actually running it.
        ...args # Arbitrary arguments to `cargo install`.
      ] {
        let cmd_opts = (
          $p_cmd_opts
          | do { |opts| if ($unlocked) { $opts } else { $opts | append "--locked" } } $in
          | do { |opts| if ($default) { $opts } else { $opts | append "--no-default-features" } } $in
          | uniq
        )
        let pkg_features_excl = $p_pkg_features_excl | append [ default ] | uniq
        let pkg_features = (
          (
            if ($all) {
              http get $"https://crates.io/api/v1/crates/($pkg_name)"
              | get versions
              | first
              | get features
              | columns
            } else {
              []
            }
          )
          | append $pkg_features_incl
          | where { |feature| not ($feature in $pkg_features_excl) }
          | uniq
        )
        let cmd_opt_val_pkg_features = (
          if ($pkg_features | is-not-empty) {
            $pkg_features
            | where { |feature|
              if ($only_included) {
                $feature in $pkg_features_incl
              } else {
                true
              }
            }
            | do { |features| if ($features | is-not-empty) { $features } else { print $"No features included for package ($pkg_name)! At least one feature is necessary."; exit 127; }  } $in
            | str join ','
          } else {
            []
          }
        )
        let cmd = [
          ...$cmd_opts
          ...$args
          ...(
            if ($cmd_opt_val_pkg_features | is-not-empty) {
              ["--features" $cmd_opt_val_pkg_features]
            } else {
              []
            }
          ) $pkg_name
        ] | compact --empty

        let entrypoint = [ cargo install ]
        let cmd_full = $entrypoint | append $cmd

        if ($debug) {
          echo ($cmd_full | str join ' ')
        } else {
          if ($quiet) {
            run-external ...$cmd_full out+err> (null-device)
          } else {
            run-external ...$cmd_full out+err> (if ((sys host | get name | str downcase) != "windows") { "/dev/stderr" } else { (null-device) })
            echo ($cmd_full | str join ' ')
          }
        }
      }

      # Install `cargo` package with feature management.
      # Provide a feature exclusion and/or inclusion list.
      # Merges your feature inclusion/exclusion list with all available features of this Rust crate by fetching its metadata from `crates.io`.
      #
      # If you are unsure about this tool's resulting action, run it with `--debug`.
      #
      # Note: The lists are provided as NUON strings.
      export def --wrapped "featured" [
        name: string = nu # Cargo package name.
        --features_incl(-i): list<string> = [] # Cargo package feature inclusion list.
        --features_excl(-e): list<string> = [] # Cargo package feature exclusion list.
        --opts(-o): list<string> = [] # Command line options for `cargo install`.
        --unlocked(-u) # If this flag is set, the `cargo install` command will not apply the `--locked` CLI option.
        --only-included(-n) # If this flag is set, only install explicitly included features, without adding any other found package features.
        --all(-a) # If this flag is set, all available features from crates.io will be retrieved and added to be installed. (Overruled by `only_included`.)
        --default(-d) # If this flag is set, `--no-default-features` won't be added to `cargo install`'s CLI option list. (Overruled by `only_included`.)
        --quiet(-q) # If this flag is set, package installations will produce no viewable output.
        --debug # Show command to be run, rather than actually running it.
        ...args # Arbitrary arguments to `cargo install`.
      ] {
        let features_incl_parsed = ($features_incl)
        if ($only_included and ($features_incl_parsed | is-empty)) {
          error make --unspanned { msg: "If passing '--only-included' you must provide a non-empty list to '--features_incl'." }
        }
        (
          cargo install
            $name
            $features_incl_parsed
            $features_excl
            $opts
            $unlocked
            $only_included
            $all
            $default
            $debug
            ...$args
        )
      }
    }

    use std/log [ warning ]
    use util
    use cargo

    # Update Cargo Crates.
    export def cargo [
      --config-file(-c): string|null = null # Path to configuration file.
      --user(-u): string|null = null # Provide user name, as found in `config.yaml`, to get cargo list for. If not provided, uses result of `whoami`.
      --only-included(-n) # If this flag is set, only install explicitly included features, without adding any other found package features.
      --all(-a) # If this flag is set, all available features from crates.io will be retrieved and added to be installed.
      --default(-d) # If this flag is set, `--no-default-features` won't be added to `cargo install`'s CLI option list.
      --log-file = false # If this flag is set, will output CSV with installed package and whether the installation went successfully into a folder named after the script, without its extension.
      --as-root # If this flag is set, allow this script to be only run as root.
    ] {

      # Load Environment
      util source_env

      let paths_config = [
        $env.PUTNAM____INPUT__CONFIG_MASTER_PATH?
      ]

      if ((is-admin) and (not $as_root)) {
        error make --unspanned { msg: "You are running as root! If you truly want to run this script as root, then run it with the '--as-root' flag." }
      } else if ((not (is-admin)) and $as_root) {
        error make --unspanned { msg: "You set the '--as-root' flag, but this script is not running as root!" }
      }

      let user_name = (
        if ($user | is-not-empty) {
          $user
        } else {
          whoami | str downcase
        }
      )

      let config = config get
      let profiles = machine get | get spec.profiles
      let putnam_users_associated_with_username = (
        $config
        | where kind == User
        | where subkind == Root
        | where ($it.profiles | any { |profile|
            $profile.name in $profiles.name
          }
        )
        | where ($it.profiles | any { |profile|
            $profile.context in $profiles.context
          }
        )
        | where ($it.spec.sys | any { |usersys|
            ($usersys | get --optional name | default null) == $user_name
          }
        )
      )

      if ($putnam_users_associated_with_username | is-empty) {
        return
      }

      # Putnam `User` resource's `spec.sys` found.
      # This confirms, that the current user utilising this module,
      # is actually configured for this machine & context.
      let putnam_user_sys = (
        $putnam_users_associated_with_username
        | get spec.sys
        | each { first }
        | where name == $user_name
        | first
      )

      let cargos = (
        $config
        | where kind == Stack
        | where subkind == Rust
        | where { |doc|
          $profiles | any { |profile|
            (
                ($profile | get name | str downcase) in ($doc | get profiles | get name | first | each { str downcase })
              and
                ($profile | get context | str downcase) in ($doc | get profiles | get context | first | each { str downcase })
            )
          }
        }
        | get spec
        | do { |specs|
          if ($specs | is-empty) {
            print "Required Putnam resource definition not found. Check documentation of this command, before trying again."
            exit 29
          } else {
            $specs
          }
        } $in
        | get cargo
      )

      $cargos | each { |cargo|
        let packages = $cargo.packages
        let packages_non_uniq = $packages | uniq-by --repeated name

        if ($packages_non_uniq | is-not-empty) {
          warning $"Ommitting the following packages, as there are duplicated entries for them: ($packages_non_uniq.name | to nuon --indent 2)"
        }

        $packages
        | where not ($it.name in $packages_non_uniq.name)
        | each { |pkg|
          try {
            let cmd = (
              cargo featured
                --features_incl ($pkg | get --optional features.incl | default [])
                --features_excl ($pkg | get --optional features.excl | default [])
                --only-included=(
                    (
                      $pkg
                      | get --optional features.only_included
                      | default ($cargo | get --optional global.features.only_included)
                      | default false
                    )
                    or $only_included
                  )
                --all=(
                    (
                      $pkg
                      | get --optional features.all
                      | default ($cargo | get --optional global.features.all)
                      | default false
                    )
                    or $all
                  )
                --default=(
                    (
                      $pkg
                      | get --optional features.default
                      | default ($cargo | get --optional global.features.default)
                      | default false
                    )
                    or $default
                  )
              $pkg.name
                ...(
                  $pkg
                  | get --optional args
                  | default []
                )
            )
            {
              name: $pkg.name
              success: true
              cmd: $cmd
            }
          } catch {
            {
              name: $pkg.name
              success: false
              cmd: null
            }
          }
        }
        | do { |status|
          if (($status | is-not-empty) and $log_file) {
            mkdir $path_script_output
            $status
            | to csv
            | save (
              $path_script_output
              | path join $"log_(date now | format date '%Y%m%d_%H%M%S').csv"
            )
          }
          $status
        } $in
      }
      | reduce { |$it, $acc|
        $acc | append ($it | first)
      }
    }
  }

  export use config
  export use language
  export use package
}


export use config
export use machine
export use stack
export use system
export use sync
export use convert *
export use util *