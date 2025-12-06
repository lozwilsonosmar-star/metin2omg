# The Metin2 Server
The Old Metin2 Project aims at improving and maintaining the 2014 Metin2 game
files up to modern standards. The goal is to archive the game as it was in order
to preserve it for the future and enable nostalgic players to have a good time.

For-profit usage of this material is certainly illegal without the proper
licensing agreements and is hereby discouraged (not legal advice). Even so, the
nature of this project is HIGHLY EXPERIMENTAL - bugs are to be expected for now.

## 1. Usage
We aim to provide Docker images which _just work_ for your convenience.
A Docker Compose project is maintained in the [Deployment project](https://git.old-metin2.com/metin2/deploy).
Please head over there for further instructions.

## 2. Building

**Note:** This project is compatible with Ubuntu 22.04 and 24.04. For Ubuntu 24.04, see the [specific instructions](#ubuntu-2404-specific-instructions) below.
### A. Building Docker images
#### Building a Docker image from the repository
In order to build a local Docker image on your local architecture, just build the
provided Dockerfile in this project:

```shell
docker build -t metin2/server:test --provenance=false .
```

#### Publishing a multiplatform Docker image manually
This command is reserved only for repository maintainers in order to publish
new Docker images for public use with the Deployment project.

**WARNING:** Using WSL for building might lead to QEMU segmentation fault issues;
this can be worked around by using `binfmt` and `qemu-user-static` as described 
[here](https://github.com/docker/buildx/issues/1170#issuecomment-1159350550).

```shell
docker build --push -t git.old-metin2.com/metin2/server:<IMAGE-TAG-HERE> --platform linux/amd64,linux/arm64 --provenance=false .
```

### B. Building the binaries yourself (for advanced users)
_Sadly, we're unable to provide hand-holding services. You should have some C++ development experience
going forward with this route._

A Linux environment is strongly recommended, preferably of the Ubuntu/Debian
variety. This project is also compatible with WSL, even though WSL can be buggy
at times. FreeBSD/Windows compatibility is untested and unsupported for the
time being - there are other projects out there if that's what you want.

#### Setting up the requirements

**Important for Ubuntu 24.04 users:** This project requires Python 2.7 for quest compilation, which is not available by default in Ubuntu 24.04. See the [Ubuntu 24.04 specific instructions](#ubuntu-2404-specific-instructions) below.

On your Linux box, install the dependencies for `vcpkg` and the other libraries
we're going to install.
```shell
apt-get update
apt-get install -y git cmake build-essential tar curl zip unzip pkg-config autoconf python3 libncurses5-dev
```

Also install DevIL (1.7.8) and the BSD compatibility library:
```shell
apt-get install -y libdevil-dev libbsd-dev
```

Install `vcpkg` according to the [latest instructions](https://vcpkg.io/en/getting-started.html).

Build and install the required libraries:
```shell
vcpkg install cryptopp effolkronium-random libmariadb libevent lzo fmt spdlog argon2
```

#### Ubuntu 24.04 Specific Instructions

**Python 2.7 Requirement:** The quest compilation script (`gamefiles/data/quest/make.py`) requires Python 2.7, which was removed from Ubuntu 24.04. You need to install it from the deadsnakes PPA:

```shell
# Install Python 2.7 from deadsnakes PPA
apt-get update
apt-get install -y software-properties-common
add-apt-repository -y ppa:deadsnakes/ppa
apt-get update
apt-get install -y python2.7

# Create symlink for python2
ln -s /usr/bin/python2.7 /usr/bin/python2
```

**Quick Installation Script:** For convenience, you can use the provided installation script:

```shell
sudo bash instalar-en-vps.sh
```

This script will automatically:
- Install Python 2.7 from deadsnakes PPA
- Install all required system dependencies
- Set up vcpkg and install all required libraries

**Database Compatibility Note:** While the documentation mentions MySQL 5.x, the codebase uses `libmariadb` which is compatible with:
- MySQL 5.x, 6.x, 7.x, 8.x
- MariaDB 10.x, 11.x

Ubuntu 24.04 includes MariaDB/MySQL 8.x by default, which works perfectly with this project.

**Docker Users:** The Dockerfile has been updated to support Ubuntu 24.04 and automatically handles the Python 2.7 installation. Simply build as usual:

```shell
docker build -t metin2/server:test --provenance=false .
```

#### Building the binaries
Instead of building the binaries directly from the CLI, we recommend using an IDE, since
you're probably doing some kind of development anyway. See the "Development" section for more information on that.

If you decide do build from the command line, make sure to find the right path for `vcpkg.cmake` and run the following:
```shell
mkdir build/
cd build && cmake -DCMAKE_TOOLCHAIN_FILE=/path/to/vcpkg/scripts/buildsystems/vcpkg.cmake ..
make -j $(nproc)
```

If everything goes right, you should now have compiled binaries in the `build/` directory.

## 2. Development
The preferred IDE in order to develop and debug the server is [CLion](https://www.jetbrains.com/clion/),
baked by the fine Czech folks at JetBrains. Educational licenses are available if you're elligible.

1. Make sure you install all the dependencies mentioned in the "Build the binaries yourself" section.
2. Inside a WSL environment, a remote SSH one or directly on a Linux machine, just
clone this repository and open it with CLion.
3. Set up "Run/Debug Configurations" of the "CMake Application" type for
the `db`, `auth`, and `game` services, using the "db" target for the former and
the "game" target for the latter two. Make sure each service has its own working
directory with all the required configuration and game files.
4. Optionally, add a "Compound" configuration containing these three configurations
in order to start them at once.
5. Of course, you'll need a MySQL/MariaDB database (MySQL 5.x, 8.x, or MariaDB 10.x/11.x are all compatible), Valgrind and any other development
goodies you wish. Also, a lot of time.

### Creating a minimal test server (WIP)

In CLion, create a `test` directory containing the `auth`, `db`, and `game`
directories, and then symlink the following files in the `gamefiles` directory.

```shell
ln -s ../../gamefiles/conf/item_names_en.txt ./test/db/item_names.txt
ln -s ../../gamefiles/conf/item_proto.txt ./test/db/item_proto.txt
ln -s ../../gamefiles/conf/mob_names_en.txt ./test/db/mob_names.txt
ln -s ../../gamefiles/conf/mob_proto.txt ./test/db/mob_proto.txt

ln -s ../../gamefiles/data ./test/auth/data
ln -s ../../gamefiles/data ./test/game/data
```

## 3. Improvements
### Major improvements
- The binaries run on 64-bit Linux with the network stack being partially rewritten in Libevent.
- CMake build system mainly based on `vcpkg`. Docker-friendly architectural approach.
- HackShield and other proprietary binaries were successfully _yeeted_, the project only has open-source dependencies.
- Included gamefiles from [TMP4's server files](https://metin2.dev/topic/27610-40250-reference-serverfile-client-src-15-available-languages/) (2023.08.05 version).

### Minor improvements
- Removed unused functionalities (time bombs, activation servers, other Korean stuff)
- Switched to the [effolkronium/random PRNG](https://github.com/effolkronium/random) instead of the standard C functions.
- Refactored macros to modern C++ functions.
- Network settings are manually configurable through the `PUBLIC_IP`, `PUBLIC_BIND_IP`, `INTERNAL_IP`, `INTERNAL_BIND_IP` settings in the `game.conf` file. (Might need further work)
- Refactored logging to use [spdlog](https://github.com/gabime/spdlog) for more consistent function calls.
- Refactored login code to use Argon2ID.

## 4. Bugfixes
**WARNING: This project is based on the "kraizy" leak. That was over 10 years ago.
A lot of exploits and bugs were discovered since then. Most of these public bugs are UNPATCHED.
This is a very serious security risk and one of the reasons this project is still experimental.**

### Gameplay
- Fixed invisibility bug on login/respawn/teleport etc.
- Fixed player level not updating [(thread)](https://metin2.dev/topic/30612-official-level-update-fix-reversed/)

### Exploits
- See the warning above :(

### Architectural
- Fixed various bugs caused by the migration of the codebase to 64-bit (some C/C++ data types have different lengths based on the CPU architecture)
- Fixed buffer overruns and hardcoded limits in the MAP_ALLOW parsing routines.
- Fixed quest server timers cancellation bug which could cause a server crash - [(thread)](https://metin2.dev/topic/25142-core-crash-when-cancelling-server-timers/).
- Fixed buffer overruns and integer overflows in SQL queries.

## 5. Further plans
- Migrate `db.conf` and `game.conf` to a modern dotenv-like format, which would enable pretty nice Docker images.
- Use the [fmt](https://fmt.dev/latest/index.html) library for safe and modern string formatting.
- Handle kernel signals (SIGTERM, SIGHUP etc.) for gracefully shutting down the game server.
- Improve memory safety.
- Use fixed width integer types instead of Microsoft-style typedefs.
- Convert C-style strings to C++ `std::string`.
- Perform static and runtime analysis.
- Find and implement other fitting improvements from projects such as [Vanilla's core](https://metin2.dev/topic/14770-vanilla-core-latest-r71480/), [TMP's serverfiles](https://metin2.dev/topic/27610-40250-reference-serverfile-client-src-15-available-languages/).
- Find time to take care of this project.

## 6. Troubleshooting

### Ubuntu 24.04 Issues

**Problem: `python2: command not found` during quest compilation**

**Solution:** Python 2.7 is not available by default in Ubuntu 24.04. Install it from deadsnakes PPA:
```shell
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt-get update
sudo apt-get install -y python2.7
sudo ln -s /usr/bin/python2.7 /usr/bin/python2
```

**Problem: Docker build fails with `python2` not found**

**Solution:** The Dockerfile has been updated for Ubuntu 24.04. Make sure you're using the latest version. If you're using an older Dockerfile, update it to include the Python 2.7 installation steps.

**Problem: CMake repository errors on Ubuntu 24.04**

**Solution:** The CMake repository URL in the Dockerfile uses `noble` (Ubuntu 24.04 codename) instead of `jammy` (Ubuntu 22.04). Make sure your Dockerfile is up to date.

### General Issues

**Problem: vcpkg installation fails**

**Solution:** Make sure you have all required dependencies:
```shell
apt-get install -y git cmake build-essential tar curl zip unzip pkg-config autoconf python3
```

**Problem: Database connection errors**

**Solution:** 
- Verify MySQL/MariaDB is running: `systemctl status mysql` or `systemctl status mariadb`
- Check database credentials in `db.conf` and `game.conf`
- Ensure databases are created: `account`, `common`, `player`, `log`
- Verify network connectivity and firewall settings

**Problem: Quest compilation errors**

**Solution:**
- Ensure Python 2.7 is installed and accessible as `python2`
- Check file permissions in `gamefiles/data/quest/`
- Verify all quest files are present and readable

**Problem: Build fails with missing libraries**

**Solution:** Make sure all vcpkg libraries are installed:
```shell
vcpkg install cryptopp effolkronium-random libmariadb libevent lzo fmt spdlog argon2
```

### Getting Help

- Check the [Deployment project](https://git.old-metin2.com/metin2/deploy) for Docker Compose examples
- Review the [analysis document](ANALISIS_UBUNTU24.md) for Ubuntu 24.04 compatibility details
- Ensure you're using the latest version of the repository