#!/usr/bin/env nu
############################################################################
# Copyright © 2025  Daniel Braniewski                                      #
#                                                                          #
# This program is free software: you can redistribute it and/or modify     #
# it under the terms of the GNU Affero General Public License as           #
# published by the Free Software Foundation, either version 3 of the       #
# License, or (at your option) any later version.                          #
#                                                                          #
# This program is distributed in the hope that it will be useful,          #
# but WITHOUT ANY WARRANTY; without even the implied warranty of           #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the             #
# GNU Affero General Public License for more details.                      #
#                                                                          #
# You should have received a copy of the GNU Affero General Public License #
# along with this program.  If not, see <https://www.gnu.org/licenses/>.   #
############################################################################

# Testing tin/sync/language/rust Module

let component_undesired = "rustc-dev"

def "list-components" [] {
  rustup component list --installed | lines
  | where { |line| ($line | str trim | str length) > 0 }
  | each { |line|
    $line
    | str trim
    | split row (char space)
    | get 0
  }
}

# Trim target suffixes (e.g. `-x86_64-unknown-linux-gnu`) from component names.
#
# Intended usage:
#   list-components
#   | trim-component-suffixes
#   | filter-extra-components
#
# Behavior:
#   cargo-x86_64-unknown-linux-gnu      -> cargo
#   rust-std-aarch64-apple-ios          -> rust-std
#   llvm-tools-preview-x86_64-unknown-linux-gnu -> llvm-tools-preview
#   rust-src                            -> rust-src   (unchanged)
#
# It detects valid target triples via `rustc --print target-list`,
# so only real targets are stripped. See:
#   - Targets: https://doc.rust-lang.org/rustc/platform-support.html
#   - Target list: `rustc --print target-list`
def "trim-component-suffixes" [] {
  let components = $in

  # Collect all valid targets from rustc so we only strip real triples.
  # Example output: x86_64-unknown-linux-gnu, aarch64-apple-ios, wasm32-unknown-unknown, ...
  # https://doc.rust-lang.org/rustc/platform-support.html 
  let targets = (
    ^rustc --print target-list
    | lines
    | each {|target| $target | str trim }
    | where {|target| $target | is-not-empty }
  )

  $components
  | each {|component|
      # Find any target that matches as a suffix: "<component>-<target>"
      let matches = (
        $targets
        | where {|target| $component | str ends-with ("-" + $target) }
      )

      if ($matches | is-empty) {
        # No matching target suffix -> leave component as-is
        $component
      } else {
        # Take the first matching target triple
        let target = ($matches | get 0)
        let suffix = ("-" + $target)

        let total_len = ($component | str length)
        let suffix_len = ($suffix | str length)
        let base_len = $total_len - $suffix_len

        # Keep everything before the "-<target>" suffix
        $component | str substring 0..$base_len | str trim --char "-"
      }
    }
}

use std/assert
use std/log [ info error ]
use std/util [ null-device ]
use ../src/tin.nu

try { rustup component remove $component_undesired out+err> (null-device) } catch {}
let components_before = (list-components | trim-component-suffixes)
rustup component add $component_undesired
let components_after = (list-components | trim-component-suffixes)
tin sync language rust
let components_final = (list-components | trim-component-suffixes)

try {
  assert ($component_undesired not-in $components_before)
} catch { |err|
  error "Undesired component already available before installation!!"
  error $"(ansi red)==== Test Rust failed! ====(ansi reset)"
  exit 1
}

try {
  assert ($component_undesired in $components_after)
} catch { |err|
  error "Undesired component not available after installation!!"
  error $"(ansi red)==== Test Rust failed! ====(ansi reset)"
  exit 1
}

try {
  assert ($component_undesired not-in $components_final)
} catch { |err|
  error "Undesired component remains after sync!"
  error $"(ansi red)==== Test Rust failed! ====(ansi reset)"
  exit 1
}

info $"(ansi green)==== Test Rust succeeded! ====(ansi reset)"
