#!/bin/sh

# Copyright (C) 2024-2025 Free Software Foundation, Inc.
#
# This file is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# This file is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# This script builds a tarball of the package on a single platform.
# Usage: build-on.sh PACKAGE CONFIGURE_OPTIONS MAKE INSTALL_OPTIONAL_DEPENDENCIES_COMMAND

package="$1"
configure_options="$2"
make="$3"
install_optional_dependencies_command="$4"

set -x

# Unpack the tarball.
tarfile=`echo "$package"-*.tar.gz`
packagedir=`echo "$tarfile" | sed -e 's/\.tar\.gz$//'`
tar xfz "$tarfile"
cd "$packagedir" || exit 1

# First, without the optional dependencies.
mkdir build
cd build

# Configure.
FORCE_UNSAFE_CONFIGURE=1 ../configure --config-cache --with-openssl=no $configure_options > log1 2>&1; rc=$?; cat log1; test $rc = 0 || exit 1

# Build.
$make V=1 > log2 2>&1; rc=$?; cat log2; test $rc = 0 || exit 1

# Run the tests.
$make check V=1 > log3 2>&1; rc=$?; cat log3; test $rc = 0 || exit 1

cd ..

if test -n "$install_optional_dependencies_command"; then
  # Install the optional dependencies.
  sh -c "$install_optional_dependencies_command"

  # Build again, this time with optional packages installed.
  mkdir build-full
  cd build-full

  # Configure.
  FORCE_UNSAFE_CONFIGURE=1 ../configure --config-cache --with-openssl=auto $configure_options > log1 2>&1; rc=$?; cat log1; test $rc = 0 || exit 1

  # Build.
  $make V=1 > log2 2>&1; rc=$?; cat log2; test $rc = 0 || exit 1

  # Run the tests.
  $make check V=1 > log3 2>&1; rc=$?; cat log3; test $rc = 0 || exit 1

  cd ..
fi

exit 0
