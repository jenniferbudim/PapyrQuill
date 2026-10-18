#!/usr/bin/env python3
"""Builds assets/dictionary/en_words.txt from the Hunspell en_US dictionary
(SCOWL word list, permissive licence): expands every word with its prefix and
suffix rules, lower-cases, and keeps plain words (letters and apostrophes).

Usage: python3 tool/build_wordlist.py [en_US.aff] [en_US.dic] [out.txt]
"""
import re
import sys

aff_path = sys.argv[1] if len(sys.argv) > 1 else '/usr/share/hunspell/en_US.aff'
dic_path = sys.argv[2] if len(sys.argv) > 2 else '/usr/share/hunspell/en_US.dic'
out_path = sys.argv[3] if len(sys.argv) > 3 else 'assets/dictionary/en_words.txt'

rules = {'PFX': {}, 'SFX': {}}   # kind -> flag -> (cross, [rules])
with open(aff_path, encoding='utf-8') as f:
    for line in f:
        parts = line.split()
        if len(parts) >= 4 and parts[0] in rules and parts[2] in ('Y', 'N') \
                and parts[3].isdigit():
            rules[parts[0]][parts[1]] = (parts[2] == 'Y', [])
        elif len(parts) >= 5 and parts[0] in rules:
            kind, flag, strip, add, cond = parts[:5]
            strip = '' if strip == '0' else strip
            add = '' if add == '0' else add
            add = add.split('/')[0]
            pattern = '^' + cond if kind == 'PFX' else cond + '$'
            if cond == '.':
                pattern = '.'
            rules[kind][flag][1].append((strip, add, re.compile(pattern)))


def apply(kind, flag, word):
    out = []
    if flag not in rules[kind]:
        return out
    for strip, add, cond in rules[kind][flag][1]:
        if not cond.search(word):
            continue
        if kind == 'SFX':
            if strip and not word.endswith(strip):
                continue
            out.append(word[:len(word) - len(strip)] + add)
        else:
            if strip and not word.startswith(strip):
                continue
            out.append(add + word[len(strip):])
    return out


words = set()
with open(dic_path, encoding='utf-8') as f:
    next(f)  # entry count
    for line in f:
        line = line.rstrip('\n').split('\t')[0]
        if not line:
            continue
        base, _, flags = line.partition('/')
        base = base.split(' ')[0]
        flags = flags.split(' ')[0]
        forms = {base}
        sfx = []
        for flag in flags:
            for w in apply('SFX', flag, base):
                forms.add(w)
                sfx.append((flag, w))
        for flag in flags:
            if flag not in rules['PFX']:
                continue
            cross = rules['PFX'][flag][0]
            for w in apply('PFX', flag, base):
                forms.add(w)
                if cross:
                    for sflag, sw in sfx:
                        if rules['SFX'][sflag][0]:
                            for w2 in apply('PFX', flag, sw):
                                forms.add(w2)
        words.update(forms)

ok = re.compile(r"^[a-zà-ÿ]+(?:'[a-zà-ÿ]+)*$")
final = sorted({w.lower().replace('’', "'") for w in words
                if ok.match(w.lower().replace('’', "'"))})
with open(out_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(final) + '\n')
print(len(final), 'words')
