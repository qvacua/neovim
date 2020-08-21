## How to develop

First, clean everything

```
$ ./bin/clean_all.sh
```

Then, build `libnvim` once with dependencies

```
$ target=x86_64 build_deps=true ./bin/build_libnvim.sh
```

After editing the code of neovim or NvimServer, you build NvimServer in Xcode
or by executing the following:

```
$ target=x86_64 build_dir="${some_dir}" build_deps=false ./bin/build_nvimserver.sh
```

where the resulting binary will be located in `${some_dir}`

## How to release

```
$ ./bin/build_release.sh 
```

The resulting packge will be in ...

## Individual steps

In the following the `target` variable can be either `x86_64` or `arm64`.

### How to build `libintl`

```
$ target=x86_64 ./bin/build_deps.sh
```

which will result in

```
/
    NvimServer
        third-party
            lib
                liba
                libb
                ...
            include
                a.h
                b.h
                ...
            x86_64
                lib
                    liba
                    libb
                include
                    a.h
                    b.h
```

Files in `/NvimServer/third-party` are used to build `libnvim` and NvimServer.

### How to build `libnvim`

```
$ target=x86_64 build_deps=true ./bin/build_libnvim.sh
```

When `build_deps` is `true`, then the `build_deps.sh` is executed. The resuling library will be
located in `/build/lib/libnvim.a`.

### how to build NvimServer

```
$ target=x86_64 build_dir="${some_dir}" build_deps=true ./bin/build_nvimserver.sh
```

The `build_libnvim.sh` script is executed automatically with the given parameters. The resulting
binary will be located in `${some_dir}`.
