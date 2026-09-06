from pathlib import Path
import json
base=Path(__file__).resolve().parent
pairs={}
for line in (base/'translations.txt').read_text().splitlines():
    if not line.strip(): continue
    de,en=line.split('|||',1)
    pairs[de.replace('\\n','\n')]=en.replace('\\n','\n')
for language in ('de','en'):
    folder=base/'Resources'/f'{language}.lproj'; folder.mkdir(parents=True,exist_ok=True)
    (folder/'Localizable.strings').write_text('\n'.join(json.dumps(key,ensure_ascii=False)+' = '+json.dumps(value if language=='en' else key,ensure_ascii=False)+';' for key,value in pairs.items())+'\n')
print(f'Localized {len(pairs)} interface strings in German and English')
