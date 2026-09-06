#include "ps2_runtime_macros.h"
#include <vector>
#include <fstream>
#include <iterator>
#include <cstdlib>
#include <cstdio>
void FUN_0042b140_0x42b140(uint8_t*,R5900Context*,PS2Runtime*);
void sub_0042BE50_0x42be50(uint8_t*,R5900Context*,PS2Runtime*);
namespace {
void require(bool ok,const char* why) { if(!ok) { std::fprintf(stderr,"FAIL list: %s\n",why); std::exit(1); } }
uint32_t read(const std::vector<uint8_t>& b,uint32_t a) { require(uint64_t(a)+4<=b.size(),"read bounds"); uint32_t v;std::memcpy(&v,b.data()+a,4);return v; }
void write(std::vector<uint8_t>& b,uint32_t a,uint32_t v) { require(uint64_t(a)+4<=b.size(),"write bounds");std::memcpy(b.data()+a,&v,4); }
uint64_t reg(const R5900Context& c,unsigned r) { return r ? uint64_t(_mm_extract_epi64(c.r[r],0)) : 0; }
void set(R5900Context& c,unsigned r,uint64_t v) { if(r) c.r[r]=_mm_insert_epi64(c.r[r],v,0); }
uint64_t sx(uint32_t v) { return uint64_t(int64_t(int32_t(v))); }
// Small independent reference interpreter reads retail ELF words, not helper
// expressions. Only this function's opcodes are supported; all others fail.
void reference(std::vector<uint8_t>& ram,R5900Context& c,const std::vector<uint32_t>& code) {
    auto word=[&](uint32_t pc) { require(pc>=0x42b150 && pc<=0x42b1c0 && pc%4==0,"reference PC");return code[(pc-0x42b150)/4]; };
    auto ordinary=[&](uint32_t w) {
        unsigned op=w>>26,s=(w>>21)&31,t=(w>>16)&31,d=(w>>11)&31;
        int32_t imm=int16_t(w&65535); uint32_t a=uint32_t(reg(c,s))+uint32_t(imm);
        switch(op) {
        case 15:set(c,t,sx(uint32_t(w&65535)<<16));break;
        case 35:set(c,t,sx(read(ram,a)));break;
        case 43:write(ram,a,uint32_t(reg(c,t)));break;
        case 9:set(c,t,sx(a));break;
        case 11:set(c,t,reg(c,s)<uint64_t(int64_t(imm)));break;
        case 0:
            if((w&63)==45) set(c,d,reg(c,s)+reg(c,t));
            else if((w&63)==35) set(c,d,sx(uint32_t(reg(c,s))-uint32_t(reg(c,t))));
            else require(false,"unsupported SPECIAL");
            break;
        default:require(false,"unsupported ordinary opcode");
        }
    };
    for(unsigned steps=0;c.pc!=0x123456;steps++) {
        require(steps<1000,"reference step bound");
        const uint32_t pc=c.pc,w=word(pc); unsigned op=w>>26,s=(w>>21)&31,t=(w>>16)&31;
        const bool jr=op==0 && (w&63)==8;
        if(jr || op==4 || op==5 || op==21) {
            const bool taken=jr || (op==4 ? reg(c,s)==reg(c,t) : reg(c,s)!=reg(c,t));
            const uint32_t target=jr ? uint32_t(reg(c,s)) : pc+4+uint32_t(int32_t(int16_t(w&65535))*4);
            if(op!=21 || taken) { c.branch_pc=pc;c.in_delay_slot=true;c.pc=pc+4;ordinary(word(pc+4));c.in_delay_slot=false; }
            c.pc=taken ? target : pc+8;
        } else { ordinary(w); c.pc=pc+4; }
    }
}
}
unsigned runListEntryTests() {
    std::ifstream stream("extracted_iso/SLUS_213.55",std::ios::binary);
    require(bool(stream),"ELF open");
    std::vector<uint8_t> elf((std::istreambuf_iterator<char>(stream)),{});
    require(read(elf,0)==0x464c457f && elf[4]==1 && elf[5]==1,"ELF32 LE");
    const uint32_t ph=read(elf,28),sz=read(elf,40)>>16,count=read(elf,44)&65535;
    std::vector<uint32_t> code;
    for(uint32_t i=0;i<count;i++) {
        uint32_t p=ph+i*sz,v=read(elf,p+8),len=read(elf,p+16);
        if(read(elf,p)==1 && 0x42b150>=v && uint64_t(0x42b1c4)<=uint64_t(v)+len)
            for(uint32_t a=0x42b150;a<0x42b1c4;a+=4) code.push_back(read(elf,read(elf,p+4)+a-v));
    }
    require(code.size()==29,"mapped 29 instruction words");
    unsigned cases=0;
    // All status branches, delta 0/1/2, negative delta, wrap, and mixed chains.
    for(uint32_t status : {0u,1u,2u,0xffffffffu}) for(uint32_t delta : {0u,1u,2u,100u,0xffffffffu,0x80000000u}) {
        std::vector<uint8_t> ram(32u*1024u*1024u);
        write(ram,0x618d04,100);write(ram,0x1000,0x2000);write(ram,0x1018,3);
        for(uint32_t n=0;n<3;n++) { uint32_t a=0x2000+n*0x100;
            write(ram,a+12,n==0 ? 100-delta : 98);write(ram,a+16,n==0 ? status : 0);
            write(ram,a+24,n==2 ? 0 : a+0x100);
        }
        R5900Context ctx{};ctx.pc=0x42b150;
        for(unsigned r=1;r<32;r++) ctx.r[r]=_mm_set_epi64x(0x123456789abcdefll+r,0x998877665544ll+r);
        set(ctx,4,0x1000);set(ctx,31,0x123456);
        auto expected=ctx;auto expectedRam=ram;
        reference(expectedRam,expected,code);
        FUN_0042b140_0x42b140(ram.data(),&ctx,nullptr);
        require(ctx.pc==expected.pc && ctx.branch_pc==expected.branch_pc && ctx.in_delay_slot==expected.in_delay_slot,"PC/branch equivalence");
        require(std::memcmp(ctx.r,expected.r,sizeof(ctx.r))==0,"all 128-bit GPR equivalence");
        require(ram==expectedRam,"all RAM stores equivalent");
        require(reg(ctx,2)==(status!=0 || delta<2 ? 0x2100u : 0x2000u),"expected selected node");
        cases++;
    }
    // Entire chain skipped -> zero; actual caller must invoke registered body,
    // update the list and restore its stack/callee saves. Also test nonzero result.
    auto runtime=std::make_unique<PS2Runtime>();
    runtime->registerFunction(0x42b150,FUN_0042b140_0x42b140);
    for(bool allSkipped : {true,false}) {
        std::vector<uint8_t> ram(32u*1024u*1024u);
        write(ram,0x618d04,100);write(ram,0x5000,0x6000);write(ram,0x5018,1);
        write(ram,0x6010,allSkipped ? 1 : 0);write(ram,0x600c,98);
        R5900Context c{};c.pc=0x42bf00;
        set(c,4,0x4000);set(c,5,0x5000);set(c,29,0x8000);set(c,31,0x123456);
        set(c,16,0x1122334455667788ull);set(c,17,0x8877665544332211ull);
        sub_0042BE50_0x42be50(ram.data(),&c,runtime.get());
        require(c.pc==0x123456 && reg(c,29)==0x8000,"caller return/stack");
        require(reg(c,16)==0x1122334455667788ull && reg(c,17)==0x8877665544332211ull,"callee saves");
        require(reg(c,2)==(allSkipped ? 0u : 0x6000u),"caller null/non-null result");
        require(read(ram,0x5000)==0 && read(ram,0x5018)==0,"caller consumed list");
        cases++;
    }
    std::printf("PASS: %u list cases (24 ELF-reference comparisons + 2 nested caller paths)\n",cases);
    return cases;
}
