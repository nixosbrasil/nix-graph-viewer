#!/usr/bin/env python3

from subprocess import PIPE, run
from argparse import ArgumentParser
from sys import stderr
from json import loads, dump
from pathlib import Path

TEMPLATE_FILE = Path(__file__).parent / "result"

parser = ArgumentParser(description="Dumps path relations of a Nix closure")
parser.add_argument('-i', type=str, help="Nix flake ref or nix store path", required=True)
parser.add_argument('-o', type=str, help="Where to save the generated HTML file", required=True)
parser.add_argument('-j', type=bool, help="JSON only", default=False)
args = parser.parse_args()

proc = run(["nix", "path-info", "-Sh", args.i, "--json", "--recursive"], stdout=PIPE, stderr=stderr, check=True)
items = loads(proc.stdout)
links = {}
backlinks = {}
paths = {}
for item in items:
    path = item['path']
    paths[path] = {
        'nar': item['narSize'],
        'closure': item['closureSize']
    }
    for reference in item['references']:
        if path not in links:
            links[path] = []
        links[path].append(reference)

        if reference not in backlinks:
            backlinks[reference] = []
        backlinks[reference].append(path)

with open(args.o, 'w') as w:
    if not args.j:
        with open(str(TEMPLATE_FILE), 'r') as r:
            while True:
                chunk = r.read(128*1024)
                if not chunk:
                    break
                w.write(chunk)
        print("<script>window.onload = () => window.setData(", file=w)
    dump(dict(links=links,backlinks=backlinks,paths=paths), w)
    if not args.j:
        print(")</script>", file=w)

