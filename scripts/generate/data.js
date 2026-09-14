import { capitalize, range, product } from '../helpers.js';

// ─── Shared helpers ───
export * as sanitize from './helpers/sanitize.js';
export * from './helpers/conversion.js';
export * from '../helpers.js';

export const args = (...parts) => parts.filter(Boolean).join(', ');

// ─── All solidity types ───
export const TYPES = Object.fromEntries(
  [
    { type: 'address', size: 160 },
    { type: 'bool', name: 'Boolean', size: 1 },
    ...range(1, 33).map(size => ({
      type: `bytes${size}`,
      size: 8 * size,
      upcastTo: size < 32 ? 'bytes32' : undefined,
    })),
    ...range(8, 257, 8).map(size => ({
      type: `uint${size}`,
      size,
      upcastTo: size < 256 ? 'uint256' : undefined,
    })),
    ...range(8, 257, 8).map(size => ({
      type: `int${size}`,
      size,
      upcastTo: size < 256 ? 'int256' : undefined,
      signed: true,
    })),
    { type: 'string' },
    { type: 'bytes' },
  ]
    .map(entry => ({
      ...entry,
      name: entry.name ?? capitalize(entry.type),
      location: entry.size ? '' : 'memory',
    }))
    .map((entry, _, all) => ({
      ...entry,
      upcastTo: all.find(type => type.type === entry.upcastTo),
      upcastOf: all.filter(type => type.upcastTo === entry.type),
    }))
    .map(entry => [entry.type, entry]),
);

// ─── Arrays ───
export const ARRAYS_TYPES = [TYPES.address, TYPES.bytes32, TYPES.uint256, TYPES.bytes, TYPES.string];

export const ARRAYS_VALUE_TYPES = ARRAYS_TYPES.filter(type => type.size);
export const ARRAYS_CAST_TYPES = ARRAYS_VALUE_TYPES.filter(type => type.type !== 'uint256');
export const ARRAYS_SORT_TYPES = ARRAYS_VALUE_TYPES.toSorted((a, b) => (b.type == 'uint256') - (a.type == 'uint256'));
export const ARRAYS_COMPARATOR_TYPES = ARRAYS_VALUE_TYPES.filter(type => type.size < 256);

// ─── Checkpoints (Checkpoints + Checkpoints.t) ───
export const CHECKPOINTS_LENGTH = [256, 224, 208, 160].map(size => ({ size, keySize: size < 256 ? 256 - size : 256 }));

// ─── Enumerable (EnumerableSet, EnumerableMap) ───
const enumerableName = ({ type, name }) => (type === 'uint256' ? 'Uint' : name);

export const SET_TYPES = [TYPES.bytes32, TYPES.bytes4, TYPES.address, TYPES.uint256, TYPES.string, TYPES.bytes].map(
  value => ({
    name: `${enumerableName(value)}Set`,
    value,
  }),
);

export const MAP_TYPES = []
  .concat(
    // value type maps
    [TYPES.uint256, TYPES.address, TYPES.bytes32]
      .flatMap((key, _, array) => array.map(value => ({ key, value })))
      .slice(0, -1), // remove bytes32 → bytes32 (last one) that is already defined
    // other value type maps
    { key: TYPES.bytes4, value: TYPES.address },
    // non-value type maps
    { key: TYPES.bytes, value: TYPES.bytes },
  )
  .map(({ key, value }) => ({
    name: `${enumerableName(key)}To${enumerableName(value)}Map`,
    key,
    value,
  }));

// ─── Heap ───
// One entry per supported value width. Widths below 256 pack `256 / size` values per storage slot; the
// packed-access shifts are all derived from `size` (see the `.eta` template's assembly accessors).
export const HEAP_TYPES = [256, 128, 64, 32].map(size => ({
  size,
  name: `Uint${size}Heap`,
  valueType: `uint${size}`,
  packed: size < 256,
  perSlot: 256 / size,
  blockShift: Math.log2(256 / size), // element index -> slot offset: shr(blockShift, index)
  offsetMask: 256 / size - 1, // element index -> position in slot: and(index, offsetMask)
  valueShift: Math.log2(size), // position in slot -> bit shift: shl(valueShift, position)
  maskShift: 256 - size, // low `size` bits mask: shr(maskShift, not(0))
}));

// ─── MerkleProof ───
export const MERKLEPROOF_DEFAULT_HASH = 'Hashes.commutativeKeccak256';
export const MERKLEPROOF_OPTS = product(
  [
    { suffix: '', location: 'memory' },
    { suffix: 'Calldata', location: 'calldata' },
  ],
  [{ visibility: 'pure' }, { visibility: 'view', hash: 'hasher' }],
).map(objs => Object.assign({}, ...objs));

// ─── Packing (Packing + Packing.t) ───
export const PACKING_SIZES = [1, 2, 4, 6, 8, 10, 12, 16, 20, 22, 24, 28, 32];

// ─── SafeCast ───
// downcast target bit-lengths: 248, 240, ..., 8
export const SAFECAST_LENGTHS = Array.from({ length: 31 }, (_, i) => 248 - i * 8);

// ─── Slot family (StorageSlot, TransientSlot, SlotDerivation, and their mocks/tests) ───
export const SLOT_TYPES = Object.values(TYPES).filter(type => !type.upcastTo);
