import struct
import unittest
import numpy as np
from realmcraft_map.chunks import ChunkError, decode


def rle(values):
    output = bytearray()
    start = 0
    while start < len(values):
        end = start+1
        while end < len(values) and values[end] == values[start]:
            end += 1
        count = end-start
        while count > 255:
            output.append(0)
            count -= 255
        output.extend((count, int(values[start])))
        start = end
    return bytes(output)


def fixture(blocks=None, x=-16, z=32, dimension=0):
    if blocks is None: blocks = np.zeros((256,16,16), dtype=np.uint32)
    output = bytearray(struct.pack('>IiiBBB',9,x,z,dimension,8,16))
    for section in blocks.reshape(16,4096):
        count = int(np.count_nonzero(section & 4095))
        output.extend(struct.pack('>I',count))
        if count:
            payload = b'\0'*4 + b''.join(rle((section >> shift)&255) for shift in (0,8,16,24))
            output.extend(struct.pack('>I',len(payload)))
            output.extend(payload)
    return bytes(output)


class DecoderTests(unittest.TestCase):
    def test_vertical_run_index_covers_every_column(self):
        blocks=np.zeros((256,16,16),dtype=np.uint32)
        blocks[:10,:,:]=1
        blocks[50,3,7]=72
        columns=decode(fixture(blocks)).columns()
        offsets=np.frombuffer(columns[:1028],dtype='<u4')
        records=np.frombuffer(columns[1028:],dtype=[('y','u1'),('id','<u2')])
        self.assertEqual(len(offsets),257)
        index=7*16+3
        self.assertEqual(records[offsets[index]:offsets[index+1]].tolist(),[(0,1),(10,0),(50,72),(51,0)])
        self.assertEqual(int(offsets[-1]),len(records))

    def test_coordinates_byte_channels_and_orientation(self):
        blocks=np.zeros((256,16,16),dtype=np.uint32)
        blocks[0,:,:]=25
        blocks[69,3,7]=0xA1B2C026
        blocks[70,3,7]=639  # Cave air must not obscure the block beneath.
        chunk=decode(fixture(blocks),'o.-16,32')
        self.assertEqual(int(chunk.blocks[69,3,7]),0xA1B2C026)
        ids,heights=chunk.surface()
        self.assertEqual(int(ids[7,3]),38)
        self.assertEqual(int(heights[7,3]),69)
        self.assertEqual(int(heights[3,7]),0)

    def test_long_rle_and_payload_end(self):
        blocks=np.full((256,16,16),1,dtype=np.uint32)
        raw=fixture(blocks)
        chunk=decode(raw+b'opaque entities and lights')
        self.assertEqual(chunk.block_data_end,len(raw))
        np.testing.assert_array_equal(chunk.blocks,blocks)

    def test_nether_cut(self):
        blocks=np.zeros((256,16,16),dtype=np.uint32)
        blocks[40,:,:]=27
        blocks[127,:,:]=25
        chunk=decode(fixture(blocks,dimension=1),'n.-16,32')
        ids,heights=chunk.surface(90)
        self.assertTrue(np.all(ids==27));self.assertTrue(np.all(heights==40))
        self.assertTrue(np.all(chunk.surface()[1]==127))

    def test_stale_nonair_counter_is_not_a_checksum(self):
        blocks=np.ones((256,16,16),dtype=np.uint32)
        raw=bytearray(fixture(blocks));struct.pack_into('>I',raw,15,4000)
        self.assertTrue(np.all(decode(bytes(raw)).blocks==1))

    def test_invalid_headers(self):
        raw=fixture()
        for bad in [b'',raw[:12],struct.pack('>I',10)+raw[4:],raw[:14]+b'\xff'+raw[15:]]:
            with self.assertRaises(ChunkError):decode(bad)
        with self.assertRaises(ChunkError):decode(raw,'o.0,0')
        with self.assertRaises(ChunkError):decode(raw,'n.-16,32')

    def test_truncated_and_overflow_payload(self):
        blocks=np.ones((256,16,16),dtype=np.uint32)
        raw=fixture(blocks)
        with self.assertRaises(ChunkError):decode(raw[:40])
        bad=bytearray(raw);bad[27:45]=b'\0'*18
        with self.assertRaises(ChunkError):decode(bytes(bad))


if __name__=='__main__':unittest.main()
