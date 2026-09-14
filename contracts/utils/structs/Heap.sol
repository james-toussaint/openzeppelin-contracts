// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.7.0) (utils/structs/Heap.sol)
// This file was procedurally generated from scripts/generate/templates/Heap.sol.eta.

pragma solidity ^0.8.24;

import {Arrays} from "../Arrays.sol";
import {Comparators} from "../Comparators.sol";
import {Math} from "../math/Math.sol";
import {Panic} from "../Panic.sol";
import {StorageSlot} from "../StorageSlot.sol";

/**
 * @dev Library for managing https://en.wikipedia.org/wiki/Binary_heap[binary heap] that can be used as
 * https://en.wikipedia.org/wiki/Priority_queue[priority queue].
 *
 * Heaps are represented as a tree of values where the first element (index 0) is the root, and where the node at
 * index i is the child of the node at index (i-1)/2 and the parent of nodes at index 2*i+1 and 2*i+2. Each node
 * stores an element of the heap.
 *
 * The structure is ordered so that, per the comparator, each node has lower priority than its parent; as a
 * consequence, the highest-priority value is at the root. This value can be looked up in constant time (O(1)) at
 * `heap.tree[0]`. By default, the comparator is `Comparators.lt`, which treats smaller values as higher priority
 * (min-heap). Using `Comparators.gt` yields a max-heap.
 *
 * The structure is designed to perform the following operations with the corresponding complexities:
 *
 * * peek (get the highest priority value): O(1)
 * * insert (insert a value): O(log(n))
 * * pop (remove the highest priority value): O(log(n))
 * * replace (replace the highest priority value with a new value): O(log(n))
 * * length (get the number of elements): O(1)
 * * clear (remove all elements): O(1)
 *
 * IMPORTANT: This library allows for the use of custom comparator functions. Given that manipulating
 * memory can lead to unexpected behavior. Consider verifying that the comparator does not manipulate
 * the Heap's state directly and that it follows the Solidity memory safety rules.
 *
 * _Available since v5.1._
 */
library Heap {
    using Arrays for *;
    using Math for *;

    /**
     * @dev Binary heap that supports values of type uint256.
     *
     * Each element of that structure uses one storage slot.
     */
    struct Uint256Heap {
        uint256[] tree;
    }

    /**
     * @dev Lookup the root element of the heap.
     */
    function peek(Uint256Heap storage self) internal view returns (uint256) {
        // self.tree[0] will `ARRAY_ACCESS_OUT_OF_BOUNDS` panic if heap is empty.
        return self.tree[0];
    }

    /**
     * @dev Remove (and return) the root element for the heap using the default comparator.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function pop(Uint256Heap storage self) internal returns (uint256) {
        return pop(self, Comparators.lt);
    }

    /**
     * @dev Remove (and return) the root element for the heap using the provided comparator.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function pop(
        Uint256Heap storage self,
        function(uint256, uint256) view returns (bool) comp
    ) internal returns (uint256) {
        unchecked {
            uint256 size = length(self);
            if (size == 0) Panic.panic(Panic.EMPTY_ARRAY_POP);

            // cache
            uint256 rootValue = self.tree.unsafeAccess(0).value;
            if (size == 1) {
                self.tree.pop();
            } else {
                // swap last leaf with root ...
                uint256 lastValue = self.tree.unsafeAccess(size - 1).value;
                self.tree.unsafeAccess(0).value = lastValue;
                // ... shrink tree ...
                self.tree.pop();
                // ... re-heapify
                _siftDown(self, size - 1, 0, lastValue, comp);
            }
            return rootValue;
        }
    }

    /**
     * @dev Insert a new element in the heap using the default comparator.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function insert(Uint256Heap storage self, uint256 value) internal {
        insert(self, value, Comparators.lt);
    }

    /**
     * @dev Insert a new element in the heap using the provided comparator.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function insert(
        Uint256Heap storage self,
        uint256 value,
        function(uint256, uint256) view returns (bool) comp
    ) internal {
        uint256 size = length(self);

        // push new item and re-heapify
        self.tree.push(value);
        _siftUp(self, size, value, comp);
    }

    /**
     * @dev Return the root element for the heap, and replace it with a new value, using the default comparator.
     * This is equivalent to using {pop} and {insert}, but requires only one rebalancing operation.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function replace(Uint256Heap storage self, uint256 newValue) internal returns (uint256) {
        return replace(self, newValue, Comparators.lt);
    }

    /**
     * @dev Return the root element for the heap, and replace it with a new value, using the provided comparator.
     * This is equivalent to using {pop} and {insert}, but requires only one rebalancing operation.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function replace(
        Uint256Heap storage self,
        uint256 newValue,
        function(uint256, uint256) view returns (bool) comp
    ) internal returns (uint256) {
        uint256 size = length(self);
        if (size == 0) Panic.panic(Panic.EMPTY_ARRAY_POP);

        // cache
        uint256 oldValue = self.tree.unsafeAccess(0).value;

        // replace and re-heapify
        self.tree.unsafeAccess(0).value = newValue;
        _siftDown(self, size, 0, newValue, comp);

        return oldValue;
    }

    /**
     * @dev Returns the number of elements in the heap.
     */
    function length(Uint256Heap storage self) internal view returns (uint256) {
        return self.tree.length;
    }

    /**
     * @dev Removes all elements in the heap.
     */
    function clear(Uint256Heap storage self) internal {
        self.tree.unsafeSetLength(0);
    }

    /**
     * @dev Swap node `i` and `j` in the tree.
     */
    function _swap(Uint256Heap storage self, uint256 i, uint256 j) private {
        StorageSlot.Uint256Slot storage ni = self.tree.unsafeAccess(i);
        StorageSlot.Uint256Slot storage nj = self.tree.unsafeAccess(j);
        (ni.value, nj.value) = (nj.value, ni.value);
    }

    /**
     * @dev Perform heap maintenance on `self`, starting at `index` (with the `value`), using `comp` as a
     * comparator, and moving toward the leaves of the underlying tree.
     *
     * NOTE: This is a private function that is called in a trusted context with already cached parameters. `size`
     * and `value` could be extracted from `self` and `index`, but that would require redundant storage read. These
     * parameters are not verified. It is the caller role to make sure the parameters are correct.
     */
    function _siftDown(
        Uint256Heap storage self,
        uint256 size,
        uint256 index,
        uint256 value,
        function(uint256, uint256) view returns (bool) comp
    ) private {
        unchecked {
            // Check if there is a risk of overflow when computing the indices of the child nodes. If that is the case,
            // there cannot be child nodes in the tree, so sifting is done.
            if (index >= type(uint256).max / 2) return;

            // Compute the indices of the potential child nodes
            uint256 lIndex = 2 * index + 1;
            uint256 rIndex = 2 * index + 2;

            // Three cases:
            // 1. Both children exist: sifting may continue on one of the branches (selection required)
            // 2. Only left child exist: sifting may continue on the left branch (no selection required)
            // 3. Neither child exist: sifting is done
            if (rIndex < size) {
                uint256 lValue = self.tree.unsafeAccess(lIndex).value;
                uint256 rValue = self.tree.unsafeAccess(rIndex).value;
                if (comp(lValue, value) || comp(rValue, value)) {
                    uint256 cIndex = comp(lValue, rValue).ternary(lIndex, rIndex);
                    _swap(self, index, cIndex);
                    _siftDown(self, size, cIndex, value, comp);
                }
            } else if (lIndex < size) {
                uint256 lValue = self.tree.unsafeAccess(lIndex).value;
                if (comp(lValue, value)) {
                    _swap(self, index, lIndex);
                    _siftDown(self, size, lIndex, value, comp);
                }
            }
        }
    }

    /**
     * @dev Perform heap maintenance on `self`, starting at `index` (with the `value`), using `comp` as a
     * comparator, and moving toward the root of the underlying tree.
     *
     * NOTE: This is a private function that is called in a trusted context with already cached parameters. `value`
     * could be extracted from `self` and `index`, but that would require redundant storage read. These parameters are not
     * verified. It is the caller role to make sure the parameters are correct.
     */
    function _siftUp(
        Uint256Heap storage self,
        uint256 index,
        uint256 value,
        function(uint256, uint256) view returns (bool) comp
    ) private {
        unchecked {
            while (index > 0) {
                uint256 parentIndex = (index - 1) / 2;
                uint256 parentValue = self.tree.unsafeAccess(parentIndex).value;
                if (comp(parentValue, value)) break;
                _swap(self, index, parentIndex);
                index = parentIndex;
            }
        }
    }

    /**
     * @dev Binary heap that supports values of type uint128.
     *
     * Values are packed 2 per storage slot, reducing the heap's storage footprint (and the gas cost of
     * {insert} and {pop}) relative to {Uint256Heap}, at the cost of a smaller value range.
     */
    struct Uint128Heap {
        uint128[] tree;
    }

    /**
     * @dev Lookup the root element of the heap.
     */
    function peek(Uint128Heap storage self) internal view returns (uint128) {
        // self.tree[0] will `ARRAY_ACCESS_OUT_OF_BOUNDS` panic if heap is empty.
        return self.tree[0];
    }

    /**
     * @dev Remove (and return) the root element for the heap using the default comparator.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function pop(Uint128Heap storage self) internal returns (uint128) {
        return pop(self, Comparators.lt);
    }

    /**
     * @dev Remove (and return) the root element for the heap using the provided comparator.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function pop(
        Uint128Heap storage self,
        function(uint256, uint256) view returns (bool) comp
    ) internal returns (uint128) {
        unchecked {
            uint256 size = length(self);
            if (size == 0) Panic.panic(Panic.EMPTY_ARRAY_POP);

            // cache
            uint128 rootValue = _unsafeGet(self.tree, 0);
            if (size == 1) {
                self.tree.pop();
            } else {
                // swap last leaf with root ...
                uint128 lastValue = _unsafeGet(self.tree, size - 1);
                _unsafeSet(self.tree, 0, lastValue);
                // ... shrink tree ...
                self.tree.pop();
                // ... re-heapify
                _siftDown(self, size - 1, 0, lastValue, comp);
            }
            return rootValue;
        }
    }

    /**
     * @dev Insert a new element in the heap using the default comparator.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function insert(Uint128Heap storage self, uint128 value) internal {
        insert(self, value, Comparators.lt);
    }

    /**
     * @dev Insert a new element in the heap using the provided comparator.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function insert(
        Uint128Heap storage self,
        uint128 value,
        function(uint256, uint256) view returns (bool) comp
    ) internal {
        uint256 size = length(self);

        // push new item and re-heapify
        self.tree.push(value);
        _siftUp(self, size, value, comp);
    }

    /**
     * @dev Return the root element for the heap, and replace it with a new value, using the default comparator.
     * This is equivalent to using {pop} and {insert}, but requires only one rebalancing operation.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function replace(Uint128Heap storage self, uint128 newValue) internal returns (uint128) {
        return replace(self, newValue, Comparators.lt);
    }

    /**
     * @dev Return the root element for the heap, and replace it with a new value, using the provided comparator.
     * This is equivalent to using {pop} and {insert}, but requires only one rebalancing operation.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function replace(
        Uint128Heap storage self,
        uint128 newValue,
        function(uint256, uint256) view returns (bool) comp
    ) internal returns (uint128) {
        uint256 size = length(self);
        if (size == 0) Panic.panic(Panic.EMPTY_ARRAY_POP);

        // cache
        uint128 oldValue = _unsafeGet(self.tree, 0);

        // replace and re-heapify
        _unsafeSet(self.tree, 0, newValue);
        _siftDown(self, size, 0, newValue, comp);

        return oldValue;
    }

    /**
     * @dev Returns the number of elements in the heap.
     */
    function length(Uint128Heap storage self) internal view returns (uint256) {
        return self.tree.length;
    }

    /**
     * @dev Removes all elements in the heap.
     */
    function clear(Uint128Heap storage self) internal {
        uint128[] storage tree = self.tree;
        assembly ("memory-safe") {
            sstore(tree.slot, 0)
        }
    }

    /**
     * @dev Swap node `i` and `j` in the tree.
     */
    function _swap(Uint128Heap storage self, uint256 i, uint256 j) private {
        uint128[] storage tree = self.tree;
        assembly ("memory-safe") {
            mstore(0x00, tree.slot)
            let base := keccak256(0x00, 0x20)
            let si := add(base, shr(1, i)) // slot holding element i
            let sj := add(base, shr(1, j)) // slot holding element j
            let shi := shl(7, and(i, 1)) // bit offset of element i in its slot
            let shj := shl(7, and(j, 1)) // bit offset of element j in its slot
            let mask := shr(128, not(0)) // low 128 bits
            switch eq(si, sj)
            case 1 {
                // i and j share a storage slot: read it once, swap the two sub-words, write it once
                let w := sload(si)
                let vi := and(shr(shi, w), mask)
                let vj := and(shr(shj, w), mask)
                w := and(w, not(or(shl(shi, mask), shl(shj, mask))))
                sstore(si, or(w, or(shl(shi, vj), shl(shj, vi))))
            }
            default {
                let vi := and(shr(shi, sload(si)), mask)
                let vj := and(shr(shj, sload(sj)), mask)
                sstore(si, or(and(sload(si), not(shl(shi, mask))), shl(shi, vj)))
                sstore(sj, or(and(sload(sj), not(shl(shj, mask))), shl(shj, vi)))
            }
        }
    }

    /**
     * @dev Perform heap maintenance on `self`, starting at `index` (with the `value`), using `comp` as a
     * comparator, and moving toward the leaves of the underlying tree.
     *
     * NOTE: This is a private function that is called in a trusted context with already cached parameters. `size`
     * and `value` could be extracted from `self` and `index`, but that would require redundant storage read. These
     * parameters are not verified. It is the caller role to make sure the parameters are correct.
     */
    function _siftDown(
        Uint128Heap storage self,
        uint256 size,
        uint256 index,
        uint128 value,
        function(uint256, uint256) view returns (bool) comp
    ) private {
        unchecked {
            // Check if there is a risk of overflow when computing the indices of the child nodes. If that is the case,
            // there cannot be child nodes in the tree, so sifting is done.
            if (index >= type(uint256).max / 2) return;

            // Compute the indices of the potential child nodes
            uint256 lIndex = 2 * index + 1;
            uint256 rIndex = 2 * index + 2;

            // Three cases:
            // 1. Both children exist: sifting may continue on one of the branches (selection required)
            // 2. Only left child exist: sifting may continue on the left branch (no selection required)
            // 3. Neither child exist: sifting is done
            if (rIndex < size) {
                uint128 lValue = _unsafeGet(self.tree, lIndex);
                uint128 rValue = _unsafeGet(self.tree, rIndex);
                if (comp(lValue, value) || comp(rValue, value)) {
                    uint256 cIndex = comp(lValue, rValue).ternary(lIndex, rIndex);
                    _swap(self, index, cIndex);
                    _siftDown(self, size, cIndex, value, comp);
                }
            } else if (lIndex < size) {
                uint128 lValue = _unsafeGet(self.tree, lIndex);
                if (comp(lValue, value)) {
                    _swap(self, index, lIndex);
                    _siftDown(self, size, lIndex, value, comp);
                }
            }
        }
    }

    /**
     * @dev Perform heap maintenance on `self`, starting at `index` (with the `value`), using `comp` as a
     * comparator, and moving toward the root of the underlying tree.
     *
     * NOTE: This is a private function that is called in a trusted context with already cached parameters. `value`
     * could be extracted from `self` and `index`, but that would require redundant storage read. These parameters are not
     * verified. It is the caller role to make sure the parameters are correct.
     */
    function _siftUp(
        Uint128Heap storage self,
        uint256 index,
        uint128 value,
        function(uint256, uint256) view returns (bool) comp
    ) private {
        unchecked {
            while (index > 0) {
                uint256 parentIndex = (index - 1) / 2;
                uint128 parentValue = _unsafeGet(self.tree, parentIndex);
                if (comp(parentValue, value)) break;
                _swap(self, index, parentIndex);
                index = parentIndex;
            }
        }
    }

    /**
     * @dev Read the `index`th element of a packed (2-per-slot) `uint128[]` storage array, skipping the
     * solidity "index-out-of-range" check. It is the caller's responsibility to make sure `index` is in bounds.
     */
    function _unsafeGet(uint128[] storage tree, uint256 index) private view returns (uint128 value) {
        assembly ("memory-safe") {
            mstore(0x00, tree.slot)
            let slot := add(keccak256(0x00, 0x20), shr(1, index))
            value := and(shr(shl(7, and(index, 1)), sload(slot)), shr(128, not(0)))
        }
    }

    /**
     * @dev Write `value` to the `index`th element of a packed (2-per-slot) `uint128[]` storage array, skipping
     * the solidity "index-out-of-range" check. It is the caller's responsibility to make sure `index` is in bounds.
     */
    function _unsafeSet(uint128[] storage tree, uint256 index, uint128 value) private {
        assembly ("memory-safe") {
            mstore(0x00, tree.slot)
            let slot := add(keccak256(0x00, 0x20), shr(1, index))
            let shift := shl(7, and(index, 1)) // bit offset of the element in its slot
            // clear the target sub-word, then splice `value` into it (`value` already fits in 128 bits)
            sstore(slot, or(and(sload(slot), not(shl(shift, shr(128, not(0))))), shl(shift, value)))
        }
    }

    /**
     * @dev Binary heap that supports values of type uint64.
     *
     * Values are packed 4 per storage slot, reducing the heap's storage footprint (and the gas cost of
     * {insert} and {pop}) relative to {Uint256Heap}, at the cost of a smaller value range.
     */
    struct Uint64Heap {
        uint64[] tree;
    }

    /**
     * @dev Lookup the root element of the heap.
     */
    function peek(Uint64Heap storage self) internal view returns (uint64) {
        // self.tree[0] will `ARRAY_ACCESS_OUT_OF_BOUNDS` panic if heap is empty.
        return self.tree[0];
    }

    /**
     * @dev Remove (and return) the root element for the heap using the default comparator.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function pop(Uint64Heap storage self) internal returns (uint64) {
        return pop(self, Comparators.lt);
    }

    /**
     * @dev Remove (and return) the root element for the heap using the provided comparator.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function pop(
        Uint64Heap storage self,
        function(uint256, uint256) view returns (bool) comp
    ) internal returns (uint64) {
        unchecked {
            uint256 size = length(self);
            if (size == 0) Panic.panic(Panic.EMPTY_ARRAY_POP);

            // cache
            uint64 rootValue = _unsafeGet(self.tree, 0);
            if (size == 1) {
                self.tree.pop();
            } else {
                // swap last leaf with root ...
                uint64 lastValue = _unsafeGet(self.tree, size - 1);
                _unsafeSet(self.tree, 0, lastValue);
                // ... shrink tree ...
                self.tree.pop();
                // ... re-heapify
                _siftDown(self, size - 1, 0, lastValue, comp);
            }
            return rootValue;
        }
    }

    /**
     * @dev Insert a new element in the heap using the default comparator.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function insert(Uint64Heap storage self, uint64 value) internal {
        insert(self, value, Comparators.lt);
    }

    /**
     * @dev Insert a new element in the heap using the provided comparator.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function insert(
        Uint64Heap storage self,
        uint64 value,
        function(uint256, uint256) view returns (bool) comp
    ) internal {
        uint256 size = length(self);

        // push new item and re-heapify
        self.tree.push(value);
        _siftUp(self, size, value, comp);
    }

    /**
     * @dev Return the root element for the heap, and replace it with a new value, using the default comparator.
     * This is equivalent to using {pop} and {insert}, but requires only one rebalancing operation.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function replace(Uint64Heap storage self, uint64 newValue) internal returns (uint64) {
        return replace(self, newValue, Comparators.lt);
    }

    /**
     * @dev Return the root element for the heap, and replace it with a new value, using the provided comparator.
     * This is equivalent to using {pop} and {insert}, but requires only one rebalancing operation.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function replace(
        Uint64Heap storage self,
        uint64 newValue,
        function(uint256, uint256) view returns (bool) comp
    ) internal returns (uint64) {
        uint256 size = length(self);
        if (size == 0) Panic.panic(Panic.EMPTY_ARRAY_POP);

        // cache
        uint64 oldValue = _unsafeGet(self.tree, 0);

        // replace and re-heapify
        _unsafeSet(self.tree, 0, newValue);
        _siftDown(self, size, 0, newValue, comp);

        return oldValue;
    }

    /**
     * @dev Returns the number of elements in the heap.
     */
    function length(Uint64Heap storage self) internal view returns (uint256) {
        return self.tree.length;
    }

    /**
     * @dev Removes all elements in the heap.
     */
    function clear(Uint64Heap storage self) internal {
        uint64[] storage tree = self.tree;
        assembly ("memory-safe") {
            sstore(tree.slot, 0)
        }
    }

    /**
     * @dev Swap node `i` and `j` in the tree.
     */
    function _swap(Uint64Heap storage self, uint256 i, uint256 j) private {
        uint64[] storage tree = self.tree;
        assembly ("memory-safe") {
            mstore(0x00, tree.slot)
            let base := keccak256(0x00, 0x20)
            let si := add(base, shr(2, i)) // slot holding element i
            let sj := add(base, shr(2, j)) // slot holding element j
            let shi := shl(6, and(i, 3)) // bit offset of element i in its slot
            let shj := shl(6, and(j, 3)) // bit offset of element j in its slot
            let mask := shr(192, not(0)) // low 64 bits
            switch eq(si, sj)
            case 1 {
                // i and j share a storage slot: read it once, swap the two sub-words, write it once
                let w := sload(si)
                let vi := and(shr(shi, w), mask)
                let vj := and(shr(shj, w), mask)
                w := and(w, not(or(shl(shi, mask), shl(shj, mask))))
                sstore(si, or(w, or(shl(shi, vj), shl(shj, vi))))
            }
            default {
                let vi := and(shr(shi, sload(si)), mask)
                let vj := and(shr(shj, sload(sj)), mask)
                sstore(si, or(and(sload(si), not(shl(shi, mask))), shl(shi, vj)))
                sstore(sj, or(and(sload(sj), not(shl(shj, mask))), shl(shj, vi)))
            }
        }
    }

    /**
     * @dev Perform heap maintenance on `self`, starting at `index` (with the `value`), using `comp` as a
     * comparator, and moving toward the leaves of the underlying tree.
     *
     * NOTE: This is a private function that is called in a trusted context with already cached parameters. `size`
     * and `value` could be extracted from `self` and `index`, but that would require redundant storage read. These
     * parameters are not verified. It is the caller role to make sure the parameters are correct.
     */
    function _siftDown(
        Uint64Heap storage self,
        uint256 size,
        uint256 index,
        uint64 value,
        function(uint256, uint256) view returns (bool) comp
    ) private {
        unchecked {
            // Check if there is a risk of overflow when computing the indices of the child nodes. If that is the case,
            // there cannot be child nodes in the tree, so sifting is done.
            if (index >= type(uint256).max / 2) return;

            // Compute the indices of the potential child nodes
            uint256 lIndex = 2 * index + 1;
            uint256 rIndex = 2 * index + 2;

            // Three cases:
            // 1. Both children exist: sifting may continue on one of the branches (selection required)
            // 2. Only left child exist: sifting may continue on the left branch (no selection required)
            // 3. Neither child exist: sifting is done
            if (rIndex < size) {
                uint64 lValue = _unsafeGet(self.tree, lIndex);
                uint64 rValue = _unsafeGet(self.tree, rIndex);
                if (comp(lValue, value) || comp(rValue, value)) {
                    uint256 cIndex = comp(lValue, rValue).ternary(lIndex, rIndex);
                    _swap(self, index, cIndex);
                    _siftDown(self, size, cIndex, value, comp);
                }
            } else if (lIndex < size) {
                uint64 lValue = _unsafeGet(self.tree, lIndex);
                if (comp(lValue, value)) {
                    _swap(self, index, lIndex);
                    _siftDown(self, size, lIndex, value, comp);
                }
            }
        }
    }

    /**
     * @dev Perform heap maintenance on `self`, starting at `index` (with the `value`), using `comp` as a
     * comparator, and moving toward the root of the underlying tree.
     *
     * NOTE: This is a private function that is called in a trusted context with already cached parameters. `value`
     * could be extracted from `self` and `index`, but that would require redundant storage read. These parameters are not
     * verified. It is the caller role to make sure the parameters are correct.
     */
    function _siftUp(
        Uint64Heap storage self,
        uint256 index,
        uint64 value,
        function(uint256, uint256) view returns (bool) comp
    ) private {
        unchecked {
            while (index > 0) {
                uint256 parentIndex = (index - 1) / 2;
                uint64 parentValue = _unsafeGet(self.tree, parentIndex);
                if (comp(parentValue, value)) break;
                _swap(self, index, parentIndex);
                index = parentIndex;
            }
        }
    }

    /**
     * @dev Read the `index`th element of a packed (4-per-slot) `uint64[]` storage array, skipping the
     * solidity "index-out-of-range" check. It is the caller's responsibility to make sure `index` is in bounds.
     */
    function _unsafeGet(uint64[] storage tree, uint256 index) private view returns (uint64 value) {
        assembly ("memory-safe") {
            mstore(0x00, tree.slot)
            let slot := add(keccak256(0x00, 0x20), shr(2, index))
            value := and(shr(shl(6, and(index, 3)), sload(slot)), shr(192, not(0)))
        }
    }

    /**
     * @dev Write `value` to the `index`th element of a packed (4-per-slot) `uint64[]` storage array, skipping
     * the solidity "index-out-of-range" check. It is the caller's responsibility to make sure `index` is in bounds.
     */
    function _unsafeSet(uint64[] storage tree, uint256 index, uint64 value) private {
        assembly ("memory-safe") {
            mstore(0x00, tree.slot)
            let slot := add(keccak256(0x00, 0x20), shr(2, index))
            let shift := shl(6, and(index, 3)) // bit offset of the element in its slot
            // clear the target sub-word, then splice `value` into it (`value` already fits in 64 bits)
            sstore(slot, or(and(sload(slot), not(shl(shift, shr(192, not(0))))), shl(shift, value)))
        }
    }

    /**
     * @dev Binary heap that supports values of type uint32.
     *
     * Values are packed 8 per storage slot, reducing the heap's storage footprint (and the gas cost of
     * {insert} and {pop}) relative to {Uint256Heap}, at the cost of a smaller value range.
     */
    struct Uint32Heap {
        uint32[] tree;
    }

    /**
     * @dev Lookup the root element of the heap.
     */
    function peek(Uint32Heap storage self) internal view returns (uint32) {
        // self.tree[0] will `ARRAY_ACCESS_OUT_OF_BOUNDS` panic if heap is empty.
        return self.tree[0];
    }

    /**
     * @dev Remove (and return) the root element for the heap using the default comparator.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function pop(Uint32Heap storage self) internal returns (uint32) {
        return pop(self, Comparators.lt);
    }

    /**
     * @dev Remove (and return) the root element for the heap using the provided comparator.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function pop(
        Uint32Heap storage self,
        function(uint256, uint256) view returns (bool) comp
    ) internal returns (uint32) {
        unchecked {
            uint256 size = length(self);
            if (size == 0) Panic.panic(Panic.EMPTY_ARRAY_POP);

            // cache
            uint32 rootValue = _unsafeGet(self.tree, 0);
            if (size == 1) {
                self.tree.pop();
            } else {
                // swap last leaf with root ...
                uint32 lastValue = _unsafeGet(self.tree, size - 1);
                _unsafeSet(self.tree, 0, lastValue);
                // ... shrink tree ...
                self.tree.pop();
                // ... re-heapify
                _siftDown(self, size - 1, 0, lastValue, comp);
            }
            return rootValue;
        }
    }

    /**
     * @dev Insert a new element in the heap using the default comparator.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function insert(Uint32Heap storage self, uint32 value) internal {
        insert(self, value, Comparators.lt);
    }

    /**
     * @dev Insert a new element in the heap using the provided comparator.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function insert(
        Uint32Heap storage self,
        uint32 value,
        function(uint256, uint256) view returns (bool) comp
    ) internal {
        uint256 size = length(self);

        // push new item and re-heapify
        self.tree.push(value);
        _siftUp(self, size, value, comp);
    }

    /**
     * @dev Return the root element for the heap, and replace it with a new value, using the default comparator.
     * This is equivalent to using {pop} and {insert}, but requires only one rebalancing operation.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function replace(Uint32Heap storage self, uint32 newValue) internal returns (uint32) {
        return replace(self, newValue, Comparators.lt);
    }

    /**
     * @dev Return the root element for the heap, and replace it with a new value, using the provided comparator.
     * This is equivalent to using {pop} and {insert}, but requires only one rebalancing operation.
     *
     * NOTE: All inserting and removal from a heap should always be done using the same comparator. Mixing comparator
     * during the lifecycle of a heap will result in undefined behavior.
     */
    function replace(
        Uint32Heap storage self,
        uint32 newValue,
        function(uint256, uint256) view returns (bool) comp
    ) internal returns (uint32) {
        uint256 size = length(self);
        if (size == 0) Panic.panic(Panic.EMPTY_ARRAY_POP);

        // cache
        uint32 oldValue = _unsafeGet(self.tree, 0);

        // replace and re-heapify
        _unsafeSet(self.tree, 0, newValue);
        _siftDown(self, size, 0, newValue, comp);

        return oldValue;
    }

    /**
     * @dev Returns the number of elements in the heap.
     */
    function length(Uint32Heap storage self) internal view returns (uint256) {
        return self.tree.length;
    }

    /**
     * @dev Removes all elements in the heap.
     */
    function clear(Uint32Heap storage self) internal {
        uint32[] storage tree = self.tree;
        assembly ("memory-safe") {
            sstore(tree.slot, 0)
        }
    }

    /**
     * @dev Swap node `i` and `j` in the tree.
     */
    function _swap(Uint32Heap storage self, uint256 i, uint256 j) private {
        uint32[] storage tree = self.tree;
        assembly ("memory-safe") {
            mstore(0x00, tree.slot)
            let base := keccak256(0x00, 0x20)
            let si := add(base, shr(3, i)) // slot holding element i
            let sj := add(base, shr(3, j)) // slot holding element j
            let shi := shl(5, and(i, 7)) // bit offset of element i in its slot
            let shj := shl(5, and(j, 7)) // bit offset of element j in its slot
            let mask := shr(224, not(0)) // low 32 bits
            switch eq(si, sj)
            case 1 {
                // i and j share a storage slot: read it once, swap the two sub-words, write it once
                let w := sload(si)
                let vi := and(shr(shi, w), mask)
                let vj := and(shr(shj, w), mask)
                w := and(w, not(or(shl(shi, mask), shl(shj, mask))))
                sstore(si, or(w, or(shl(shi, vj), shl(shj, vi))))
            }
            default {
                let vi := and(shr(shi, sload(si)), mask)
                let vj := and(shr(shj, sload(sj)), mask)
                sstore(si, or(and(sload(si), not(shl(shi, mask))), shl(shi, vj)))
                sstore(sj, or(and(sload(sj), not(shl(shj, mask))), shl(shj, vi)))
            }
        }
    }

    /**
     * @dev Perform heap maintenance on `self`, starting at `index` (with the `value`), using `comp` as a
     * comparator, and moving toward the leaves of the underlying tree.
     *
     * NOTE: This is a private function that is called in a trusted context with already cached parameters. `size`
     * and `value` could be extracted from `self` and `index`, but that would require redundant storage read. These
     * parameters are not verified. It is the caller role to make sure the parameters are correct.
     */
    function _siftDown(
        Uint32Heap storage self,
        uint256 size,
        uint256 index,
        uint32 value,
        function(uint256, uint256) view returns (bool) comp
    ) private {
        unchecked {
            // Check if there is a risk of overflow when computing the indices of the child nodes. If that is the case,
            // there cannot be child nodes in the tree, so sifting is done.
            if (index >= type(uint256).max / 2) return;

            // Compute the indices of the potential child nodes
            uint256 lIndex = 2 * index + 1;
            uint256 rIndex = 2 * index + 2;

            // Three cases:
            // 1. Both children exist: sifting may continue on one of the branches (selection required)
            // 2. Only left child exist: sifting may continue on the left branch (no selection required)
            // 3. Neither child exist: sifting is done
            if (rIndex < size) {
                uint32 lValue = _unsafeGet(self.tree, lIndex);
                uint32 rValue = _unsafeGet(self.tree, rIndex);
                if (comp(lValue, value) || comp(rValue, value)) {
                    uint256 cIndex = comp(lValue, rValue).ternary(lIndex, rIndex);
                    _swap(self, index, cIndex);
                    _siftDown(self, size, cIndex, value, comp);
                }
            } else if (lIndex < size) {
                uint32 lValue = _unsafeGet(self.tree, lIndex);
                if (comp(lValue, value)) {
                    _swap(self, index, lIndex);
                    _siftDown(self, size, lIndex, value, comp);
                }
            }
        }
    }

    /**
     * @dev Perform heap maintenance on `self`, starting at `index` (with the `value`), using `comp` as a
     * comparator, and moving toward the root of the underlying tree.
     *
     * NOTE: This is a private function that is called in a trusted context with already cached parameters. `value`
     * could be extracted from `self` and `index`, but that would require redundant storage read. These parameters are not
     * verified. It is the caller role to make sure the parameters are correct.
     */
    function _siftUp(
        Uint32Heap storage self,
        uint256 index,
        uint32 value,
        function(uint256, uint256) view returns (bool) comp
    ) private {
        unchecked {
            while (index > 0) {
                uint256 parentIndex = (index - 1) / 2;
                uint32 parentValue = _unsafeGet(self.tree, parentIndex);
                if (comp(parentValue, value)) break;
                _swap(self, index, parentIndex);
                index = parentIndex;
            }
        }
    }

    /**
     * @dev Read the `index`th element of a packed (8-per-slot) `uint32[]` storage array, skipping the
     * solidity "index-out-of-range" check. It is the caller's responsibility to make sure `index` is in bounds.
     */
    function _unsafeGet(uint32[] storage tree, uint256 index) private view returns (uint32 value) {
        assembly ("memory-safe") {
            mstore(0x00, tree.slot)
            let slot := add(keccak256(0x00, 0x20), shr(3, index))
            value := and(shr(shl(5, and(index, 7)), sload(slot)), shr(224, not(0)))
        }
    }

    /**
     * @dev Write `value` to the `index`th element of a packed (8-per-slot) `uint32[]` storage array, skipping
     * the solidity "index-out-of-range" check. It is the caller's responsibility to make sure `index` is in bounds.
     */
    function _unsafeSet(uint32[] storage tree, uint256 index, uint32 value) private {
        assembly ("memory-safe") {
            mstore(0x00, tree.slot)
            let slot := add(keccak256(0x00, 0x20), shr(3, index))
            let shift := shl(5, and(index, 7)) // bit offset of the element in its slot
            // clear the target sub-word, then splice `value` into it (`value` already fits in 32 bits)
            sstore(slot, or(and(sload(slot), not(shl(shift, shr(224, not(0))))), shl(shift, value)))
        }
    }
}
