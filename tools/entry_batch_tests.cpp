// Exercises the actual compiled generated owners, not reimplemented helpers.
#include "ps2_runtime_macros.h"
#include <vector>
#include <cstdio>
#include <cstdlib>
void sub_00501088_0x501088(uint8_t*, R5900Context*, PS2Runtime*);
void sub_0042BE50_0x42be50(uint8_t*, R5900Context*, PS2Runtime*);
void FUN_005b9500_0x5b9500(uint8_t*, R5900Context*, PS2Runtime*);
void FUN_005b9908_0x5b9908(uint8_t*, R5900Context*, PS2Runtime*);
// Test-only fail-fast sentinels for unexercised neighboring paths. Never linked
// into the game; an accidental jump to a neighboring body must fail the test.
void FUN_0024a5a8_0x24a5a8(uint8_t*, R5900Context*, PS2Runtime*) { std::abort(); }
void FUN_0024a7d8_0x24a7d8(uint8_t*, R5900Context*, PS2Runtime*) { std::abort(); }
void FUN_0055f288_0x55f288(uint8_t*, R5900Context*, PS2Runtime*) { std::abort(); }
void sub_0042BE28_0x42be28(uint8_t*, R5900Context*, PS2Runtime*) { std::abort(); }
static void check(bool ok, const char* message) {
    if (!ok) { std::fprintf(stderr,"FAIL: %s\n",message); std::exit(1); }
}
unsigned runListEntryTests();
int main() {
    std::vector<uint8_t> ram(32u*1024u*1024u);
    auto u32=[&](uint32_t a, uint32_t v) { std::memcpy(ram.data()+a,&v,4); };
    auto f32=[&](uint32_t a, float v) { std::memcpy(ram.data()+a,&v,4); };
    // Element 1 is a circle centered at (10,20), radius 5. Element 0 is a decoy.
    u32(0x1004,0x2000);
    f32(0x200c,10); f32(0x2010,20); f32(0x2014,5);
    unsigned cases=0;
    for (uint32_t entry : {0x501268u,0x5012c0u}) {
        for (float x : {10.f,13.f,16.f}) {
            f32(0x3000,x); f32(0x3004,x==13.f ? 24.f : 20.f);
            R5900Context ctx{};
            ctx.pc=entry;
            SET_GPR_U32(&ctx,4,0x1000); SET_GPR_U32(&ctx,5,1);
            SET_GPR_U32(&ctx,6,0x3000); SET_GPR_U32(&ctx,31,0x123456);
            SET_GPR_U32(&ctx,29,0x8000); SET_GPR_U64(&ctx,2,0xfeedface);
            sub_00501088_0x501088(ram.data(),&ctx,nullptr);
            const bool inside=x!=16.f;
            check(GPR_U64((&ctx),2)==uint64_t(entry==0x501268u ? inside : !inside),"circle predicate inside/boundary/outside");
            check(ctx.pc==0x123456 && GPR_U32((&ctx),29)==0x8000,"predicate RA/SP");
            cases++;
        }
    }
    // Zero-count branch requires no nested runtime calls, but executes real prologue/epilogue.
    R5900Context ctx{};
    ctx.pc=0x42bf00;
    SET_GPR_U32(&ctx,4,0x4000); SET_GPR_U32(&ctx,5,0x5000);
    SET_GPR_U32(&ctx,29,0x8000); SET_GPR_U32(&ctx,31,0x123456);
    SET_GPR_U64(&ctx,16,0x1122334455667788ull); SET_GPR_U64(&ctx,17,0x8877665544332211ull);
    u32(0x5018,0);
    sub_0042BE50_0x42be50(ram.data(),&ctx,nullptr);
    check(ctx.pc==0x123456 && GPR_U32((&ctx),29)==0x8000,"42bf00 RA/SP restored");
    check(GPR_U64((&ctx),2)==0 && GPR_U64((&ctx),16)==0x1122334455667788ull && GPR_U64((&ctx),17)==0x8877665544332211ull,"42bf00 return/callee saves");
    cases++;
    for (uint32_t entry : {0x5b94f0u,0x5b94f8u,0x5b9990u,0x5b9998u}) {
        R5900Context leaf{}; leaf.pc=entry;
        SET_GPR_U32(&leaf,31,0x123456); SET_GPR_U64(&leaf,2,0xabcdef);
        const auto before=leaf;
        (entry<0x5b9900 ? FUN_005b9500_0x5b9500 : FUN_005b9908_0x5b9908)(ram.data(),&leaf,nullptr);
        check(leaf.pc==0x123456 && std::memcmp(leaf.r,before.r,sizeof(leaf.r))==0,"actual owner leaf dispatch preserves GPRs");
        check(leaf.branch_pc==entry && !leaf.in_delay_slot,"leaf branch metadata");
        cases++;
    }
    cases += runListEntryTests();
    std::printf("PASS: %u actual generated-entry cases\n",cases);
}
