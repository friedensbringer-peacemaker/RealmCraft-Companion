"""Generate reviewable wiki Markdown from bundled help; never publish or overwrite output."""
from pathlib import Path
import argparse
import hashlib
import json
import re


def build(base, output):
    base, output = Path(base), Path(output)
    if output.exists() or output.is_symlink():
        raise ValueError('Output must be new')
    resources = base / 'Resources'
    config = json.loads((resources / 'PublicDocumentation.json').read_text())
    articles = json.loads((resources / 'HelpArticles.json').read_text())['articles']
    ids = [a['id'] for a in articles]
    if len(set(ids)) != len(ids) or any(not re.fullmatch(r'[a-zA-Z][a-zA-Z0-9-]*', i) for i in ids):
        raise ValueError('Invalid or duplicate help ID')
    if any(set(a.get('related', [])) - set(ids) for a in articles):
        raise ValueError('Unresolved help reference')
    repo = config['repository']
    if not re.fullmatch(r'https://github.com/[A-Za-z0-9-]+/[A-Za-z0-9_.-]+', repo):
        raise ValueError('Invalid project URL')
    labels = {k: v['en'] for k, v in config['labels'].items()}
    build_text = (base / 'build.sh').read_text()
    version = re.search(r'CFBundleShortVersionString</key><string>([0-9.]+)', build_text)[1]
    number = re.search(r'CFBundleVersion</key><string>([0-9]+)', build_text)[1]
    inputs = {'build.sh', 'Resources/HelpArticles.json', 'Resources/PublicDocumentation.json',
              'Resources/AgentSkills/realmcraft-public-docs/SKILL-en.md'}
    titles = {a['id']: a['enTitle'] for a in articles}
    def link(i):
        return f"[{titles[i]}]({repo}/wiki/Help-{i})"
    def footer(source):
        return f"\n\n---\n{labels['source']}: **{version} ({number})** · [{source}]({repo}/blob/main/RealmCraftCompanion/{source})\n\n{labels['generatedNotice']}\n\n{labels['credit']}\n"
    pages = {}
    for a in articles:
        resource = a.get('enResource')
        source = 'Resources/HelpArticles.json'
        if resource:
            if resource not in {'SETUP-en', 'TRANSFER-en', 'CHANGELOG', 'BACKLOG'}:
                raise ValueError('Unexpected resource reference')
            source = f'Resources/{resource}.md'
            inputs.add(source)
            body = (base / source).read_text()
        else:
            body = a['en']
            # Help's all-caps section headings become Markdown headings, preserving prose.
            body = '\n'.join('## ' + line if line.strip() and line == line.upper() and
                             re.search('[A-Z]', line) and not line.startswith(('#', '-', '*', '>'))
                             else line for line in body.splitlines())
        related = ' · '.join(link(i) for i in a.get('related', []))
        pages[f"Help-{a['id']}.md"] = f"# {a['enTitle']}\n\n{body}\n\n## {labels['related']}\n\n{related}" + footer(source)
    pages['Home.md'] = f"# {labels['home']}\n\n**{labels['credit']}**\n\n{labels['intro']}\n\n> {labels['versionNotice']}\n\n" + \
        f"**{link('start')}** · [{labels['gallery']}]({repo}/wiki/Screenshot-gallery) · [{labels['downloads']}]({repo}/releases/latest) · [{labels['demo']}](https://friedensbringer-peacemaker.github.io/RealmCraft-Companion/)\n\n## {labels['contents']}\n\n" + \
        '\n'.join('- ' + link(a['id']) for a in articles) + f"\n\n[{labels['maintenance']}]({repo}/wiki/Maintaining-the-wiki)" + footer('Resources/HelpArticles.json')
    gallery = f"# {labels['gallery']}\n\n{labels['galleryIntro']}\n\n"
    for item in config['screenshots']:
        path = item['path']
        if not re.fullmatch(r'docs/screenshots/v[0-9.]+/[a-z0-9-]+\.png', path) or not re.fullmatch('[a-f0-9]{64}', item['sha256']):
            raise ValueError('Invalid screenshot record')
        gallery += f"## {item['title']['en']}\n\n![{item['title']['en']}]({repo}/raw/refs/heads/main/{path})\n\n{item['caption']['en']}\n\n`{item['version']}` · SHA-256 `{item['sha256']}`\n\n"
    pages['Screenshot-gallery.md'] = gallery + footer('Resources/PublicDocumentation.json')
    skill = 'Resources/AgentSkills/realmcraft-public-docs/SKILL-en.md'
    pages['Maintaining-the-wiki.md'] = (base / skill).read_text().split('---', 2)[2].strip() + footer(skill)
    pages['_Sidebar.md'] = f"[Home]({repo}/wiki)\n\n" + '\n'.join('- ' + link(i) for i in ['start','setup','library','maps','ores','metro','crafting','builds','aiExport','feedback']) + f"\n- [{labels['gallery']}]({repo}/wiki/Screenshot-gallery)\n- [{labels['maintenance']}]({repo}/wiki/Maintaining-the-wiki)\n"
    pages['_Footer.md'] = labels['credit'] + '\n'
    manifest = {'version': version, 'build': number,
                'sources': {name: hashlib.sha256((base/name).read_bytes()).hexdigest() for name in sorted(inputs)},
                'pages': {name: hashlib.sha256(text.encode()).hexdigest() for name,text in sorted(pages.items())}}
    output.mkdir(parents=True)
    for name,text in pages.items():
        (output/name).write_text(text, encoding='utf-8')
    (output/'source-manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
    return manifest

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    result = build(Path(__file__).resolve().parents[1], args.output)
    print(f"Generated {len(result['pages'])} wiki pages for {result['version']} ({result['build']})")
