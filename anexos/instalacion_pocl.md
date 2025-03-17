# PoCL

PoCL es una implementación portable y de código abierto basada en el estándar **OpenCL**, cuyo objetivo es proporcionar alta portabilidad entre diversos dispositivos sin comprometer el rendimiento. 

Actualmente, **PoCL** soporta varias arquitecturas de **CPU** (x86, ARM, RISC-V) y ofrece compatibilidad con **GPUs de NVIDIA** a través de **libCUDA**, así como con **GPUs de Intel**. Además, admite configuraciones heterogéneas, permitiendo la ejecución de kernels en múltiples tipos de hardware dentro de un mismo sistema. 

Internamente, **PoCL** utiliza **Clang** como frontend basado en C y **LLVM** como base para la generación y optimización de código a nivel de kernel.

## Instalación de LLVM y Clang 15.0

Se instala primero LLVM y Clang versión v15 usando el script obtenido desde la pagina oficial de LLVM.

```bash
# To install a specific version of LLVM:
wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
sudo ./llvm.sh 15
```

```bash
echo 'export PATH=/usr/lib/llvm-15/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
llvm-config --version
clang --version
```

Output:

```bash
jetson@node2:~$ llvm-config --version
15.0.7
jetson@node2:~$ clang --version
Ubuntu clang version 15.0.7
Target: aarch64-unknown-linux-gnu
Thread model: posix
InstalledDir: /usr/lib/llvm-15/bin
```

## Instalación de PoCL 6.0

```bash
wget https://github.com/pocl/pocl/archive/refs/tags/v6.0.tar.gz
tar -xvzf v6.0.tar.gz
cd ~/pocl-6.0
mkdir build
cd build
cmake .. -DSTATIC_LLVM=ON -DENABLE_CUDA=ON -DLLC_HOST_CPU=cortex-a57
sudo make -j4 && sudo make install
```

Si se presente el error de que Polly y Clang no son encontrados:

```bash
sudo apt update
sudo apt install libpolly-15-dev
sudo apt install libclang-15-dev
```

Luego de la instalación, se **registra PoCL como un driver OpenCL en el sistema**, creando el archivo de configuración **pocl.icd** en **`/etc/OpenCL/vendors/`** y agregando la ruta de **libpocl.so** para que OpenCL lo detecte como una implementación válida.

```bash
sudo mkdir -p /etc/OpenCL/vendors/
sudo touch /etc/OpenCL/vendors/pocl.icd
echo "/usr/local/lib/libpocl.so" | sudo tee --append /etc/OpenCL/vendors/pocl.icd
```

Si la instalación se realizó correctamente, se podrá ver la información de PoCL en la lista de plataformas soportadas por OpenCL.

```bash
clinfo
```

```bash
Number of platforms                               1
  Platform Name                                   Portable Computing Language
  Platform Vendor                                 The pocl project
  Platform Version                                OpenCL 3.0 PoCL 6.0  Linux, RelWithDebInfo, RELOC, LLVM 15.0.7, SLEEF, CUDA, POCL_DEBUG
  Platform Profile                                FULL_PROFILE
  Platform Extensions                             cl_khr_icd cl_khr_priority_hints cl_khr_throttle_hints cl_pocl_content_size cl_ext_buffer_device_address
  Platform Host timer resolution                  1ns
  Platform Extensions function suffix             POCL

  Platform Name                                   Portable Computing Language
Number of devices                                 2
  Device Name                                     cpu-cortex-a57-cortex-a57
  Device Vendor                                   ARM
  Device Vendor ID                                0x13b5
  Device Version                                  OpenCL 3.0 PoCL HSTR: cpu-aarch64-unknown-linux-gnu-cortex-a57
  Driver Version                                  6.0
  Device OpenCL C Version                         OpenCL C 1.2 PoCL
  Device Type                                     CPU
  Device Profile                                  FULL_PROFILE
  Device Available                                Yes
  Compiler Available                              Yes
  Linker Available                                Yes
  Max compute units                               4
  Max clock frequency                             1479MHz
  Device Partition                                (core)
    Max number of sub-devices                     4
    Supported partition types                     equally, by counts
    Supported affinity domains                    (n/a)
  Max work item dimensions                        3
  Max work item sizes                             4096x4096x4096
  Max work group size                             4096
  Preferred work group size multiple              8
  Max sub-groups per work group                   128
  Sub-group sizes (Intel)                         1, 2, 4, 8, 16, 32, 64, 128, 256, 512
  Preferred / native vector sizes
    char                                                16 / 16
    short                                                8 / 8
    int                                                  4 / 4
    long                                                 2 / 2
    half                                                 0 / 0        (n/a)
    float                                                4 / 4
    double                                               2 / 2        (cl_khr_fp64)
  Half-precision Floating-point support           (n/a)
  Single-precision Floating-point support         (core)
    Denormals                                     No
    Infinity and NANs                             Yes
    Round to nearest                              Yes
    Round to zero                                 No
    Round to infinity                             No
    IEEE754-2008 fused multiply-add               No
    Support is emulated in software               No
    Correctly-rounded divide and sqrt operations  No
  Double-precision Floating-point support         (cl_khr_fp64)
    Denormals                                     Yes
    Infinity and NANs                             Yes
    Round to nearest                              Yes
    Round to zero                                 Yes
    Round to infinity                             Yes
    IEEE754-2008 fused multiply-add               Yes
    Support is emulated in software               No
  Address bits                                    64, Little-Endian
  Global memory size                              3117493248 (2.903GiB)
  Error Correction support                        No
  Max memory allocation                           1073741824 (1024MiB)
  Unified memory for Host and Device              Yes
  Shared Virtual Memory (SVM) capabilities        (core)
    Coarse-grained buffer sharing                 Yes
    Fine-grained buffer sharing                   Yes
    Fine-grained system sharing                   Yes
    Atomics                                       Yes
  Minimum alignment for any data type             128 bytes
  Alignment of base address                       1024 bits (128 bytes)
  Preferred alignment for atomics
    SVM                                           64 bytes
    Global                                        64 bytes
    Local                                         64 bytes
  Max size for global variable                    64000 (62.5KiB)
  Preferred total size of global vars             524288 (512KiB)
  Global Memory cache type                        Read/Write
  Global Memory cache size                        2097152 (2MiB)
  Global Memory cache line size                   64 bytes
  Image support                                   Yes
    Max number of samplers per kernel             16
    Max size for 1D images from buffer            67108864 pixels
    Max 1D or 2D image array size                 2048 images
    Max 2D image size                             8192x8192 pixels
    Max 3D image size                             2048x2048x2048 pixels
    Max number of read image args                 128
    Max number of write image args                128
    Max number of read/write image args           128
  Max number of pipe args                         0
  Max active pipe reservations                    0
  Max pipe packet size                            0
  Local memory type                               Global
  Local memory size                               524288 (512KiB)
  Max number of constant args                     8
  Max constant buffer size                        524288 (512KiB)
  Max size of kernel argument                     1024
  Queue properties (on host)
    Out-of-order execution                        Yes
    Profiling                                     Yes
  Queue properties (on device)
    Out-of-order execution                        No
    Profiling                                     No
    Preferred size                                0
    Max size                                      0
  Max queues on device                            0
  Max events on device                            0
  Prefer user sync for interop                    Yes
  Profiling timer resolution                      1ns
  Execution capabilities
    Run OpenCL kernels                            Yes
    Run native kernels                            Yes
    Sub-group independent forward progress        Yes
    IL version                                    (n/a)
  printf() buffer size                            16777216 (16MiB)
  Built-in kernels                                pocl.add.i8;org.khronos.openvx.scale_image.nn.u8;org.khronos.openvx.scale_image.bl.u8;org.khronos.openvx.tensor_convert_depth.wrap.u8.f32
  Device Extensions                               cl_khr_byte_addressable_store cl_khr_global_int32_base_atomics cl_khr_global_int32_extended_atomics cl_khr_local_int32_base_atomics cl_khr_local_int32_extended_atomics cl_khr_3d_image_writes cl_khr_command_buffer cl_khr_command_buffer_multi_device cl_khr_subgroups cl_intel_unified_shared_memory cl_ext_buffer_device_address       cl_pocl_svm_rect cl_pocl_command_buffer_svm       cl_pocl_command_buffer_host_buffer cl_khr_subgroup_ballot cl_khr_subgroup_shuffle cl_intel_subgroups cl_intel_subgroups_short cl_ext_float_atomics cl_intel_required_subgroup_size cl_khr_fp64 cl_khr_int64_base_atomics cl_khr_int64_extended_atomics

  Device Name                                     NVIDIA Tegra X1
  Device Vendor                                   NVIDIA Corporation
  Device Vendor ID                                0x10de
  Device Version                                  OpenCL 3.0 PoCL HSTR: CUDA-sm_53
  Driver Version                                  6.0
  Device OpenCL C Version                         OpenCL C 1.2 PoCL
  Device Type                                     GPU
  Device Topology (NV)                            PCI-E, 00:00.0
  Device Profile                                  FULL_PROFILE
  Device Available                                Yes
  Compiler Available                              Yes
  Linker Available                                Yes
  Max compute units                               1
  Max clock frequency                             921MHz
  Compute Capability (NV)                         5.3
  Device Partition                                (core)
    Max number of sub-devices                     1
    Supported partition types                     None
    Supported affinity domains                    (n/a)
  Max work item dimensions                        3
  Max work item sizes                             1024x1024x64
  Max work group size                             1024
  Preferred work group size multiple              32
  Warp size (NV)                                  32
  Max sub-groups per work group                   32
  Preferred / native vector sizes
    char                                                 1 / 1
    short                                                1 / 1
    int                                                  1 / 1
    long                                                 1 / 1
    half                                                 0 / 0        (cl_khr_fp16)
    float                                                1 / 1
    double                                               1 / 1        (cl_khr_fp64)
  Half-precision Floating-point support           (cl_khr_fp16)
    Denormals                                     No
    Infinity and NANs                             Yes
    Round to nearest                              Yes
    Round to zero                                 No
    Round to infinity                             No
    IEEE754-2008 fused multiply-add               No
    Support is emulated in software               No
  Single-precision Floating-point support         (core)
    Denormals                                     Yes
    Infinity and NANs                             Yes
    Round to nearest                              Yes
    Round to zero                                 Yes
    Round to infinity                             Yes
    IEEE754-2008 fused multiply-add               Yes
    Support is emulated in software               No
    Correctly-rounded divide and sqrt operations  No
  Double-precision Floating-point support         (cl_khr_fp64)
    Denormals                                     Yes
    Infinity and NANs                             Yes
    Round to nearest                              Yes
    Round to zero                                 Yes
    Round to infinity                             Yes
    IEEE754-2008 fused multiply-add               Yes
    Support is emulated in software               No
  Address bits                                    64, Little-Endian
  Global memory size                              4156657664 (3.871GiB)
  Error Correction support                        No
  Max memory allocation                           1783308288 (1.661GiB)
  Unified memory for Host and Device              Yes
  Integrated memory (NV)                          Yes
  Shared Virtual Memory (SVM) capabilities        (core)
    Coarse-grained buffer sharing                 Yes
    Fine-grained buffer sharing                   Yes
    Fine-grained system sharing                   No
    Atomics                                       No
  Minimum alignment for any data type             128 bytes
  Alignment of base address                       4096 bits (512 bytes)
  Preferred alignment for atomics
    SVM                                           64 bytes
    Global                                        64 bytes
    Local                                         64 bytes
  Max size for global variable                    0
  Preferred total size of global vars             0
  Global Memory cache type                        None
  Image support                                   No
  Max number of pipe args                         0
  Max active pipe reservations                    0
  Max pipe packet size                            0
  Local memory type                               Local
  Local memory size                               49152 (48KiB)
  Registers per block (NV)                        32768
  Max number of constant args                     8
  Max constant buffer size                        65536 (64KiB)
  Max size of kernel argument                     4352 (4.25KiB)
  Queue properties (on host)
    Out-of-order execution                        No
    Profiling                                     Yes
  Queue properties (on device)
    Out-of-order execution                        No
    Profiling                                     No
    Preferred size                                0
    Max size                                      0
  Max queues on device                            0
  Max events on device                            0
  Prefer user sync for interop                    Yes
  Profiling timer resolution                      1ns
  Execution capabilities
    Run OpenCL kernels                            Yes
    Run native kernels                            No
    Sub-group independent forward progress        No
    Kernel execution timeout (NV)                 Yes
  Concurrent copy and kernel execution (NV)       Yes
    Number of async copy engines                  1
    IL version                                    (n/a)
  printf() buffer size                            16777216 (16MiB)
  Built-in kernels                                pocl.mul.i32;pocl.add.i32;pocl.dnn.conv2d_int8_relu;pocl.sgemm.local.f32;pocl.abs.f32;pocl.add.i8;org.khronos.openvx.scale_image.nn.u8;org.khronos.openvx.scale_image.bl.u8;org.khronos.openvx.tensor_convert_depth.wrap.u8.f32
  Device Extensions                               cl_khr_byte_addressable_store cl_khr_global_int32_base_atomics     cl_khr_global_int32_extended_atomics cl_khr_local_int32_base_atomics     cl_khr_local_int32_extended_atomics cl_khr_int64_base_atomics     cl_khr_int64_extended_atomics cl_nv_device_attribute_query cl_khr_fp16 cl_khr_fp64 cl_ext_buffer_device_address cl_khr_subgroup_ballot cl_khr_subgroup_shuffle

NULL platform behavior
  clGetPlatformInfo(NULL, CL_PLATFORM_NAME, ...)  Portable Computing Language
  clGetDeviceIDs(NULL, CL_DEVICE_TYPE_ALL, ...)   Success [POCL]
  clCreateContext(NULL, ...) [default]            Success [POCL]
  clCreateContextFromType(NULL, CL_DEVICE_TYPE_DEFAULT)  Success (1)
    Platform Name                                 Portable Computing Language
    Device Name                                   cpu-cortex-a57-cortex-a57
  clCreateContextFromType(NULL, CL_DEVICE_TYPE_CPU)  Success (1)
    Platform Name                                 Portable Computing Language
    Device Name                                   cpu-cortex-a57-cortex-a57
  clCreateContextFromType(NULL, CL_DEVICE_TYPE_GPU)  Success (1)
    Platform Name                                 Portable Computing Language
    Device Name                                   NVIDIA Tegra X1
  clCreateContextFromType(NULL, CL_DEVICE_TYPE_ACCELERATOR)  No devices found in platform
  clCreateContextFromType(NULL, CL_DEVICE_TYPE_CUSTOM)  No devices found in platform
  clCreateContextFromType(NULL, CL_DEVICE_TYPE_ALL)  Success (2)
    Platform Name                                 Portable Computing Language
    Device Name                                   cpu-cortex-a57-cortex-a57
    Device Name                                   NVIDIA Tegra X1

ICD loader properties
  ICD loader Name                                 OpenCL ICD Loader
  ICD loader Vendor                               OCL Icd free software
  ICD loader Version                              2.2.11
  ICD loader Profile                              OpenCL 2.1
        NOTE:   your OpenCL library only supports OpenCL 2.1,
                but some installed platforms support OpenCL 3.0.
                Programs using 3.0 features may crash
                or behave unexpectedly
```

Ejecutar tests de PoCL con backend CUDA

```bash
jetson@node2:~/pocl-6.0/build$ ../tools/scripts/run_cuda_tests
```

```bash
95% tests passed, 3 tests failed out of 60

Label Time Summary:
cuda          = 211.81 sec*proc (60 tests)
hsa           =   8.14 sec*proc (3 tests)
hsa-native    = 176.71 sec*proc (45 tests)
internal      = 211.81 sec*proc (60 tests)
kernel        = 120.63 sec*proc (18 tests)
level0        = 207.84 sec*proc (58 tests)
proxy         =  66.16 sec*proc (29 tests)
regression    =  41.44 sec*proc (15 tests)
runtime       =  32.79 sec*proc (20 tests)
tce           =  11.43 sec*proc (5 tests)
vulkan        =  24.16 sec*proc (13 tests)

Total Test time (real) = 211.95 sec

The following tests did not run:
        190 - runtime/test_buffer-image-copy (Skipped)
        194 - runtime/clGetSupportedImageFormats (Skipped)

The following tests FAILED:
        167 - regression/clSetKernelArg_overwriting_the_previous_kernel's_args_loopvec (Failed)
        209 - runtime/test_device_address (SEGFAULT)
        210 - runtime/test_svm (Bus error)
Errors while running CTest
```

## Referencias

[PoCL - Portable Computing Language](https://portablecl.org/)

[OpenCL Support - Jetson & Embedded Systems / Jetson Nano - NVIDIA Developer Forums](https://forums.developer.nvidia.com/t/opencl-support/74071/7)

[PoCL - Portable Computing Language | NVIDIA GPU support via CUDA backend](https://portablecl.org/cuda-backend.html)

[NVIDIA GPU support — Portable Computing Language (PoCL) 6.0 documentation](https://portablecl.org/docs/html/cuda.html)

https://apt.llvm.org/ 

[could not find native static library `Polly` (#13) · Issues · Peter Marheine / llvm-sys.rs · GitLab](https://gitlab.com/taricorp/llvm-sys.rs/-/issues/13)

[PoCL Installation on Jetson - Monolithe Documentation](https://largo.lip6.fr/monolithe/admin_pocl/)
