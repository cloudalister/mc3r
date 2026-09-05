#pragma once
// Passive retail mc3FeView +0x6AC writer probe. Included only by four local
// generated owners; never modifies the guest state or the scheduler.
#include <atomic>
#include <cstdio>
#include <cstdlib>
#include <cstring>

inline void mc3TraceFeWrite(const uint8_t* ram, const R5900Context* ctx,
                          uint32_t object, uint32_t value, uint32_t pc)
{
    static const bool enabled = [] {
        const char* env = std::getenv("MC3_FE_WRITE_TRACE");
        return env && std::strcmp(env, "1") == 0;
    }();
    static std::atomic<unsigned> count{0};
    if (!enabled || !ram || count.load(std::memory_order_relaxed) >= 512) return;
    const uint32_t base = object & PS2_RAM_MASK;
    if (base > PS2_RAM_MASK - 0x6B7u) return;
    const auto read32 = [ram](uint32_t address) {
        uint32_t result = 0;
        address &= PS2_RAM_MASK;
        if (address <= PS2_RAM_MASK - 3u) std::memcpy(&result, ram + address, 4);
        return result;
    };
    const uint32_t slot = read32(base + 0x6B0u);
    const uint32_t camera = slot < 11 ? read32(base + 0x680u + 4 * slot) : 0;
    uint16_t length = 0;
    if (camera && (camera & PS2_RAM_MASK) <= PS2_RAM_MASK - 5u)
        std::memcpy(&length, ram + (camera & PS2_RAM_MASK) + 4, 2);
    float timer = 0, duration = 0;
    std::memcpy(&timer, ram + 0x617988u, 4);
    std::memcpy(&duration, ram + 0x617990u, 4);
    const unsigned n = count.fetch_add(1, std::memory_order_relaxed);
    if (n >= 512) return;
    char line[512];
    std::snprintf(line, sizeof(line),
        "[mc3-fe-write] n=%u pc=0x%x obj=0x%x old=%d new=%d slot=%u camera=0x%x length=%u flag38=%u flag49=%u flag4a=%u timer=%.9g duration=%.9g f20=%.9g ra=0x%x\n",
        n, pc, object, static_cast<int32_t>(read32(base + 0x6ACu)),
        static_cast<int32_t>(value), slot, camera, unsigned(length),
        unsigned(ram[base + 0x38u]), unsigned(ram[base + 0x49u]), unsigned(ram[base + 0x4Au]),
        double(timer), double(duration), double(ctx->f[20]), getRegU32(ctx, 31));
    std::fputs(line, stderr);
}
