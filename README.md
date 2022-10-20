# Additional tests for Arpack

This repository contains some tests I build for verifying that Arpack can be built using CMake, and that it properly translates all its dependencies to applications using it -- for instance, linking software that uses Arpack with the proper BLAS and LAPACK libraries.

The usage is relatively simple. There is a script `test.sh` that does all the job. the options it includes can be combined in any order:

- `dynamic` vs `shared` decides whether the tests build Arpack as a dynamically or statically linked library. The latter is desired to verify that Arpack propagates all dependencies in all platforms.

- `original` vs `new` is an internal flag to either test stock Arpack or the fork I am using to contribute changes.
