#include "runtime/ps2_timer_wait_probe.h"
#include <cassert>
int main() {
    using namespace ps2_timer_wait_probe;
    assert(enabled());
    assert(isMain(1) && !isMain(7));
    assert(!matches(-1,0xffffffffu) && matches(21,21) && !matches(21,22));
    prepared(7,21);assert(mainSema.load()==-1);
    begin(1,1000,0x322ffc,0x10000);prepared(1,21);assert(mainSema.load()==21);
    callback(8,22,123,456);assert(callbackSema==-1);
    armed(1,21,123);callback(8,21,123,456);assert(callbackSema==21);
    woke(1,21,21);assert(mainSema.load()==-1);
    // Main can wake before the callback resumes after iSignalSema.
    signaled(8,0);assert(callbackSema==-1);
    callback(8,21,123,456);assert(callbackSema==-1);
    // An alarm worker's TLS can default to1: correlation is by semaphore,
    // never by treating callback tid1 as host-main identity.
    prepared(1,30);callback(1,31,456,789);assert(callbackSema==-1);
    callback(1,30,456,789);assert(callbackSema==30);
    signaled(1,0);woke(1,30,30);assert(mainSema.load()==-1);
    std::puts("PASS: main filter, identity, and wake-before-callback-return lifecycle");
}
