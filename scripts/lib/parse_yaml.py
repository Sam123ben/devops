#!/usr/bin/env python

import yaml
import sys
import argparse
import flatten

if __name__ == '__main__':
  parser = argparse.ArgumentParser(description='Load some values from a yaml file')
  requiredArgs = parser.add_argument_group('required arguments')
  requiredArgs.add_argument("-f", "--file", dest="filename", nargs='?', type=argparse.FileType('r'),
    help="YAML_FILE to read the value from, or '-' if to read from STDIN", required=True, metavar="YAML_FILE|-")
  args = parser.parse_args()
  inputFile=args.filename

  if inputFile.name == '<stdin>':
    y=yaml.safe_load(sys.stdin.read())
  else:
    y=yaml.safe_load(open(inputFile.name).read())

  flat=flatten.json2json(y)

  for k,v in flat.items():
    print("export "+k+"='"+str(v)+"'")