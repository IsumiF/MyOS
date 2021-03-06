#include <myos/kernel/Kernel.hpp>

using myos::kernel::Kernel;

extern "C" void cpu_enterUserCode(uint32_t, uint32_t);

extern "C" uint32_t __init_array_start;

extern "C" int main() {
    // initialize
    auto ctor = reinterpret_cast<void (*)()>(__init_array_start);
    ctor();

    return 0;
}

extern "C" void __cxa_pure_virtual() {
    // No op
}

namespace {

class Dumb {
public:
    Dumb() {
        asm volatile("nop");
    }
};

// So that we can make sure .init_array section always exists.
Dumb dumb;

}

extern "C" uint32_t __init_array_start;

extern "C" {

int c_main() {
    extern int main();
    auto ctor = reinterpret_cast<void (*)()>(__init_array_start);
    ctor();
    return main();
}

void *__dso_handle;

int __cxa_atexit(void (*destructor)(void *), void *arg, void *dso) {
    return 0;
}

void __cxa_finalize(void *f) {

}

}
