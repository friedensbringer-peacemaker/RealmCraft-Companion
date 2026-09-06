from pathlib import Path
import sys
import numpy as np
from test_chunks import fixture
from realmcraft_map.build import build
root=Path(sys.argv[1]);source=root/'world';source.mkdir(parents=True,exist_ok=True)
a=np.zeros((256,16,16),dtype=np.uint32);a[:25,:,:]=1;a[50,3,7]=72
(source/'o.-16,32').write_bytes(fixture(a))
build(source,root/'map',cache=root/'cache')
