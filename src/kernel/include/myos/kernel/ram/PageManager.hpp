#pragma once

#include <cstddef>
#include <myos/core/collections/BitSet.hpp>
#include <myos/core/collections/ArrayList.hpp>

namespace myos::kernel::ram {

/**
 * Manages page frames for user programs.
 * A PageFrameManager merely records usage statistics about
 * page frames, it doesn't directly access them.
 */
class PageManager {
public:
    /**
     * Construct a PageFrameManager
     * @param start start address (physical) of all page frames. It must
     * be aligned to pageFrameSize.
     * @param pageFrameSize size of each page frame
     * @param count (maximum) number of page frames
     */
    explicit PageManager(void *start, size_t count);

    /**
     * Allocate a page frame for use by user programs.
     * @return pointer to the beginning of a page frame,
     * nullptr if failed.
     */
    void *newPage();

    uint32_t &processCount(void *page);

    const uint32_t &processCount(void *page) const;

    /**
     * Subtract the number of processes using a particular page
     * @param physicalAddress the page frame to deallocate.
     */
    void deletePage(void *physicalAddress);

private:
    // Each element is the number of processes sharing a page.
    core::collections::ArrayList<uint32_t> counters;

    uintptr_t start;

    /**
     * Convert from index of page frame to physical memory address.
     */
    void *indexToAddress(size_t index) const;

    size_t addressToIndex(void *address) const;
};

}
